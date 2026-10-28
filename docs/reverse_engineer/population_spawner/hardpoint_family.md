# Hardpoint spawner family — PC v1.0 implementable spec

Evidence base: live image `au/mid_img.bin` (flat 0x400000-based image of
`updated-chris-exports/20261021_chris-jacobs-mid-mission.dmp`; slot targets resolved from it),
disassembled with `au/xdis.py` / `hp/tr2.py`; Ghidra `output/_ghidra/mercs2_unpacked.exe_decomp.txt`;
Xbox preview `output/_ghidra_x360_preview_xenon/xenon_decomp_named.c`; PS3 `ps3_retail_decomp_named.c`
+ `output/_ghidra_exports/ps3-v103-na.annotate.jsonl` (RTTI). Live reads with `au/md.py` (scripts
`hp/live1.py`..`hp/live7.py`, outputs `hp/live*.txt`). Raw disassembly per function in `hp/*.txt`.

Grades: P = PROVEN (read this run from bytes / live), I = INFERRED, S = SPECULATIVE.

## A. Updater FUN_004e2110(float dt)  (asm `hp/u2110.txt`; Xbox twin FUN_82337958)

```
for i = count(0xDCD2F4)-1 down to 0:                                    P 4e2114..4e2124, 4e236c..4e2380
    sp = (0<=i<count) ? list[0xDCCFD0+4i] : *(0xDCD2F0)                  P 4e2137..4e2146 (bounds-checked accessor; out-of-range never hit: list only shrinks at/above i)
    if sp+0x50 != 0: FUN_004e2c10(edi=sp)                               P 4e2148..4e2150
    if sp+0x64 > 0:                       # randomised think interval     P 4e2155..4e217b
        sp+0x64 -= dt ; sp+0x68 += dt ; continue
    x1 = S*0x19660D+0x3C6EF35F ; x2 = x1*0x19660D+0x3C6EF35F ; S=x2      P 4e2180..4e219d (S = DAT_00DFCBAC)
    r = float_bits(((x2&0xFFFF0000)|(x1>>16))>>9 | 0x3F800000)  # [1,2)  P 4e21a2..4e21b8
    sp+0x64 = (r-1.0)*3.0 + 0.1          # U[0.1,3.1) s                   P 4e21be..4e21d6 (0xB9B664=1.0,0xBA8990=3.0,0xB92B58=0.1)
    acc = dt + sp+0x68 ; sp+0x68 = 0                                     P 4e21db..4e21ee
    h = FUN_004e3dd0(esi=sp)              # xmm0                          P 4e21f3, stored [esp+0x2c]
    if !(h > 0) or sp+0x89(state)==0: RELEASE_R1                         P 4e21f8..4e2211 -> 4e2444
    ok = FUN_004e3cd0(&params, sp)        # spawn transform, see D        P 4e2217..4e2228
    act = FUN_00432740(edi=sp+0x24)       # owner physics actor, see F     P 4e2222..4e222c
    flag = act ? act->vtbl[+0x9C]() : 0                                  P 4e2231..4e2243
    if !ok or flag: RELEASE_R2                                           P 4e2245..4e2252 -> 4e2412
    if !FUN_004e39d0(&params, sp): continue   # unit-tracking gate        P 4e2258..4e2268
    if sp+0x89 == 5: RELEASE_R3                                          P 4e226e..4e228a
    if !FUN_004e38d0(eax=&params, edx=sp): continue                      P 4e228f..4e229c
    if FUN_004e0fb0(ecx=sp, h): continue      # activation still dormant  P 4e22a2..4e22b6, body hp/4e0fb0.txt
    if FUN_004e11c0(esi=sp): continue         # Squad gate, see G         P 4e22bc..4e22c5
    if sp+0x60 > 0:                           # one-shot wakeup           P 4e22cb..4e22f5
        sp+0x60 -= acc
        if sp+0x60 <= 0: FUN_004e0ca0(eax=sp, ecx=0)
        continue
    if FUN_004e11f0(edi=sp, acc): continue    # cycle countdown           P 4e22f7..4e230b
    sp+0x5c = sp+0x6c                                                    P 4e230d..4e2312
    if FUN_004e2770(edx=sp):                  # skip roll                 P 4e2315..4e2325
        FUN_004e2800(sp): sp+0x92=0; if sp+0x8f>0: sp+0x91++ ; continue  P 4e2800..4e2817
    FUN_004e2820(sp): sp+0x91=0; if sp+0x90>0: sp+0x92++                 P 4e2820..4e2837
    if sp+0x4c != -1 and !FUN_00536640(eax=sp+0x4c): continue  # seat busy P 4e232c..4e233b, see E
    unit = FUN_004e4150(eax=sp, &params)                                 P 4e233d..4e234b
    if unit == -1: RELEASE_R4                                            P 4e234e..4e2363
    if unit == 0: continue                    # cycle consumed, no spawn  P 4e238e..4e2390
    if byte[0xDFBD74]: FUN_006b2e60(eax=unit, cl=1)                      P 4e2392..4e239f (queues {unit,1} into 0x17C1200[0x400], I)
    FUN_004e19f0(eax=unit, sp)                # +0x40 = unit (0x4e1a1b)   P 4e23a4..4e23ac
    if FUN_004e26f0(edx=sp): sp+0x89 = 5                                 P 4e23af..4e23ba
    FUN_005a1500(esi=&a); FUN_004b1270(edi=sp+0x24, esi=&a)              P 4e23c1..4e23cd (arg list with owner, I)
    FUN_005a0cc0(ecx="OccupiedBuildingSpawnCallback"@0xBB13BC,
                 eax=0x543977F7, &a, 1, 0, 1)                            P 4e23d2..4e23e5; 0x543977F7 = pandemic_hash_m2("DangerousBuilding") P
    FUN_0056af60(eax=unit, ecx=0x065BD62D, xmm0=50.0, 0,0,0,0,0,0)       P 4e23ea..4e240a (0xB984AC=50.0; builds 0x38-byte msg -> FUN_004f10d0, I)
```
RELEASE_Rn (R1 4e2444, R2 4e2412 inline; R3 4e2277, R4 4e2353 via FUN_004e5a90 = slot 0x245E378 ->
0x03260000, same body): `if 0<=i<count: count--; if i!=count: list[i]=list[count]` then
`FUN_004e0eb0(eax=sp)`. P (`hp/secu.txt` 0x3260000: count += [0x245FCC0]=0xFFFFFFFF).

