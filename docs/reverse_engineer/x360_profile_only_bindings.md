# Triage of the 27 Lua bindings that exist only in x360-preview-profile, for a port to pc-v11

Grades: **P** = PROVEN (read in this session), **I** = INFERRED, **S** = SPECULATIVE.
VAs belong to x360-preview-profile unless another image is named.

## 0. Provenance and absence (P)
- None of the 27 names appear in the luareg tables of pc-v11, x360-retail or x360-preview-final.
  - PC `Graphics` (0x00b9a4d0) has 75 rows.
  - PC `Sys` (0x00b98a78) has 64 rows.
  - PC `Ai` (0x00b9a938) has 66 rows.
- Every pc-v11 VA cited below is byte-identical to the live 7a348847 (v11-patched-securom) image at `game-files/memory-dumps/7a348847_patched-securom/pmc/image.bin`. VAs checked: 0x466da0, 0x4a65d0, 0x4a5890, 0x4a6730, 0x468ea0, 0x5c1260, 0x5b0050, 0x4effd0, 0x4f0900, 0x4f0c40, 0x4fee20, 0x852640, 0x6aef90, 0x753480, 0xb98a78, 0xb9a4d0. (P: the bytes were compared range by range against the pc-v11 dump, sha 819a96db.)
- The PC C-API VAs in `scripting_host_binding_code_map.md` come from the build whose stub is at 0x006D5640. The v1.1 stub is at 0x006aef90 (`xor eax,eax; ret`, P), so do not reuse the doc's C-API VAs on v1.1 untranslated.

## 1. Shared mechanisms

### M1. The render debug-flag word (20 Graphics.Debug toggles)

**Toggle body (P).** Every toggle is this 7-instruction body (disasm 0x82432940–0x82432bb8):
`lis r11,0x82d5; li r3,0; lwz r11,-0x1338(r11); lwz r10,0x2d28(r11); xor[i]s r9,r10,BIT; stw r9,0x2d28(r11); blr`.
- Lua contract: no arguments read, no values returned.

**The object.** *0x82d4ecc8 is the renderer.
- Profile PgScene::RenderColor 0x8229a088 reads `+0x2b92` from it (P).
- The translated PC function 0x00466da0 reads the same `+0x2b92` from *0x00dfb2f8 (P).

**Pending and latched words.**
- +0x2d28 is the pending word. FUN_828f72e0 latches it into +0x2d2c. That function is called from 0x828f28b8 (P); "once per frame" is I.
- Every consumer reads the latched copy at +0x2d2c.
- Bit 0 is not a debug toggle. Graphics.ScreenShot → FUN_828f7378 sets it, and EndFrame clears it at 0x828ea93c (P).

**Defaults (P).** The constructor FUN_828f7008 writes 0x03000004 to word 0xb4a (= +0x2d28). So Shadows, AA and EnableLights start on, and every other bit starts off.

**Reader census (P).** An instruction scan of the profile PE found **28** reads of +0x2d2c:
- `lwz`: 0x82298b7c, 0x82298c90, 0x82298d60, 0x8229a68c, 0x822aab70, 0x822aace0, 0x822aba78, 0x822ac3dc, 0x822ad450, 0x822ad6a0, 0x822b6b0c, 0x822b6e04, 0x822b6f84, 0x822b71a8, 0x822ca238, 0x822da8d4, 0x822dab40, 0x822dfde8, 0x822e0554, 0x822e05bc, 0x822e0610, 0x822e0cc8, 0x8236f1d4, 0x828ea908.
- `lhz`: 0x822dcc78, 0x822dd034, 0x822dd404. Because the word is big-endian, `&1` on the halfword is bit 16 (TerrainMesh).
- `lbz`: 0x828e9fe4. `&1` on the top byte is bit 24 (AA).

Each read feeds one rlwinm bit test, and every read was mapped to its bit.
- No `addi` or `ld`/`std` form touches the flag word. The only `addi +0x2d2c` builds the string pointer 0x82012d2c.

