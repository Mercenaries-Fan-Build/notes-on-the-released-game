#!/usr/bin/env python3
"""Scan patch WAD blocks for ECS Transform / flgs placement float violations.

Mirrors ``wad_simulator`` placement checks (NaN/Inf, world bounds, BE-looking
floats). Used by ``scan_patch_placements.py`` and ``dlc_port`` post-build gate.
"""
from __future__ import annotations

import math
import struct
from dataclasses import dataclass, field
from pathlib import Path

from aset_type_ids import TYPE_HASH_TO_TYPE_ID
from sges_decompress import decompress_sges_block
from wad_patcher import parse_block_entries

TYPE_HASH_LAYER = 0xE6B81A54
TYPE_HASH_WORLD_ENTITY = 0x5647C35D
TRANSFORM_COMP_HASH = 0x753EB623
TRANSFORM_RECORD_STRIDE = 42
TRANSFORM_MIN_READABLE = 0x24
FLGS_RECORD_STRIDE = 42
ONE_F_LE = bytes([0x00, 0x00, 0x80, 0x3F])

WORLD_X_MIN, WORLD_X_MAX = -5000.0, 5000.0
WORLD_Y_MIN, WORLD_Y_MAX = -500.0, 1000.0
WORLD_Z_MIN, WORLD_Z_MAX = -5000.0, 5000.0
ABS_COORD_LIMIT = 5000.0


@dataclass
class PlacementHit:
    kind: str  # transform | flgs
    record_idx: int
    field: str
    le_vals: tuple[float, ...]
    be_vals: tuple[float, ...] | None = None
    reason: str = ""

    def summary(self) -> str:
        lv = self.le_vals
        if self.kind == "transform":
            return (
                f"{self.kind}[{self.record_idx}] {self.field} {self.reason}: "
                f"LE=({lv[0]:.4g},{lv[1]:.4g},{lv[2]:.4g})"
                + (
                    f" BE=({self.be_vals[0]:.4g},{self.be_vals[1]:.4g},{self.be_vals[2]:.4g})"
                    if self.be_vals
                    else ""
                )
            )
        return f"{self.kind}[{self.record_idx}] {self.field} {self.reason}: LE={lv[0]:.4g}"


@dataclass
class BlockScanResult:
    block_index: int
    path: str
    layer_entries: int = 0
    transform_records: int = 0
    flgs_records: int = 0
    hits: list[PlacementHit] = field(default_factory=list)

    @property
    def violation_count(self) -> int:
        return len(self.hits)


def _f32_le(data: bytes, off: int) -> float:
    return struct.unpack_from("<f", data, off)[0]


def _f32_be(data: bytes, off: int) -> float:
    return struct.unpack_from(">f", data, off)[0]


def _coord_issue(le: float, be: float) -> str | None:
    """Return violation reason for one coordinate, or None if OK."""
    if not math.isfinite(le):
        if math.isfinite(be) and abs(be) <= ABS_COORD_LIMIT:
            return "nan_inf_be_valid"
        return "nan_inf"
    if abs(le) > ABS_COORD_LIMIT:
        if math.isfinite(be) and abs(be) <= ABS_COORD_LIMIT:
            return "extreme_be_valid"
        return "extreme"
    if not (WORLD_X_MIN <= le <= WORLD_X_MAX):
        # only X checked per-axis in composite check
        pass
    return None


