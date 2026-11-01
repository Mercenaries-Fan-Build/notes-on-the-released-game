# Mercenaries 2 PC v1.1 D3D resource pool and address-space budget

Grades: **PROVEN** = read from code bytes or a dump; **INFERRED** = reasoned from proven parts;
**SPECULATIVE** = guess. Addresses are `pc-v11` (image `genuine_patched_unpacked.exe`, sha256 `819a96db…`).
Live numbers come from the v1.1 minidumps `game-files/memory-dumps/7a348847_patched-securom/{menu,pmc}/process.dmp`.

## 1. Pool model

Textures, vertex buffers and index buffers are cached by exact shape. A create call looks in a free list and
only reaches D3D on a miss. A release call moves the object back to the free list.

| Resource | Create wrapper | Release wrapper | D3D call | Register | Lists (in-use / free) |
|---|---|---|---|---|---|
| 2D texture | `FUN_0085cdf0` | `FUN_0085d0f0` | CreateTexture, vtbl `+0x5c`, `0x85cec8` | `FUN_0085c990` | `DAT_01173fe8` / `DAT_011697cc` |
| Cube texture | `FUN_0085cef0` | same | CreateCubeTexture, vtbl `+0x64`, `0x85cf8f` | `FUN_0085c990` | same |
| Vertex buffer | `FUN_0085cfb0` | `FUN_0085d2b0` | CreateVertexBuffer, vtbl `+0x68`, `0x85d02f` | `FUN_0085caf0` | `DAT_01173ff0` / `DAT_01173ff8` |
| Index buffer | `FUN_0085d050` | `FUN_0085d1e0` | CreateIndexBuffer, vtbl `+0x6c`, `0x85d0cb` | `FUN_0085ca50` | `DAT_01173fec` / `DAT_01173ff4` |

**List heads.** The five after the texture free lists are consecutive, on both builds:

| List | v1.1 | v1.0 code |
|---|---|---|
| Texture free | `0x011697CC` | `0x0116A7CC` |
| Texture in use | `0x01173FE8` | `0x01174FE8` |
| Index buffer in use | `0x01173FEC` | `0x01174FEC` |
| Vertex buffer in use | `0x01173FF0` | `0x01174FF0` |
| Index buffer free | `0x01173FF4` | `0x01174FF4` |
| Vertex buffer free | `0x01173FF8` | `0x01174FF8` |

The index and vertex buffer lookups (v1.1 `0x85CC70`, `0x85CD30`) are byte-identical apart from these operands, so
no signature tells them apart. `mercs2_formats::pmc_sites` resolves the two texture heads and takes the rest by offset.

**Texture lists** are indexed `[format bucket][log2 width]`. The bucket is the format if below 200, else
`format >> 25`. Width and height come from the exponent of the float value.

**Texture key** (64 bits): low dword `((Levels | 0x1000) << 12) | (log2Height << 4) | log2Width`, high dword is the
format. Example: low `0x0100A0BB`, high `0x31545844` is 2048×2048, 10 levels, DXT1.

**Node** (0x18 bytes): `+0` key low (with `0x10000000` set while in use), `+4` key high, `+8` resource,
`+0xc` owner, `+0x10` next, `+0x14` previous.

**Pool argument.** Textures are always `D3DPOOL_MANAGED`. Vertex and index buffers use Usage `8` and MANAGED,
except on NVIDIA device IDs `0x400..0x403` (`-- nv8600 detected, using dynamic vb/ib resources.`), which use
Usage `0x208` and DEFAULT. The switch is `[dev+0x5e4] & 0x20`, read at `0x85c6b3`.

### 1.1 Lifetime

- A texture release never reaches `IUnknown::Release`. `FUN_0085d0f0` tail-jumps through `[0x24cdcbc]=0x5069fd`
  into the body ending `0x85d1da`, which only moves the node. **PROVEN**
- Nothing walks, counts or trims the texture lists. A whole-image scan finds five sites per list: init, lookup and
  release. References built at run time would not show in that scan. **PROVEN** for static references.
- Device reset drops free-list VBs and IBs. `FUN_0085d460` calls vtbl `+8` on nodes with `+0xc == 0`. It does not
  touch the texture lists. **PROVEN**
- Menu to PMC in the dumps: 0 texture keys decreased, 24 increased; VB dropped 42.6 MB, IB 1.7 MB. **PROVEN**
  That a device reset ran between the two captures is **INFERRED** (`[0x1175294]` went 0 to `0x6e`, and its only
  writers are inside `FUN_0074d410`).
- `FUN_007510f0` creates a new texture for a mip change, copies through `FUN_00751380` and releases the old one
  to its own key, so that memory is not reused across keys. **PROVEN**
- Texture memory therefore ratchets to the sum over keys of peak concurrency × size for the session. **INFERRED**
- No `EvictManagedResources` or `GetAvailableTextureMem` call exists at the two device-load idioms swept
  (`+0x5bc`, renderer `+0x2d28`). Other cached device pointers were not covered. **INFERRED**

### 1.2 Preallocation