**Retail Xbox.**
- The retail material bind 0x8256d998 uses renderer +0x2d28 as the device pointer that the profile reads at +0x2d38 (P). So retail lacks 0x10 bytes the profile has.
- That those 0x10 bytes are exactly the flag words is I. The shift is known to fall somewhere between +0x2b92 and +0x2d38.
- Retail RenderColor 0x821b6a98 and UpVis 0x821f94b0 contain no flag tests (P).

**PC.**
- A byte scan of pc-v11 .text finds no bit test using disp32 0x2d28 or 0x2d2c. Every hit is a mov, a dec, or bytes inside a rel32 (P).
- PC RenderColor 0x466da0 has no flag test (P).
- PC UpVis 0x4a65d0 has the same loop as profile 0x822e0be8, without the EnableLights gate (P). The shared shape: count at +0x2000, visible list at +0x2004/+0x1000, `+0x10 & 1`, `[0x7c] > 0`, then a vtable call.

**All 20 toggles are class (c).** PC has neither the state nor the gate. Where the gated body exists on PC, a port needs a new flag plus a hook on that body.

**Gate nesting is part of the behaviour (P).** FUN_82298b58 sits entirely inside the ZPass gate (bit 0x4000). Inside it:
- The Occlusion gate (0x100) calls FUN_822e0538 and Water::RenderOcclusion.
- FUN_822e0538 holds the LightOcclusion gate, and its only caller is 0x82298ca8.

So setting ZPass also suppresses Occlusion, LightOcclusion and water occlusion. A port that hooks these independently will not reproduce this.

### M2. The profile's return-0 stub
- 0x824e7d58 is `li r3,0; blr`, with 44 callers (P). It plays the same role as the PC stub 0x006aef90.
- Debug.VSync and Debug.Prim both point at it. That is why they share a VA: both were already compiled out in the profile build.

### M3. Argument helpers (P)
| Helper | Behaviour |
|---|---|
| FUN_8241cc58 | Number → int. Uses isnumber 0x82879128 and tonumber 0x82879388. |
| FUN_8241dcf8 | String → pandemic_hash via FUN_8290ba80. Returns hash ≠ 0. |
| FUN_8241ee98 | Table field → int. Requires the field to be a number. |
| FUN_8241f088 | Table field → hash. Returns (present && hash ≠ 0). Confirmed by disasm 0x8241f110–0x8241f134. |
| Failure path | lua_checkstack 0x82878c50, then pushnil 0x82879760; the binding returns 1, i.e. nil. |

## 2. Table, one row per binding

All 26 rows below are class (c) on PC except VSync and Prim, which have no behaviour to port. "OFF" means setting the bit disables the feature. "Draws when set" means setting it turns on a debug draw. Every binding has no Lua caller except Sys.GetIgnoreLayers.

**The 20 flag toggles**

