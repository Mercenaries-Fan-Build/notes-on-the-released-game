#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Harvest ECS-style UCFX ``COMP`` blobs (ModelName, HibernationControl, regions, …).

Each COMP ``data`` blob is an array of fixed-stride records:

    [ u32_le entity_key ][ payload bytes … ]

The stride comes from the ``schm`` child: ``struct.unpack_from('<I', schm, 4)[0]``
gives the payload stride; total = 4 + payload.  Exception: ``Transform`` (schm
reports 52 but actual payload is 38 → stride 42, verified across all 173
``layers_static`` sub-blocks).

Entity keys are shared across all COMPs in a sub-block and match the ``Name``
COMP's keys.  This module extracts per-entity keyed records and the merge
function attaches them to placement dicts by entity key.

Verified patterns are documented in ``docs/ecs_components.md``.
"""

from __future__ import annotations

import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from placement_extractor import parse_vz_state_chunk_table

ECS_COMP_NAMES: frozenset[str] = frozenset(
    {
        "ModelName",
        "HibernationControl",
        "ObjectScript",
        "EntranceLink",
        "EntranceParameters",
        "EntranceToSeat",
        "Door",
        "DoorCoupling",
        "SoundInterior",
        "SphereRegion",
        "CircleRegion",
        "LineRegion",
        "LandingZone",
        "FactionZone",
        "FactionMarker",
        "PointLocation",
        "RuntimeLayerId",
        "DestructionLink",
        "LightObject",
        "Label",
        "Anchor",
        "MaterialMapping",
        "ModifierKey",
        "Road",
        "RoadIntersection",
        "ScrubObject",
        "DangerousBuilding",
        "StateMachine",
        "PhysicalLink",
        "BuildingDestruction",
    }
)

TRANSFORM_STRIDE = 42


def _parse_chdr_sub_block(
    data: bytes,
    ucfx_pos: int,
    block_end: int,
) -> tuple[list[dict[str, Any]], int]:
    """Parse a single sub-UCFX CHDR table.

    Returns (chunks, data_area_start) where chunks is a list of
    ``{'tag', 'children': [{'tag', 'offset', 'size'}, …]}`` dicts.
    Children offsets are **relative** to data_area_start.
    """
    ucfx_size = struct.unpack_from("<I", data, ucfx_pos + 4)[0]
    chdr_pos = data.find(b"CHDR", ucfx_pos, ucfx_pos + ucfx_size + 200)
    if chdr_pos < 0:
        return [], ucfx_pos + 8
    chdr_entries = struct.unpack_from("<I", data, chdr_pos + 12)[0]

    pos = chdr_pos + 20
    chunks: list[dict[str, Any]] = []
    for _ in range(chdr_entries):
        if pos + 20 > block_end:
            break
        tag = data[pos : pos + 4]
        if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
            break
        num_children = struct.unpack_from("<I", data, pos + 16)[0]
        children: list[dict[str, Any]] = []
        child_pos = pos + 20
        for _ in range(num_children):
            if child_pos + 20 > block_end:
                break
            ctag = data[child_pos : child_pos + 4].decode("ascii", errors="replace")
            coff = struct.unpack_from("<I", data, child_pos + 4)[0]
            csz = struct.unpack_from("<I", data, child_pos + 8)[0]
            children.append({"tag": ctag, "offset": coff, "size": csz})
            child_pos += 20
        chunks.append({"tag": tag.decode("ascii", errors="replace"), "children": children})
        pos = child_pos

    return chunks, pos  # pos == data_area_start


def _comp_info_name(data: bytes, data_area_start: int, children: list[dict]) -> str | None:
    for c in children:
        if c["tag"] == "info":
            abs_off = data_area_start + c["offset"]
            sz = c["size"]
            if abs_off + sz <= len(data):
                raw = data[abs_off : abs_off + sz]
                ni = raw.find(b"\x00")
                if ni > 0:
                    return raw[:ni].decode("ascii", errors="replace").strip()
    return None


def _comp_child_blob(
    data: bytes,
    data_area_start: int,
    children: list[dict],
    tag_name: str,
    *,
    absolute: bool = False,
) -> bytes | None:
    for c in children:
        if c["tag"] == tag_name:
            off = c["offset"] if absolute else data_area_start + c["offset"]
            sz = c["size"]
            if off + sz <= len(data) and sz > 0:
                return data[off : off + sz]
    return None


def _stride_from_schm(schm: bytes | None, info_name: str) -> int | None:
    """Derive total record stride from a ``schm`` blob.

    Returns ``4 + payload_stride`` (entity key + payload), or ``None`` if
    the schm is absent/too small.  Transform is hardcoded because its schm
    reports 52 but the actual payload is 38.
    """
    if info_name == "Transform":
        return TRANSFORM_STRIDE
    if schm is None or len(schm) < 8:
        return None
    payload = struct.unpack_from("<I", schm, 4)[0]
    if payload <= 0 or payload > 4096:
        return None
    return 4 + payload


def _parse_name_blob(blob: bytes) -> dict[int, str]:
    """Parse a Name COMP data blob → {entity_key: name_string}."""
    result: dict[int, str] = {}
    p = 0
    while p + 4 < len(blob):
        key = struct.unpack_from("<I", blob, p)[0]
        p += 4
        ni = blob.find(b"\x00", p)
        if ni < 0:
            break
        nm = blob[p:ni].decode("ascii", errors="replace")
        # Strip the trailing " 0xHEXID" if present to get the bare entity name
        hex_idx = nm.rfind(" 0x")
        bare = nm[:hex_idx].strip() if hex_idx >= 0 else nm.strip()
        result[key] = bare
        p = ni + 1
        if p < len(blob) and blob[p] == 0:
            p += 1
    return result


def _parse_keyed_records(blob: bytes, stride: int) -> list[tuple[int, bytes]]:
    """Parse a COMP data blob into (entity_key, payload_bytes) pairs."""
    if stride < 5 or len(blob) < stride:
        return []
    records: list[tuple[int, bytes]] = []
    p = 0
    while p + stride <= len(blob):
        key = struct.unpack_from("<I", blob, p)[0]
        payload = blob[p + 4 : p + stride]
        records.append((key, payload))
        p += stride
    return records


def _detect_stride_empirical(blob: bytes, name_keys: set[int]) -> int | None:
    """Try strides 5..500 until data_size is evenly divisible and all keys match name_keys."""
    if not name_keys or len(blob) < 5:
        return None
    for stride in range(5, min(501, len(blob) + 1)):
        if len(blob) % stride != 0:
            continue
        n = len(blob) // stride
        if n < 1:
            continue
        ok = True
        p = 0
        while p + stride <= len(blob):
            k = struct.unpack_from("<I", blob, p)[0]
            if k not in name_keys:
                ok = False
                break
            p += stride
        if ok:
            return stride
    return None


# ---------------------------------------------------------------------------
# layers_static extraction
# ---------------------------------------------------------------------------


def extract_ecs_layers_static(
    data: bytes, source_file: str
) -> list[dict[str, Any]]:
    """Walk every ``layers_static`` sub-UCFX and emit per-entity keyed ECS records.

    Returns a list of dicts, each with ``entity_key``, ``comp_info_name``,
    ``payload_hex``, ``sub_block``, and decoded fields where known.
    """
    ucfx_positions: list[int] = []
    pos = 0
    while True:
        idx = data.find(b"UCFX", pos)
        if idx == -1:
            break
        ucfx_positions.append(idx)
        pos = idx + 1

    all_records: list[dict[str, Any]] = []

    for si, ucfx_pos in enumerate(ucfx_positions):
        block_end = ucfx_positions[si + 1] if si + 1 < len(ucfx_positions) else len(data)
        chunks, data_area_start = _parse_chdr_sub_block(data, ucfx_pos, block_end)

        # First pass: parse Name to build the entity key set for this sub-block
        name_keys: dict[int, str] = {}
        for ch in chunks:
            if ch["tag"] != "COMP":
                continue
            iname = _comp_info_name(data, data_area_start, ch["children"])
            if iname == "Name":
                blob = _comp_child_blob(data, data_area_start, ch["children"], "data")
                if blob:
                    name_keys = _parse_name_blob(blob)

        if not name_keys:
            continue

        name_key_set = set(name_keys.keys())

        # Second pass: parse targeted COMPs
        for ch in chunks:
            if ch["tag"] != "COMP":
                continue
            iname = _comp_info_name(data, data_area_start, ch["children"])
            if not iname or iname not in ECS_COMP_NAMES:
                continue

            d_blob = _comp_child_blob(data, data_area_start, ch["children"], "data")
            if not d_blob or len(d_blob) < 5:
                continue

            schm_blob = _comp_child_blob(data, data_area_start, ch["children"], "schm")
            stride = _stride_from_schm(schm_blob, iname)

            # Validate schm-derived stride against Name keys
            if stride and len(d_blob) % stride == 0:
                test_ok = True
                p = 0
                while p + stride <= len(d_blob):
                    if struct.unpack_from("<I", d_blob, p)[0] not in name_key_set:
                        test_ok = False
                        break
                    p += stride
                if not test_ok:
                    stride = None

            if stride is None:
                stride = _detect_stride_empirical(d_blob, name_key_set)

            if stride is None:
                continue

            keyed = _parse_keyed_records(d_blob, stride)
            for entity_key, payload in keyed:
                rec: dict[str, Any] = {
                    "source": source_file,
                    "block_type": "layers_static",
                    "sub_block": si,
                    "entity_key": entity_key,
                    "comp_info_name": iname,
                    "payload_size": len(payload),
                    "payload_hex": payload.hex(),
                }
                _decode_payload(rec, iname, payload)
                all_records.append(rec)

    return all_records


# ---------------------------------------------------------------------------
# vz_state extraction
# ---------------------------------------------------------------------------


def extract_ecs_vz_state(data: bytes, source_file: str) -> list[dict[str, Any]]:
    """``vz_state`` COMP entries have a different structure from ``layers_static``.

    In vz_state, the CHDR COMP entries contain component *definitions* and
    *enum/schema tables*, not per-entity keyed records.  Placement data is
    in the ``flgs`` section (already extracted by ``placement_extractor``).

    This function currently returns an empty list because the vz_state COMP
    blobs are not per-entity keyed records that can be merged into placements.
    The entity cross-referencing for vz_state is done via ``entity_id`` fields
    that reference back to ``layers_static``.
    """
    return []


# ---------------------------------------------------------------------------
# Payload decoders (verified fields only)
# ---------------------------------------------------------------------------


def _key_hex_u32(value: int) -> str:
    return f"0x{value:08x}"


def decode_road_payload(payload: bytes) -> dict[str, Any]:
    """Decode a 40-byte Road COMP payload (schm: 4×u32 + 2×Vec3)."""
    if len(payload) < 40:
        raise ValueError(f"Road payload too short: {len(payload)}")
    k0, k1, h0, h1 = struct.unpack_from("<4I", payload, 0)
    ax, ay, az = struct.unpack_from("<3f", payload, 16)
    bx, by, bz = struct.unpack_from("<3f", payload, 28)
    return {
        "road_ref_key_0": _key_hex_u32(k0),
        "road_ref_key_0_int": k0,
        "road_ref_key_1": _key_hex_u32(k1),
        "road_ref_key_1_int": k1,
        "road_lane_hash_0": _key_hex_u32(h0),
        "road_lane_hash_1": _key_hex_u32(h1),
        "road_endpoint_a": {"x": round(ax, 4), "y": round(ay, 4), "z": round(az, 4)},
        "road_endpoint_b": {"x": round(bx, 4), "y": round(by, 4), "z": round(bz, 4)},
    }


def decode_road_intersection_payload(payload: bytes) -> dict[str, Any]:
    """Decode a 124-byte RoadIntersection COMP payload (7×u32 + 6×Vec3 + 6×u32)."""
    if len(payload) < 124:
        raise ValueError(f"RoadIntersection payload too short: {len(payload)}")
    refs = struct.unpack_from("<7I", payload, 0)
    vec3s: list[dict[str, float]] = []
    for i in range(6):
        off = 28 + i * 12
        x, y, z = struct.unpack_from("<3f", payload, off)
        vec3s.append({"x": round(x, 4), "y": round(y, 4), "z": round(z, 4)})
    tail = struct.unpack_from("<6I", payload, 100)
    return {
        "intersection_ref_keys": [_key_hex_u32(v) for v in refs],
        "intersection_ref_keys_int": list(refs),
        "intersection_vec3s": vec3s,
        "intersection_tail_u32": [_key_hex_u32(v) for v in tail],
        "intersection_tail_u32_int": list(tail),
    }


def _decode_payload(rec: dict[str, Any], info_name: str, payload: bytes) -> None:
    """Add decoded fields to *rec* for COMP types with known layouts."""
    if info_name == "ModelName" and len(payload) >= 4:
        rec["model_name_hash"] = f"0x{struct.unpack_from('<I', payload, 0)[0]:08x}"

    elif info_name == "HibernationControl" and len(payload) >= 6:
        rec["hibernation_u8_0"] = payload[0]
        rec["hibernation_u8_1"] = payload[1]
        rec["hibernation_f16_or_u16"] = struct.unpack_from("<H", payload, 2)[0]
        rec["hibernation_u16_4"] = struct.unpack_from("<H", payload, 4)[0]

    elif info_name == "ObjectScript" and len(payload) >= 8:
        rec["script_hash_0"] = f"0x{struct.unpack_from('<I', payload, 0)[0]:08x}"
        if len(payload) >= 8:
            rec["script_u32_1"] = struct.unpack_from("<I", payload, 4)[0]

    elif info_name == "DestructionLink" and len(payload) >= 16:
        # schm layout: type6@0, type9@4, type7@8, type6@12 (see docs/schm_type_codes.md)
        rec["destruction_ref_key"] = f"0x{struct.unpack_from('<I', payload, 0)[0]:08x}"
        rec["destruction_u32_1"] = struct.unpack_from("<I", payload, 4)[0]
        rec["destruction_link_key"] = f"0x{struct.unpack_from('<I', payload, 8)[0]:08x}"
        rec["destruction_u32_3"] = struct.unpack_from("<I", payload, 12)[0]

    elif info_name == "LightObject" and len(payload) >= 52:
        rec["light_u32_0"] = struct.unpack_from("<I", payload, 0)[0]
        rec["light_color_r"] = round(struct.unpack_from("<f", payload, 4)[0], 4)
        rec["light_color_g"] = round(struct.unpack_from("<f", payload, 8)[0], 4)
        rec["light_color_b"] = round(struct.unpack_from("<f", payload, 12)[0], 4)
        rec["light_intensity"] = round(struct.unpack_from("<f", payload, 16)[0], 4)
        rec["light_radius"] = round(struct.unpack_from("<f", payload, 20)[0], 4)

    elif info_name == "Road" and len(payload) >= 40:
        rec.update(decode_road_payload(payload))

    elif info_name == "RoadIntersection" and len(payload) >= 124:
        rec.update(decode_road_intersection_payload(payload))


# ---------------------------------------------------------------------------
# Merge into placement dicts
# ---------------------------------------------------------------------------


def placement_entity_key(entity_name: str | None) -> int | None:
    """Extract the u32 entity key from a placement's ``entity_name`` or ``entity_id`` hex string."""
    if not entity_name:
        return None
    if entity_name.startswith("0x"):
        try:
            return int(entity_name, 16)
        except ValueError:
            return None
    if " 0x" in entity_name:
        tail = entity_name.rsplit(" 0x", 1)[-1].strip()
        try:
            return int(tail, 16)
        except ValueError:
            return None
    return None


