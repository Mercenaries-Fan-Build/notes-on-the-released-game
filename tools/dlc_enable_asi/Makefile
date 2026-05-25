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

.PHONY: all clean mingw mingw-nobootstrap mingw-minimal mingw-nohooks mingw-no-crash-patch mingw-probe mingw-bootstrap mingw-bootstrap-deferred mingw-bootstrap-early mingw-debug msvc help

# Default: net hooks + logging only — WAD scripts_vz bootstrap owns dlc01 registration.
all: mingw

mingw: EXTRA_CFLAGS += -DDLC_ENABLE_VZ_LOAD_BOOTSTRAP=0 -DDLC_ENABLE_CRASH_PATCH=1
mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) VZ_LOAD=0 CRASH_PATCH=1"
	@echo "Copy to: <game>/scripts/dlc_enable.asi"
	@echo "Log must show: VZ_LOAD=0 CRASH_PATCH=1; dlc01 loads via WAD scripts_vz hook"

# Bisect: VZ bootstrap without 0x005AE372 code-cave patch (shell movie path).
mingw-no-crash-patch: EXTRA_CFLAGS += -DDLC_ENABLE_VZ_LOAD_BOOTSTRAP=1
mingw-no-crash-patch: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) VZ_LOAD=1 CRASH_PATCH=0"

# Net hooks only — no Lua bootstrap (G5: test WAD hook without ASI inject).
mingw-nobootstrap: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) NO bootstrap (REG_PATCH+NET)"

# Net hooks only — no Debug.Printf / print() patch (isolates REG_PATCH).
mingw-minimal: EXTRA_CFLAGS += -DDLC_ENABLE_MINIMAL_MODE=1
mingw-minimal: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) MINIMAL (NET only)"

# DllMain log only — zero hooks (isolates ASI entirely).
mingw-nohooks: EXTRA_CFLAGS += -DDLC_ENABLE_NO_HOOKS=1
mingw-nohooks: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) NO_HOOKS (log only)"

# G3: inject type(import), type(_SYS._IMPORT), type(error) at VZ-load trigger.
mingw-probe: EXTRA_CFLAGS += -DDLC_ENABLE_PROBE_GLOBALS=1 -DDLC_ENABLE_VZ_LOAD_BOOTSTRAP=1 -DDLC_ENABLE_CRASH_PATCH=1
mingw-probe: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) PROBE_GLOBALS=1"
	@echo "Log must show: [dlc_enable] PROBE type(import)= ..."

# Explicit ASI Lua bootstrap (bisect / fallback if WAD hook fails).
mingw-bootstrap: EXTRA_CFLAGS += -DDLC_ENABLE_VZ_LOAD_BOOTSTRAP=1 -DDLC_ENABLE_CRASH_PATCH=1
mingw-bootstrap: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes) VZ_LOAD=1 CRASH_PATCH=1"
	@echo "Copy to: <game>/scripts/dlc_enable.asi"
	@echo "Log must show: VZ_LOAD=1 CRASH_PATCH=1; deferred inject ~3s after vz masterscript"

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
	@echo "  make mingw                  — Default (NET + REG_PATCH; WAD owns dlc01)"
	@echo "  make mingw-bootstrap        — ASI VZ bootstrap + CRASH_PATCH (fallback)"
	@echo "  make mingw-nobootstrap      — REG_PATCH + NET, no bootstrap inject"
	@echo "  make mingw-minimal          — NET hooks only (no print patch)"
	@echo "  make mingw-nohooks          — DllMain log only (zero hooks)"
	@echo "  make mingw-no-crash-patch   — VZ bootstrap without 0x005AE372 patch"
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