`FUN_0085c330` runs once at startup (`0x7494f0 → 0x749270 → 0x74c7a0 → 0x74c90f`). For each row it creates n, then
releases n. Rows sharing a key reuse earlier objects, so the created count for a key is the max across rows.

| Table | Row size | Created | MiB |
|---|---|---|---|
| Textures, `0xce3500` | 20 B | 3242 | 126.82 |
| Index buffers, `0xce3af0` | 8 B | 435 | 3.01 |
| Vertex buffers, `0xce5ae0` | 8 B | 888 | 49.00 |
| Total | | 4565 | 178.83 |

Live pool (free plus in-use): 229.2 MiB at the menu, 226.6 MiB at PMC. Non-power-of-two textures are lower bounds,
because keys store floor log2.

## 2. HRESULT handling

| Site | Tested | On failure |
|---|---|---|
| `FUN_0085cdf0`, `FUN_0085cef0` | No | NULL reaches `FUN_0085c990`, fault at `0x85c999` `mov eax,[ebp]` |
| `FUN_0085cfb0` | No | fault in `FUN_0085caf0` `mov eax,[esi]` |
| `FUN_0085d050` | No | fault in `FUN_0085ca50` `mov eax,[esi]` |
| `0x751300` direct CreateTexture | No | not traced |
| `0x46d46e`, `0x48270e`, `0x482d72`, `0x482e58` direct MANAGED creates | No | not traced |
| `0x752470`, `0x752dd0` reset recreate | Yes | logs and continues |
| Render-target creates (`0x74a315`, `0x7524ca`, `0x75607e`) | Yes | logs |

Fault addresses of the three trackers:

| Tracker | v1.1 | v1.0 code |
|---|---|---|
| Texture, `mov eax,[ebp]` | `0x85C999` | `0x85C779` |
| Index buffer, `mov eax,[esi]` | `0x85CA50` | `0x85C830` |
| Vertex buffer, `mov eax,[esi]` | `0x85CAF0` | `0x85C8D0` |

## 3. Callers of `FUN_0085cdf0`

| Site | Function | Creates |
|---|---|---|
| `0x46ba58` | `0x46b610` | 256×1×1 A8R8G8B8 |
| `0x483ade` | `0x4835a0` | w×h×1 A4R4G4B4 |
| `0x485e26` | `0x485c60` | 256×1×1 A8R8G8B8 |
| `0x70a070` | no Ghidra function | Bink frame textures |
| `0x750d7c` | `FUN_00750c40` | asset texture from the INFO chunk |
| `0x751173` | `FUN_007510f0` | mip change |
| `0x7511d0` | `FUN_007511b0` | w×h×1 |
| `0x85c776` | `FUN_0085c330` | preallocation |

## 4. Address-space budget

- `FUN_004c17f0` calls `VirtualAlloc(NULL, 0x26226000, MEM_COMMIT, PAGE_EXECUTE_READWRITE)` at `0x4c1f6a`: 610.15 MiB
  committed. Failure shows the insufficient-RAM message box and exits. **PROVEN**
- Main heap (`DAT_017d40b0`) is 608 MiB, Network is 2200 KiB, and Script, Sound, Device and System are 0. The
  sizes come from a compiled-in `[pcwin_Memory]` blob at `0xbaf180`. **PROVEN**
- `FUN_0084b0c0` raises low-memory alerts from Main heap free space only (50/40/30 MiB). It reads neither D3D nor
  address space. **PROVEN**

The dumps are from one non-LAA process right after load, on a different GPU (device `0x28b0`):

| State | Free below `0x7ffe0000` | Largest hole |
|---|---|---|
| Menu | 457.2 MiB | 236.6 MiB |
| PMC | 371.4 MiB | 140.0 MiB |

## 5. Load path into the pool

From the `0x85c999` crash stack, frame offsets checked against each function's prologue:

`FUN_004c0970` (loader state machine) → `FUN_004c0e70` → `FUN_004c96f0` → `0x4b1160` stub → `FUN_004b1171` →
`call edx` at `0x4b11d6` → `FUN_004b0ff0` → `FUN_00750c40` → `FUN_0085cdf0` → `FUN_0085c990`.

Two hops are **INFERRED**: the `edx` target comes from the frame shape, and the stub's jump through `[0x024d30e8]`
was read from disk, not the live process. The rest is **PROVEN**. `FUN_004c09c0`, the name used for this pump
elsewhere in the docs, is not an entry point: `0x4c09c0` lies inside `FUN_004c0970`.

The chain runs on the main thread. **INFERRED**: the crash's ESP lies in the dumps' main stack
`[0x3c52000, 0x3c80000)`, the return addresses `0x4c0e8b` and `0x4c0b1f` sit within 8 bytes of their dump positions,
and dxwrapper logged the fault on its load thread. No function in the chain sets `FS:[0]`.

## 6. Not determined

- The system-memory footprint of a MANAGED resource, and D3D runtime or driver overhead.
- The share of session growth that comes from this pool rather than other consumers.
- Whether another thread touches the texture lists.