def _position_issues(
    data: bytes,
    off: int,
    *,
    check_world_envelope: bool,
) -> tuple[str | None, tuple[float, float, float] | None]:
    x_le, y_le, z_le = _f32_le(data, off), _f32_le(data, off + 4), _f32_le(data, off + 8)
    x_be, y_be, z_be = _f32_be(data, off), _f32_be(data, off + 4), _f32_be(data, off + 8)
    be_t = (x_be, y_be, z_be)

    for name, le, be in [("x", x_le, x_be), ("y", y_le, y_be), ("z", z_le, z_be)]:
        iss = _coord_issue(le, be)
        if iss:
            return (f"pos_{name}_{iss}", be_t)

    if check_world_envelope:
        if not all(math.isfinite(v) for v in (x_le, y_le, z_le)):
            return ("pos_non_finite", be_t)
        if not (
            WORLD_X_MIN <= x_le <= WORLD_X_MAX
            and WORLD_Y_MIN <= y_le <= WORLD_Y_MAX
            and WORLD_Z_MIN <= z_le <= WORLD_Z_MAX
        ):
            be_ok = (
                WORLD_X_MIN <= x_be <= WORLD_X_MAX
                and WORLD_Y_MIN <= y_be <= WORLD_Y_MAX
                and WORLD_Z_MIN <= z_be <= WORLD_Z_MAX
            )
            if be_ok:
                return ("pos_oob_be_valid", be_t)
            return ("pos_oob", be_t)
    return (None, None)


def _quat_issue(data: bytes, off: int) -> str | None:
    qx, qy, qz, qw = (_f32_le(data, off + i) for i in range(0, 16, 4))
    if not all(math.isfinite(v) for v in (qx, qy, qz, qw)):
        return "quat_nan_inf"
    mag_sq = qx * qx + qy * qy + qz * qz + qw * qw
    if not (0.81 <= mag_sq <= 1.21):
        return "quat_not_unit"
    return None


def _extract_component_name(info: bytes) -> str:
    nul = info.find(0)
    if nul < 0:
        nul = len(info)
    candidate = info[:nul]
    if candidate and all(32 <= b <= 126 for b in candidate):
        return candidate.decode("ascii", errors="replace")
    if len(info) >= 4:
        h = struct.unpack_from("<I", info, 0)[0]
        if h == TRANSFORM_COMP_HASH:
            return "Transform"
        return f"__hash_0x{h:08X}"
    return ""


def _is_transform_info(info: bytes) -> bool:
    name = _extract_component_name(info).lower()
    return (
        name == "transform"
        or name.startswith("transform")
        or "position" in name
        or name == "transformcomponent"
    )


def _read_u32_le(container: bytes, off: int) -> int:
    return struct.unpack_from("<I", container, off)[0]


def _validate_transform_comp(
    container: bytes,
    data_area_off: int,
    n_desc: int,
    start_idx: int,
    label: str,
    *,
    check_world_envelope: bool,
) -> tuple[int, list[PlacementHit]]:
    hits: list[PlacementHit] = []
    info_body: bytes | None = None
    data_body: bytes | None = None

    end = min(start_idx + 6, n_desc)
    for j in range(start_idx, end):
        row_off = 20 + j * 20
        if row_off + 20 > len(container):
            break
        tag = container[row_off : row_off + 4]
        if tag == b"COMP":
            break
        row_u0 = _read_u32_le(container, row_off + 4)
        if row_u0 == 0xFFFFFFFF:
            continue
        body_size = _read_u32_le(container, row_off + 8)
        body_start = data_area_off + row_u0 if data_area_off else 8 + row_u0
        body_end = body_start + body_size
        if body_end > len(container):
            continue
        body = container[body_start:body_end]
        if tag == b"info":
            info_body = body
        elif tag == b"data":
            data_body = body

    if info_body is None or data_body is None or not _is_transform_info(info_body):
        return 0, hits

    comp_name = _extract_component_name(info_body)
    stride = TRANSFORM_RECORD_STRIDE
    if len(data_body) < stride:
        return 0, hits

    record_count = len(data_body) // stride
    for rec_idx in range(record_count):
        rec_off = rec_idx * stride
        if rec_off + TRANSFORM_MIN_READABLE > len(data_body):
            break
        reason, be_t = _position_issues(
            data_body, rec_off + 4, check_world_envelope=check_world_envelope,
        )
        if reason:
            hits.append(
                PlacementHit(
                    kind="transform",
                    record_idx=rec_idx,
                    field=comp_name,
                    le_vals=(
                        _f32_le(data_body, rec_off + 4),
                        _f32_le(data_body, rec_off + 8),
                        _f32_le(data_body, rec_off + 12),
                    ),
                    be_vals=be_t,
                    reason=reason,
                )
            )
        qiss = _quat_issue(data_body, rec_off + 0x14)
        if qiss:
            hits.append(
                PlacementHit(
                    kind="transform",
                    record_idx=rec_idx,
                    field=f"{comp_name}:quat",
                    le_vals=(
                        _f32_le(data_body, rec_off + 0x14),
                        _f32_le(data_body, rec_off + 0x18),
                        _f32_le(data_body, rec_off + 0x1C),
                        _f32_le(data_body, rec_off + 0x20),
                    ),
                    reason=qiss,
                )
            )
    return record_count, hits


