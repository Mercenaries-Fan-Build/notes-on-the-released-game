#include <windows.h>
#include <psapi.h>

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "hook_manager.h"
#include "probe_runtime.h"

namespace {

struct ProbeConfigEntry {
    std::string probe_id;
    uintptr_t value = 0;
    bool is_rva = false;
    bool capture_snapshot = false;
};

HMODULE g_module = nullptr;

constexpr DWORD kExpectedExeSize = 53482288;
constexpr DWORD kInitDelayMs = 8000;

constexpr const char* kDefaultRunId = "engine_trace_v1_breakpoint_backend";
constexpr const char* kDefaultOutputFile = "trace_raw.ndjson";
constexpr const char* kDefaultConfigFile = "trace_profile.ini";
constexpr const char* kConfigEnvVar = "ENGINE_TRACE_PROFILE_PATH";

std::string ToLower(std::string value) {
    for (char& ch : value) {
        ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
    }
    return value;
}

std::string Trim(const std::string& value) {
    size_t start = 0;
    while (start < value.size() && std::isspace(static_cast<unsigned char>(value[start])) != 0) {
        ++start;
    }
    size_t end = value.size();
    while (end > start && std::isspace(static_cast<unsigned char>(value[end - 1])) != 0) {
        --end;
    }
    return value.substr(start, end - start);
}

std::string CanonicalizeProbeId(const std::string& raw_id) {
    const std::string id = ToLower(Trim(raw_id));
    if (id == "mixsources_entry" || id == "audio.palsoundengine.mixsources.entry" ||
        id == "palsoundengine.mixsources.entry" || id == "mixsources.entry") {
        return "audio.palsoundengine.mixsources.entry";
    }
    if (id == "mixsources_exit" || id == "audio.palsoundengine.mixsources.exit" ||
        id == "audio.palsoundengine.mixsources.callsite" || id == "mixsources.callsite") {
        return "audio.palsoundengine.mixsources.exit";
    }
    if (id == "audio_object_free" || id == "audio.palsoundengine.audio_object_free" || id == "audio.object.free") {
        return "audio.palsoundengine.audio_object_free";
    }
    if (id == "audio.mixer_thread.loop") {
        return "audio.mixer_thread.loop";
    }
    return std::string();
}

std::string GetModuleDir(HMODULE module) {
    char path[MAX_PATH] = {};
    if (!::GetModuleFileNameA(module, path, MAX_PATH)) {
        return ".";
    }
    std::string out(path);
    const size_t slash = out.find_last_of("\\/");
    if (slash == std::string::npos) {
        return ".";
    }
    return out.substr(0, slash);
}

std::string JoinPath(const std::string& left, const std::string& right) {
    if (left.empty()) {
        return right;
    }
    if (left.back() == '\\' || left.back() == '/') {
        return left + right;
    }
    return left + "\\" + right;
}

bool ParseUint(const std::string& raw_value, uintptr_t* out) {
    if (!out) {
        return false;
    }
    std::string value = Trim(raw_value);
    if (value.empty()) {
        return false;
    }
    int base = 10;
    if (value.size() > 2 && value[0] == '0' && (value[1] == 'x' || value[1] == 'X')) {
        base = 16;
    }
    char* end = nullptr;
    const unsigned long parsed = std::strtoul(value.c_str(), &end, base);
    if (!end || *end != '\0') {
        return false;
    }
    *out = static_cast<uintptr_t>(parsed);
    return true;
}

bool ParseBool(const std::string& raw_value, bool* out) {
    if (!out) {
        return false;
    }
    const std::string value = ToLower(Trim(raw_value));
    if (value == "1" || value == "true" || value == "yes" || value == "on") {
        *out = true;
        return true;
    }
    if (value == "0" || value == "false" || value == "no" || value == "off") {
        *out = false;
        return true;
    }
    return false;
}

ProbeConfigEntry* FindEntry(std::vector<ProbeConfigEntry>* entries, const std::string& probe_id) {
    if (!entries) {
        return nullptr;
    }
    for (ProbeConfigEntry& entry : *entries) {
        if (entry.probe_id == probe_id) {
            return &entry;
        }
    }
    return nullptr;
}

void ApplyAddressOverride(
    std::vector<ProbeConfigEntry>* entries,
    const std::string& probe_id,
    uintptr_t value,
    bool is_rva) {
    ProbeConfigEntry* entry = FindEntry(entries, probe_id);
    if (!entry) {
        ProbeConfigEntry created;
        created.probe_id = probe_id;
        created.value = value;
        created.is_rva = is_rva;
        created.capture_snapshot = true;
        entries->push_back(created);
        return;
    }
    entry->value = value;
    entry->is_rva = is_rva;
}

void LoadIniOverrides(const std::string& config_path, std::vector<ProbeConfigEntry>* entries,
                      engine_trace::TraceRuntime* rt) {
    std::ifstream in(config_path);
    if (!in.is_open()) {
        if (rt) rt->LogDiagnostic("info", "config file not found, using defaults");
        return;
    }
    if (rt) rt->LogDiagnostic("info", "loading config file: " + config_path);

    std::string line;
    size_t line_number = 0;
    while (std::getline(in, line)) {
        ++line_number;
        const size_t comment_pos = line.find_first_of("#;");
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        line = Trim(line);
        if (line.empty()) {
            continue;
        }
        const size_t eq = line.find('=');
        if (eq == std::string::npos) {
            if (rt) rt->LogDiagnostic("warning", "config parse warning: missing '=' on line");
            continue;
        }
        const std::string key = Trim(line.substr(0, eq));
        const std::string value = Trim(line.substr(eq + 1));
        const std::string prefix = "probe.";
        if (key.rfind(prefix, 0) != 0) {
            continue;
        }
        const size_t suffix_dot = key.find_last_of('.');
        if (suffix_dot == std::string::npos || suffix_dot <= prefix.size()) {
            if (rt) rt->LogDiagnostic("warning", "config parse warning: malformed probe key");
            continue;
        }
        const std::string probe_alias = key.substr(prefix.size(), suffix_dot - prefix.size());
        const std::string field = ToLower(key.substr(suffix_dot + 1));
        const std::string probe_id = CanonicalizeProbeId(probe_alias);
        if (probe_id.empty()) {
            if (rt) rt->LogDiagnostic("warning", "config ignored unknown probe id: " + probe_alias);
            continue;
        }
        if (field == "address" || field == "va" || field == "rva") {
            uintptr_t parsed = 0;
            if (!ParseUint(value, &parsed)) {
                if (rt) rt->LogDiagnostic("error", "config parse error: bad integer for " + key);
                continue;
            }
            ApplyAddressOverride(entries, probe_id, parsed, field == "rva");
            continue;
        }
        if (field == "snapshot" || field == "capture_snapshot") {
            bool parsed = false;
            if (!ParseBool(value, &parsed)) {
                if (rt) rt->LogDiagnostic("error", "config parse error: bad bool for " + key);
                continue;
            }
            ProbeConfigEntry* entry = FindEntry(entries, probe_id);
            if (entry) {
                entry->capture_snapshot = parsed;
            }
            continue;
        }
        (void)line_number;
    }
}

void LoadEnvOverride(const char* env_name, const std::string& probe_id, bool is_rva,
                     std::vector<ProbeConfigEntry>* entries, engine_trace::TraceRuntime* rt) {
    char raw[128] = {};
    const DWORD got = ::GetEnvironmentVariableA(env_name, raw, static_cast<DWORD>(sizeof(raw)));
    if (got == 0 || got >= sizeof(raw)) {
        return;
    }
    uintptr_t value = 0;
    if (!ParseUint(raw, &value)) {
        if (rt) rt->LogDiagnostic("error", std::string("invalid environment override: ") + env_name);
        return;
    }
    ApplyAddressOverride(entries, probe_id, value, is_rva);
    if (rt) rt->LogDiagnostic("info", std::string("applied environment override: ") + env_name);
}

uintptr_t GetModuleImageSize(HMODULE module) {
    if (!module) {
        return 0;
    }
    const auto* dos = reinterpret_cast<const IMAGE_DOS_HEADER*>(module);
    if (dos->e_magic != IMAGE_DOS_SIGNATURE) {
        return 0;
    }
    const auto* nt = reinterpret_cast<const IMAGE_NT_HEADERS*>(reinterpret_cast<const uint8_t*>(module) + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE) {
        return 0;
    }
    return static_cast<uintptr_t>(nt->OptionalHeader.SizeOfImage);
}

std::vector<ProbeConfigEntry> BuildProbeConfig(const std::string& module_dir, engine_trace::TraceRuntime* rt) {
    std::vector<ProbeConfigEntry> entries = {
        {"audio.mixer_thread.loop", 0x00831EE0u, false, false},
        {"audio.palsoundengine.mixsources.entry", 0x00836610u, false, true},
        {"audio.palsoundengine.mixsources.exit", 0x0083664Cu, false, true},
        {"audio.palsoundengine.audio_object_free", 0, false, true},
    };

    char config_env[MAX_PATH] = {};
    std::string config_path = JoinPath(module_dir, kDefaultConfigFile);
    const DWORD path_len = ::GetEnvironmentVariableA(kConfigEnvVar, config_env, MAX_PATH);
    if (path_len > 0 && path_len < MAX_PATH) {
        config_path = config_env;
    }
    LoadIniOverrides(config_path, &entries, rt);

    LoadEnvOverride("ENGINE_TRACE_MIXSOURCES_ENTRY_RVA", "audio.palsoundengine.mixsources.entry", true, &entries, rt);
    LoadEnvOverride("ENGINE_TRACE_MIXSOURCES_ENTRY_VA", "audio.palsoundengine.mixsources.entry", false, &entries, rt);
    LoadEnvOverride("ENGINE_TRACE_MIXSOURCES_EXIT_RVA", "audio.palsoundengine.mixsources.exit", true, &entries, rt);
    LoadEnvOverride("ENGINE_TRACE_MIXSOURCES_EXIT_VA", "audio.palsoundengine.mixsources.exit", false, &entries, rt);
    LoadEnvOverride("ENGINE_TRACE_AUDIO_OBJECT_FREE_RVA", "audio.palsoundengine.audio_object_free", true, &entries, rt);
    LoadEnvOverride("ENGINE_TRACE_AUDIO_OBJECT_FREE_VA", "audio.palsoundengine.audio_object_free", false, &entries, rt);

    return entries;
}

bool VerifyExeSize(engine_trace::TraceRuntime* rt) {
    char exe_path[MAX_PATH] = {};
    if (::GetModuleFileNameA(nullptr, exe_path, MAX_PATH) == 0) {
        rt->LogDiagnostic("warning", "GetModuleFileNameA failed for EXE size check");
        return false;
    }
    HANDLE h = ::CreateFileA(exe_path, GENERIC_READ, FILE_SHARE_READ, nullptr,
                             OPEN_EXISTING, 0, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        rt->LogDiagnostic("warning", "cannot open EXE for size check");
        return false;
    }
    DWORD size = ::GetFileSize(h, nullptr);
    ::CloseHandle(h);
    if (size != kExpectedExeSize) {
        std::ostringstream oss;
        oss << "EXE size mismatch: got " << size << " expected " << kExpectedExeSize
            << " — hardcoded VAs may be wrong, hooks disabled";
        rt->LogDiagnostic("error", oss.str());
        return false;
    }
    return true;
}

void InstallHooks(engine_trace::TraceRuntime* rt, engine_trace::HookManager* hm) {
    if (!VerifyExeSize(rt)) {
        return;
    }

    HMODULE game_module = ::GetModuleHandleA(nullptr);
    if (!game_module) {
        rt->LogDiagnostic("error", "GetModuleHandleA(NULL) failed: missing game module");
        return;
    }
    const uintptr_t module_base = reinterpret_cast<uintptr_t>(game_module);
    const uintptr_t module_size = GetModuleImageSize(game_module);
    if (module_size == 0) {
        rt->LogDiagnostic("error", "failed to read game module image size");
        return;
    }

    const std::vector<ProbeConfigEntry> entries = BuildProbeConfig(GetModuleDir(g_module), rt);
    std::vector<engine_trace::HookBinding> bindings;
    bindings.reserve(entries.size());

    for (const ProbeConfigEntry& entry : entries) {
        if (entry.value == 0) {
            rt->LogDiagnostic("warning", "probe address missing; hook skipped", entry.probe_id, 0);
            continue;
        }
        uintptr_t resolved = entry.value;
        if (entry.is_rva) {
            if (entry.value >= module_size) {
                rt->LogDiagnostic(
                    "error",
                    "bad RVA: outside module image",
                    entry.probe_id,
                    entry.value);
                continue;
            }
            resolved = module_base + entry.value;
        }

        engine_trace::ProbeSpec spec;
        spec.probe_id = entry.probe_id;
        spec.address = resolved;
        spec.capture_snapshot = entry.capture_snapshot;
        rt->RegisterProbe(spec);

        engine_trace::HookBinding binding;
        binding.spec = spec;
        binding.resolved_address = resolved;
        bindings.push_back(binding);
    }

    if (bindings.empty()) {
        rt->LogDiagnostic("warning", "no probe bindings resolved — nothing to hook");
        return;
    }

    const engine_trace::HookInstallResult result = hm->Install(bindings, rt);
    if (!result.ok) {
        rt->LogDiagnostic("error", "hook backend install failed: " + result.detail);
    }
}

static engine_trace::TraceRuntime* g_active_rt = nullptr;
static engine_trace::HookManager* g_active_hm = nullptr;

LONG CALLBACK InitCrashGuard(PEXCEPTION_POINTERS info) {
    if (!info || !info->ExceptionRecord) {
        return EXCEPTION_CONTINUE_SEARCH;
    }
    DWORD code = info->ExceptionRecord->ExceptionCode;
    if (code == EXCEPTION_ACCESS_VIOLATION || code == EXCEPTION_IN_PAGE_ERROR ||
        code == EXCEPTION_STACK_OVERFLOW) {
        if (g_active_hm) {
            g_active_hm->Uninstall();
        }
        if (g_active_rt) {
            g_active_rt->LogDiagnostic("error", "FATAL: exception during engine_trace init — hooks removed");
            g_active_rt->Shutdown();
        }
        g_active_rt = nullptr;
        g_active_hm = nullptr;
    }
    return EXCEPTION_CONTINUE_SEARCH;
}

DWORD WINAPI InitThread(LPVOID) {
    ::Sleep(kInitDelayMs);

    auto* rt = new (std::nothrow) engine_trace::TraceRuntime();
    auto* hm = new (std::nothrow) engine_trace::HookManager();
    if (!rt || !hm) {
        delete rt;
        delete hm;
        return 0;
    }

    PVOID guard = ::AddVectoredExceptionHandler(1, InitCrashGuard);
    g_active_rt = rt;
    g_active_hm = hm;

    const std::string module_dir = GetModuleDir(g_module);
    const std::string output_path = JoinPath(module_dir, kDefaultOutputFile);
    if (!rt->Init(output_path, kDefaultRunId)) {
        g_active_rt = nullptr;
        g_active_hm = nullptr;
        if (guard) ::RemoveVectoredExceptionHandler(guard);
        delete hm;
        delete rt;
        return 0;
    }

    rt->LogDiagnostic("info", "engine_trace_asi init started (deferred)");
    InstallHooks(rt, hm);

    engine_trace::ProbeSpec startup_marker;
    startup_marker.probe_id = "engine.trace.module";
    startup_marker.capture_snapshot = false;
    rt->OnProbeEntry(startup_marker, 0);

    g_active_rt = nullptr;
    g_active_hm = nullptr;
    if (guard) ::RemoveVectoredExceptionHandler(guard);

    // rt and hm intentionally leaked — they must persist for the process lifetime.
    return 0;
}

}  // namespace

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        g_module = module;
        ::DisableThreadLibraryCalls(module);
        ::CreateThread(nullptr, 0, InitThread, nullptr, 0, nullptr);
    }
    return TRUE;
}
