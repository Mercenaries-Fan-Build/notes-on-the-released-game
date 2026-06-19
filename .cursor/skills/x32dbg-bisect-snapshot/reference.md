# Bisection Snapshot Reference

## Fault taxonomy (debugger-calibrated)

These classes were derived from live captures in `output/_bisection_results/`.
Always match against exemplar snapshots before inventing a new class.

### Healthy main-menu

**Exemplar:** `step2-retest/main-menu`

| Signal | Expected |
|--------|----------|
| Main CIP | `0x7705951c` (ntdll Sleep) |
| Worker CIP | `0x7705951c` (Sleep) |
| Stride gate | `0x00000000` |
| Render view | `0x017CFAF0` typical |
| State | `PAUSED` |

### Load success (in-world)

**Exemplar:** `dedup-strip/load-success`, `patched-animation-table/load-success`

| Signal | Expected |
|--------|----------|
| Outcome | `load_success` |
| Worker CIP | `0x7705951c` (Sleep / WrUserRequest) |
| Render view | `0x017CFAF0` |
| Main CIP | Game runtime (e.g. `0x4076a3`, `0x67d4c0` in GZLibFile::Write) |
| Callstack | Deep frames: `GMatrix2D::Swap`, `0x630fb1`, d3d9 |
| No | GlobalEnter stack (`0x4b1197`), `esi=0x2004FFB0`, `jnz 0x67d130` spin |
| State | `PAUSED_IN_WORLD` |

Stride gate may be `0x38` (dedup-strip) or all zeros — not decisive alone.

### GlobalEnter livelock

**Exemplar:** `q2-lo-hi/load-broken`, `arena-1-10-hi/load-broken`

| Signal | Expected |
|--------|----------|
| Outcome | `load_broken` |
| Fault kind | `globalenter_livelock` |
| Main CIP | `0x4b1180`–`0x4b1300` region |
| esi / csi | Often `0x2004FFB0` |
| Stride gate | First u32 often `0x00000038` |
| Stack | Return addrs like `0x004b1197`, `0x8745xx`, `0x004c9c80` |
| Render view | Often still `0x017CFAF0` (not 0xFFFF) |
| State | `PAUSED_LIVELOCK` |

### Game spin livelock (patch variants)

**Exemplar:** `block-index-patch1/load-broken`, `global-livelock-patch1/load-broken`

| Signal | Expected |
|--------|----------|
| Outcome | `load_broken` |
| Fault kind | `game_spin_livelock` |
| Main CIP | `0x67d130` |
| Disasm | `jnz 0x0067D130` (jump to self) |
| Callstack anchor | `0x1ff07980` in GZLibFile::Write |
| Worker CIP | `0x876430` (active, not Sleep) |
| Stride gate | All zeros — **not** GlobalEnter |
| Render view | `0x017CFAF0` |
| State | `PAUSED_LIVELOCK` |

Patch attempts can move the hang from GlobalEnter into this different spin site.

### Loading stall (non-GlobalEnter)

**Exemplar:** `blk18-hi/load-broken`

| Signal | Expected |
|--------|----------|
| Outcome | `load_broken` |
| Fault kind | `loading_stall` |
| Render view | First u32 `0x0000FFFF` |
| Stride gate | May be `0x38` |
| Main | Often in ntdll/kernel32, not game spin |
| Worker | Active via kernel32, not Sleep |

### NULL pointer access violation

| Signal | Expected |
|--------|----------|
| Outcome | `load_broken` |
| Fault kind | `null_pointer_av` |
| Fault site | e.g. `@0x858db8` |
| cax | `0x0` |
| State | `PAUSED_FAULT` |

## stack_esp decoding

MCP `MemoryRead` at `regs.csp` returns hex like `8079f01fffffffff...`.

Split into 8-hex-char chunks, reverse each chunk byte-wise for LE u32 display:

```
8079f01f → bytes 80 79 f0 1f → u32 0x1ff07980
```

Emit 16 words for `stack_esp`.

## Known addresses (Mercenaries2.exe base 0x00400000)

| Symbol | Address | Notes |
|--------|---------|-------|
| Main thread entry | `0xb04c2e` | startAddress in GetThreadList |
| Worker entry | `0x876400` | startAddress for worker_876400 |
| GlobalEnter loop | `0x4B1180` | livelock region |
| GZLibFile spin | `0x67d130` | `jnz self` livelock |
| kernel32 Sleep | `0x7705951c` | healthy worker/menu idle |
| Render view slot | `0x00DFC2F8` | watch window |
| Stride gate | `0x01176078` | watch window |

## Incomplete captures

If MCP disconnects mid-session:

- Save partial snapshot with `"capture_incomplete": true`
- Include whatever fields were collected before disconnect
- Note in `note` which fields are null/missing
- Offer to re-capture when debug session is restored

## Root manifest schema

`output/_bisection_results/manifest.json`:

```json
{
  "variants": {
    "<variant-id>": {
      "manifest": "output/_bisection_results/<variant-id>/manifest.json",
      "snapshots": ["main-menu", "load-broken"]
    }
  },
  "updated_at": "<UTC ISO>"
}
```

Variant manifest:

```json
{
  "variant_id": "<variant-id>",
  "description": "Bisection variant: …",
  "snapshots": {
    "<snapshot-id>": {
      "path": "output/_bisection_results/…/snapshot.json",
      "captured_at": "<UTC ISO>",
      "state": "PAUSED_IN_WORLD",
      "classification": "load_success"
    }
  },
  "updated_at": "<UTC ISO>"
}
```
