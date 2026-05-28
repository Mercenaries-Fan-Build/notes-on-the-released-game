"""Shared audio endian field-type classification and periodic folding.

Provides:
- classify_4byte_diff(): classify a single 4-byte field from Xbox vs PC bytes
- SoundbankGeometry: header parse + section/stride derivation
- fold_to_record_relative(): aggregate absolute-offset classifications into
  record-relative positions using computed stride
- build_audio_field_spec(): produce the machine-readable JSON spec from
  matched Xbox/PC body pairs
"""
from __future__ import annotations

import json
import struct
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

TYPE_SOUNDBANK = 0x9F8BCA10
TYPE_WAVEBANK = 0xF753F6D0
AUDIO_TYPES = {TYPE_SOUNDBANK, TYPE_WAVEBANK}
TYPE_NAMES = {TYPE_SOUNDBANK: "soundbank", TYPE_WAVEBANK: "wavebank"}

SOUNDBANK_HEADER_SIZE = 32


def classify_4byte_diff(xbox_bytes: bytes, pc_bytes: bytes) -> str:
    """Classify a 4-byte field based on how Xbox (BE) maps to PC (LE).

    Returns: 'u32' (full reversal), 'u16x2' (two pairs reversed),
             'u8x4' (identical), 'zero' (both zero), or 'mixed'.
    """
    if xbox_bytes == pc_bytes == b'\x00\x00\x00\x00':
        return "zero"
    if xbox_bytes == pc_bytes:
        return "u8x4"
    if xbox_bytes == pc_bytes[::-1]:
        return "u32"
    if (xbox_bytes[0] == pc_bytes[1] and xbox_bytes[1] == pc_bytes[0] and
            xbox_bytes[2] == pc_bytes[3] and xbox_bytes[3] == pc_bytes[2]):
        return "u16x2"
    return "mixed"


@dataclass
class SoundbankGeometry:
    """Parsed soundbank section layout from a body's header."""
    data_start: int
    section_off1: int
    section_off2: int
    section_off3: int
    sub_count: int
    sub_count2: int
    body_len: int

    @property
    def valid(self) -> bool:
        return (self.data_start <= self.section_off1 <= self.section_off2
                <= self.section_off3 <= self.body_len
                and self.data_start >= SOUNDBANK_HEADER_SIZE)

    @property
    def stride_a(self) -> int | None:
        if not self.valid or self.sub_count == 0:
            return None
        sec_a = self.section_off1 - self.data_start
        if sec_a <= 0 or sec_a % self.sub_count != 0:
            return None
        return sec_a // self.sub_count

    @property
    def stride_c(self) -> int | None:
        if not self.valid or self.sub_count2 == 0:
            return None
        sec_c = self.section_off3 - self.section_off2
        if sec_c <= 0 or sec_c % self.sub_count2 != 0:
            return None
        return sec_c // self.sub_count2

    @classmethod
    def from_body(cls, body: bytes, endian: str = "le") -> SoundbankGeometry | None:
        if len(body) < SOUNDBANK_HEADER_SIZE:
            return None
        fmt = "<" if endian == "le" else ">"
        data_start = struct.unpack_from(f"{fmt}I", body, 16)[0]
        section_off1 = struct.unpack_from(f"{fmt}I", body, 20)[0]
        section_off2 = struct.unpack_from(f"{fmt}I", body, 24)[0]
        section_off3 = struct.unpack_from(f"{fmt}I", body, 28)[0]
        sub_count = struct.unpack_from(f"{fmt}H", body, 8)[0]
        sub_count2 = struct.unpack_from(f"{fmt}H", body, 10)[0]
        return cls(
            data_start=data_start,
            section_off1=section_off1,
            section_off2=section_off2,
            section_off3=section_off3,
            sub_count=sub_count,
            sub_count2=sub_count2,
            body_len=len(body),
        )


@dataclass
class FieldVotes:
    """Accumulated votes for a single record-relative offset."""
    votes: dict[str, int] = field(default_factory=lambda: defaultdict(int))

    @property
    def dominant_type(self) -> str:
        if not self.votes:
            return "unknown"
        return max(self.votes, key=self.votes.get)

    @property
    def is_ambiguous(self) -> bool:
        non_zero = {k: v for k, v in self.votes.items() if k != "zero"}
        return len(non_zero) > 1

    @property
    def total(self) -> int:
        return sum(self.votes.values())