| Binding (profile VA) | Bit and default | Profile consumer | PC v1.1 |
|---|---|---|---|
| Graphics.Debug.Lod 0x82432940 | 0x2, off | **No reader found.** The debug-menu callback 0x82279038 ("Toggle Debug Lod", string 0x82012458) flips the same bit (P). | Nothing to port: there is no reference behaviour. |
| Debug.Shadows 0x82432960 | 0x4, on | RenderColor 0x8229a68c tests `!=0`; when set it gathers shadow casters. | Substitute knob. The same gather loop on PC (0x00467004/0x0046701d) is gated on `DAT_0117407f==0 && DAT_00dfb360`. 0x00dfb360 is INI Render/EnableShadows (writer 0x753915). This is a substitute, not the same state (P). LTILibName.LTIVideoSwitchOpt1 0x5c1260 (arg 40/41) also sets it, and writes the INI as a side effect (P). |
| Debug.ShadowBounds 0x82432980 | 0x8, off | No reader found. Debug-menu callback 0x822790a8 ("Toggle Shadow Bounds", 0x82012488) (P). | No reference behaviour. |
| Debug.Texturing 0x824329a0 | 0x10, off | No reader found. | No reference behaviour. |
| Debug.Filters 0x824329c0 | 0x40, OFF | FUN_82298d48 tests `==0` and runs the post-filter pass. The config parser also XORs this bit on key 0x2a2e26f0 (P). | PC counterpart not located. |
| Debug.AA 0x824329e0 | 0x1000000, on | FUN_828e9fa8 (`lbz &1`) takes the non-AA path when the bit is clear. The config parser sets the bit from a float at +0x2bd4 (P). | PC uses INI FSAA 0xdfb33c (P), but no per-frame reader was checked, so no substitute is claimed. |
| Debug.EnableLights 0x82432a00 | 0x2000000, on | UpVis 0x822e0be8 tests `!=0` and builds the visible-light list. | Gated body = PC UpVis 0x4a65d0 (P, structural match). Hook point I. |
| Debug.RenderLights 0x82432a20 | 0x8000000, draws when set | FUN_822e05a0 calls vtable+0x34 on each visible light. | Not located; probably compiled out (I). |
| Debug.RenderLightBounds 0x82432a40 | 0x4000000, draws when set | FUN_822e05a0 calls FUN_822e0328 on each light. | Not located (I). |
| Debug.LightOcclusion 0x82432a60 | 0x10000000, OFF | FUN_822e0538 tests `==0` and calls FUN_822a4788 on each light. Nested under ZPass. | Not located. Reading 0x4a6730 as the counterpart is S. |
| Debug.Water 0x82432a80 | 0x80, OFF | FUN_822b6af8 and Water::Render 0x822b70f0 test `==0`. | Water calls are inline in 0x466da0 (FUN_00486460, FUN_00487610, FUN_00487ea0), gated only on `DAT_00d69f80 && DAT_00d69f84 && +0xca4`. Correspondence I. |
| Debug.Occlusion 0x82432aa0 | 0x100, OFF | Gate inside FUN_82298b58. Water::RenderOcclusion 0x822b6df0 also tests the bit itself. Nested under ZPass. | Not located. |
| Debug.Scrub 0x82432b00 | 0x200, OFF | FUN_822dfdc8 tests `==0`. | Substitute knob: FUN_004a5890 renders only when DAT_00dfb35f (INI Render/EnableScrub, writer 0x7538cd) is set (P). That this function corresponds to the profile consumer is I. |
| Debug.Foliage 0x82432b20 | 0x400, off | No reader found. | No reference behaviour. |
| Debug.Models 0x82432b40 | 0x800, OFF | FUN_822aab58, FUN_822aacc8 and FUN_822ac3b8 test `==0`. | Not located. |
| Debug.Sky 0x82432b60 | 0x1000, off | No reader found. | No reference behaviour. |
| Debug.ZPass 0x82432b80 | 0x4000, OFF | Gates all of FUN_82298b58, including Occlusion and LightOcclusion. | Not located. PC 0x468ea0 has a different shape (P). |
| Debug.LogRenderCalls 0x82432ba0 | 0x2000, off | No reader found. | No reference behaviour. |
| Debug.Reflections 0x82432ac0 | 0x8000, OFF | Water::RenderReflections 0x822b6f70 tests `==0`. | Not located. |
| Debug.TerrainMesh 0x82432ae0 | 0x10000, OFF | TerrainMeshRenderable::Render, ::RenderZPass and ::RenderShadow (`lhz &1`). | Not located. The retail Xbox versions are named (0x821f5270/0x821f56c8/0x821f5990), but their translation to pc-v11 is empty. |

**The other seven bindings**

