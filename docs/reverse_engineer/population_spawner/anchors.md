# Population anchors — camera eyes and player positions (PC v1.0)

Decoded and adversarially audited 2026-10-21 (code read from two different capture images; live
checks on the clean-load, mid-mission, flying-winch and Mattias captures). Grades: PROVEN unless
marked.

## Writer and frame order

`FUN_00503e20` is the only writer of array A (`0x1796530`, count `0x1175D80`), array B (`0x1796554`,
count `0x1175D8C`) and the GUID array `0xED564C` (full-`.text` scans; Xbox preview twin
`FUN_8235f948`, `xenon_decomp_named.c` ~351701, is likewise the only writer of its equivalents). A
look-ahead array C (`0x179650C`) and flag `0xED5598` are written separately (`0x504F1A/28/40`).

`FUN_00503e20` is called from `PgSysPopulation::Update` `FUN_00502510` (at `0x5025CC`, and at
`0x5025A2` on the Net-client early-return path) — before `UpdateSimpleSpawners` (`0x50261C`) and before
the camera update `FUN_0070f330` (`0x4C998A`) of the same frame, so A is the camera handed to the
renderer on the previous frame.

## What it writes

For `i < [0x17C0DD0]` with `p = GetPlayer(i)` (`FUN_006cdaf0` returns 0 for `i > 1`: at most 2
players), skipping players not joined (`p+0x30 == -1`):

1. `g = p+0x20` (character GUID); read its transform (`FUN_00665af0`). If that succeeds:
   `ED564C[nB] = g`, `B[nB] = position`, `nB++` — B is the **character root**, also when the player
   rides a vehicle.
2. A local player (`p+0x58 == 0`; INFERRED meaning): `A[nA]` = the eye (`+0x40`) of camera-stack
   entry `*cs` (`cs = *[0x11761B0] + …`); look-ahead `C[nA] = eye + xznorm(fwd) × (15 or 5)`.
   A remote player: `A[nA] = C[nA] = character position`.
3. `nA++`. After the loop the two counts are stored.

A and B never overlap (A has 3 slots, at most 2 written).

## Consumers

The spawner active-range test `FUN_004E38D0` (types 1/2/5/6 use A, 3/4 use B) and the post-spawn
event gate `FUN_00505E90` (A, XZ, returns `ED564C[nearest]`). The population death check
`FUN_00500B40` does **not** reference A or B — its anchor is still to be found.
