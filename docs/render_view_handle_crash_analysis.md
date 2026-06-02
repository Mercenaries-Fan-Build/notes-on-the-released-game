# Render-view handle-table resolve crash (`0xFFFF` write) — Ghidra static RE

**Binary:** `…\Mercenaries 2 World in Flames\Mercenaries2.exe` (cracked v1.1, the one
that runs / is debugged). MD5 `535e2ea8fe6e3dae2d273e7b3ade2b1d`, PE x86:LE:32, image
base `0x00400000` (VAs map 1:1). Confirmed this is the EXE imported into the existing
analyzed Ghidra project at `output/_ghidra/proj` (program `Mercenaries2.exe`).

**Method:** offline headless Ghidra 12.1 (`tools/ghidra_12.1_PUBLIC`, JDK
`tools/jdk21/jdk-21.0.11+10`), reused the already-analyzed project with `-process
-noanalysis`. Post-scripts `scripts/ghidra_scripts/DecompileRenderHandle.java` and
`DecompileRenderHandle2.java`. Raw output: `output/_ghidra/render_handle_decomp.txt`
and `render_handle_decomp2.txt`. No binary or game files were modified.

> The `.securom` block (`0x023E9000–0x037005F7`, `rwx`) is where the live x32dbg
> FPO stack-walk wall sits. Ghidra left functions there undefined; this pass
> force-disassembled and created the resolve-loop function so it decompiled cleanly.

---

## 1. The crash function — resolve loop `FUN_024611A3` (`.securom`)

Force-created at the loop entry the live trace identified (`mov ebp,0x04`). Decompiled C
(Ghidra), annotated:

```c
// EAX = render-view struct base (0x00DE8A48); param_6 = same base.
void FUN_024611a3(...uint param_3 /*start row*/, ...int param_6 /*base*/) {
  piVar5 = (int *)(in_EAX + 0x138a8);          // handle table base = 0x00DE8A48+0x138A8 = 0x00DFC2F0
  do {                                         // OUTER: rows
    iVar7 = 4;                                 // 0x024611AE  MOV EBP,0x4  -> exactly 4 slots
    piVar6 = piVar5;
    do {                                       // INNER: 4 slots
      iVar1 = *piVar6;                         // 0x024611CA  read slot value
      if (iVar1 == 0) {                        // 0x024611CE  JZ  -> empty slot
LAB_024613c3:
        *piVar6 = 0xffff;                      // 0x024613C3  MOV [EBX],0xFFFF  <-- THE BAD WRITE
      } else {
        ... hash-lookup iVar1 in the handle registry
            ([0x017c0398]=bucketcount, [0x017c03ac]=keys,
             [0x017c03b0]=value/page table, [0x017c03a4]=hash mul,
             [0x017c0380] bit3 = mode) ...
        if (piVar3 == 0) goto LAB_024613c3;    // 0x024613BB  JZ  -> NOT FOUND -> 0xFFFF
        *piVar6 = *piVar3;                      // 0x024613BF  resolve: slot <- pointer
      }
      piVar6 = piVar6 + 1;                      // 0x024613C9  ADD EBX,4  next slot
      iVar7 = iVar7 + -1;                       // 0x024613CC  SUB EBP,1
    } while (iVar7 != 0);                       // 0x024613CF  JNZ 0x024611B8
    param_3 = param_3 + 1;
    piVar5 = piVar5 + 8;                        // stride 0x20 to next row
    if (*(ushort *)(param_6 + 0x1ce98) <= param_3) return;  // bound = u16 @ 0x00DE8A48+0x1CE98 = 0x00E057E0
  } while( true );
}
```

All fault-site VAs from the live trace are confirmed in the disassembly:
`0x024611AE mov ebp,0x4`, `0x024611CE jz`, `0x024613BB jz`, `0x024613C3 mov [ebx],0xffff`,
`0x024613C9 add ebx,4`, `0x024613CF jnz 0x024611b8`.

### Address arithmetic (confirms the object identity) — **HIGH confidence**

- Render-view struct base = **`0x00DE8A48`**
- `+0x138A8` → **`0x00DFC2F0`** = the 4 handle slots `F0/F4/F8/FC` ✔ (matches live trace)
- `+0x1CE98` → **`0x00E057E0`** = the **u16 row count** that bounds the outer loop
- Slot 2 `[0x00DFC2F8]` = the "consumed singleton": after resolution it holds the live
  render-view sub-object pointer (`0x017CFAF0`), and is dereferenced as a vtable
  (`(**(*[0x00DFC2F8] + N))()`) by the per-frame tick and the worker.