| Binding (profile VA) | Lua contract | Profile behaviour | PC v1.1 |
|---|---|---|---|
| Debug.ObjectCapping 0x82431be0 | (number) → none; a bad argument returns nil | Writes the integer to DAT_82b88030. **Write-only.** Ghidra xrefs show a single WRITE at 0x82431c40, and a lis/D-form scan finds only that store (P). | No reference behaviour. |
| Debug.Shader 0x82433350 | (string name) → none; a bad argument returns nil | See the Debug.Shader notes below. | Retail Xbox bind 0x8256d998 has no `+10` check (P). PC bind/registry not located. |
| Debug.VSync 0x824e7d58 | () → none | M2 stub. | A faithful port is a return-0 stub. |
| Debug.Prim 0x824e7d58 | () → none | M2 stub. | Same as VSync. |
| Ai.Debug 0x82426378 | (table {AIGuid, Enable: number (default 1), Show}) → none | See the Ai.Debug notes below. | No `+0x1845` or `+0x1840 & mask` access anywhere in the pc-v11 or x360-retail decomp (P, text scan). That the PC AI object has no such field is I. |
| Ai.Chatter 0x82426f08 | (table {Command: string}) → nothing, or N strings for "Log" | See the Ai.Chatter notes below. | See the Ai.Chatter notes below. |
| Sys.GetIgnoreLayers 0x8245fca8 | () → table of strings | See the Sys.GetIgnoreLayers notes below. | pc-v11 contains neither the string "IgnoreLayers" nor 0x649bb805 in either endianness (P, whole-file byte scan). |

**Debug.Shader notes.**
- The binding hashes `name` with FUN_8290ba80, then looks it up in the shader registry 0x83c61188 via FUN_82279738 (key table at +0x1008, 0x400 entries). It flips byte +10 of the shader found.
- Material bind FUN_828f2e58 substitutes PgColorFP (0x83c59624; name at 0x820c4340, file "PgColorFP.sho") when +10 == 0. Net effect: the named shader renders as flat colour (P).
- That +10 is set non-zero when a shader loads is I.
- Unknown-name edge case: on a lookup miss, FUN_82279738 returns `*(registry+4)`, and the binding then flips +10 on that object if it is non-zero. What sits at registry+4 was not determined (FUN_828f4028 does not write it).

**Ai.Debug notes.**
- `Enable` must be a number. FUN_8241ee98 requires one, so `true` makes the binding exit early (P).
- Intended path: FUN_8240b1a8(AI manager DAT_837fd280, guid or all, 0x4000, Enable≠0) → FUN_823e1288 sets ai+0x1845 = 1 and ORs 0x4000 into ai+0x1840. Passing Enable = 0 never clears the bit.
- FUN_823ecb78 tests 0x4000 and calls FUN_823ea250, which draws perception arcs via FUN_823d34b0.
- **Unreachable as written (P, disasm).**
  - The binding needs FUN_8241f088(Show) to return false (`bne` at 0x82426410). It also needs `[r1+0x58] == 0x3f6ab8f0`, which is pandemic_hash("Perception").
  - That slot is written only when the getter returns true. For "" it is written as 0.
  - So the check can only pass on a stale stack value.

**Ai.Chatter notes.**
- The binding acts on the chatter manager DAT_8371ef20 (= &0x83468c4c).
- Commands:

| Command (hash) | Effect |
|---|---|
| "Start" (0x37b8cdaf) | Sets +0x1a0 = 1. |
| "Stop" (0xe2ec63dd) | Sets +0x1a0 = 0 (bytes at 0x823484f0). |
| "Reset" (0xfdc8b95e) | Zeroes +0x10[50] and +0xd8[50]. |
| 0xc71dc7a3 (uncracked) | Reset, then start. |
| "Log" (0x280344a1) | Returns one string per category with +0x10[i] ≠ 0, formatted "%s - %f%%" or "%d - %f%%"; the value is +0xd8[i] / +0x10[i] × k. |

- FUN_8234b408 increments +0x10[cat] when a line plays and +0x1a0 is set (P). The writer of +0xd8 was not located.
- PC:
  - The PC chatter manager 0x014b9f08 (static ctor 0x004effd0) starts its 2×0x5dc8 voice slots at +0x10 (P).
  - Retail Xbox also starts its slots at +0x10, and its request function 0x82253960 has no counter (P).
  - That PC has no counter is I: the PC request function was not located, and it may be in Stext.

