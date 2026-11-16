using System;
using System.Runtime.InteropServices;
using System.Text;
using Accessibility;

[ComImport, Guid("30cbe57d-d9d0-452a-ab13-7ac5ac4825ee"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IUIAutomation {
  void CompareElements();
  void CompareRuntimeIds();
  IUIAutomationElement GetRootElement();
  IUIAutomationElement ElementFromHandle(IntPtr hwnd);
  void ElementFromPoint();
  IUIAutomationElement GetFocusedElement();
  void GetRootElementBuildCache();
  void ElementFromHandleBuildCache();
  void ElementFromPointBuildCache();
  void GetFocusedElementBuildCache();
  void CreateTreeWalker();
  IUIAutomationTreeWalker get_ControlViewWalker();
  IUIAutomationTreeWalker get_ContentViewWalker();
  IUIAutomationTreeWalker get_RawViewWalker();
}

[ComImport, Guid("4042c624-389c-4afc-a630-9df854a541fc"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IUIAutomationTreeWalker {
  IUIAutomationElement GetParentElement(IUIAutomationElement e);
  IUIAutomationElement GetFirstChildElement(IUIAutomationElement e);
  IUIAutomationElement GetLastChildElement(IUIAutomationElement e);
  IUIAutomationElement GetNextSiblingElement(IUIAutomationElement e);
}

[ComImport, Guid("d22108aa-8ac5-49a5-837b-37bbb3d7591e"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IUIAutomationElement {
  void SetFocus();
  void GetRuntimeId();
  void FindFirst();
  void FindAll();
  void FindFirstBuildCache();
  void FindAllBuildCache();
  void BuildUpdatedCache();
  [return: MarshalAs(UnmanagedType.Struct)] object GetCurrentPropertyValue(int propertyId);
  void GetCurrentPropertyValueEx();
  void GetCachedPropertyValue();
  void GetCachedPropertyValueEx();
  void GetCurrentPatternAs();
  void GetCachedPatternAs();
  [return: MarshalAs(UnmanagedType.IUnknown)] object GetCurrentPattern(int patternId);
}

[ComImport, Guid("fb377fbe-8ea6-46d5-9c73-6499642d3059"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IUIAutomationInvokePattern {
  void Invoke();
}

public static class UiaCom {
  const int NameId = 30005, ControlTypeId = 30003, ClassNameId = 30012, HasFocusId = 30008, InvokePatternId = 10000;

  public static string LastPath = "";

  [DllImport("oleacc.dll")] static extern int AccessibleObjectFromWindow(IntPtr hwnd, uint id, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out object acc);
  [DllImport("oleacc.dll")] static extern int AccessibleChildren(IAccessible parent, int start, int count, [Out] object[] children, out int obtained);
  [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hwnd, uint cmd);

  static IUIAutomation Create() {
    return (IUIAutomation)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("ff48dba4-60ef-4201-aa87-54103eef594e")));
  }

  static string Clean(string text) {
    return (text ?? "").Replace("\r", " ").Replace("\n", " / ");
  }

  static string Prop(IUIAutomationElement e, int id) {
    try {
      var v = e.GetCurrentPropertyValue(id);
      return v == null ? "" : Clean(Convert.ToString(v));
    } catch {
      return "";
    }
  }

  static bool Matches(string name, string target, bool exact) {
    return name == target || (!exact && name.StartsWith(target + " "));
  }

  public static string Dump(IntPtr hwnd, int max) {
    var uia = Create();
    var sb = new StringBuilder();
    int count = 0;
    Visit(uia.get_RawViewWalker(), uia.ElementFromHandle(hwnd), 0, sb, ref count, max);
    return sb.ToString();
  }

  static void Visit(IUIAutomationTreeWalker w, IUIAutomationElement e, int depth, StringBuilder sb, ref int count, int max) {
    if (e == null || count++ > max) return;
    sb.Append(new string(' ', depth * 2)).Append(Prop(e, ControlTypeId)).Append(" | ").Append(Prop(e, NameId)).Append(" | ").Append(Prop(e, ClassNameId));
    if (Prop(e, HasFocusId) == "True") sb.Append(" | focused");
    sb.AppendLine();
    IUIAutomationElement child = null;
    try { child = w.GetFirstChildElement(e); } catch {}
    while (child != null) {
      Visit(w, child, depth + 1, sb, ref count, max);
      try { child = w.GetNextSiblingElement(child); } catch { child = null; }
    }
  }

  static bool Invokable(IUIAutomationElement e) {
    try { return e.GetCurrentPattern(InvokePatternId) is IUIAutomationInvokePattern; } catch { return false; }
  }

  static IUIAutomationElement Find(IUIAutomation uia, IntPtr hwnd, string target) {
    var walker = uia.get_RawViewWalker();
    return Find(walker, uia.ElementFromHandle(hwnd), target, true, 0) ?? Find(walker, uia.ElementFromHandle(hwnd), target, false, 0);
  }

  static IUIAutomationElement Find(IUIAutomationTreeWalker w, IUIAutomationElement e, string target, bool exact, int depth) {
    if (e == null || depth > 60) return null;
    if (Matches(Prop(e, NameId), target, exact) && Invokable(e)) return e;
    IUIAutomationElement child = null;
    try { child = w.GetFirstChildElement(e); } catch {}
    while (child != null) {
      var hit = Find(w, child, target, exact, depth + 1);
      if (hit != null) return hit;
      try { child = w.GetNextSiblingElement(child); } catch { child = null; }
    }
    return null;
  }

  static IAccessible MsaaRoot(IntPtr hwnd) {
    var view = GetWindow(hwnd, 5);
    var iid = new Guid("618736E0-3C3D-11CF-810C-00AA00389B71");
    object acc;
    if (view == IntPtr.Zero || AccessibleObjectFromWindow(view, 0xFFFFFFFC, ref iid, out acc) != 0) return null;
    return acc as IAccessible;
  }

  static IAccessible MsaaFind(IAccessible a, string target, bool exact, int depth, ref int seen) {
    if (a == null || depth > 60 || seen++ > 5000) return null;
    string name = "";
    try { name = Clean(a.get_accName(0)); } catch {}
    if (target != null && Matches(name, target, exact)) {
      string action = null;
      try { action = a.get_accDefaultAction(0); } catch {}
      if (!string.IsNullOrEmpty(action)) return a;
    }
    int count = 0;
    try { count = a.accChildCount; } catch {}
    if (count <= 0) return null;
    var kids = new object[count];
    int got;
    if (AccessibleChildren(a, 0, count, kids, out got) != 0) return null;
    for (int i = 0; i < got; i++) {
      var hit = MsaaFind(kids[i] as IAccessible, target, exact, depth + 1, ref seen);
      if (hit != null) return hit;
    }
    return null;
  }

  static IAccessible MsaaLookup(IntPtr hwnd, string name) {
    int seen = 0;
    var exact = MsaaFind(MsaaRoot(hwnd), name, true, 0, ref seen);
    if (exact != null) return exact;
    seen = 0;
    return MsaaFind(MsaaRoot(hwnd), name, false, 0, ref seen);
  }

  public static int MsaaCount(IntPtr hwnd) {
    int seen = 0;
    MsaaFind(MsaaRoot(hwnd), null, true, 0, ref seen);
    return seen;
  }

  public static bool Exists(IntPtr hwnd, string name) {
    if (Find(Create(), hwnd, name) != null) return true;
    return MsaaLookup(hwnd, name) != null;
  }

  public static bool Invoke(IntPtr hwnd, string name) {
    var element = Find(Create(), hwnd, name);
    if (element != null) {
      ((IUIAutomationInvokePattern)element.GetCurrentPattern(InvokePatternId)).Invoke();
      LastPath = "uia";
      return true;
    }
    var acc = MsaaLookup(hwnd, name);
    if (acc == null) return false;
    acc.accDoDefaultAction(0);
    LastPath = "msaa";
    return true;
  }

  public static string Focused() {
    var e = Create().GetFocusedElement();
    return Prop(e, ControlTypeId) + " | " + Prop(e, NameId);
  }
}