### Root-cause mechanic — **HIGH confidence**

The loop is **not idempotent and has no per-slot "already-resolved" guard.** It reads
each slot and *unconditionally* treats the value as a handle:
- 1st resolve: slots hold handles (`< 0x160000` or `~0x40005Cxx`) → looked up → replaced
  with pointers (e.g. `0x017CFAF0`).
- 2nd resolve over the *same* slots: the value is now the pointer `0x017CFAF0`, which is
  not a handle key → lookup fails (`piVar3 == 0`) → `*piVar6 = 0xFFFF` → the live
  render-view pointer in slot 2 is destroyed.

Next deref of slot 2 faults: main thread at `0x00630FC7` (`MOV ECX,[0x00DFC2F8]` then
`(**(*ptr+0x14))()`), worker at `0x0046A3E7` (`FUN_0046A3C0` does
`(**(*[0x00DFC2F8]+4))()`).

---

## 2. The "dirty / needs-resolve" gate — **HIGH confidence**

There is **no per-object dirty bit inside the loop.** Whether the resolve runs is gated
upstream by the render-manager flag word:

- **Dirty/needs-resolve flag = `[0x017BBD08]` bit 0  ==  render-mgr `[0x017BBCC8] + 0x40`, bit 0.**
  (`0x017BBCC8 + 0x40 = 0x017BBD08`, confirmed.)

`FUN_004C15E0` (called every frame by the resolve dispatcher `FUN_004C14F0`) is a small
state machine over the render-stage array `[0x017BBCCC + i*4]` (cursor `[0x017BBCF8]`,
count `[0x017BBCF4]`, pivot `[0x017BBCFC]`). When the cursor reaches the pivot/end it
**sets** the dirty bit; otherwise it **clears** it:

```c
// FUN_004C15E0 (per-frame), key edges:
if (DAT_017bbcf8 == DAT_017bbcfc) { DAT_017bbd08 |= 1;  return; }   // 0x004C167F OR  ...,1   SET
...
if ((DAT_017bbd08 & 1) != 0)        DAT_017bbd08 &= ~1u;            // 0x004C1693 AND ...,~1  CLEAR
```

### Writers of the dirty flag `[0x017BBD08]`
| VA | Function | Instruction | Effect |
|----|----------|-------------|--------|
| `0x004C167F` | `FUN_004C15E0` | `OR  [0x017bbd08],1` | **SET** (render pipeline reached the resolve stage) |
| `0x004C1693` | `FUN_004C15E0` | `AND [0x017bbd08],~1` | clear |
| `0x004C11F3` | `FUN_004C1170` | `MOV [0x017bbd08],ECX` (after `AND ECX,0xFFFFFFE4`) | render-mgr **constructor/reset** clears bits 0,1,3,4 |

`FUN_004C1170` is the render-manager constructor: zeroes `[0x017BBCC8]`, sets the stage
array `[0x017BBCCC..]` to 5 fixed render-stage objects (`count [0x017BBCF4]=5`, pivot
`[0x017BBCFC]=4`).

---

## 3. The gate that re-triggers re-init on (save-)load — `[0x01175A94]`

`FUN_00630EF0` (per-frame render/scene tick) runs the one-time re-init only when the
load gate is armed, then disarms it:

```c
void FUN_00630ef0(void) {
  if (DAT_01175a94 == 1) {                 // 0x00630F02  load/re-init pending
    FUN_004c0730();                         // 0x00630F0B  registry enumerator / re-init
    *(uint*)(DAT_01175cdc + 0x40) &= ~4u;   // clear bit2 of the *other* render-mgr at [0x01175cdc]
    *(int*) (DAT_01175cdc + 0x3c) = DAT_00b9b664;
    DAT_01175a94 = 2;                       // 0x00630F26  MOV [0x01175a94],2  (done)
  }
  FUN_004c16e0();
  ...
  FUN_004c14f0(dt);                          // 0x00630FAC / 0x00630FC2  resolve dispatcher (EVERY frame)
  (**(code**)(*(int*)PTR_DAT_00dfc2f8 + 0x14))();   // 0x00630FC7  deref slot-2 ptr -> CRASH if 0xFFFF
  ...
  (**(code**)(*(int*)PTR_DAT_00dfc2f8 + 0x10))();
}
```

