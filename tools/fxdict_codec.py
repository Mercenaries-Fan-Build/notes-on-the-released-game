#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Shared codecs for Mercenaries 2 fxdict and effect UCFX containers."""

from __future__ import annotations

import struct
from dataclasses import dataclass
from typing import Any, Iterator

from ucfx_mesh_codec import CHUNK_HDR, CONTAINER_SENTINEL, read_chunk_header

FXDICT_TYPE_HASH = 0xFA46D8A8
EFFECT_TYPE_HASH = 0x5608BD5A
FXDICT_ASSET_HASH = 0x86BF6C5B  # pandemic_hash_m2("fx")

DICT_RECORD_SIZE = 20


@dataclass(frozen=True)
class FxDictParam:
    index: int
    name_hash: int
    default: float
    value_b: float
    value_c: float
    flags: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "index": self.index,
            "name_hash": f"0x{self.name_hash:08X}",
            "default": round(self.default, 8),
            "value_b": round(self.value_b, 8),
            "value_c": round(self.value_c, 8),
            "flags": f"0x{self.flags:08X}",
        }


@dataclass(frozen=True)
class UcfxChunk:
    tag: str
    rel_off: int
    size: int
    u2: int
    u3: int
    payload: bytes

    def to_dict(self, *, include_payload_hex: int = 0) -> dict[str, Any]:
        out: dict[str, Any] = {
            "tag": self.tag,
            "rel_off": self.rel_off,
            "size": self.size,
            "u2": self.u2,
            "u3": self.u3,
        }
        if include_payload_hex > 0 and self.payload:
            out["payload_head_hex"] = self.payload[:include_payload_hex].hex()
        return out


def walk_ucfx_chunks(body: bytes) -> tuple[int, list[UcfxChunk]]:
    """Parse a standard UCFX container chunk table (dao + inline headers)."""
    if len(body) < 20 or body[:4] != b"UCFX":
        raise ValueError("body is not a UCFX container")
    dao, _u1, _u2, n_chunks = struct.unpack_from("<IIII", body, 4)
    chunks: list[UcfxChunk] = []
    for i in range(int(n_chunks)):
        cpos = 20 + i * CHUNK_HDR
        if cpos + CHUNK_HDR > len(body):
            break
        tag_b, (u0, u1, u2, u3) = read_chunk_header(body, cpos)
        tag = tag_b.decode("ascii", errors="replace")
        if u0 == CONTAINER_SENTINEL or u1 == 0:
            chunks.append(UcfxChunk(tag, int(u0), int(u1), int(u2), int(u3), b""))
            continue
        start = int(dao) + int(u0)
        end = min(len(body), start + int(u1))
        chunks.append(UcfxChunk(tag, int(u0), int(u1), int(u2), int(u3), body[start:end]))
    return int(dao), chunks


def chunk_map(chunks: list[UcfxChunk]) -> dict[str, UcfxChunk]:
    return {c.tag: c for c in chunks}


def parse_fxdict_ucfx(body: bytes) -> dict[str, Any]:
    """Decode fxdict INFO+DICT payload from a UCFX container body."""
    dao, chunks = walk_ucfx_chunks(body)
    by_tag = chunk_map(chunks)
    info = by_tag.get("INFO")
    dict_chunk = by_tag.get("DICT")
    if info is None or dict_chunk is None:
        raise ValueError("fxdict container missing INFO and/or DICT chunk")

    if len(info.payload) < 4:
        raise ValueError(f"INFO too short ({len(info.payload)} bytes)")
    entry_count = struct.unpack_from("<I", info.payload, 0)[0]
    dict_body = dict_chunk.payload
    expected = entry_count * DICT_RECORD_SIZE
    if len(dict_body) < expected:
        raise ValueError(
            f"DICT size {len(dict_body)} < expected {expected} for {entry_count} entries"
        )
    if len(dict_body) != expected:
        # tolerate trailing padding but report it
        trailing = len(dict_body) - expected
    else:
        trailing = 0

    params: list[FxDictParam] = []
    for i in range(entry_count):
        off = i * DICT_RECORD_SIZE
        name_hash, default, value_b, value_c = struct.unpack_from("<Ifff", dict_body, off)
        flags = struct.unpack_from("<I", dict_body, off + 16)[0]
        params.append(
            FxDictParam(
                index=i,
                name_hash=int(name_hash),
                default=float(default),
                value_b=float(value_b),
                value_c=float(value_c),
                flags=int(flags),
            )
        )

    return {
        "dao": dao,
        "entry_count": entry_count,
        "dict_bytes": len(dict_body),
        "dict_trailing_bytes": trailing,
        "parameters": params,
        "chunks": [c.to_dict(include_payload_hex=32) for c in chunks],
    }


def _u32_list(payload: bytes, max_words: int | None = None) -> list[int]:
    n = len(payload) // 4
    if max_words is not None:
        n = min(n, max_words)
    if n <= 0:
        return []
    return list(struct.unpack_from(f"<{n}I", payload, 0))


def _f32_list(payload: bytes, max_words: int | None = None) -> list[float]:
    n = len(payload) // 4
    if max_words is not None:
        n = min(n, max_words)
    if n <= 0:
        return []
    return list(struct.unpack_from(f"<{n}f", payload, 0))


