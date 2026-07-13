# Makefile for crowd_fog_couple.asi — couple ambient crowd (fog + despawn + reach + density) to the
# fog distance. 32-bit (x86) DLL. Runtime memory patches + one MinHook (density ceiling on
# FUN_004d60e0). Build: `make` (i686 MinGW at C:\Users\Shadow\mingw32\bin). Deploy .asi to <game>/scripts/.
# See docs/reverse_engineer/render_distance_and_density_levers.md.

CC_MINGW     = i686-w64-mingw32-gcc
TARGET       = crowd_fog_couple.asi
SRC          = src/crowd_fog_couple.c

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
