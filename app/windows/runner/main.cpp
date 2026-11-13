#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdint>
#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

using CliDispatch = bool (*)(uint32_t, const char*, int32_t*);
using ForwardToRunningInstance = bool (*)(uint32_t);
using SetAppUserModelIdFn = bool (*)(uint32_t);

HMODULE LoadBridge() {
  wchar_t module_path[MAX_PATH];
  const DWORD length = ::GetModuleFileNameW(nullptr, module_path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return nullptr;
  }
  std::wstring library_path(module_path, length);
  library_path = library_path.substr(0, library_path.find_last_of(L"\\/") + 1) +
                 L"godothub_bridge.dll";
  return ::LoadLibraryW(library_path.c_str());
}

bool RunCli(HMODULE library, int* exit_code) {
  if (library == nullptr) {
    return false;
  }
  const auto dispatch = reinterpret_cast<CliDispatch>(
      ::GetProcAddress(library, "godothub_cli_dispatch"));
  int32_t code = 0;
  if (dispatch == nullptr ||
      !dispatch(GODOTHUB_CHANNEL, GODOTHUB_VERSION, &code)) {
    return false;
  }
  *exit_code = code;
  return true;
}

bool ForwardedToRunningInstance(HMODULE library) {
  if (library == nullptr) {
    return false;
  }
  const auto forward = reinterpret_cast<ForwardToRunningInstance>(
      ::GetProcAddress(library, "godothub_forward_to_running_instance"));
  return forward != nullptr && forward(GODOTHUB_CHANNEL);
}

void SetAppUserModelId(HMODULE library) {
  if (library == nullptr) {
    return;
  }
  const auto set_id = reinterpret_cast<SetAppUserModelIdFn>(
      ::GetProcAddress(library, "godothub_set_app_user_model_id"));
  if (set_id != nullptr) {
    set_id(GODOTHUB_CHANNEL);
  }
}

}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HMODULE bridge = LoadBridge();
  int cli_exit_code = 0;
  if (RunCli(bridge, &cli_exit_code)) {
    return cli_exit_code;
  }
  if (ForwardedToRunningInstance(bridge)) {
    return EXIT_SUCCESS;
  }
  SetAppUserModelId(bridge);

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_impeller_switch(flutter::ImpellerSwitch::Disabled);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"GodotHub Beta", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
