# Makefile for surface_a.asi — Surface-A asset->struct oracle (modernization program).
#
# 32-bit (x86) DLL to match Mercenaries 2 (exe size 53482288). MinHook from the vendored submodule.
# WRAPS Mtrl_Parse (FUN_00858790, __stdcall) and dumps {consumed input span, parsed output struct}
# per distinct material to surface_a.bin, so the Rust reimpl's parser can be diffed byte-for-byte.
# Build: `make` (uses the i686 MinGW at C:\Users\Shadow\mingw32\bin). Deploy to <game>/scripts/.

CC_MINGW     = i686-w64-mingw32-gcc
TARGET       = surface_a.asi
SRC          = src/surface_a_asi.c

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
