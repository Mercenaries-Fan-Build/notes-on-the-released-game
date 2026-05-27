#pragma once

#include <cstdint>
#include <fstream>
#include <mutex>
#include <string>
#include <vector>

#include "../include/trace_events.h"

namespace engine_trace {

struct ProbeSpec {
    std::string probe_id;
    uintptr_t address = 0;
    bool capture_snapshot = false;
    uint32_t max_windows = 8;
    uint32_t max_bytes_per_window = 4096;
};

class TraceRuntime {
  public:
    bool Init(const std::string& output_path, const std::string& run_id);
    void Shutdown();

    void RegisterProbe(const ProbeSpec& spec);
    void OnProbeEntry(const ProbeSpec& spec, uintptr_t instruction_ptr);
    void OnProbeExit(const ProbeSpec& spec, uintptr_t instruction_ptr);
    void LogDiagnostic(
        const std::string& level,
        const std::string& message,
        const std::string& probe_id = std::string(),
        uintptr_t address = 0);

  private:
    ProbeRecord BuildBaseRecord(
        const ProbeSpec& spec,
        const char* event_name,
        const char* record_type,
        uintptr_t instruction_ptr) const;
    void CaptureMemoryWindows(const ProbeSpec& spec, ProbeRecord* record) const;
    void EmitRecord(const ProbeRecord& record);

    std::ofstream out_;
    std::string run_id_;
    std::vector<ProbeSpec> probes_;
    std::mutex out_mutex_;
};

}  // namespace engine_trace
