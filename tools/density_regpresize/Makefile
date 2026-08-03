# Makefile for density_regpresize.asi — presizes the SceneObject registry to kill the O(N^2)
# grow-storm during world load (M1 of the density-upgrade program). Deployed exe = 53482288 bytes,
# imagebase 0x400000, no ASLR. 32-bit (x86) DLL, MinHook from the vendored submodule.
# Deploy into <game>/scripts/ (renamed to .asi so the ASI loader picks it up).

CC_MINGW     = i686-w64-mingw32-gcc
TARGET       = density_regpresize.asi
SRC          = density_regpresize.c

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