def parse_effect_ucfx(body: bytes) -> dict[str, Any]:
    """Best-effort decode of one effect UCFX container."""
    dao, chunks = walk_ucfx_chunks(body)
    by_tag = chunk_map(chunks)

    out: dict[str, Any] = {
        "dao": dao,
        "chunk_tags": [c.tag for c in chunks],
        "chunks": [c.to_dict(include_payload_hex=24) for c in chunks],
    }

    efct = by_tag.get("EFCT")
    if efct and efct.payload:
        pl = efct.payload
        out["efct"] = {
            "size": len(pl),
            "hex": pl.hex(),
            "u32": [f"0x{x:08X}" for x in _u32_list(pl, 8)],
        }
        if len(pl) >= 8:
            out["efct"]["u32_le"] = {
                "word0": struct.unpack_from("<I", pl, 0)[0],
                "word1": struct.unpack_from("<I", pl, 4)[0],
            }

    emit = by_tag.get("EMIT")
    if emit:
        out["emit"] = {
            "header_emitter_count_u2": emit.u2,
            "header_field_u3": emit.u3,
            "payload_size": len(emit.payload),
        }

    emtr = by_tag.get("EMTR")
    if emtr:
        out["emtr"] = {
            "header_u2": emtr.u2,
            "header_u3": emtr.u3,
            "payload_hex": emtr.payload.hex(),
        }

    trfm = by_tag.get("TRFM")
    if trfm and len(trfm.payload) == 64:
        floats = struct.unpack_from("<16f", trfm.payload, 0)
        out["trfm"] = {
            "matrix_row_major_4x4": [round(x, 6) for x in floats],
        }

    atrb = by_tag.get("ATRB")
    if atrb and atrb.payload:
        out["atrb"] = {
            "u32": [f"0x{x:08X}" for x in _u32_list(atrb.payload)],
            "f32": [round(x, 6) for x in _f32_list(atrb.payload)],
        }

    ptyp = by_tag.get("PTYP")
    if ptyp:
        out["ptyp"] = {
            "header_particle_type_u2": ptyp.u2,
            "header_field_u3": ptyp.u3,
            "payload_u32": [f"0x{x:08X}" for x in _u32_list(ptyp.payload)],
        }

    text = by_tag.get("TEXT")
    if text and text.payload:
        words = _u32_list(text.payload)
        out["text"] = {
            "byte_size": len(text.payload),
            "u32_count": len(words),
            "leading_u32": f"0x{words[0]:08X}" if words else None,
            "texture_or_param_hashes": [f"0x{w:08X}" for w in words[1:]],
        }

    colr = by_tag.get("COLR")
    if colr and colr.payload:
        pl = colr.payload
        stride = 16
        keys = []
        for ki in range(len(pl) // stride):
            chunk = pl[ki * stride : (ki + 1) * stride]
            keys.append(
                {
                    "index": ki,
                    "u32": [f"0x{struct.unpack_from('<I', chunk, o)[0]:08X}" for o in range(0, 16, 4)],
                    "hex": chunk.hex(),
                }
            )
        out["colr"] = {
            "byte_size": len(pl),
            "key_count": len(keys),
            "stride_bytes": stride,
            "keys": keys[:8],
            "keys_truncated": len(keys) > 8,
        }

    frce = by_tag.get("FRCE")
    if frce and frce.payload:
        out["frce"] = {
            "f32": [round(x, 6) for x in _f32_list(frce.payload)],
            "u32": [f"0x{x:08X}" for x in _u32_list(frce.payload)],
        }

    anim = by_tag.get("ANIM")
    if anim:
        out["anim"] = {
            "header_u2": anim.u2,
            "header_u3": anim.u3,
            "payload_u32": [f"0x{x:08X}" for x in _u32_list(anim.payload)],
        }

    akey = by_tag.get("AKEY")
    if akey and akey.payload:
        out["akey"] = {"u32": [f"0x{x:08X}" for x in _u32_list(akey.payload)]}

    geom = by_tag.get("GEOM")
    if geom and geom.payload:
        out["geom"] = {"u32": [f"0x{x:08X}" for x in _u32_list(geom.payload)]}

    return out


def find_block_entry(
    data: bytes,
    *,
    type_hash: int | None = None,
    asset_hash: int | None = None,
) -> tuple[int, int, int, int, bytes] | None:
    """Return (index, asset_hash, type_hash, size, body) for the first matching entry."""
    count = struct.unpack_from("<I", data, 0)[0]
    cumulative = 4 + count * 16
    for i in range(count):
        off = 4 + i * 16
        ah, th, _res, sz = struct.unpack_from("<IIII", data, off)
        body = data[cumulative : cumulative + sz]
        cumulative += sz
        if type_hash is not None and th != type_hash:
            continue
        if asset_hash is not None and ah != asset_hash:
            continue
        return i, ah, th, sz, body
    return None


def iter_typed_entries(
    data: bytes, type_hash: int
) -> Iterator[tuple[int, int, int, bytes]]:
    """Yield (index, asset_hash, size, body) for all entries matching ``type_hash``."""
    count = struct.unpack_from("<I", data, 0)[0]
    cumulative = 4 + count * 16
    for i in range(count):
        off = 4 + i * 16
        ah, th, _res, sz = struct.unpack_from("<IIII", data, off)
        body = data[cumulative : cumulative + sz]
        cumulative += sz
        if th == type_hash:
            yield i, ah, sz, body
