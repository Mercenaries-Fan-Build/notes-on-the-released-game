# Makefile for lua_trace.asi — Surface-B Lua->engine binding-call oracle (modernization program).
#
# 32-bit (x86) DLL to match Mercenaries 2. Scans luaL_Reg tables at runtime (no hardcoded addrs)
# and MinHooks every game binding; emits an ordered NDJSON call trace next to the exe.
# Build: `make` (uses the i686 MinGW at C:\Users\Shadow\mingw32\bin). Deploy to <game>/scripts/.

CC_MINGW     = i686-w64-mingw32-gcc
TARGET       = lua_trace.asi
SRC          = src/lua_trace_asi.c

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
