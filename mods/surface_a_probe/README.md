# surface_a.asi — Surface-A asset→struct oracle

Captures the **original game's PARSED structs at a known load-path boundary**, so the 64-bit Rust
reimplementation's parsers can be diffed **byte-for-byte** against ground truth. This is **Surface A**
of the modernization regression harness (`docs/modernization/00_charter.md`; full design in
`docs/modernization/surface_a_oracle_design.md`).

The sibling **Surface B** binding-call oracle is `mods/lua_trace_asi/`. Surface B gates the
script→engine boundary; Surface A gates the asset→struct boundary. **Implementation is free;
behavior is gated by provable equivalence.**

## First target (A1): `Mtrl_Parse` (`FUN_00858790`, `__stdcall`, `ret 0x8`)

```c
void __stdcall Mtrl_Parse(void *out_material, ChunkReader *reader);
```

The boundary is pure: `parse(input_bytes) -> struct`. The probe **wraps** the function — on entry it
snapshots the reader's byte cursor; it calls the real parser; on return it captures the exact input
span the parser consumed (`[base+cursor_entry, base+cursor_exit)`) and the finished output struct
(`out_material[0..0x1C0]`, covering the u16 tex-count @+0xa2 and the 10-slot `{hash,0xF011157A,0}`
array @+0xac). One golden record per **distinct** input (deduped by CRC32).

## How it works

1. `DllMain` opens `surface_a.bin` (writes the 8-byte `"SA1\0"` + version header) and `surface_a.log`,
   verifies the exe size (`53482288`, deployed no-ASLR build — refuses a mismatch, like `resprobe`),
   and starts a **watcher** thread + a delayed **install** thread.
2. The install thread waits 2.5 s (so the cracked exe's `.text` is mapped), `MH_Initialize`s, and
   MinHooks `Mtrl_Parse` to a **wrapping naked detour**.
3. The detour preserves `__stdcall` semantics: it reads `cursor_at_entry`, calls the real parser via
   the trampoline, then calls `RecordMtrl` (ZERO I/O) and `ret 0x8`.
4. `RecordMtrl` bounds-guards every read (`Readable` + `VirtualQuery` range check, like `lua_trace`),
   CRC32s the input span, dedupes, and pushes a fixed-size record into a lock-free ring.
5. The watcher drains the ring to `surface_a.bin` as length-delimited binary records.

All game-memory reads are guarded, so a bad pointer degrades to a **skipped record, never an AV**.

## Build

```bash
# i686 MinGW (C:\Users\Shadow\mingw32\bin) + GnuWin32 make on PATH
make
```

Produces `surface_a.asi` (32-bit DLL). MinHook is the vendored `submodules/minhook`.

## Deploy

Drop `surface_a.asi` into `<game>/scripts/` alongside the Ultimate ASI Loader (`dinput8.dll`).
Run the game and load a level. The corpus appears as `<game>/surface_a.bin` (+ `surface_a.log`).

## Output schema (`surface_a.bin`)

```
File header (8 bytes):  char magic[4]="SA1\0"  ;  u32 version=1

Record:  u32 rec_len          # bytes after this field
         u32 target_va        # 0x00858790 for A1
         u32 seq              # monotonic capture order
         u32 input_len        # consumed input span length
         u32 input_crc32      # CRC32 of the input span (identity key)
         u32 output_len       # 0x1C0 for A1
         u8  input[input_len] # exact asset bytes the parser consumed
         u8  output[output_len]# the parsed struct, verbatim
```

## Diffing against the Rust reimpl

1. Read `surface_a.bin`; for each record feed `input[]` to the Rust parser for `target_va`
   (`0x858790 -> wad_simulator::mtrl::parse`).
2. Serialize the Rust struct to the engine's in-memory layout; assert byte-identical to `output[]`.
3. First differing offset localizes the bug to an exact field. Runtime-handle fields are masked per
   the documented field-mask (see the design doc); hashes, sentinels, floats and flags compare exact.

## Extending (v2)

`target_va` is already in every record, so adding A2 (`Tex_ConsumeChunk` `0x750a30`) or A3
(`Chunk_GetEntryReader` `0x464780`) is one more entry/exit hook pair each — the file format and Rust
diff harness are unchanged.
