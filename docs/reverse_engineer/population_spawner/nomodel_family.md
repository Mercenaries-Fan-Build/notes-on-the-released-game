# NoModel spawner family + ParkingSpace (PC v1.0)

Decoded 2026-10-21. Grades: **P** proven from bytes this pass, **I** inferred (Xbox twins, unreferenced
native copies in the PC image). Addresses are PC v1.0; bytes identical in disc `ada55455` and rebuilt
`23fe7f38`. Runtime spawner layout: `../population_spawner_code_map.md` §6.

## A. Activator branch (`0x2928000`) — P

Entry: `edi` = record, `ebp` = owner, `eax`/`esi` = SpawnerAdjust (may be 0).

1. record `+0x64` IgnoreModel ≠ 1 → return.
2. g = record `+0x58`. If g ≤ `[0x245FE6C]` (7 live) and the adjust's state-mask bit g is set:
   on = `adjust[g+5] ≠ 0`; else on = record `+0x50` DefaultState ≠ 0. Not on → return.
3. `4e4af0(owner, record)` false → return (uniqueness). `4e2480(record)` true → return (roll).
4. record `+0x63` PathCount > 0 → `4e4f70` (Path); else record `+0x54` == 6 → `4e4dc0` (ParkingSpace);
   else → `4e4e50` (NoModel).

NoModel = IgnoreModel 1, PathCount 0, SpawnerType ≠ 6. Matches Xbox `FUN_82336d98`.

## B. Creator `FUN_004e4e50(eax=adjust, record, owner)` — P (Xbox `FUN_82335058` identical)

```
4e4e5b  if free_cnt[0xDCCAF4]==0 return
4e4e69  if cap[0xDCCFC8](=100) - cnt[0xDCCFC4] == 0 return
4e4e7f  free_cnt--; sp = free[0xDCC6F0 + 4*free_cnt]
4e4e82  if cnt<cap: list[0xDCCE30 + 4*cnt++] = sp
4e4ea0  4e2840(push record, eax=owner, edi=sp)            ; init
4e4eac  if adjust: 4e35b0(eax=adjust, edi=sp)              ; tweak overrides
4e4eb7  sp+0x48 = -1 ; sp+0x4c = -1
4e4ebe  4e3cd0(&xf, sp)                                   ; result ignored
4e4ecb  k = 8242b0(ecx=owner, esi=0x16DA1A8, 0x80)        ; NoModel owner set (128)
4e4ee3  k>=0 ? ++cnt[0x16D9FA8+4k] : 56f010(ecx=0x16D9FA0, edx=owner, &1)
4e4f0f  if sp+0x60 <= 0.0:
4e4f18     h = 4e3dd0(esi=sp)
4e4f1f     if 4e38d0(eax=&xf, edx=sp) && 4e0fb0(ecx=sp, h):
4e4f50          4e0ca0(eax=sp, ecx=&xf); return            ; wakeup now
4e4f5c     sp+0x60 = 0.01f [0xB97EEC]                      ; retry wakeup in 0.01 s
```

Live (mid-mission): every untriggered NoModel spawner has `+0x60` = 0.01 and `+0x48`/`+0x4c` = −1.

## C. Updater `FUN_004e1ad0(float dt)` — P (Xbox `FUN_823370a8` line by line)

Walks i = cnt−1 … 0 (invalid index reads sentinel `0xDCCFC0`).

```
4e1b0c  if sp+0x89 == 0 (Off): swap-remove i; 4e2650(esi=sp); if free_cnt < 256: free[free_cnt++]=sp; next
4e1b5f  dtl=dt; if 4e0c00(ecx=sp, esi=&dtl): next          ; 0.1–3.1 s throttle, may raise dtl
4e1b7e  if !4e3cd0(&xf,sp): swap-remove i; release + free-push; next
4e1bb8  if !4e39d0(&xf,sp): next                           ; unit slot not free
4e1bce  if sp+0x89 == 5: 4e5ac0(ecx=i); 4e0e80(eax=sp); next
4e1bea  if !4e38d0(eax=&xf, edx=sp): next                  ; active radius
4e1bfd  if 4e0fb0(ecx=sp, 1.0f): next                      ; dormant check, health fixed at 1.0
4e1c15  if 4e11c0(esi=sp): next                            ; squad
4e1c24  if sp+0x60 > 0: sp+0x60 -= dtl; if <=0: 4e0ca0(eax=sp, ecx=0); next
4e1c53  if 4e11f0(dtl): next                               ; +0x5c cycle running
4e1c6b  sp+0x5c = sp+0x6c
4e1c73  if 4e2770(edx=sp): 4e2800(eax=sp); next            ; skip: +0x92=0; if +0x8f>0: +0x91++
4e1c88  4e2820(eax=sp)                                     ; spawn: +0x91=0; if +0x90>0: +0x92++
4e1c8d  u = 4e4150(eax=sp, &xf)
4e1c9e  if u == -1: 4e5ac0(ecx=i); 4e0e80(eax=sp); next
4e1cb3  if u == 0: next                                    ; cycle already consumed
4e1cb7  if byte[0xDFBD74]: 6b2e60(eax=u, cl=1)
4e1cc9  4e19f0(eax=u, push sp)                             ; +0x40 = u
4e1cd4  if 4e26f0(edx=sp): sp+0x89 = 5
4e1ce6  5a1500(&ctx); 4b1270(&ctx, sp+0x24)                ; Lua arg = owner
4e1cfd  5a0cc0(0x543977F7 "DangerousBuilding", "OccupiedBuildingSpawnCallback" @0xBB13BC, &ctx,1,0,1)
4e1d0f  56af60(eax=u, ecx=0x065BD62D, xmm0=50.0f [0xB984AC], 0×6)
```