def fold_soundbank_bodies(
    xbox_bodies: dict[int, bytes],
    pc_bodies: dict[int, bytes],
) -> dict[str, dict[int, FieldVotes]]:
    """Classify fields at record-relative offsets across matched soundbank pairs.

    Groups by stride to avoid cross-contamination between different record sizes.
    Returns dict with 'header' (aggregated) and 'section_a' / 'section_c'
    (only offsets with consensus across stride groups).

    Also populates per_stride_a/per_stride_c as side data.
    """
    header_votes: dict[int, FieldVotes] = defaultdict(FieldVotes)
    stride_a_groups: dict[int, dict[int, FieldVotes]] = defaultdict(
        lambda: defaultdict(FieldVotes))
    stride_c_groups: dict[int, dict[int, FieldVotes]] = defaultdict(
        lambda: defaultdict(FieldVotes))

    matched_hashes = set(xbox_bodies.keys()) & set(pc_bodies.keys())

    for h in sorted(matched_hashes):
        xbox_body = xbox_bodies[h]
        pc_body = pc_bodies[h]
        common_len = min(len(xbox_body), len(pc_body))
        if common_len < SOUNDBANK_HEADER_SIZE:
            continue

        geo_pc = SoundbankGeometry.from_body(pc_body, "le")
        geo_xbox = SoundbankGeometry.from_body(xbox_body, "be")
        if geo_pc is None or not geo_pc.valid:
            continue
        if geo_xbox is None or not geo_xbox.valid:
            continue

        # Header (0..32)
        for off in range(0, SOUNDBANK_HEADER_SIZE, 4):
            if off + 4 > common_len:
                break
            cls = classify_4byte_diff(xbox_body[off:off+4], pc_body[off:off+4])
            header_votes[off].votes[cls] += 1

        stride_a = geo_pc.stride_a
        stride_c = geo_pc.stride_c

        # Section A: fold per-stride group
        if stride_a and stride_a >= 4:
            sec_a_end = min(geo_pc.section_off1, common_len)
            for off in range(geo_pc.data_start, sec_a_end - 3, 4):
                rel = (off - geo_pc.data_start) % stride_a
                if rel % 4 != 0:
                    continue
                cls = classify_4byte_diff(xbox_body[off:off+4], pc_body[off:off+4])
                stride_a_groups[stride_a][rel].votes[cls] += 1

        # Section C: fold per-stride group
        if stride_c and stride_c >= 4:
            sec_c_end = min(geo_pc.section_off3, common_len)
            for off in range(geo_pc.section_off2, sec_c_end - 3, 4):
                rel = (off - geo_pc.section_off2) % stride_c
                if rel % 4 != 0:
                    continue
                cls = classify_4byte_diff(xbox_body[off:off+4], pc_body[off:off+4])
                stride_c_groups[stride_c][rel].votes[cls] += 1

    # Merge stride groups: only offsets that are unanimously the same type
    # across ALL stride groups where that offset exists
    section_a_votes: dict[int, FieldVotes] = defaultdict(FieldVotes)
    if stride_a_groups:
        min_stride = min(stride_a_groups.keys())
        for rel in range(0, min_stride, 4):
            for stride, group in stride_a_groups.items():
                if rel in group:
                    for cls, count in group[rel].votes.items():
                        section_a_votes[rel].votes[cls] += count

    section_c_votes: dict[int, FieldVotes] = defaultdict(FieldVotes)
    if stride_c_groups:
        min_stride_c = min(stride_c_groups.keys())
        for rel in range(0, min_stride_c, 4):
            for stride, group in stride_c_groups.items():
                if rel in group:
                    for cls, count in group[rel].votes.items():
                        section_c_votes[rel].votes[cls] += count

    return {
        "header": dict(header_votes),
        "section_a": dict(section_a_votes),
        "section_c": dict(section_c_votes),
        "_stride_a_groups": stride_a_groups,
        "_stride_c_groups": stride_c_groups,
    }


def fold_wavebank_bodies(
    xbox_bodies: dict[int, bytes],
    pc_bodies: dict[int, bytes],
) -> dict[str, dict[int, FieldVotes]]:
    """Classify wavebank fields at absolute offsets (no periodic structure)."""
    abs_votes: dict[int, FieldVotes] = defaultdict(FieldVotes)

    matched_hashes = set(xbox_bodies.keys()) & set(pc_bodies.keys())
    for h in sorted(matched_hashes):
        xbox_body = xbox_bodies[h]
        pc_body = pc_bodies[h]
        common_len = min(len(xbox_body), len(pc_body))
        for off in range(0, common_len - 3, 4):
            cls = classify_4byte_diff(xbox_body[off:off+4], pc_body[off:off+4])
            abs_votes[off].votes[cls] += 1

    return {"absolute": dict(abs_votes)}