Ghidra's decomp of 4e2110 mislabels the health/acc locals (it passes `local_24`/`fVar7`); the asm
above is authoritative (health = [esp+0x2c] -> 4e0fb0; acc = [esp+0x20] -> 4e11f0 / +0x60).

Xbox FUN_82337958 has the same shape: FUN_82332fa0 = the +0x64/+0x68 interval block; vcall
`+0xAC`; skip bookkeeping inlined (+0x8f/+0x91/+0x92 identical); FUN_8239cb88 = seat check;
FUN_82334a68 = unit choice (-1 -> release, 0 -> nothing); constants 0x543977F7, 0x065BD62D. P (decomp
lines 324234-324400).

## B. Creator FUN_004e5090(record, adjust, owner)  (asm `hp/c5090.txt`; Xbox FUN_82335358)
```
if record+0x24 (HardPoint) == 0: return 0                                P 4e50a1..4e50b0
flag = (act=FUN_00432740(edi=owner)) ? act->vtbl[+0x9C]() : 0            P 4e50b1..4e50ca
if free_count(0xDCCAF4)==0 or cap(0xDCD2F8)==count(0xDCD2F4) or flag:
    return 1                                                             P 4e50cc..4e50ed -> 4e520e
if FUN_006886a0(eax=owner, edi=&tmpXf, record+0x24) < 1: return 0        P 4e50f3..4e5108 (tmpXf discarded)
key = FUN_004df5d0(owner, record+0x24)                                   P 4e510a..4e5117
sp = *FUN_004e5a50()  # free[--free_count] (0x47B440)                    P 4e511b..4e5120, hp/47b440.txt
FUN_004e5a70(eax=0xDCCFD0, edx=&sp)  # list[count++]=sp if count<cap     P 4e5126..4e512f, return ignored
FUN_004e2840(edi=sp, eax=owner, record)  # runtime+0x28 = record+0x24     P 4e5134..4e513c, 4e2855..4e2858
if adjust: FUN_004e35b0(edi=sp)          # SpawnerAdjust                  P 4e5141..4e5148
sp+0x48 = key                                                            P 4e514d..4e5151
sp+0x4c = FUN_004df4f0(eax=owner, sp+0x28)                               P 4e5154..4e5168
FUN_004e3cd0(&params, sp)                                                P 4e5162..4e516b
per-owner counter map @0x16DA3A8: found -> ++, write back (FUN_004e5a20); else insert 1 (FUN_00632250)  P 4e5173..4e51af (map semantics I)
if sp+0x60 <= 0:                                                         P 4e51b4..4e51bb
    h = FUN_004e3dd0(esi=sp)
    if FUN_004e38d0(eax=&params, edx=sp) and FUN_004e0fb0(ecx=sp, h):
        FUN_004e0ca0(eax=sp, ecx=&params); return 1                      P 4e51bd..4e5200
    sp+0x60 = 0.01 (0xB97EEC)                                            P 4e5201..4e5209
return 1
```

