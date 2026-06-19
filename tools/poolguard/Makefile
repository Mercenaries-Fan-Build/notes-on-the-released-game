# Makefile for poolguard.asi — custom pool-allocator corruption tracer
#
# Builds a 32-bit (x86) DLL to match Mercenaries 2 (the game is 32-bit, so the .asi
# MUST be x86). MinHook is compiled directly from the git submodule at
# submodules/minhook/ (same as tools/pmc_blackbox) — no separate MinHook DLL needed.
#
# Prerequisites:
#   Windows: i686-w64-mingw32-gcc on PATH (this machine: MinGW-w64 at
#            /c/Users/Shadow/mingw32/bin)
#   macOS:   brew install mingw-w64
#   Ubuntu:  apt install gcc-mingw-w64-i686

CC_MINGW    = i686-w64-mingw32-gcc
# This i686-only MinGW install ships strip unprefixed; override on the CLI
# (make STRIP_MINGW=i686-w64-mingw32-strip) if your toolchain prefixes it.
STRIP_MINGW = strip

TARGET      = poolguard.asi
SRC         = poolguard.c

# --- MinHook submodule paths (relative to this Makefile) ---
MINHOOK_ROOT = ../../submodules/minhook
MINHOOK_INC  = $(MINHOOK_ROOT)/include
MINHOOK_SRC  = $(MINHOOK_ROOT)/src
SRCS_MH      = $(MINHOOK_SRC)/hook.c \
               $(MINHOOK_SRC)/buffer.c \
               $(MINHOOK_SRC)/trampoline.c \
               $(MINHOOK_SRC)/hde/hde32.c

SRCS_ALL    = $(SRC) $(SRCS_MH)

CFLAGS      = -O2 -Wall -Wno-unused-function -I$(MINHOOK_INC) -shared -Wl,--enable-stdcall-fixup
LDFLAGS     = -lkernel32 -luser32

.PHONY: all clean mingw help

all: mingw

mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRCS_ALL) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Copy to: <game>/scripts/poolguard.asi"
	@echo "Log:     pmc_blackbox.log (or poolguard.log next to the EXE)"

clean:
	rm -f $(TARGET) *.o

help:
	@echo "Usage:"
	@echo "  make mingw   — Cross/native compile with MinGW i686 (default, x86)"
	@echo "  make clean   — Remove build artifacts"
	@echo ""
	@echo "Env knobs (set before launching the game):"
	@echo "  PG_RECORD=0  — disable the FUN_0084DCE0 alloc-record hook (VEH-only,"
	@echo "                 maximally non-perturbing; dump shows class+head only)."
