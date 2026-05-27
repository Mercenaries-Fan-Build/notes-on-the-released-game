#include "probe_runtime.h"

#include <windows.h>

#include <chrono>
#include <iomanip>
#include <sstream>
#include <thread>

namespace engine_trace {
namespace {

uint64_t NowMicros() {
    using namespace std::chrono;
    return duration_cast<microseconds>(steady_clock::now().time_since_epoch()).count();
}

std::string HexAddr(uintptr_t addr) {
    std::ostringstream oss;
    oss << "0x" << std::hex << std::uppercase << addr;
    return oss.str();
}

std::string EscapeJson(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    for (char c : s) {
        if (c == '\\' || c == '"') {
            out.push_back('\\');
        }
        out.push_back(c);
    }
    return out;
}

}  // namespace

bool TraceRuntime::Init(const std::string& output_path, const std::string& run_id) {
    run_id_ = run_id;
    out_.open(output_path, std::ios::out | std::ios::app);
    return out_.is_open();
}

void TraceRuntime::Shutdown() {
    if (out_.is_open()) {
        out_.flush();
        out_.close();
    }
}

void TraceRuntime::RegisterProbe(const ProbeSpec& spec) {
    probes_.push_back(spec);
}

void TraceRuntime::OnProbeEntry(const ProbeSpec& spec, uintptr_t instruction_ptr) {
    ProbeRecord record = BuildBaseRecord(spec, "probe_entry", spec.capture_snapshot ? "snapshot" : "event", instruction_ptr);
    record.event_name = spec.probe_id + ".entry";
    CaptureMemoryWindows(spec, &record);
    EmitRecord(record);
}

void TraceRuntime::OnProbeExit(const ProbeSpec& spec, uintptr_t instruction_ptr) {
    ProbeRecord record = BuildBaseRecord(spec, "probe_exit", spec.capture_snapshot ? "snapshot" : "event", instruction_ptr);
    record.event_name = spec.probe_id + ".exit";
    CaptureMemoryWindows(spec, &record);
    EmitRecord(record);
}

ProbeRecord TraceRuntime::BuildBaseRecord(
    const ProbeSpec& spec,
    const char* event_name,
    const char* record_type,
    uintptr_t instruction_ptr) const {
    ProbeRecord record;
    record.schema_version = 1;
    record.record_type = record_type;
    record.run_id = run_id_;
    record.timestamp_us = NowMicros();
    record.lifecycle_phase = "audio_stream_runtime";
    record.probe_id = spec.probe_id;
    record.thread_id = static_cast<uint32_t>(::GetCurrentThreadId());
    record.instruction_ptr = instruction_ptr;
    record.event_name = event_name;
    return record;
}

void TraceRuntime::CaptureMemoryWindows(const ProbeSpec& spec, ProbeRecord* record) const {
    if (!spec.capture_snapshot) {
        return;
    }
    // Skeleton behavior: keep pointer-only data until concrete probe windows are wired.
    record->pointers.emplace_back("instruction_ptr", record->instruction_ptr);
}

void TraceRuntime::EmitRecord(const ProbeRecord& record) {
    std::lock_guard<std::mutex> lock(out_mutex_);
    if (!out_.is_open()) {
        return;
    }
    out_ << "{";
    out_ << "\"schema_version\":" << record.schema_version << ",";
    out_ << "\"record_type\":\"" << EscapeJson(record.record_type) << "\",";
    out_ << "\"run_id\":\"" << EscapeJson(record.run_id) << "\",";
    out_ << "\"timestamp_us\":" << record.timestamp_us << ",";
    out_ << "\"lifecycle_phase\":\"" << EscapeJson(record.lifecycle_phase) << "\",";
    out_ << "\"probe_id\":\"" << EscapeJson(record.probe_id) << "\",";
    out_ << "\"thread_id\":" << record.thread_id << ",";
    out_ << "\"instruction_ptr\":\"" << HexAddr(record.instruction_ptr) << "\",";
    out_ << "\"event_name\":\"" << EscapeJson(record.event_name) << "\"";
    if (!record.diagnostic_message.empty()) {
        out_ << ",\"diagnostic_message\":\"" << EscapeJson(record.diagnostic_message) << "\"";
    }
    if (!record.pointers.empty()) {
        out_ << ",\"pointers\":[";
        for (size_t i = 0; i < record.pointers.size(); ++i) {
            const auto& p = record.pointers[i];
            if (i > 0) {
                out_ << ",";
            }
            out_ << "{\"label\":\"" << EscapeJson(p.first) << "\",\"address\":\"" << HexAddr(p.second) << "\"}";
        }
        out_ << "]";
    }
    out_ << "}\n";
    out_.flush();
}

void TraceRuntime::LogDiagnostic(
    const std::string& level,
    const std::string& message,
    const std::string& probe_id,
    uintptr_t address) {
    ProbeSpec synthetic;
    synthetic.probe_id = probe_id.empty() ? "engine.trace.diag" : probe_id;
    synthetic.capture_snapshot = false;
    ProbeRecord record = BuildBaseRecord(synthetic, "diagnostic", "diagnostic", address);
    record.event_name = level;
    record.diagnostic_message = message;
    EmitRecord(record);
}

}  // namespace engine_trace