def merge_ecs_into_placements(
    placements: list[dict],
    ecs_records: list[dict],
    *,
    block_type: str,
) -> int:
    """Mutate *placements* in-place, attaching ``ecs`` dict keyed by COMP name.

    Matching is by u32 entity key (``entity_key`` in ECS records, derived from
    ``entity_id`` or ``entity_name`` hex suffix in placements).

    Returns the number of placements that received at least one ECS record.
    """
    # Index ECS records by entity_key
    ecs_by_key: dict[int, list[dict]] = {}
    for r in ecs_records:
        if r.get("block_type") != block_type:
            continue
        ek = r.get("entity_key")
        if isinstance(ek, int):
            ecs_by_key.setdefault(ek, []).append(r)

    merged = 0
    for p in placements:
        if p.get("block_type", block_type) != block_type:
            continue

        # Try entity_id first (vz_state has this), then entity_name hex suffix
        ek: int | None = None
        eid_raw = p.get("entity_id")
        if isinstance(eid_raw, str) and eid_raw.startswith("0x"):
            try:
                ek = int(eid_raw, 16)
            except ValueError:
                pass
        if ek is None:
            ek = placement_entity_key(p.get("entity_name"))

        if ek is None or ek not in ecs_by_key:
            continue

        ecs_payload: dict[str, Any] = {}
        for r in ecs_by_key[ek]:
            name = r.get("comp_info_name")
            if not name:
                continue
            entry: dict[str, Any] = {
                "payload_size": r.get("payload_size"),
            }
            for k, v in r.items():
                if k.startswith(
                    (
                        "model_",
                        "hibernation_",
                        "script_",
                        "destruction_",
                        "light_",
                        "road_",
                        "intersection_",
                    )
                ):
                    entry[k] = v
            entry["payload_hex"] = r.get("payload_hex")
            ecs_payload[name] = entry

        if ecs_payload:
            p["ecs"] = ecs_payload
            merged += 1

            if "ModelName" in ecs_payload:
                p["model_name_hash"] = ecs_payload["ModelName"].get("model_name_hash")
            if "HibernationControl" in ecs_payload:
                p["hibernation_control"] = {
                    k: v
                    for k, v in ecs_payload["HibernationControl"].items()
                    if k.startswith("hibernation_")
                }

    return merged
