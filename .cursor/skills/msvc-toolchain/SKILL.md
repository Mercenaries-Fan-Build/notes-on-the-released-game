---
name: msvc-toolchain
description: >-
  Set up the local MSVC toolchain environment for compiling C/C++ with cl.exe,
  linking with link.exe, and building Rust crates with cargo. Use when running
  cargo build, cargo check, cl.exe, link.exe, or any native compilation that
  needs the MSVC linker on this Windows machine.
---

# MSVC Toolchain

This repo ships a portable MSVC toolchain in `msvc/` (not in system PATH).
All Shell commands that need `cl.exe`, `link.exe`, or the MSVC linker for
`cargo` must source the environment first.

## Setup script

`msvc/setup_x64.bat` sets `PATH`, `INCLUDE`, and `LIB` for the session:

- VC Tools: `msvc/VC/Tools/MSVC/14.51.36231/`
- Windows SDK: `msvc/Windows Kits/10/` (10.0.28000.0)

## Running commands with MSVC

Wrap every native-compilation Shell call with `cmd /c` so the batch file
environment carries through:

```
cmd /c "call \"<repo>/msvc/setup_x64.bat\" && <command>"
```

### Cargo (Rust)

```
cmd /c "call \"<repo>/msvc/setup_x64.bat\" && cd /d \"<repo>/tools/wad_simulator\" && cargo check 2>&1"
```

The default Rust target on this machine is `x86_64-pc-windows-msvc`.
The `.cargo/config.toml` in `tools/wad_simulator` also defines an
`i686-pc-windows-gnu` target using MinGW at `C:\Users\Shadow\mingw32\`.

### C/C++ (cl.exe)

```
cmd /c "call \"<repo>/msvc/setup_x64.bat\" && cl /nologo /W3 /O2 source.c /Fe:output.exe"
```

### Link-only

```
cmd /c "call \"<repo>/msvc/setup_x64.bat\" && link /nologo object.obj /OUT:output.exe"
```

## Important notes

- Always use `cmd /c "call ... && ..."` -- PowerShell cannot source `.bat`
  env vars into its own session.
- The `2>&1` redirect is needed for cargo because it writes progress to stderr.
- Replace `<repo>` with the actual workspace root path.
