# Makefile for freecam.asi — F11 freecam for Mercenaries 2 (deployed exe size 53482288).
# 32-bit (x86) DLL, MinHook from the vendored submodule. Deploy into <game>/scripts/.

CC_MINGW     = i686-w64-mingw32-gcc
TARGET       = freecam.asi
SRC          = freecam.c

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
