# Makefile for PMC Blackbox — SecuROM spoof + debug console + ASI loader
# Output: pmc_bb.dll — game's import table must reference this name.
#
# Cross-compiles from macOS/Linux using MinGW, or native on Windows with MSVC.
#
# Prerequisites:
#   macOS:   brew install mingw-w64
#   Ubuntu:  apt install gcc-mingw-w64-i686
#   Windows: Visual Studio with C++ Desktop workload

CC_MINGW    = i686-w64-mingw32-gcc
STRIP_MINGW = i686-w64-mingw32-strip
CC_MSVC     = cl

TARGET      = pmc_bb.dll
SRC         = pmc_blackbox.c
DEF         = pmc_blackbox.def
CFLAGS      = -O2 -Wall -shared -Wl,--enable-stdcall-fixup
LDFLAGS     = -lkernel32 -luser32

.PHONY: all clean mingw msvc help

all: mingw

mingw: $(SRC) $(DEF)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(DEF) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Place next to Mercenaries2.exe"

msvc: $(SRC) $(DEF)
	$(CC_MSVC) /LD /O2 /GS- $(SRC) /link /DEF:$(DEF) /OUT:$(TARGET) kernel32.lib user32.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) pmc_blackbox.obj pmc_blackbox.exp pmc_blackbox.lib

help:
	@echo "Usage:"
	@echo "  make mingw  — Cross-compile with MinGW (macOS/Linux)"
	@echo "  make msvc   — Compile with MSVC (Windows)"
	@echo "  make clean  — Remove build artifacts"
	@echo ""
	@echo "Output: pmc_bb.dll (~4-6 KB) [PMC Blackbox]"
	@echo "  Place next to Mercenaries2.exe."
	@echo "  Game import table must reference pmc_bb.dll (patch with exe tool)."
	@echo "  Adds debug console + ASI plugin loading on startup."
