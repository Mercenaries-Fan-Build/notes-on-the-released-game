#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace engine_trace {

struct MemoryWindowCapture {
    std::string label;
    uintptr_t address = 0;
    uint32_t requested_size = 0;
    bool truncated = false;
    std::vector<uint8_t> bytes;
};

struct ProbeRecord {
    uint32_t schema_version = 1;
    std::string record_type;
    std::string run_id;
    uint64_t timestamp_us = 0;
    std::string lifecycle_phase;
    std::string probe_id;
    uint32_t thread_id = 0;
    uintptr_t instruction_ptr = 0;
    std::string event_name;
    std::string diagnostic_message;
    std::vector<std::pair<std::string, uintptr_t>> pointers;
    std::vector<MemoryWindowCapture> memory_windows;
};

}  // namespace engine_trace
