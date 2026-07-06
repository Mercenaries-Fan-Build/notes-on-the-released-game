# Economy Singleton — Cash & Fuel Datatype and the 1-Billion Cap

**Status: decomp-traced + signedness-proven (2026-06-30).** Source of record: memory
`money-fuel-datatype-and-cap`.

## Storage

Cash and fuel are both **signed int32**, stored on one economy singleton (global pointer
`0x01176054`, the `DAT_01176054` seen elsewhere):

| Field | Offset |
|-------|--------|
| cash  | `+0x2C` |
| fuel  | `+0x30` |

## Native Lua bindings

VAs are unpacked-dump (base `0x400000`; subtract `0x400000` for doc/RVA space):

| Binding | Dump VA |
|---------|---------|
| GetCash | `0x5DF440` |
| SetCash | `0x5DF480` |
| GetFuel | `0x5DF590` |
| SetFuel | `0x5DF5D0` |
| AddFuel | `0x5DF670` |

Reg table at dump `0xB99250` = doc `0x799250`.

**Signedness proof:** getters do `cvtsi2ss xmm0, <field>` (signed int → float); `AddFuel`
uses `jns` → reset-to-0 (a signed clamp). Setters store a raw dword. Native ceiling =
int32 max **2,147,483,647**.

## The 1-billion limit is a Lua soft-clamp, NOT the type

`mrxpmc.lua` `AddCashQty` uses `knBillion = 1000000000` and clamps each delta **and** the
running total to `[0, 1e9]`. Fuel clamps to `[0, capacity]`, capacity `[300, 9999]` (cheat
bypass). The `1e9` written to `[singleton + 0x3594]` in `FUN_006cbae0` is an **unrelated**
field, not the wallet. The `CashValue` ECS pickup component is separately int32 (see
`docs/mercs2-ecs/`).

## Raising the ceiling

Edit `knBillion` in `mrxpmc.lua`. Two real ceilings:

1. int32 max = 2.147 B.
2. This Lua build's `lua_Number` is a **32-bit float** (getters `movss` + tag 3; matches
   `luadisass_findings.md`) → integer-exact only to `2^24 = 16,777,216`. Cash already
   snaps to ULP 64 near 1e9 / 128 near 2e9.

**Recommendation: cap ≈ 1,900,000,000.** Exact values `> 16.7 M` or `> 2.1 B` would need
int64 widening plus patching the 5 C functions — not worth it.