## C. FUN_004df5d0(owner, hpHash) -> node-health key  (asm `s/aud94_4df4f0.txt` tail + `s/aud94_4df68d.txt`; Xbox FUN_82330d50 identical)
```
static-guard byte 0x198E17C |= 1  (no other effect)                      P 4df5da..4df5e9
p  = RuntimeSceneObject(0xDF9C90)[owner] ? elem+0x30 : 0   (FUN_00649f00) P 4df5f4, hp/649f00.txt
if !p or !(p0=*p): return 0                                              P 4df5f9..4df609
mh = *FUN_00423dc0(esi=ModelName 0xDF6C08, eax=owner)  # template-inherited; default elem = cont+0x7C  P 4df60f..4df61b
model = FUN_004352b0(eax=mh)  # resource lookup key {mh, type 0x5B724250='model'} under CS 0x1174FFC  P hp/plain.txt (551885 -> 4352bb)
if !model or model+0x14 (u16) not in {2,4}: return 0                     P 4df622..4df63e
idx = FUN_00470520(ecx=model, hpHash)  # model+0x64 sorted (u32 hash,i32 index) pairs, count @+0x6C; binary/linear search 0x247D1C0; -1 if absent  P hp/2467440.txt blocks 6bfba0/247d1c0
if idx < 0: return -1                                                    P 4df64f..4df653
N = *( *(p0+4) + 0x10 )                                                  P 4df65e..4df66a
par = parent(idx)  # nodes = model+0x60, stride 0xB0, +4 = i16 parent     P 4df655..4df662
while par >= N: idx = par; par = parent(idx)   (stop if idx<0)           P 4df670..4df68b
X = FUN_006657d0(eax=owner) = RuntimeNodeHealth(0x17BEFC8)[owner] ? *elem : 0   P 4df690, hp/secu.txt 31e0000
if !X or par < 0: return -1                                              P 4df695..4df6a9
loop:                                                                     P 4df6ab..4df6f5
    e = FUN_00435140(edi=X, ecx=nodes[par].hash)   # see H
    if e: return *e            # = the entry key = that ancestor's name hash   P 4df701
    idx = par ; par = parent(idx)
    if par < 0: return -1
```
Only ancestors are tested, never the HardPoint node itself. Nodes with index >= N are skipped
upward before the test starts (I: N = number of posed nodes in the instance; every live HardPoint
node sits at an index >= N: 22 of N=22, 18 of N=18).

Return contract: **0** = no scene instance / model / model state, **-1** = HardPoint not a model
node, no RuntimeNodeHealth, or no ancestor in the table, **key** otherwise. P.