**Placement** comes only from `xf` built by `4e3cd0`. For IgnoreModel (`+0x93` bit 0) the tail
`0x4e3d17`→`0x4e3d64`: identity; rotation = owner quaternion (`0x4e3d6b`); `824c00` composes the
spawner's local Position/quat (`+0x00..0x1f`); `0x4e3d8d` adds the owner world position — world =
owner ∘ spawner-local (bytes P; the quaternion product inside `824c00` I). Xbox `FUN_82332740` (bit
0x80 branch) agrees.

## D. Release exits

1. State 0 (`4e1b0c`). 2. `4e3cd0` fails (`4e1b8e`). 3. State 5 with the unit slot free (`4e1bd9`/`4e1be0`).
4. `4e4150` == −1 (`4e1ca5`/`4e1cac`). 5. `4e5220(owner, group)` → slot `0x2458E8C` → `0x2476A50` (P):
   if the owner is not in set `0x16DA1A8`, return; walk the list, for each spawner with `+0x24` == owner
   and (group < 0 or `+0x8b` == group): swap-remove, `4e2650`, free-push; then `582930(owner,
   0x16D9FA0)` erases the owner key — even for a single-group release (Xbox `FUN_82335588` →
   `FUN_822f07c8`), so the owner's spawners in other groups drop out of the set (I).

`4e0e80` (−1 / state-5 release; VM stub `0x24F0120`): `if (sp) { 4e2650(sp); if free_cnt<cap:
free[free_cnt++]=sp }` — I, from Xbox `FUN_823331d0` and the unreferenced native copy `0x6D4FF0`
(mutated: obfuscated `call 0x4e2650` via `[0x245AC08]+[0x59D730]`, free-list cap through `[0x2460844]`).
`4e5ac0(ecx=i)` (VM `0x24E7E50`): NoModel list swap-remove at i — I, from the Xbox inline and the
copy `0x430D50`.

## E. ParkingSpace (SpawnerType 6) — `4e4dc0`

Not a spawner list. Slot `0x245908C` → VM stub `0x24EBA70` in every capture; the PC body is the
unreferenced plaintext `0x2479320` (bytes P, linkage I), matching Xbox retail `FUN_82244d40` / preview
`FUN_82334fc8`:

```
2479323 if map.count[0x16D6660] > 0x20 return
247933d if !665af0(owner, &xf) return                    ; owner world transform
247937c if rec+0x2c: 4e90e0(rec+0x2c, …)                  ; unit-list addref (Xbox passes 1)
247939c unit = 4e86e0(rec+0x2c); if 0 return              ; weighted max(w,1) draw among list units whose
                                                          ; resident state is 2 or 3 (Xbox FUN_8224add8)
247947c 6746d0([0x1176108], unit, &xf, &out, 5, X)        ; spawn (Xbox X = 0)
2479495 id = out ? 504840(&out) : 0                       ; SceneObject+0x1a |= 0x40, posts 0xF956736B
24794b8 4e5860 -> insert(owner, {id, rec+0x2c})
```

Map `0x16D6660`: count +0; values `0x16D666C` 64 × {object id, UnitList}; keys `0x16D686C` 64 owners;
slot = key & 0x3F, linear probe; insert does not check for an existing key. No per-frame updater.
Consumer: owner cache-out / removal `4e5630` → `0x6BC3F0` — find owner, remove, `5087e0(id)` (destroy),
`4e9330(list)` (unref), then `4e54f0(owner)`. Live map count 0 in all four chris captures.

## Constants

| What | Value |
|---|---|
| NoModel list / count / cap | `0xDCCE30` / `0xDCCFC4` / `0xDCCFC8` = 100; sentinel `0xDCCFC0` |
| Free pool / count / cap | `0xDCC6F0` / `0xDCCAF4` / `0xDCCAF8` = 256 |
| NoModel owner set | `0x16D9FA0`: keys `0x16DA1A8` (128), counts `0x16D9FA8` |
| ParkingSpace map | `0x16D6660` (64 slots, refuses at count > 0x20) |
| Floats | 0.01 `0xB97EEC`; 1.0 `0xB9B664`; 0.0 `0xB9B690`; 50.0 `0xB984AC` |

## Open

Native bodies of `4e0e80`, `4e5ac0`, `4e4dc0` were never observed executing (a capture after a NoModel
−1 / state-5 release or a ParkingSpace activation would settle them); `[0x246047c]` and the 6th
`6746d0` argument on PC; `582930` / `4e9330` (VM, Xbox-only semantics); event `0x065BD62D`.
