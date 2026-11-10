#include <dlfcn.h>
#include <limits.h>
#include <unistd.h>

#include <cstdint>
#include <string>

#include "my_application.h"

namespace {

using CliDispatch = bool (*)(uint32_t, const char*, int32_t*);
using ForwardToRunningInstance = bool (*)(uint32_t);

void* LoadBridge() {
  char exe_path[PATH_MAX];
  const ssize_t length = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
  if (length <= 0) {
    return nullptr;
  }
  std::string library_path(exe_path, static_cast<size_t>(length));
  library_path =
      library_path.substr(0, library_path.find_last_of('/') + 1) + "lib/libgodothub_bridge.so";
  return dlopen(library_path.c_str(), RTLD_NOW | RTLD_GLOBAL);
}

bool RunCli(void* library, int* exit_code) {
  if (library == nullptr) {
    return false;
  }
  const auto dispatch =
      reinterpret_cast<CliDispatch>(dlsym(library, "godothub_cli_dispatch"));
  int32_t code = 0;
  if (dispatch == nullptr || !dispatch(GODOTHUB_CHANNEL, GODOTHUB_VERSION, &code)) {
    return false;
  }
  *exit_code = code;
  return true;
}

bool ForwardedToRunningInstance(void* library) {
  if (library == nullptr) {
    return false;
  }
  const auto forward = reinterpret_cast<ForwardToRunningInstance>(
      dlsym(library, "godothub_forward_to_running_instance"));
  return forward != nullptr && forward(GODOTHUB_CHANNEL);
}

}

int main(int argc, char** argv) {
  void* bridge = LoadBridge();
  int cli_exit_code = 0;
  if (RunCli(bridge, &cli_exit_code)) {
    return cli_exit_code;
  }
  if (ForwardedToRunningInstance(bridge)) {
    return 0;
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