**Sys.GetIgnoreLayers notes.**
- The binding copies config buffer 0x83451a88. The config parser FUN_82301b88 writes that buffer at 0x82303a30 for key 0x649bb805 = hash("IgnoreLayers"), up to 0x100 bytes.
- It splits the buffer on ',' into t[1..n]. An empty buffer returns {""} (P).
- **The shipped PC Lua already calls it, guarded by an existence check:** `docs/mercs2-luacd/src/resident/mrxlayermanager.lua:113-121`.
  - The call sits inside `_AddRequest`, once per layer name.
  - Lua lowercases both sides of the comparison.
  - So the binding must be cheap and does not need to lowercase.
  - Registering it changes engine behaviour with no script edit.

**Shipped Lua callers.** Only Sys.GetIgnoreLayers has any: PC `mrxlayermanager.lua:113-114`, and retail Xbox `docs/mercs2-luacd-xbox/src/resident/mrxlayermanager.lua:284-287`. None of the other 26 bindings is called.

### Other bits (context)
The debug-menu callbacks (0x82278818–0x82279100) flip these bits as well, and they have readers. No Lua binding reaches any of them (P):

| Bit | Reader(s) |
|---|---|
| 0x80000 | 0x822ca220 |
| 0x200000 | 0x822ad438, 0x822ad688 |
| 0x400000 | 0x8236f198 |
| 0x800000 | 0x822da8b8, 0x822dab28 |
| 0x20000000 | 0x822aba70 |

### Lua caller search
- grep found only the GetIgnoreLayers hits. Trees searched: `docs/mercs2-luacd/src` (PC retail, per its README), `docs/mercs2-luacd-xbox/src` (retail Xbox scripts_vz, per its `_manifest.md`), `docs/mercs2-dlc-luacd/src`, `mods`, `shipments` and `game-scripts`.
- **The profile disc's own scripts were not searched.**
- `corpus_lua_xref` returns 0 even for GetIgnoreLayers, so that index is incomplete for this form. grep is authoritative.
- Dotted luareg names are nested tables in Lua: "Atmosphere.SetSky" is called as `Graphics.Atmosphere.SetSky` (`wifvzatmosphere.lua:5`, P). The contract is therefore `Graphics.Debug.Lod()` (I).

## 3. Open questions and next steps
1. **IgnoreLayers data source on PC:** decided: a required `IgnoreLayers` key in the porting ASI's own `.ini`.
2. **Ai.Debug fidelity:** decided: port the intent (the perception-arc draw). That needs a PC debug-draw path, and none was found yet.
3. **0xc71dc7a3 is uncracked.** Next: run `exemap hash-join x360-preview-profile` and check the rainbow files. Do not guess.
4. **PC hook sites not located** for Filters, Occlusion, ZPass, Models, Reflections, TerrainMesh, LightOcclusion, RenderLights/Bounds, the Shader bind and registry, and the PC chatter request.
   - Next: run corpus_translate on the named x360-retail functions (TerrainMeshRenderable 0x821f5270/0x821f56c8/0x821f5990, FullScreen 0x822193d8).
   - Where that comes back empty, align the callee order of PC 0x466da0 with retail 0x821b6a98. That is the same platform as the profile, with fewer profile-only calls.
   - For the chatter request, look in Stext (thunk_FUN_025xxxxx) for the min(n,2) loop over 0x014b9f18.
5. **v1.1 Lua C-API VAs for runtime registration** (pushcclosure, setfield, and the namespace registrar). Next: `exemap translate` the code-map VAs to pc-v11 and confirm them against the 7a348847 image. The luaL_Reg tables are in .rdata, so new functions have to be added at runtime.
6. **No reader found for Lod, ShadowBounds, Texturing, Foliage, Sky or LogRenderCalls.** The method was the D-form scan plus the instruction after each of the 28 loads. Next: a Ghidra register-liveness pass from each load, plus a scan for any memcpy or struct copy covering renderer +0x2d28..+0x2d30.
7. **Debug.Shader on a miss.** Next: find the writer of registry+4 (0x83c6118c) with a D-form/lis scan for disp 0x118c.
