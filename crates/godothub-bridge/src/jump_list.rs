use std::sync::{Mutex, OnceLock};

use godothub_core::recent::RecentProject;

pub(crate) fn refresh(projects: Vec<RecentProject>) {
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
    platform::apply(projects);
}

#[cfg(windows)]
mod platform {
    use super::RecentProject;
    use godothub_core::recent::OPEN_PROJECT_ARG;
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

    pub(super) fn apply(projects: Vec<RecentProject>) {
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
        let exe = HSTRING::from(godothub_core::install_mode::launch_executable().unwrap_or_default().as_os_str());
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

#[cfg(not(windows))]
mod platform {
    use super::RecentProject;

    pub(super) fn apply(_projects: Vec<RecentProject>) {}
}