## D. FUN_006886a0 = PgHardpoints::FindTransforms  (slot 0x245A084 -> 0x248B050 -> 0x2467440)
`(eax=owner, edi=&outMatrix, stack hpHash) -> int`. 0x248B050: elem = RuntimeSceneObject[owner];
p = elem? elem+0x30 : 0; p0 = p? *p : 0; model = p? *(p0+8) : 0; out==0 -> 0; else
FUN_00688770(=0x2467440)(out, p0, elem, p, model, eax=hpHash). P (`hp/secu.txt`, `hp/2467440*.txt`).
0x2467440:
- p and p+0x2A4 > 0 -> log `"-- PgHardpoints::FindTransforms(): Pose has no root node index!!!"`
  (string 0xBCDA48, decoded from [0x245A884]-[0x6B720A]) -> return 0. P
- p and FUN_0068fb10(ecx=hash, p, out): instance table at p0 (+0x14 cap, +0x20 keys, +0x1C values,
  +0x24 default; open addressing via FUN_008242b0) -> node n -> 32-byte entry at *(p+4)+n*32
  (pos @0, quat @0x10) -> out; then if elem: out = out x world(elem) (FUN_008247d0, FUN_0096bc94);
  return 1. P (structure); matrix conventions not decoded.
- else (fallback): model==0 -> 0; idx = model.find(hash) (<0 -> 0); out = bind(node idx)
  (node+0x10, FUN_00835e80); while parent >= N: out = out x bind(parent); if parent >= 0 and p:
  out = out x instanceXf(parent) (FUN_0068fbc0); if elem: out = out x world; return = SecuROM
  constant tree 0x2457E63 evaluated by `hp/evaltree.py` = **1** (+0x28 only if EFLAGS.TF set — anti-debug). P
So the return is 1 on success, 0 on failure; callers test `>= 1`/`!= 0`. P

## E. FUN_004df4f0(owner, hpHash) -> sp+0x4C   (slot 0x245F6C8 -> 0x2467A70; Xbox FUN_82330078)
Iterates the owner's **SeatLink** records (container 0xDF8188, FUN_006499f0(&cont,0,1) + FUN_00649a80;
no template inheritance since arg2=0); runtime SeatLink element (stride 8) = `{+0 HardPoint, +4 NAME}`;
on `elem+0 == hpHash` returns `cont+0x60[recordIndex]` = the record's unnamed first field
(schema hash 0x54704554, a 0x8000xxxx key — the seat); none -> -1. P (code); field equality P
(live: element 0 = 0x56063B28/0xB7B967D0, +0x60[0]=0x80006186 = authored row
`80006186 56063B28 B7B967D0`, `hp/seat.txt`, `hp/seatlink_schema.txt`).
Window's FUN_004e3ea0 does the same walk but matches `elem+4 == 0x12531EB9` (NAME). P (decomp 116560+)
Updater use: `FUN_00536640(eax=+0x4C)` (slot -> 0x4D4550) = **true iff that key has no RiderLink
(0xDF8408) element** -> spawn allowed only when the seat is unoccupied. P (code); "occupied" reading I.
All 9 live Hardpoint spawners have +0x4C = -1 (no SeatLink on their owners). P

