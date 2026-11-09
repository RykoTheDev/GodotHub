use std::sync::{Mutex, OnceLock};
use tauri::AppHandle;

use godothub_core::recent::RecentProject;

pub(crate) fn refresh(app: &AppHandle, projects: Vec<RecentProject>) {
    static LAST: OnceLock<Mutex<Option<Vec<RecentProject>>>> = OnceLock::new();
    let mut last = LAST
        .get_or_init(|| Mutex::new(None))
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner);
    if last.as_ref() == Some(&projects) {
        return;
    }
    *last = Some(projects.clone());
    drop(last);
    platform::apply(app, projects);
}

#[cfg(windows)]
mod platform {
    use super::RecentProject;
    use godothub_core::recent::OPEN_PROJECT_ARG;
    use tauri::AppHandle;
    use windows::core::{Interface, HSTRING};
    use windows::Win32::Storage::EnhancedStorage::PKEY_Title;
    use windows::Win32::System::Com::StructuredStorage::PROPVARIANT;
    use windows::Win32::System::Com::{
        CoCreateInstance, CoInitializeEx, CoUninitialize, CLSCTX_INPROC_SERVER,
        COINIT_APARTMENTTHREADED,
    };
    use windows::Win32::System::Variant::VT_LPWSTR;
    use windows::Win32::UI::Shell::Common::{IObjectArray, IObjectCollection};
    use windows::Win32::UI::Shell::PropertiesSystem::IPropertyStore;
    use windows::Win32::UI::Shell::{
        DestinationList, EnumerableObjectCollection, ICustomDestinationList, IShellLinkW,
        SHStrDupW, ShellLink,
    };

    pub(super) fn apply(_app: &AppHandle, projects: Vec<RecentProject>) {
        std::thread::spawn(move || unsafe {
            let initialized = CoInitializeEx(None, COINIT_APARTMENTTHREADED).is_ok();
            if let Err(error) = build(&projects) {
                eprintln!("Could not update the jump list: {error}");
            }
            if initialized {
                CoUninitialize();
            }
        });
    }

    unsafe fn removed_ids(list: &IObjectArray) -> Vec<String> {
        let count = list.GetCount().unwrap_or(0);
        (0..count)
            .filter_map(|i| {
                let link: IShellLinkW = list.GetAt(i).ok()?;
                let mut buffer = [0u16; 1024];
                link.GetArguments(&mut buffer).ok()?;
                let len = buffer.iter().position(|c| *c == 0).unwrap_or(buffer.len());
                String::from_utf16_lossy(&buffer[..len])
                    .strip_prefix(OPEN_PROJECT_ARG)
                    .map(str::to_string)
            })
            .collect()
    }

    unsafe fn build(projects: &[RecentProject]) -> windows::core::Result<()> {
        let list: ICustomDestinationList =
            CoCreateInstance(&DestinationList, None, CLSCTX_INPROC_SERVER)?;
        let mut slots = 0u32;
        let removed: IObjectArray = list.BeginList(&mut slots)?;
        let removed = removed_ids(&removed);
        let exe = HSTRING::from(std::env::current_exe().unwrap_or_default().as_os_str());
        let collection: IObjectCollection =
            CoCreateInstance(&EnumerableObjectCollection, None, CLSCTX_INPROC_SERVER)?;
        let mut added = 0;
        for project in projects
            .iter()
            .filter(|p| !removed.contains(&p.id))
            .take(slots as usize)
        {
            let link: IShellLinkW = CoCreateInstance(&ShellLink, None, CLSCTX_INPROC_SERVER)?;
            link.SetPath(&exe)?;
            link.SetArguments(&HSTRING::from(format!("{OPEN_PROJECT_ARG}{}", project.id)))?;
            link.SetDescription(&HSTRING::from(project.path.as_str()))?;
            link.SetIconLocation(&exe, 0)?;
            let store: IPropertyStore = link.cast()?;
            let mut title = PROPVARIANT::default();
            (*title.Anonymous.Anonymous).vt = VT_LPWSTR;
            (*title.Anonymous.Anonymous).Anonymous.pwszVal =
                SHStrDupW(&HSTRING::from(project.label.as_str()))?;
            store.SetValue(&PKEY_Title, &title)?;
            store.Commit()?;
            collection.AddObject(&link)?;
            added += 1;
        }
        if added > 0 {
            let array: IObjectArray = collection.cast()?;
            list.AppendCategory(&HSTRING::from("Recent Projects"), &array)?;
        }
        list.CommitList()
    }
}