def _votes_to_json(votes: dict[int, FieldVotes]) -> dict:
    result = {}
    for off in sorted(votes.keys()):
        fv = votes[off]
        result[str(off)] = {
            "type": fv.dominant_type,
            "votes": dict(fv.votes),
            "ambiguous": fv.is_ambiguous,
            "total": fv.total,
        }
    return result


def build_audio_field_spec(
    xbox_soundbanks: dict[int, bytes],
    pc_soundbanks: dict[int, bytes],
    xbox_wavebanks: dict[int, bytes],
    pc_wavebanks: dict[int, bytes],
) -> dict:
    """Build the full audio_field_spec dict from matched body pairs.

    Returns a JSON-serializable dict conforming to the spec schema.
    """
    sb_matched = set(xbox_soundbanks.keys()) & set(pc_soundbanks.keys())
    wb_matched = set(xbox_wavebanks.keys()) & set(pc_wavebanks.keys())

    # Compute common stride across matched soundbanks
    strides_a: list[int] = []
    strides_c: list[int] = []
    for h in sb_matched:
        geo = SoundbankGeometry.from_body(pc_soundbanks[h], "le")
        if geo and geo.valid:
            if geo.stride_a:
                strides_a.append(geo.stride_a)
            if geo.stride_c:
                strides_c.append(geo.stride_c)

    sb_result = fold_soundbank_bodies(xbox_soundbanks, pc_soundbanks)
    wb_result = fold_wavebank_bodies(xbox_wavebanks, pc_wavebanks)

    # Per-stride section A field maps
    stride_a_spec: dict[str, dict] = {}
    stride_a_groups = sb_result.get("_stride_a_groups", {})
    for stride in sorted(stride_a_groups.keys()):
        group = stride_a_groups[stride]
        u8x4_offsets = [
            off for off, fv in sorted(group.items())
            if fv.dominant_type == "u8x4"
        ]
        stride_a_spec[str(stride)] = {
            "u8x4_offsets": u8x4_offsets,
            "fields": _votes_to_json(group),
        }

    spec: dict = {
        "version": 1,
        "matched_soundbanks": len(sb_matched),
        "matched_wavebanks": len(wb_matched),
        "soundbank": {
            "header": _votes_to_json(sb_result["header"]),
            "section_a": {
                "stride_formula": "(section_off1 - data_start) / sub_count",
                "observed_strides": sorted(set(strides_a)),
                "fields": _votes_to_json(sb_result["section_a"]),
                "per_stride": stride_a_spec,
            },
            "section_c": {
                "stride_formula": "(section_off3 - section_off2) / sub_count2",
                "observed_strides": sorted(set(strides_c)),
                "fields": _votes_to_json(sb_result["section_c"]),
            },
        },
        "wavebank": {
            "fields": _votes_to_json(wb_result["absolute"]),
        },
    }
    return spec


def check_spec_strict(spec: dict) -> list[str]:
    """Validate that the spec is internally consistent.

    This checks the GENERATED spec (from vote aggregation) — it does NOT
    validate individual banks. Use verify_u8x4_invariant() for per-bank proof.

    Fails when:
    - An expected u8x4 offset ({12, 20, 44}) is not the dominant type in section_a
    - Section A has a dominant u8x4 offset NOT in the known set (unprotected field)
    """
    EXPECTED_U8X4_A = {12, 20, 44}
    failures: list[str] = []

    sa_fields = spec.get("soundbank", {}).get("section_a", {}).get("fields", {})
    for off_str, finfo in sa_fields.items():
        off = int(off_str)
        votes = finfo.get("votes", {})
        non_zero = {k: v for k, v in votes.items() if k != "zero"}
        if not non_zero:
            continue
        dom_type = max(non_zero, key=non_zero.get)

        if off in EXPECTED_U8X4_A and dom_type != "u8x4":
            failures.append(
                f"soundbank section_a rel {off}: expected u8x4 but dominant "
                f"is '{dom_type}' ({non_zero})"
            )
        elif off not in EXPECTED_U8X4_A and dom_type == "u8x4":
            u8_count = non_zero.get("u8x4", 0)
            total_nz = sum(non_zero.values())
            if total_nz > 0 and u8_count == total_nz:
                failures.append(
                    f"soundbank section_a rel {off}: UNPROTECTED u8x4 field "
                    f"(100% u8x4, not in production skip set)"
                )
    return failures


