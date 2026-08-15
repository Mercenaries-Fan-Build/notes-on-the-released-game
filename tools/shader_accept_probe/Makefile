# shader_accept_probe.asi — R0 live gate: does the real dxwrapper D3D9 runtime accept our
# instancing-spliced vs_3_0 shaders? Pure CreateVertexShader create+release, no MinHook, no draw.
# 32-bit DLL. Deploy into <game>/scripts/ next to shader_accept_probe_bundle.bin.

CC_MINGW = i686-w64-mingw32-gcc
TARGET   = shader_accept_probe.asi
SRC      = shader_accept_probe.c

CFLAGS   = -O2 -Wall -Wno-unused-function -Wno-return-type -shared -Wl,--enable-stdcall-fixup
LDFLAGS  = -lkernel32 -luser32

.PHONY: all clean
all:
	$(CC_MINGW) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)
