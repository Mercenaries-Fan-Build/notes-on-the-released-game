# Makefile for mercs2_probe.asi — runtime research probe plugin
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

TARGET      = mercs2_probe.asi
SRC         = mercs2_probe.c
CFLAGS      = -O2 -Wall -shared -Wl,--enable-stdcall-fixup
LDFLAGS     = -lkernel32 -luser32 -lpsapi

.PHONY: all clean mingw mingw-debug msvc help

all: mingw

mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Copy to: <game>/scripts/mercs2_probe.asi"
	@echo "Output:  <game>/scripts/probe_results/*.json"

mingw-debug: $(SRC)
	$(CC_MINGW) $(CFLAGS) -DMERCS2_PROBE_MSGBOX -o $(TARGET) $(SRC) $(LDFLAGS)
	@echo "Built: $(TARGET) (DEBUG — shows MessageBox on load)"
	@echo "Copy to: <game>/scripts/mercs2_probe.asi"

msvc: $(SRC)
	$(CC_MSVC) /LD /O2 /GS- $(SRC) /link /OUT:$(TARGET) kernel32.lib user32.lib psapi.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) mercs2_probe.obj mercs2_probe.exp mercs2_probe.lib mercs2_probe.log

help:
	@echo "Usage:"
	@echo "  make mingw        — Cross-compile with MinGW (macOS/Linux)"
	@echo "  make mingw-debug  — Same but with MessageBox on load (diagnostic)"
	@echo "  make msvc         — Compile with MSVC (Windows)"
	@echo "  make clean        — Remove build artifacts"
