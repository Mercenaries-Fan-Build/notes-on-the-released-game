# Makefile for asset_miss_probe.asi — file-open failure tracer plugin
#
# Builds a 32-bit (x86) DLL to match Mercenaries 2. The game is 32-bit, so the
# .asi MUST be x86. The repo's bundled msvc/ toolchain is x64-only and cannot
# emit a 32-bit DLL, so the default/local build uses MinGW i686 (same as
# tools/mercs2_probe). The `msvc` target is provided only for a host that has a
# real x86 MSVC install.
#
# Prerequisites:
#   Windows: i686-w64-mingw32-gcc on PATH (this machine: MinGW-w64 16.1.0)
#   macOS:   brew install mingw-w64
#   Ubuntu:  apt install gcc-mingw-w64-i686

CC_MINGW    = i686-w64-mingw32-gcc
# This i686-only MinGW install ships strip/objdump unprefixed; fall back to the
# i686-prefixed name automatically if that is what your toolchain provides.
STRIP_MINGW = strip
CC_MSVC     = cl

TARGET      = asset_miss_probe.asi
SRC         = asset_miss_probe.c
CFLAGS      = -O2 -Wall -shared -Wl,--enable-stdcall-fixup
LDFLAGS     = -lkernel32 -luser32

.PHONY: all clean mingw mingw-debug msvc help

all: mingw

mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Copy to: <game>/scripts/asset_miss_probe.asi"
	@echo "Log:     pmc_blackbox.log (or asset_miss_probe.log next to the EXE)"

mingw-debug: $(SRC)
	$(CC_MINGW) $(CFLAGS) -DASSET_MISS_PROBE_MSGBOX -o $(TARGET) $(SRC) $(LDFLAGS)
	@echo "Built: $(TARGET) (DEBUG — shows MessageBox on load)"
	@echo "Copy to: <game>/scripts/asset_miss_probe.asi"

# x86 MSVC only (NOT the repo's x64-only msvc/ toolchain).
msvc: $(SRC)
	$(CC_MSVC) /LD /O2 /GS- $(SRC) /link /OUT:$(TARGET) kernel32.lib user32.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) asset_miss_probe.obj asset_miss_probe.exp asset_miss_probe.lib asset_miss_probe.log

help:
	@echo "Usage:"
	@echo "  make mingw        — Cross/native compile with MinGW i686 (default, x86)"
	@echo "  make mingw-debug  — Same but with MessageBox on load (diagnostic)"
	@echo "  make msvc         — Compile with an x86 MSVC install (not the repo x64 toolchain)"
	@echo "  make clean        — Remove build artifacts"
