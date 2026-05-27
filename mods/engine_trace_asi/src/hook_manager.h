#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "probe_runtime.h"

namespace engine_trace {

struct HookInstallResult {
    bool ok = false;
    std::string detail;
};

struct HookBinding {
    ProbeSpec spec;
    uintptr_t resolved_address = 0;
};

class HookManager {
  public:
    HookManager();
    ~HookManager();

    HookInstallResult Install(const std::vector<HookBinding>& bindings, TraceRuntime* runtime);
    void Uninstall();

  private:
    class Backend;
    Backend* backend_;
};

}  // namespace engine_trace
