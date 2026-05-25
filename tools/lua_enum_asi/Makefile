# Makefile for lua_enum.asi — runtime Lua binding inventory plugin
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

TARGET      = lua_enum.asi
SRC         = lua_enum.c
CFLAGS      = -O2 -Wall -shared -Wl,--enable-stdcall-fixup
LDFLAGS     = -lkernel32 -luser32

.PHONY: all clean mingw mingw-debug msvc help

all: mingw

mingw: $(SRC)
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(STRIP_MINGW) $(TARGET)
	@echo "Built: $(TARGET) ($$(wc -c < $(TARGET)) bytes)"
	@echo "Copy to: <game>/scripts/lua_enum.asi"

mingw-debug: $(SRC)
	$(CC_MINGW) $(CFLAGS) -DLUA_ENUM_MSGBOX -o $(TARGET) $(SRC) $(LDFLAGS)
	@echo "Built: $(TARGET) (DEBUG — shows MessageBox on load)"
	@echo "Copy to: <game>/scripts/lua_enum.asi"

msvc: $(SRC)
	$(CC_MSVC) /LD /O2 /GS- $(SRC) /link /OUT:$(TARGET) kernel32.lib user32.lib
	@echo "Built: $(TARGET)"

clean:
	rm -f $(TARGET) lua_enum.obj lua_enum.exp lua_enum.lib lua_enum.log

help:
	@echo "Usage:"
	@echo "  make mingw        — Cross-compile with MinGW (macOS/Linux)"
	@echo "  make mingw-debug  — Same but with MessageBox on load (diagnostic)"
	@echo "  make msvc         — Compile with MSVC (Windows)"
	@echo "  make clean        — Remove build artifacts"