def _find_flgs_start(flgs: bytes) -> int | None:
    pos = flgs.find(ONE_F_LE)
    if pos is None or pos < 4:
        return None
    return pos - 4


def _validate_flgs(
    flgs: bytes,
    label: str,
    *,
    check_world_envelope: bool,
) -> tuple[int, list[PlacementHit]]:
    hits: list[PlacementHit] = []
    start = _find_flgs_start(flgs)
    if start is None:
        return 0, hits
    remaining = flgs[start:]
    record_count = len(remaining) // FLGS_RECORD_STRIDE
    checked = 0
    for rec_idx in range(record_count):
        rec_off = rec_idx * FLGS_RECORD_STRIDE
        rec = remaining[rec_off : rec_off + FLGS_RECORD_STRIDE]
        px, py, pz = _f32_le(rec, 0x12), _f32_le(rec, 0x16), _f32_le(rec, 0x1A)
        if px == 0.0 and py == 0.0 and pz == 0.0:
            continue
        checked += 1
        reason, be_t = _position_issues(
            rec, 0x12, check_world_envelope=check_world_envelope,
        )
        if reason:
            hits.append(
                PlacementHit(
                    kind="flgs",
                    record_idx=rec_idx,
                    field="position",
                    le_vals=(px, py, pz),
                    be_vals=be_t,
                    reason=reason,
                )
            )
        for name, off in [("rotation_0", 0x1E), ("rotation_1", 0x22), ("rotation_y_sin", 0x26)]:
            val = _f32_le(rec, off)
            if not math.isfinite(val):
                hits.append(
                    PlacementHit(
                        kind="flgs",
                        record_idx=rec_idx,
                        field=name,
                        le_vals=(val,),
                        reason="nan_inf",
                    )
                )
            elif abs(val) > 1.0:
                hits.append(
                    PlacementHit(
                        kind="flgs",
                        record_idx=rec_idx,
                        field=name,
                        le_vals=(val,),
                        reason="out_of_range",
                    )
                )
    return checked, hits


def _extract_chunk_body(container: bytes, tag: bytes) -> bytes | None:
    if len(container) < 20 or container[:4] != b"UCFX":
        return None
    data_area_off = _read_u32_le(container, 4)
    n_desc = _read_u32_le(container, 16)
    max_desc = (len(container) - 20) // 20
    if n_desc > max_desc:
        return None
    for i in range(n_desc):
        row_off = 20 + i * 20
        if container[row_off : row_off + 4] != tag:
            continue
        row_u0 = _read_u32_le(container, row_off + 4)
        if row_u0 == 0xFFFFFFFF:
            continue
        body_size = _read_u32_le(container, row_off + 8)
        body_start = data_area_off + row_u0
        body_end = body_start + body_size
        if body_end <= len(container):
            return container[body_start:body_end]
    return None


def scan_ucfx_container(
    ucfx: bytes,
    *,
    label: str = "",
    check_world_envelope: bool = True,
) -> tuple[int, int, list[PlacementHit]]:
    """Return (transform_records, flgs_records, hits) for one LE UCFX blob."""
    if len(ucfx) < 20 or ucfx[:4] != b"UCFX":
        return 0, 0, []
    data_area_off = _read_u32_le(ucfx, 4)
    n_desc = _read_u32_le(ucfx, 16)
    max_desc = (len(ucfx) - 20) // 20
    if n_desc > max_desc:
        return 0, 0, []

    all_hits: list[PlacementHit] = []
    transform_total = 0

    i = 0
    while i < n_desc:
        row_off = 20 + i * 20
        if ucfx[row_off : row_off + 4] == b"COMP" and _read_u32_le(ucfx, row_off + 4) == 0xFFFFFFFF:
            tr_count, hits = _validate_transform_comp(
                ucfx,
                data_area_off,
                n_desc,
                i + 1,
                label,
                check_world_envelope=check_world_envelope,
            )
            transform_total += tr_count
            all_hits.extend(hits)
        i += 1

    flgs_body = _extract_chunk_body(ucfx, b"flgs")
    flgs_count = 0
    if flgs_body:
        flgs_count, flgs_hits = _validate_flgs(
            flgs_body, label, check_world_envelope=check_world_envelope,
        )
        all_hits.extend(flgs_hits)

    return transform_total, flgs_count, all_hits


