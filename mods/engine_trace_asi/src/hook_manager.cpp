#include "hook_manager.h"

#include <windows.h>

#include <sstream>

namespace engine_trace {
namespace {

std::string FormatWin32Error(const char* context, DWORD error_code) {
    std::ostringstream oss;
    oss << context << " (GetLastError=" << error_code << ")";
    return oss.str();
}

bool IsExecutablePage(DWORD protect) {
    const DWORD masked = protect & 0xFF;
    return masked == PAGE_EXECUTE || masked == PAGE_EXECUTE_READ || masked == PAGE_EXECUTE_READWRITE ||
           masked == PAGE_EXECUTE_WRITECOPY;
}

}  // namespace

class HookManager::Backend {
  public:
    virtual ~Backend() = default;
    virtual HookInstallResult Install(const std::vector<HookBinding>& bindings, TraceRuntime* runtime) = 0;
    virtual void Uninstall() = 0;
};

#if defined(_M_IX86)

class BreakpointHookBackend final : public HookManager::Backend {
  public:
    BreakpointHookBackend() = default;
    ~BreakpointHookBackend() override { Uninstall(); }

    HookInstallResult Install(const std::vector<HookBinding>& bindings, TraceRuntime* runtime) override {
        HookInstallResult result;
        if (installed_) {
            result.ok = true;
            result.detail = "backend already installed";
            return result;
        }
        if (!runtime) {
            result.ok = false;
            result.detail = "trace runtime is null";
            return result;
        }
        runtime_ = runtime;

        tls_index_ = ::TlsAlloc();
        if (tls_index_ == TLS_OUT_OF_INDEXES) {
            result.ok = false;
            result.detail = FormatWin32Error("TlsAlloc failed", ::GetLastError());
            runtime_->LogDiagnostic("error", result.detail);
            return result;
        }

        veh_handle_ = ::AddVectoredExceptionHandler(1, &BreakpointHookBackend::HandleExceptionThunk);
        if (!veh_handle_) {
            result.ok = false;
            result.detail = FormatWin32Error("AddVectoredExceptionHandler failed", ::GetLastError());
            runtime_->LogDiagnostic("error", result.detail);
            ::TlsFree(tls_index_);
            tls_index_ = TLS_OUT_OF_INDEXES;
            return result;
        }

        active_ = this;
        for (const HookBinding& binding : bindings) {
            if (binding.resolved_address == 0) {
                runtime_->LogDiagnostic(
                    "error",
                    "hook install rejected: resolved address is zero",
                    binding.spec.probe_id,
                    binding.resolved_address);
                continue;
            }
            HookInstallResult probe_result = InstallOne(binding);
            if (!probe_result.ok) {
                runtime_->LogDiagnostic(
                    "warning",
                    "hook install failed (skipping): " + probe_result.detail,
                    binding.spec.probe_id,
                    binding.resolved_address);
                continue;
            }
        }

        if (hooks_.empty()) {
            result.ok = false;
            result.detail = "no hooks were installed (all probes failed or skipped)";
            runtime_->LogDiagnostic("warning", result.detail);
            Uninstall();
            return result;
        }
        installed_ = true;
        result.ok = true;
        result.detail = "breakpoint hook backend installed";
        runtime_->LogDiagnostic("info", result.detail);
        return result;
    }

    void Uninstall() override {
        for (InstalledHook& hook : hooks_) {
            WriteByte(hook.address, hook.original_byte);
        }
        hooks_.clear();

        if (veh_handle_) {
            ::RemoveVectoredExceptionHandler(veh_handle_);
            veh_handle_ = nullptr;
        }
        active_ = nullptr;

        if (tls_index_ != TLS_OUT_OF_INDEXES) {
            ::TlsFree(tls_index_);
            tls_index_ = TLS_OUT_OF_INDEXES;
        }
        installed_ = false;
    }

  private:
    struct InstalledHook {
        ProbeSpec spec;
        uintptr_t address = 0;
        uint8_t original_byte = 0;
    };

    static LONG CALLBACK HandleExceptionThunk(PEXCEPTION_POINTERS exception_info) {
        if (!active_) {
            return EXCEPTION_CONTINUE_SEARCH;
        }
        return active_->HandleException(exception_info);
    }

