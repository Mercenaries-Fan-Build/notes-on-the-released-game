# Shipment manifest format

The reference for `manifest.yaml` — the file that describes a Mercenaries 2 mod.

A **Shipment** is a mod package. The **Quartermaster** (`qm`) reads one, checks it, and builds it
into an overlay WAD. This document is the contract between the two; `qm rules` lists every check and
links back here.

Start from the [template repo][template] rather than from a blank file.

Format version: **1**. A manifest declaring a *newer* format is rejected loudly rather than parsed
optimistically — a field this build does not understand is a field it would silently drop. Older
formats are accepted.

## The file

`manifest.yaml` at the Shipment root. `.yml`, `.json` and `.toml` are also accepted and parse
through the same model, so nothing is expressible in one and not the others. **Exactly one** — two
manifests is an error rather than a precedence puzzle.

YAML is preferred, and it is what `qm` writes, because this file is mostly prose-adjacent metadata
that people read and review.

```yaml
format: 1

shipment:
  name: my-shipment          # lowercase, dashes; becomes build/<name>.wad
  version: 1.0.0
  target: retail             # retail | reimpl
  authors: [your-name]
  description: One line about what this does.

contributions:
  - kind: replace_texture
    target: pmc_hum_mattias_v3_ub
    image: src/skin.png
```

`target` picks the engine: `retail` is the shipped game, `reimpl` the fan-build engine. There is no
value meaning "both" — a Shipment that claims to target both has almost certainly been tested
against neither, and the layers available differ (ASI plugins exist only on retail).

## Names and hashes

Anywhere an existing asset is referenced you may write **either** a name or a bare `0xHHHHHHHH`
hash. A `0x…` reference *is* that hash; anything else is treated as a name and hashed for you.

```yaml
target: pmc_hum_mattias_v3_ub    # preferred
target: "0x6F84F6A3"             # equally valid
```

**A name is preferred, not required.** The engine's hash is one-way, so a hash cannot be turned back
into a name, which makes a manifest full of them hard to read, review or diff. `qm` warns (M0130) and
offers the name when it can reverse one — but the hash works, and the warning never blocks a build.

Requiring names would be a rule the game itself does not follow: the base data ships hashes, and our
name table does not cover every asset. If you are modding something unnamed, the hash is the only
thing you *can* write.

What the linter is actually guarding against is a **wrong** pairing. An earlier draft of this
document paired `ch_veh_boat_destroyer` with `0xE54047D5` — a hash that belongs to
`al_veh_boat_destroyer`. Nothing about it looked wrong. Writing the name, where you have one, is what
makes that class of drift impossible.

## Folder layout

```
my-shipment/
  manifest.yaml     this file
  src/              your .glb / .png / .lua / raw payloads
  build/            qm output: <name>.wad + .sha256 + build.log   (gitignore this)
  README.md         your own description
```

Every path in the manifest is relative to the Shipment root and must resolve **under `src/`**. A path
that escapes the root — through `..` or a symlink — is refused (M0111), because a Shipment has to
mean the same thing on someone else's machine as on yours.

## Contribution kinds

| kind | layer | required fields |
|---|---|---|
| `replace_texture` | Data | `target`, `image` |
| `add_model` | Data | `name`, `model` |
| `add_outfit` | Data + Script | `name`, `slug`, `display`, `wearer`, `model` |
| `patch_lua` | Script | `target`, `append` |
| `edit_state_machine` | Data | `target`, `states` |
| `native_hook` | Code | `target`, plus a `plugin` or a symbol/detour descriptor, plus `touches` |
| `raw` | any | `payload`, `target_layer`, `touches` |

`donor` is optional wherever it is accepted — omit it and the Quartermaster picks a valid host.

`edit_state_machine`, `native_hook` and `raw` are **not lowered yet**. They fail with the reason
rather than being skipped, because a dropped contribution produces a WAD that looks fine and does
nothing.

### `replace_texture`

Same hash, fully resident, so your image must match the target's dimensions — a mismatch is a hard
error rather than something the builder can quietly rescale.

Two warnings are worth understanding before you pick a target:

- **M0007** — the texture *streams*. Its row names finer LOD rungs held in other blocks, and a
  fully-resident replacement stops those from being named. Hero textures (`pmc_hum_*`) are already
  single-block and are unaffected; most world textures are not.
- **M0009** — the texture has no primary ASET row of its own; retail carries it as a shared
  sub-entry. Replacing it mints a primary row, which is what makes your change take effect — and
  also means every asset sharing that texture now gets your version.

Neither blocks a build. Both change what your mod affects.

## Composition

