# Makefile for dlc_enable.asi — DLC Content Activator plugin
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

TARGET      = dlc_enable.asi
SRC         = dlc_enable.c
CFLAGS      = -O2 -Wall -shared -Wl,--enable-stdcall-fixup $(EXTRA_CFLAGS)
LDFLAGS     = -lkernel32 -luser32

.PHONY: all clean mingw mingw-nobootstrap mingw-bootstrap mingw-bootstrap-deferred mingw-bootstrap-early mingw-debug msvc help

# Default: VZ-load bootstrap (import dlc01 at masterscript). ~19.5 KB stripped.
all: mingw

mingw: EXTRA_CFLAGS += -DDLC_ENABLE_VZ_LOAD_BOOTSTRAP=1 -DDLC_ENABLE_CRASH_PATCH=1
mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) VZ_LOAD=1 CRASH_PATCH=1"
	@echo "Copy to: <game>/scripts/dlc_enable.asi"
	@echo "Log must show: VZ_LOAD=1 CRASH_PATCH=1; deferred inject ~3s after vz masterscript"

# Net hooks only — no Lua bootstrap (bisection / logging-only).
mingw-nobootstrap: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) NO bootstrap"

# Alias for explicit bootstrap (same as default mingw).
mingw-bootstrap: mingw

# InitThread waits for loadMainShell + 120s, then injects.
mingw-bootstrap-deferred: EXTRA_CFLAGS += -DDLC_ENABLE_DEFERRED_BOOTSTRAP=1
mingw-bootstrap-deferred: mingw
	@echo "Bootstrap: DEFERRED (120s after loadMainShell)"

# Inject at first IsOnlineConnected — unsafe during shell movies (bisection only).
mingw-bootstrap-early: EXTRA_CFLAGS += -DDLC_ENABLE_BOOTSTRAP=1
mingw-bootstrap-early: mingw
	@echo "Bootstrap: EARLY (IsOnlineConnected — may crash during shell)"

mingw-debug: $(SRC)
	$(CC_MINGW) $(CFLAGS) -DDLC_ENABLE_MSGBOX -o $(TARGET) $(SRC) $(LDFLAGS)
	@echo "Built: $(TARGET) (DEBUG — shows MessageBox on load)"
	@echo "Copy to: <game>/scripts/dlc_enable.asi"

msvc: $(SRC)
	$(CC_MSVC) /LD /O2 /GS- $(SRC) /link /OUT:$(TARGET) kernel32.lib user32.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) dlc_enable.obj dlc_enable.exp dlc_enable.lib dlc_enable.log

help:
	@echo "Usage:"
	@echo "  make mingw                  — Default (net hooks + Debug.Printf patch)"
	@echo "  make mingw-bootstrap        — + import(dlc01) at vz level load (recommended)"
	@echo "  make mingw-bootstrap-deferred — + import(dlc01) 120s after shell"
	@echo "  make mingw-bootstrap-early  — + import(dlc01) at shell (unsafe)"
	@echo "  make mingw-debug            — MessageBox popup on load (diagnostic)"
	@echo "  make msvc         — Compile with MSVC (Windows)"
	@echo "  make clean        — Remove build artifacts"
	@echo ""
	@echo "Prerequisites:"
	@echo "  macOS:  brew install mingw-w64"
	@echo "  Ubuntu: apt install gcc-mingw-w64-i686"
	@echo ""
	@echo "Alternative: Use the Python generator (no compiler needed):"
	@echo "  python3 tools/build_dlc_asi.py --output scripts/dlc_enable.asi"