@dataclass
class U8x4Violation:
    """A concrete violation: xbox bytes differ from PC at an expected u8x4 site."""
    hash: int
    section: str
    record_index: int
    relative_offset: int
    xbox_bytes: bytes
    pc_bytes: bytes

    def __str__(self) -> str:
        return (
            f"0x{self.hash:08X} {self.section}[{self.record_index}]+{self.relative_offset}: "
            f"xbox={self.xbox_bytes.hex()} pc={self.pc_bytes.hex()} "
            f"(NOT identical)"
        )


def verify_u8x4_invariant(
    xbox_bodies: dict[int, bytes],
    pc_bodies: dict[int, bytes],
    expected_offsets_a: frozenset[int] | None = frozenset({12, 20, 44}),
    per_stride_offsets_a: dict[int, frozenset[int]] | None = None,
    expected_offsets_c: frozenset[int] | None = None,
) -> list[U8x4Violation]:
    """Per-bank, per-record, per-offset deterministic check.

    For each matched soundbank, for each record in section A:
    - If per_stride_offsets_a is provided, uses the u8x4 offsets specific to
      that bank's stride (derived from cross-platform evidence).
    - Otherwise falls back to expected_offsets_a for all strides.

    Any mismatch where xbox bytes != pc bytes at a u8x4 offset is a violation.
    No thresholds, no voting — purely binary.
    """
    violations: list[U8x4Violation] = []
    matched = sorted(set(xbox_bodies.keys()) & set(pc_bodies.keys()))

    for h in matched:
        xbox_body = xbox_bodies[h]
        pc_body = pc_bodies[h]
        common_len = min(len(xbox_body), len(pc_body))
        if common_len < SOUNDBANK_HEADER_SIZE:
            continue

        geo_pc = SoundbankGeometry.from_body(pc_body, "le")
        geo_xbox = SoundbankGeometry.from_body(xbox_body, "be")
        if geo_pc is None or not geo_pc.valid:
            continue
        if geo_xbox is None or not geo_xbox.valid:
            continue

        # Section A
        stride_a = geo_pc.stride_a
        if stride_a and stride_a >= 4:
            # Determine which offsets to check for this stride
            if per_stride_offsets_a and stride_a in per_stride_offsets_a:
                offsets = per_stride_offsets_a[stride_a]
            elif expected_offsets_a is not None:
                offsets = expected_offsets_a
            else:
                offsets = frozenset()

            n_records = geo_pc.sub_count
            for r in range(n_records):
                rec_start = geo_pc.data_start + r * stride_a
                for rel in sorted(offsets):
                    if rel >= stride_a:
                        break
                    pos = rec_start + rel
                    if pos + 4 > common_len:
                        break
                    xb = xbox_body[pos:pos + 4]
                    pb = pc_body[pos:pos + 4]
                    if xb != pb:
                        violations.append(U8x4Violation(
                            hash=h, section="section_a",
                            record_index=r, relative_offset=rel,
                            xbox_bytes=xb, pc_bytes=pb,
                        ))

        # Section C: only if explicitly provided (different record layout)
        if expected_offsets_c is not None:
            stride_c = geo_pc.stride_c
            if stride_c and stride_c >= 4:
                n_records_c = geo_pc.sub_count2
                for r in range(n_records_c):
                    rec_start = geo_pc.section_off2 + r * stride_c
                    for rel in sorted(expected_offsets_c):
                        if rel >= stride_c:
                            break
                        pos = rec_start + rel
                        if pos + 4 > common_len:
                            break
                        xb = xbox_body[pos:pos + 4]
                        pb = pc_body[pos:pos + 4]
                        if xb != pb:
                            violations.append(U8x4Violation(
                                hash=h, section="section_c",
                                record_index=r, relative_offset=rel,
                                xbox_bytes=xb, pc_bytes=pb,
                            ))

    return violations


def get_per_stride_u8x4_offsets(spec: dict) -> dict[int, frozenset[int]]:
    """Extract per-stride u8x4 offset sets from the spec."""
    per_stride = spec.get("soundbank", {}).get("section_a", {}).get("per_stride", {})
    result: dict[int, frozenset[int]] = {}
    for stride_str, data in per_stride.items():
        stride = int(stride_str)
        offsets = data.get("u8x4_offsets", [])
        result[stride] = frozenset(offsets)
    return result


def get_u8x4_relative_offsets(spec: dict, section: str = "section_a") -> frozenset[int]:
    """Extract the set of record-relative offsets classified as u8x4."""
    fields = spec.get("soundbank", {}).get(section, {}).get("fields", {})
    return frozenset(
        int(off_str) for off_str, finfo in fields.items()
        if finfo.get("type") == "u8x4"
    )


def write_spec(spec: dict, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8")


def load_spec(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