### Writers of the load gate `[0x01175A94]`
| VA | Function | Writes | Role |
|----|----------|--------|------|
| `0x004BBD84` | `FUN_004BBD84` | `=1` | **arms re-init** (load/restore state machine; preceded by `CALL 0x004C17B0` and `[0x01175CE0]=0`) |
| `0x00630F26` | `FUN_00630EF0` | `=2` | re-init consumed |
| `0x004BBDBB` | (load state machine) | `=0` | post state-2 reset |
| `0x004BC8F2` | (load state machine) | `=EBX` | state 5→6 |
| `0x004BC787` / `0x004BC91B` / `0x004BB397` | (load state machine) | `=0` | other load/abort transitions |

The `0x004BB3xx / 0x004BC7xx–0x004BC9xx` writers are all one big level/save-load
sequencer (a `state @ [EBP+8]` machine, states 2..7) — i.e. the gate is set on
**load/restore**, exactly when the DLC save-load repro fires.

### The re-resolve invocation on load — **MEDIUM-HIGH confidence**
`FUN_004C09C0` (render-loop state machine, state 2) takes a special branch when the gate
is armed and calls the render-view object's resolve vtable methods directly:

```c
if (DAT_01175a94 == 1) {
  if (FUN_0074cc80() /*worker ready*/) {
    (**(*PTR_DAT_00dfc2f8 + 4 ))();   // re-acquire / re-resolve handle table
    (**(*PTR_DAT_00dfc2f8 + 0xc))();
    (**(*PTR_DAT_00dfc2f8 + 8 ))();
  }
  thunk_FUN_024e2be0();
}
```

`FUN_0046A3C0` (the worker that AVs at `0x0046A3E7`) calls the same `(**(*slot2+4))()`
after writing `[slot2 + 0x2B94]`. So the `+4` vtable method is the entry that drives the
resolve loop `FUN_024611A3` over `[0x00DFC2F0]`.

---

## 4. Registry enumerator `FUN_004C0730` (the load-time re-init)

Counts the render-object registries and re-activates them:

```c
void FUN_004c0730(void) {
  // count registry A [0x00D28668] -> iVar9
  // count registry B [0x00D287A0] -> iVar7
  for (each obj in A) {
     if (obj.vtbl[+4]() /*active?*/) {
        if (obj in B) { obj.vtbl[+0x28](); obj.flags &= ~... ; }
        obj.refcount[2]++;                 // piVar8[2]
        want = (obj[3]==0 && obj[2]>0);
        if (state_bit(obj) != want)        // toggle render-active state
           want ? obj.vtbl[+0x14]() : obj.vtbl[+0x18]();   // activate / deactivate
     }
  }
  // re-init render-view handle struct at [0x01175FB0]+0x64 IFF its byte+6 == 0:
  puVar2 = *(int*)([0x01175FB0]+0x64);
  if (puVar2[6] == 0) { puVar2[2]=puVar2[3]=puVar2[4]=0xFFFFFFFF;
                        *puVar2 = *(int*)([0x01175F30]+0x10);
                        thunk_FUN_028c1000(puVar2); puVar2[6]=1; }
}
```

The **counts of registries A `[0x00D28668]` / B `[0x00D287A0]` / C `[0x01175FB0]`** drive
how many render objects get (de)activated, i.e. how many handle rows are re-dirtied. The
registries are linked arrays populated by *computed-pointer* writes (Ghidra found only
`READ`/`CMP`/`LEA 0xd28668` references, no direct global stores), so the slot/registry
*producers* live behind the same securom indirection as the loop — the table writers are
not visible as direct data xrefs, which is why the live FPO wall was hit.

---

## 5. Why DLC save-load re-dirties when vanilla does not — hypothesis + confidence

**What static analysis proves (HIGH):**
1. The resolve loop is non-idempotent — re-running it over already-resolved slots writes
   `0xFFFF`. This is a genuine **engine** bug, not data corruption.
2. The trigger is the **load gate `[0x01175A94]==1`** (set on save/restore) →
   `FUN_004C0730` re-init + the `slot2->vtbl[+4]` re-resolve, gated by the render-mgr
   dirty bit `[0x017BBD08]`bit0.
