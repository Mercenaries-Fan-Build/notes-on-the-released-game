# Mercenaries 2 — Fixed-Buffer Inventory (overflow-risk landscape)

Goal: enumerate the engine's FIXED-SIZE buffers sized for base-game density that
can overflow on denser DLC patch-WAD data, so we can proxy/expand them at runtime
(pmc_bb) instead of reacting to one crash at a time. Generator:
`tools/buffer_inventory.py` over `output/_ghidra/all_functions_decomp.txt`.

**Trust-but-verify:** the generator is a CANDIDATE list. Every entry must be
confirmed against the live exe (disasm + the actual data path) before trusting it.
The detector was iteratively hardened against real false positives (see below).

## Two overflow classes

- **(A) Open-addressing HASH TABLES** → infinite linear-probe LIVELOCK when full.
  True signature (verified): `idx = (idx + 1) & MASK` probe increment. NOT a paged
  array `arr[idx >> N][idx & MASK]` (the `0x81xxxx` cluster — 18 functions — were
  this false positive; the `& 0x3FF` there pairs with `>> 10` = a growable paged
  container, NOT a fixed table). Detector now requires `+1 & MASK` and excludes a
  matching `>> shift`.
- **(B) Fixed-size ARRAYS indexed by a data count** → heap corruption when the
  count exceeds the array (e.g. MTRL 10-slot @0x858790, vertex-decl 16-slot
  @0x74D6D0). Generator currently too noisy (2973 fns, mostly 64KB+ scratch);
  needs a "array index derived from a chunk-data read" filter. TODO.

## Class A inventory — 17 hash-table candidates (probe, not paged)

| slots | addr | notes |
|---|---|---|
| 512  | 0x4F2810, 0x50B257 | |
| 1024 | **0x67CFB0** | ANIM TABLE — the confirmed hang (count 3075 > 1024). patch_anim_table.py expands to 4096. |
| 1024 | 0x6C14D0, 0x6C1290, 0x6B7050, 0x6B74B0, 0x6D6FF0, 0x6EB9A0 | **0x6B–0x6E cluster — adjacent to the anim table = likely same animation/skeleton subsystem, prime "next overflow" suspects** |
| 1024 | 0x70DD10, 0x4CC4B0, 0x50B390, 0x60D040 | |
| 2048 | 0x588930, 0x85B7C7 | |
| 4096 | 0x6B7C06, 0x6B8A20 | also 0x6B cluster |

## Known fixed buffers already named (patch_anim_table.py) — for cross-check

- 0x67CFB0 anim hash table 1024→4096 (mask 0x3FF→0xFFF) — IN the list above ✓
- 0x858790 MTRL texture array — 10 slots (class B)
- 0x74D6D0 vertex-decl stream array — 16 slots, mask 0xF (class B)
- 0x1979A40 effect-object global table — 2048 slots (the lookup is FUN_00858790)

## Verification status / next

- Detector verified: catches 0x67CFB0; paged-array FPs removed. ✓
- NOT yet done: (1) which of the 17 are fed by PATCH-WAD/DLC data (only those
  overflow) — cross-ref callers vs the world-load/asset-override path; the 0x6B–0x6E
  cluster first. (2) Class B filter for data-count-indexed arrays. (3) Live-confirm
  each candidate's mask + table base before any pmc_bb proxy targets it.
- The 3 pool allocators (0x84DCE0/0x88CB70/0x84D760) are live-verified (separate;
  see worldload-hang notes). Those are the proxy *mechanism*; this inventory is the
  proxy *target list*.
