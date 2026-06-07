# Makefile for cf340_proxy.asi — dynamic limit-adjuster / proxy-heap for FUN_004cf340 buffers
#
# 32-bit (x86) DLL to match Mercenaries 2. MinHook is compiled from the vendored submodule
# (same as poolguard / pmc_blackbox). Deploy alongside poolguard.asi in <game>/scripts/.
#
# Run measure mode first:   CF340_MODE=measure (default) — logs FUN_004cf340 alloc sizes.
# Then the fix:             set CF340_MODE=fix (and optionally CF340_HEADROOM=0x800).

CC_MINGW    = i686-w64-mingw32-gcc
STRIP_MINGW = strip

TARGET      = cf340_proxy.asi
SRC         = cf340_proxy.c

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
	-$(STRIP_MINGW) $(TARGET)
	@echo "Built $(TARGET). Deploy to <game>/scripts/ next to poolguard.asi."

clean:
	rm -f $(TARGET)

help:
	@echo "make mingw   — build cf340_proxy.asi (i686 mingw)"
	@echo "Deploy:  copy cf340_proxy.asi to '<game>/scripts/'"
	@echo "Measure: launch normally (CF340_MODE unset/measure) -> read cf340_proxy.log"
	@echo "Fix:     set env CF340_MODE=fix (optional CF340_HEADROOM=0x800) and relaunch"