def scan_decompressed_block(
    decompressed: bytes,
    block_index: int,
    path: str,
    *,
    check_world_envelope: bool = True,
) -> BlockScanResult:
    result = BlockScanResult(block_index=block_index, path=path)
    try:
        entries = parse_block_entries(decompressed)
    except Exception:
        return result

    for ent in entries:
        th = ent.get("type_hash", 0)
        if th not in (TYPE_HASH_LAYER, TYPE_HASH_WORLD_ENTITY):
            continue
        result.layer_entries += 1
        off = ent["offset"]
        size = ent["size"]
        if off + size > len(decompressed):
            continue
        chunk = decompressed[off : off + size - 8]
        ucfx_start = chunk.find(b"UCFX")
        if ucfx_start < 0:
            continue
        ucfx = chunk[ucfx_start:]
        label = f"block[{block_index}] {path}"
        tr, fl, hits = scan_ucfx_container(
            ucfx,
            label=label,
            check_world_envelope=check_world_envelope,
        )
        result.transform_records += tr
        result.flgs_records += fl
        result.hits.extend(hits)

    return result


def block_has_layer_type(decompressed: bytes) -> bool:
    try:
        entries = parse_block_entries(decompressed)
    except Exception:
        return False
    return any(e.get("type_hash") in (TYPE_HASH_LAYER, TYPE_HASH_WORLD_ENTITY) for e in entries)


def block_has_type_id_layer(decompressed: bytes) -> bool:
    """True if any entry maps to ASET type_id 9 (layer)."""
    try:
        entries = parse_block_entries(decompressed)
    except Exception:
        return False
    for ent in entries:
        tid = TYPE_HASH_TO_TYPE_ID.get(ent.get("type_hash", 0) & 0xFFFFFFFF)
        if tid == 9:
            return True
    return False


def rank_block_results(results: list[BlockScanResult]) -> list[BlockScanResult]:
    return sorted(
        results,
        key=lambda r: (
            -r.violation_count,
            -r.transform_records,
            -r.flgs_records,
            r.block_index,
        ),
    )


def format_ranked_report(
    results: list[BlockScanResult],
    *,
    top_n: int = 20,
    show_samples: int = 3,
) -> str:
    ranked = rank_block_results([r for r in results if r.violation_count > 0])
    lines: list[str] = []
    total_hits = sum(r.violation_count for r in results)
    blocks_with = len(ranked)
    lines.append(f"Blocks scanned: {len(results)}")
    lines.append(f"Blocks with violations: {blocks_with}")
    lines.append(f"Total violations: {total_hits}")
    lines.append("")
    if not ranked:
        lines.append("No placement violations found.")
        return "\n".join(lines)

    lines.append(f"Top {min(top_n, len(ranked))} blocks by violation count:")
    lines.append(f"{'idx':>5}  {'viol':>5}  {'xfm':>5}  {'flgs':>5}  path")
    for r in ranked[:top_n]:
        lines.append(
            f"{r.block_index:5d}  {r.violation_count:5d}  "
            f"{r.transform_records:5d}  {r.flgs_records:5d}  {r.path}"
        )
        for hit in r.hits[:show_samples]:
            lines.append(f"        {hit.summary()}")
        if len(r.hits) > show_samples:
            lines.append(f"        ... +{len(r.hits) - show_samples} more")
    return "\n".join(lines)
