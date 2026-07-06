# Keystone B (#13) — the event / RPC bus: PC code map

**Scope:** the PC-side event/RPC bus in `Mercenaries2.exe` (unpacked image, base 0x400000), reversed
to **recover the router/dispatch that the prior Xbox-based analysis left as stubs**. Scoreboard row
13; companion JSON `docs/data/keystone_code_map.json`. Xbox oracle: `docs/mercs2-pdb-analysis/networking.md`
(NetEventCallback), `docs/modernization/pangea_engine_alignment.md` §Keystone B, `mercs2_core/src/event.rs`.

## Result in one line

The half Xbox couldn't show — the **subscriber registry + dispatch** — is fully in the clear on PC
and is documented below. The other half — the **publish/marshal router core** and specifically the
**local-execute-vs-serialize-to-wire branch** — is exactly where SecuROM virtualization sits, which
is *why* Xbox saw stubs; it is relocated to the packer, not gone, and is the one confirm-live item.

## 1. Subscriber registry + dispatch (recovered)

Registry singleton **`DAT_00edaf88`**, built by ctor **`FUN_005ead10`**. It is an **18-bucket
per-event-category hash table** with intrusive linked lists and an **11-tick deferred-delete GC**
(so handlers can be deleted mid-dispatch). Layout:

| offset | field |
|---|---|
| +0x04 + bucket*4 | **active** subscriber-list head (18 buckets) |
| +0x4c + bucket*4 | **deferred/free** list head (18 buckets) |
| +0xd8 (u16) | per-bucket unique-id counter |
| +0xda (u8) | epoch / tick counter (drives safe-delete) |

Subscriber node: `+0x00` filter/predicate vtable, `+0x0c` next, `+0x10` callback, `+0x14` ctx,
`+0x18` (u16) id, `+0x1a` type byte, `+0x1b` epoch stamp, `+0x1c` flags (bit0 persistent, bit2
dead/consumed).

The dispatch chain:

| PC fn | role |
|---|---|
| `FUN_005eb480` | **Event.Create registrar**: bucket = `DAT_00d12278[type*0xc]`; node from per-type factory `PTR_LAB_00d12274[type*3]`; installs match predicate via `vt[0](filter_args)`; links into the active list; id via `FUN_005ed1a0`; **returns handle = `(bucket<<16) | id16`** |
| `FUN_005ed030` | **handler invoke**: `vt[1](registry)` calls the C/Lua callback, marks node consumed (bit2), stamps `node+0x1b = registry+0xda` |
| `FUN_005ed070` | **deferred GC sweep** across all 18 buckets: reclaims consumed nodes, frees nodes >0xB (11) ticks stale via `vt[4](1)` |
| `FUN_005ed1a0` | collision-free 16-bit id allocator within a bucket |

So subscriber lookup is a **fixed 18-bucket hash keyed by event type**, then a linked-list walk
matching the 16-bit id — *not* the 256-bucket profiler registry.

## 2. Lua `Event.*` binding path (recovered)

| PC fn | Lua API |
|---|---|
| `FUN_005f6660` | **`Event.Create` / `Event.CreatePersistent`** (`param_2` = persistence bool; matches the Xbox oracle "both call 0x5F6660 with a persistence boolean"). Pops name-hash + callback + ctx off the VM value-stack (8-byte tagged slots: value@+0, type@+4 — the same TLV the marshal side uses) → `FUN_005eb480(DAT_00edaf88, …)` |
| ~`0x005f69f0` / `0x005f6a00` | thin VM wrappers passing persistence 0 / 1 |
| `FUN_005f6a10` | fire-by-handle (decodes `id>>16` bucket, matches id16, → `FUN_005ed030`) |
| `FUN_005f6a90` | **`Event.Post`** (oracle addr match): hashes the event name via `Hash_String FUN_00824270`, then routes |
| (Event.Delete) | unlinks / flags node dead (bit2) so the GC sweep frees it |

## 3. Publish / marshal router — Xbox→PC binding (partial; core SecuROM-virtualized)

| Xbox | PC | role | conf |
|---|---|---|---|
| bus ctx `DAT_837fe3a0+0x18` | `PTR_PTR_01175f30+0x18` | frame buffer (same +0x18 use) | high |
| `FUN_8241d458` allocate frame | `FUN_0059dd70` | reset/rewind value-stack frame | med |
| `FUN_82420690` **router** | `FUN_005a0cc0` (marshal) + `FUN_007002d0→(*_DAT_0244fb3c)()` + `FUN_0059ddb0→(*_DAT_0245dc0c)()` | build-and-dispatch; **core routing behind SecuROM `thunk_FUN_02xxxxxx` islands** | low |
| `FUN_8256eb28` finalize | VM-stack finalize variant of `FUN_005a0cc0` | med |

**Bridge anchor:** PC `FUN_006f4f80` is a NetSafe-style sender that builds an event on
`PTR_PTR_01175f30+0x18` with the **identical event hash `0x51ee8f14`** (NetSafeAreBriefingAssetsLoaded
— same FNV of the same name across Xbox and PC), marshals 5 args, and drives `FUN_0059dd70` +
`FUN_005a0cc0`. That is what pins the PC frame context to the Xbox `DAT_837fe3a0+0x18`.

## 4. The one remaining wall — local-vs-wire (confirm-live)

The local-execute-vs-serialize decision (category-nibble / frame-flag / IsServer) lives inside the
SecuROM-virtualized router: `FUN_007002d0 → _DAT_0244fb3c`, `FUN_0059ddb0 → _DAT_0245dc0c`, and the
`thunk_FUN_02ee0000 / 02935000 / 024f28e0` islands inside `FUN_005a0cc0`. These indirect through
unpacked-at-runtime code and cannot be read statically — the same wall as Xbox, relocated to the
packer. **Recover it live:** in x32dbg (paused), break on `FUN_005a0cc0` / `_DAT_0244fb3c`; live
memory shows the SecuROM-unpacked body. The category nibble is the first frame arg (Xbox `>>4`), so
that byte is the most likely routing key to watch.

## 5. Reconciliation with `mercs2_core::event.rs`

The Rust in-memory model matches the **marshal side** (32-bit name-hash key, 4 typed args, argc ≤ 7,
2048 cap). New ground truth this pass adds that the Rust model does **not** yet mirror: the
**18-bucket per-category subscriber registry**, the **`(bucket<<16)|id16` handle encoding**, and the
**11-tick deferred-delete window** for safe mid-dispatch deletion. Worth reconciling if the engine
grows a faithful subscription/GC model. (The wire format stays unknown until the confirm-live read.)