#[cfg(target_os = "macos")]
mod platform {
    use super::RecentProject;
    use objc2::rc::Retained;
    use objc2::runtime::{AnyClass, AnyObject, Imp, Sel};
    use objc2::{sel, MainThreadMarker, MainThreadOnly};
    use objc2_app_kit::{NSApplication, NSMenu, NSMenuItem};
    use objc2_foundation::NSString;
    use std::sync::{Mutex, OnceLock};
    use tauri::AppHandle;

    struct DockState {
        app: AppHandle,
        ids: Vec<String>,
    }

    struct MenuHandle(Retained<NSMenu>);
    unsafe impl Send for MenuHandle {}

    fn state() -> &'static Mutex<Option<DockState>> {
        static STATE: OnceLock<Mutex<Option<DockState>>> = OnceLock::new();
        STATE.get_or_init(|| Mutex::new(None))
    }

    fn menu() -> &'static Mutex<Option<MenuHandle>> {
        static MENU: OnceLock<Mutex<Option<MenuHandle>>> = OnceLock::new();
        MENU.get_or_init(|| Mutex::new(None))
    }

    extern "C" fn dock_menu(_this: &AnyObject, _cmd: Sel, _sender: *mut AnyObject) -> *mut NSMenu {
        menu()
            .lock()
            .ok()
            .and_then(|m| m.as_ref().map(|h| Retained::as_ptr(&h.0) as *mut NSMenu))
            .unwrap_or(std::ptr::null_mut())
    }

    extern "C" fn open_recent(_this: &AnyObject, _cmd: Sel, sender: *mut NSMenuItem) {
        if sender.is_null() {
            return;
        }
        let tag = unsafe { (*sender).tag() };
        let guard = state().lock().unwrap_or_else(std::sync::PoisonError::into_inner);
        if let Some(dock) = guard.as_ref() {
            if let Some(id) = usize::try_from(tag).ok().and_then(|i| dock.ids.get(i)) {
                tauri::async_runtime::spawn(godothub_core::projects::open_project(
                    crate::core_handle(&dock.app),
                    id.clone(),
                    true,
                    None,
                ));
            }
        }
    }

    fn install(delegate: &AnyObject) {
        static INSTALLED: OnceLock<()> = OnceLock::new();
        INSTALLED.get_or_init(|| unsafe {
            let class = delegate.class() as *const AnyClass as *mut AnyClass;
            let menu_imp = std::mem::transmute::<
                extern "C" fn(&AnyObject, Sel, *mut AnyObject) -> *mut NSMenu,
                Imp,
            >(dock_menu);
            objc2::ffi::class_addMethod(class, sel!(applicationDockMenu:), menu_imp, c"@@:@".as_ptr());
            let open_imp = std::mem::transmute::<extern "C" fn(&AnyObject, Sel, *mut NSMenuItem), Imp>(
                open_recent,
            );
            objc2::ffi::class_addMethod(class, sel!(godothubOpenRecent:), open_imp, c"v@:@".as_ptr());
        });
    }

    pub(super) fn apply(app: &AppHandle, projects: Vec<RecentProject>) {
        let handle = app.clone();
        let _ = app.run_on_main_thread(move || unsafe {
            let Some(mtm) = MainThreadMarker::new() else {
                return;
            };
            let ns_app = NSApplication::sharedApplication(mtm);
            let Some(delegate) = ns_app.delegate() else {
                return;
            };
            let delegate: &AnyObject = &*Retained::as_ptr(&delegate).cast::<AnyObject>();
            install(delegate);
            let dock = NSMenu::new(mtm);
            for (index, project) in projects.iter().enumerate() {
                let item = NSMenuItem::initWithTitle_action_keyEquivalent(
                    NSMenuItem::alloc(mtm),
                    &NSString::from_str(&project.label),
                    Some(sel!(godothubOpenRecent:)),
                    &NSString::from_str(""),
                );
                item.setTarget(Some(delegate));
                item.setTag(index as isize);
                item.setToolTip(Some(&NSString::from_str(&project.path)));
                dock.addItem(&item);
            }
            *state().lock().unwrap_or_else(std::sync::PoisonError::into_inner) = Some(DockState {
                app: handle,
                ids: projects.into_iter().map(|p| p.id).collect(),
            });
            *menu().lock().unwrap_or_else(std::sync::PoisonError::into_inner) =
                Some(MenuHandle(dock));
        });
    }
}

#[cfg(not(any(windows, target_os = "macos")))]
mod platform {
    use super::RecentProject;
    use tauri::AppHandle;

    pub(super) fn apply(_app: &AppHandle, _projects: Vec<RecentProject>) {}
}