Two Shipments that touch the same thing must not silently produce one winner and one no-op. This is
the part of the format that exists for that.

### The engine gives no single answer

Four subsystems, four different rules, running at once:

| subsystem | resolution |
|---|---|
| WAD stack | last mounted wins |
| runtime chunk registry | **first** writer wins |
| string databases | last registered wins, capped at 8 |
| ASI plugins | no arbitration at all |

So "load order" is not a universal answer, and for ASI plugins there is no order that resolves a
collision at all.

### Merge classes

Every claim a Shipment makes carries a class:

- **`Exclusive`** — one claimant; a second is a hard error. Raw blocks, function redefinitions, HQ
  starters, anything opaque.
- **`KeyedSet { key }`** — union by key; a duplicate key is an error. Outfits key on
  **`(wearer, slug)`**, not `slug` alone: retail reuses `Original` and `ChickenSuit` across all three
  heroes.
- **`OrderedList`** — append-only, with companion values the Quartermaster derives rather than
  trusting.
- **`LastWins`** — later wins and load order is genuinely the answer. Texture replacement.

**Unrecognized targets are `Exclusive`.** The Quartermaster knows the wardrobe list is append-only
because somebody reversed it and wrote it down; it cannot infer that for something nobody has
studied. Failing closed keeps an unknown edit *expressible* — it just cannot silently co-install.

### Write-sets and read-sets

A claim is not only a write. Shipment A can *read* something Shipment B provides; uninstall B and A's
contribution evaporates with no error anywhere. So a blast radius records both, and a read with no
writer is a finding at deploy rather than a mystery later.

`donor:` is a read — it is borrowed, never written.

### Why `patch_lua` takes an append, not a script

Scripts do not load individually. All 114 live in one block, so editing one means re-emitting all of
them — and two Shipments that each ship their own copy of that block cannot both win. The last one
installed erases the other, silently.

You therefore declare an **append**, and `qm link` composes every installed Shipment's appends onto
the base script, compiles once, and emits a single WAD mounted last.

Ordering is by Shipment name, not install order. That matters more than it looks: a saved costume is
stored as a *position* in the outfit list, so if load order changed the indices, reinstalling mods in
a different order would silently re-dress the player — or leave a saved index pointing at nothing and
wedge the load.

The same reasoning is why the availability count is derived from the final list length instead of
written by each Shipment. Two mods that each append one outfit and each hard-code "one more outfit"
produce the same number: both outfits are in the WAD, in the table, and one is unreachable.

## The Code layer

`native_hook` can carry a prebuilt `.asi` plugin, loaded on retail by `pmc_bb.dll`.

**A prebuilt ASI is arbitrary native code.** The Quartermaster does not compile it and cannot
meaningfully inspect it. What it can do is pin *which bytes* you get: every external requirement
carries a `sha256`, and plugins are distributed through GitHub release pages, which publish a digest
for every asset.

That is **integrity, not authenticity** — it guarantees you received the file the author published,
not that the file is safe. Treat installing an ASI the way you would treat running any downloaded
executable.

Two checks apply here: M0170 rejects a malformed digest, and M0171 rejects fetching over an
untrusted transport. M0160 rejects attaching an ASI to a `reimpl` target, where the loader does not
exist.

Hook claims are `Exclusive` keyed on the hooked address, and a collision is a hard error — because,
as above, there is no load order that fixes it.

## Limits

- `shipment.name` — at most 64 characters, `^[a-z0-9]+(-[a-z0-9]+)*$`. It becomes a filename.
- A patch WAD's header region — the block index, asset table and path list — shares the 2 MB below
  the payload region at `0x208000`. Overflowing it writes the path list into the payload (M0181).
- Every block must declare a decompressed size at least as large as it actually inflates to. The
  engine sizes its buffer from that number, so under-declaring overruns the heap (M0002).

The last two are properties of the built WAD rather than of your manifest, and `qm` checks them
against the artifact before writing it to disk.

## What the checks mean

```
[M0007] warning: pmc_hum_example is a STREAMED texture … — see https://…
```

| severity | effect |
|---|---|
| `info` / `warning` | printed; the build proceeds |
| `error` | the build fails |
| `HANG` | the build fails — this class freezes the game with no message at all |

Builds are gated on the **exit code**, never on a printed count, so a script that discards output
still cannot ship a broken Shipment.

`qm rules` lists every rule, including the ones that are known but **not yet implemented**. Those are
listed on purpose: a linter that silently omits its most dangerous checks reads as a clean bill of
health.

[template]: https://github.com/Mercenaries-Fan-Build/mercs2-shipment-template