## F. "Hardpoint occupant vtable+0x9C" — actually the OWNER's physics actor
FUN_00432740(edi=entity) (-> 0x4B1131 -> 0x432747): actor = *PhysicsActor(0x17BF888)[entity];
if actor && actor->vtbl[+0xE0]()==1 && (r=*PhysicsActorRagdoll(0x17BF928)[entity]) && r+0x130 != 0 -> r;
else actor (0 if no component). P (`hp/432740.txt`).
vtbl[+0x9C] (MSVC slot 39 == PS3 slot 40 `+0xA0`, Xbox `+0xAC`): of the 15 PC PhysicsActor-family
vtables (adversarial audit 2026-10-21, slot-similarity closure from 0xBA94A0), 13 use
`0x4F2900 = xor al,al; ret` (false); two override: kind-2 vtable 0xBA94A0 with 0x437280:
`o=this+0x158; true iff o && o+0x260 && FUN_0044a550(o)==0 && *(o+0x260)+0xF4 < 0.5`; and kind-0 vtable
0xBA9C28 with 0x43ce80: true iff dot(axis rotated by the actor's transform (0x433c90),
this+0x154..0x15c) < 0.87 (`0xBEB68C`) — a tipped-over test; 85 live 0xBA9C28 objects in container
0x17BF888 mid-mission. P. Xbox preview: kind 2 → 0x82248550 (< 0.5), kind 0 → 0x82251660 (< 0.87). PS3 RTTI: slot 40 base = `return 0` for PgPhysicsActor/Boat/Building/Debris/Helicopter/Jet/
LowResTerrain/Phantom/Ragdoll/Tank/TerrainMesh/Winch/Human; overrides only in PgPhysicsActorCar
(FUN_00119098 — same shape as PC 0x437280: +0x14C obj, +0x260, call==0, field < const) and
PgPhysicsActorProp (FUN_00123098, a dot-product < const test). P (corpus rows). PC kind 2 = Car and
0xBA9C28 = Prop: I (body shapes match the PS3 overrides).
FUN_0044a550 counts entries of `o+0x54..` (count `o+0x208`) whose float == 0.4 (0xBA8724). P; meaning S.
Live: every Hardpoint owner's actor is vtable 0xBA9368 (`_BuildingPhysics`, kind 6) -> always false. P

## G. FUN_004e11c0 (slot 0x245E37C -> 0x40E4B0)
`if sp+0x8A (SpawnerType) == 3 (Squad): s = FUN_004e1100(ecx=sp+0x24); if s==0 return 1 (block); sp+0x34 = s; return 0` else return 0. P.
FUN_004e1100 -> 0x2488440: owner-keyed table 0x16E45C0 (128 slots) -> 0x16E43C0 entry, picks one of
its +0x20 list (count +0x24) via FUN_004e1010; exact selection rule not decoded (I/open).
SimpleSpawnerTypeEnum from `mercs2_probe we-template --enums`: 0 Single 1 Spew 2 Once 3 Squad 4 Seat 5 SeatOnce 6 ParkingSpace. P

## H. FUN_00435140 = RuntimeNodeHealth table lookup  (slot 0x245A308 -> 0x6B2060)
`(edi=X, ecx=nodeHash) -> entry* or 0`: if (X+0x588)&0x7F == 0 -> 0; slot = FUN_008242b0(ecx=hash,
esi=X+0x388, cap 0x80) (start hash%128, linear probe, 0 = empty, hash 0 -> -1); b = slot<0 ? X[0x304] :
X[0x305+slot]; b==0xFF -> 0; else X + b*12. P (`hp/plain.txt`, `hp/8242b0.txt`, `hp/82435f.txt`).
Table X (= *RuntimeNodeHealth[owner]): `entry[b] (12 B) = {u32 nodeHash, u16 max @+4, u16 cur @+6, u32 @+8 (0x000000FF live, unknown)}`,
`+0x304` u8 not-found index (0xFF live), `+0x305[128]` u8 slot->entry, `+0x388[128]` u32 keys,
`+0x588` u8 count (&0x7F). max@+4 / cur@+6 P (FUN_004e3dd0 at 0x4e3e48/0x4e3e6a: health = cur/max
clamped to [0,1], 0 if max < 1e-4 (0xB977F8)).

