# Makefile for dlc_enable.asi — DLC Content Activator plugin
#
# Cross-compiles from macOS/Linux using MinGW, or native on Windows with MSVC.
#
# Prerequisites:
#   macOS:   brew install mingw-w64
#   Ubuntu:  apt install gcc-mingw-w64-i686
#   Windows: Visual Studio with C++ Desktop workload

CC_MINGW   = i686-w64-mingw32-gcc
STRIP_MINGW = i686-w64-mingw32-strip
CC_MSVC    = cl

TARGET     = dlc_enable.asi
SRC        = dlc_enable.c
CFLAGS     = -O2 -Wall -shared -Wl,--enable-stdcall-fixup
LDFLAGS    = -lkernel32 -luser32

.PHONY: all clean mingw msvc help

all: mingw

mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Copy to: <game>/scripts/dlc_enable.asi"

msvc: $(SRC)
	$(CC_MSVC) /LD /O2 /GS- $(SRC) /link /OUT:$(TARGET) kernel32.lib user32.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) dlc_enable.obj dlc_enable.exp dlc_enable.lib dlc_enable.log

help:
	@echo "Usage:"
	@echo "  make mingw  — Cross-compile with MinGW (macOS/Linux)"
	@echo "  make msvc   — Compile with MSVC (Windows)"
	@echo "  make clean  — Remove build artifacts"
	@echo ""
	@echo "Alternative: Use the Python generator (no compiler needed):"
	@echo "  python3 tools/build_dlc_asi.py --output scripts/dlc_enable.asi"