3. The amount of work the resolve does is **data-driven**: the outer bound is the u16 at
   `0x00E057E0`, and the re-activation count comes from registries
   `[0x00D28668]/[0x00D287A0]/[0x01175FB0]`.

**What it strongly implies but cannot read from the static image (MEDIUM):**
Vanilla and DLC run identical engine code, so the gate is armed in both. The only
variable is **how many / which render objects are registered** from the loaded WAD. The
DLC patch WAD must register **one extra render-view/scene render object** (or bump the
render-view row count `[0x00E057E0]` above the number of slots that get a fresh handle on
this load), so the re-resolve sweeps a row whose slot 2 still holds the *resolved* pointer
`0x017CFAF0` from the prior load → `0xFFFF`.

**Concrete WAD/data root-cause hypothesis (MEDIUM):**
A DLC-added entity carries a **render/scene component that registers a render-object
handle** — a camera / RenderView / viewport / reflection-or-cubemap-probe / postprocess
("scene") node, or a *duplicate* of a base entity the engine expects to register exactly
once. Such an entity pushes an extra object into registry A `[0x00D28668]` (or increments
the render-view sub-object count), so the load-time re-init activates more render objects
than the base game and re-resolves the already-resolved render-view handle table.

This is consistent with the byte-swap policy concern: a mis-converted DLC block that
over-emits a render/scene COMP (or a stride defect that produces a phantom extra
render-view record) would register the surplus object. It is **not** a NaN/position bug
(the spatial-hash track) — this is a *count/registration* defect.

---

## 6. What static analysis settles vs. what one live capture would close

**Settled (no game needed):** the engine bug, the exact bad-write site, the dirty flag and
its writers, the load gate and its writers, and that the fix must be data-side (don't
patch engine code).

**Single live capture that would close the data-side cause:**
On a **DLC** save-load, set a breakpoint at the resolve-loop entry **`0x024611A3`** and,
before it runs, read:
- the u16 row count at **`0x00E057E0`**, and
- the 4 slot values at **`0x00DFC2F0..0x00DFC2FC`**.

Then do the same on a **vanilla** save-load. If the DLC count is larger, or slot 2 already
holds a pointer (`0x017CFAF0`, in `[0x00400000,0x40000000)`) instead of a small handle
(`<0x160000` / `~0x40005Cxx`) at loop entry, the over-registration / non-reset is
confirmed. Equivalent earlier breakpoint: `FUN_004C0730` registry-A enumeration
(`0x004C0791`), comparing the entry count of `[0x00D28668]` vanilla vs DLC.

**Proposed data-side check (offline, in the simulator/converter):** extend the WAD
simulator / `ucfx_be_to_le.py` audit to **count render/scene/camera/render-view
components per loaded layer** and diff base-WAD vs `vz-patch.wad`. Any block where the DLC
emits an *extra* render-view/scene/camera render object (or a duplicate registration vs
the base) is the byte-swap/stride defect to fix — analogous to the existing
`validate_transform_components` pass but keyed on render-object/scene component type
hashes rather than `Transform` floats.

---

## Appendix — function map

| VA | Name (assigned) | Role |
|----|------|------|
| `0x00630EF0` | render/scene per-frame tick | runs load re-init when gate==1; calls resolve dispatcher every frame; derefs slot 2 (`0x00630FC7`) |
| `0x004C14F0` | resolve dispatcher | frame-time accrual; calls `FUN_004C15E0` then securom resolve thunk (`0x004C1550 → [0x0245F31C]`) |
| `0x004C15E0` | render-stage state machine / dirty-flag manager | sets/clears `[0x017BBD08]`bit0 |
| `0x004C1170` | render-mgr constructor/reset | builds 5-stage array; clears dirty bits |
| `0x004C0730` | load-time registry enumerator / re-init | (de)activates render objects from `[0x00D28668]/[0x00D287A0]/[0x01175FB0]` |
| `0x004C09C0` | render-loop state machine | state-2 path invokes `slot2->vtbl[+4/8/0xC]` re-resolve when gate==1 |
| `0x024611A3` | **handle resolve loop** (`.securom`) | 4 slots/row, bound `[base+0x1CE98]`; writes `0xFFFF` on miss (`0x024613C3`) |
| `0x0046A3C0` | worker render call | derefs slot 2 (`0x0046A3E7`) |
| `0x004BBD84` | load state: arm re-init | `[0x01175A94]=1` |