    LONG HandleException(PEXCEPTION_POINTERS exception_info) {
        if (!exception_info || !exception_info->ExceptionRecord || !exception_info->ContextRecord) {
            return EXCEPTION_CONTINUE_SEARCH;
        }
        const DWORD code = exception_info->ExceptionRecord->ExceptionCode;
        if (code == EXCEPTION_BREAKPOINT) {
            uintptr_t fault_ip = static_cast<uintptr_t>(exception_info->ContextRecord->Eip - 1U);
            for (size_t i = 0; i < hooks_.size(); ++i) {
                InstalledHook& hook = hooks_[i];
                if (hook.address != fault_ip) {
                    continue;
                }

                runtime_->OnProbeEntry(hook.spec, fault_ip);
                if (!WriteByte(hook.address, hook.original_byte)) {
                    runtime_->LogDiagnostic(
                        "error",
                        FormatWin32Error("failed to restore original byte during breakpoint", ::GetLastError()),
                        hook.spec.probe_id,
                        hook.address);
                    return EXCEPTION_CONTINUE_SEARCH;
                }

                ::TlsSetValue(tls_index_, reinterpret_cast<LPVOID>(i + 1));
                exception_info->ContextRecord->Eip = static_cast<DWORD>(hook.address);
                exception_info->ContextRecord->EFlags |= 0x100;
                return EXCEPTION_CONTINUE_EXECUTION;
            }
            return EXCEPTION_CONTINUE_SEARCH;
        }

        if (code == EXCEPTION_SINGLE_STEP) {
            const ULONG_PTR raw = reinterpret_cast<ULONG_PTR>(::TlsGetValue(tls_index_));
            if (raw == 0) {
                return EXCEPTION_CONTINUE_SEARCH;
            }
            const size_t index = static_cast<size_t>(raw - 1);
            ::TlsSetValue(tls_index_, nullptr);
            if (index >= hooks_.size()) {
                return EXCEPTION_CONTINUE_SEARCH;
            }

            InstalledHook& hook = hooks_[index];
            if (!WriteByte(hook.address, 0xCC)) {
                runtime_->LogDiagnostic(
                    "error",
                    FormatWin32Error("failed to re-arm breakpoint hook", ::GetLastError()),
                    hook.spec.probe_id,
                    hook.address);
                return EXCEPTION_CONTINUE_SEARCH;
            }
            runtime_->OnProbeExit(hook.spec, static_cast<uintptr_t>(exception_info->ContextRecord->Eip));
            return EXCEPTION_CONTINUE_EXECUTION;
        }

        return EXCEPTION_CONTINUE_SEARCH;
    }

    HookInstallResult InstallOne(const HookBinding& binding) {
        HookInstallResult result;
        MEMORY_BASIC_INFORMATION mbi{};
        if (::VirtualQuery(reinterpret_cast<LPCVOID>(binding.resolved_address), &mbi, sizeof(mbi)) == 0) {
            result.ok = false;
            result.detail = FormatWin32Error("VirtualQuery failed for hook target", ::GetLastError());
            runtime_->LogDiagnostic("error", result.detail, binding.spec.probe_id, binding.resolved_address);
            return result;
        }
        if (mbi.State != MEM_COMMIT) {
            result.ok = false;
            result.detail = "hook target is not committed memory";
            runtime_->LogDiagnostic("error", result.detail, binding.spec.probe_id, binding.resolved_address);
            return result;
        }
        if (!IsExecutablePage(mbi.Protect) || (mbi.Protect & (PAGE_GUARD | PAGE_NOACCESS))) {
            result.ok = false;
            result.detail = "hook target is not executable";
            runtime_->LogDiagnostic("error", result.detail, binding.spec.probe_id, binding.resolved_address);
            return result;
        }

        InstalledHook hook;
        hook.spec = binding.spec;
        hook.address = binding.resolved_address;
        hook.original_byte = *reinterpret_cast<uint8_t*>(binding.resolved_address);
        if (!WriteByte(binding.resolved_address, 0xCC)) {
            result.ok = false;
            result.detail = FormatWin32Error("VirtualProtect/write failed while arming breakpoint", ::GetLastError());
            runtime_->LogDiagnostic("error", result.detail, binding.spec.probe_id, binding.resolved_address);
            return result;
        }
        hooks_.push_back(hook);
        runtime_->LogDiagnostic("info", "hook installed", binding.spec.probe_id, binding.resolved_address);
        result.ok = true;
        result.detail = "hook installed";
        return result;
    }

    bool WriteByte(uintptr_t address, uint8_t value) {
        DWORD old_protect = 0;
        uint8_t* dst = reinterpret_cast<uint8_t*>(address);
        if (!::VirtualProtect(dst, 1, PAGE_EXECUTE_READWRITE, &old_protect)) {
            return false;
        }
        *dst = value;
        DWORD restore_unused = 0;
        ::VirtualProtect(dst, 1, old_protect, &restore_unused);
        ::FlushInstructionCache(::GetCurrentProcess(), dst, 1);
        return true;
    }

    static BreakpointHookBackend* active_;

    bool installed_ = false;
    DWORD tls_index_ = TLS_OUT_OF_INDEXES;
    PVOID veh_handle_ = nullptr;
    TraceRuntime* runtime_ = nullptr;
    std::vector<InstalledHook> hooks_;
};

BreakpointHookBackend* BreakpointHookBackend::active_ = nullptr;

#else

class BreakpointHookBackend final : public HookManager::Backend {
  public:
    HookInstallResult Install(const std::vector<HookBinding>&, TraceRuntime* runtime) override {
        HookInstallResult result;
        result.ok = false;
        result.detail = "breakpoint backend currently supports only x86 builds";
        if (runtime) {
            runtime->LogDiagnostic("error", result.detail);
        }
        return result;
    }

    void Uninstall() override {}
};

#endif

HookManager::HookManager() : backend_(nullptr) {}

HookManager::~HookManager() {
    if (backend_) {
        backend_->Uninstall();
        delete backend_;
        backend_ = nullptr;
    }
}

HookInstallResult HookManager::Install(const std::vector<HookBinding>& bindings, TraceRuntime* runtime) {
    if (!backend_) {
        backend_ = new (std::nothrow) BreakpointHookBackend();
        if (!backend_) {
            HookInstallResult result;
            result.ok = false;
            result.detail = "failed to allocate hook backend";
            return result;
        }
    }
    return backend_->Install(bindings, runtime);
}

void HookManager::Uninstall() {
    if (backend_) {
        backend_->Uninstall();
    }
}

}  // namespace engine_trace
