# Makefile for PMC Blackbox — SecuROM spoof + debug console + ASI loader + compat hooks
# Output: pmc_bb.dll — game's import table must reference this name.
#
# Cross-compiles from macOS/Linux using MinGW, or native on Windows with MSVC.
#
# Prerequisites:
#   macOS:   brew install mingw-w64
#   Ubuntu:  apt install gcc-mingw-w64-i686
#   Windows: Visual Studio with C++ Desktop workload (or MinGW-w64 i686)

CC_MINGW    = i686-w64-mingw32-gcc
STRIP_MINGW = i686-w64-mingw32-strip
CC_MSVC     = cl

TARGET      = pmc_bb.dll
DEF         = pmc_blackbox.def

# --- Source files ---
# MinHook is loaded dynamically from MinHook.x86.dll at runtime (no source compilation).
SRCS_ALL    = pmc_blackbox.c compat_hooks.c

CFLAGS      = -O2 -Wall -Wno-unused-function -shared -Wl,--enable-stdcall-fixup
LDFLAGS     = -lkernel32 -luser32

.PHONY: all clean mingw msvc help

all: mingw

mingw: $(SRCS_ALL) $(DEF)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRCS_ALL) $(DEF) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Place next to Mercenaries2.exe"

msvc: $(SRCS_ALL) $(DEF)
	$(CC_MSVC) /LD /O2 /GS- $(SRCS_ALL) /link /DEF:$(DEF) /OUT:$(TARGET) kernel32.lib user32.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) pmc_blackbox.obj pmc_blackbox.exp pmc_blackbox.lib *.o

help:
	@echo "Usage:"
	@echo "  make mingw  — Cross-compile with MinGW (macOS/Linux/Windows)"
	@echo "  make msvc   — Compile with MSVC (Windows)"
	@echo "  make clean  — Remove build artifacts"
	@echo ""
	@echo "Output: pmc_bb.dll (~6-8 KB) [PMC Blackbox v3]"
	@echo "  Place next to Mercenaries2.exe (alongside MinHook.x86.dll)."
	@echo "  Game import table must reference pmc_bb.dll (patch with exe tool)."
	@echo "  Includes: SecuROM bypass, debug console, compat hooks, ASI loader."
	@echo "  Requires: MinHook.x86.dll in game directory (loaded at runtime)."
