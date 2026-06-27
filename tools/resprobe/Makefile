# Makefile for resprobe.asi — resource-instantiation probe (REQ/OK4) for the v5 skin hang.
#
# 32-bit (x86) DLL to match Mercenaries 2 (exe size 53482288). MinHook from the vendored submodule.
# Hooks FUN_00874140 (acquire) + FUN_00873360 (promote-to-status-4); logs each {nameHash,typeHash}
# once per tag to resprobe.log + pmc_log. A hash REQ'd but never OK4 = the stalling sub-resource.
# Deploy alongside quiet_freeplay_vo.asi / windowed_mode.asi in <game>/scripts/.

CC_MINGW     = i686-w64-mingw32-gcc
TARGET       = resprobe.asi
SRC          = resprobe.c

MINHOOK_ROOT = ../../submodules/minhook
MINHOOK_INC  = $(MINHOOK_ROOT)/include
MINHOOK_SRC  = $(MINHOOK_ROOT)/src
SRCS_MH      = $(MINHOOK_SRC)/hook.c \
               $(MINHOOK_SRC)/buffer.c \
               $(MINHOOK_SRC)/trampoline.c \
               $(MINHOOK_SRC)/hde/hde32.c
SRCS_ALL     = $(SRC) $(SRCS_MH)

CFLAGS       = -O2 -Wall -Wno-unused-function -Wno-return-type -I$(MINHOOK_INC) -shared -Wl,--enable-stdcall-fixup
LDFLAGS      = -lkernel32 -luser32

.PHONY: all clean
all:
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRCS_ALL) $(LDFLAGS)

clean:
	rm -f $(TARGET)