## I. Release handler FUN_004e0eb0(eax=sp)  (`hp/4e0eb0.txt`, `hp/4e2650.txt`)
```
if !sp: return
if sp+0x40 and (sp+0x58 < 20.0 (0xB9B980) or sp+0x4c != -1):            P 4e0eb9..4e0ed2
    sp+0x50 = sp+0x40 ; FUN_004e2c10(edi=sp)
    if !(sp+0x93 & 8): FUN_005087e0(sp+0x40)      # unit disposal, I
    sp+0x40 = 0
FUN_004e2650(esi=sp):                                                    P
    RtExhaustionCounter(0xDF9710)->vtbl[+0x64](sp+0x24)
    sp+0x89 = 0
    if sp+0x40 and !(sp+0x93 & 2): { if !(sp+0x93 & 8): FUN_005087e0(sp+0x40); sp+0x40 = 0 }
    if sp+0x44: { if !(flags&8): dispose each of 8 slots; return array to pool 0xDCC5E0 (cnt 0xDCC6E4, cap 0xDCC6E8); sp+0x44 = 0 }
if free_count(0xDCCAF4) < cap(0xDCCAF8): free[0xDCC6F0 + 4*count++] = sp  P 4e0eff..4e0f13
```
So every Hardpoint release (flags bit1 clear) disposes the tracked unit unless TrafficSpawner (bit3).

## J. +0x40 lifecycle
Set: FUN_004e19f0 `+0x40 = unit` (0x4e1a1b, P). Cleared: FUN_004e0eb0 / FUN_004e2650 (above, P);
FUN_004e39d0 (several paths, see Ghidra 116390+; other agent). FUN_004e19f0 also: if +0x4C != -1 ->
FUN_00539ff0(eax=unit, +0x4C, 0, 0), FUN_004f8da0(eax=unit, 0,1,1), and `+0x50 = unit` unless
Window or SpawnerType Seat(4)/SeatOnce(5) (P 4e1a5a..4e1a98); the next update then runs
FUN_004e2c10 on +0x50 (RiderLink -> FUN_00535a30 -> FUN_004239f0, clears +0x50; Ghidra 115762).

## K. Spawn placement (call-site of FUN_004e3cd0, `hp/4e3cd0.txt`)
owner transform via FUN_00665af0 (fail -> 0). flags bit5 (PathCount) -> out = owner xf, ret 1.
flags bit0 (IgnoreModel) -> base = owner xf. else base = FindTransforms(owner, sp+0x28) — on 0:
out = owner xf, **return 0** (-> updater RELEASE_R2). Then out = base composed with the spawner's
local pose sp+0x00 (pos) / sp+0x10 (quat) (FUN_008244d0, FUN_0042c1e0, FUN_00824c00; out.pos +=
base.pos). P for branches; composition order I. The same buffer is passed to FUN_004e4150 (P 4e233d).

## L. Live check (mid-mission dump)
| spawner | owner | owner model | record HardPoint (+0x28) | +0x48 | +0x4c |
|---|---|---|---|---|---|
| 0x016DDB14 | 0x0011FB0C | 0x227708EC city_bld_segment16x16c | 0x5382B35E | 0x5E3BCF7B | -1 |
| 0x016DC76C | 0x0012329E | 0x227708EC | 0x5382B35E | 0x5E3BCF7B | -1 |
| 7 others (0x016DC894...) | guardtowers (0x367A8AE4 ocoutpost_guardtower) | | 0xEBBF5043 | 0x501D5FD7 | -1 |

Chain for 0x016DDB14: model nodes 23, N=22; 0x5382B35E -> node 22, parent 13 (0xFAD780B2, not in
table) -> 12 (0x5E3BCF7B, in table) -> key. Owner X=0x1D905FA0: count 2, entry0 0x443DE524 400/400,
entry1 0x5E3BCF7B **400/400** (key slots 36, 123 = hash%128; byte map ->0,1). Guardtower:
0xEBBF5043 -> node 18, parent 17 (0x206376F6) -> 1 (0x501D5FD7) -> entry0 200/200. P (`hp/live3.txt`).
The brief's `{0x5E3BCF7B, 600, 600}` at 0x1CAC43A4 is **not a live entry**: it lies in entity
0x000D6CF9's table X=0x1CAC4380 (a guardtower, count 1, only key 0x501D5FD7) at entry index 3,
beyond the count — stale bytes. P (`hp/live6.txt`, `hp/live7.txt`).
