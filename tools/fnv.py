#!/usr/bin/env python3
"""fnv.py -- the Pandemic `pandemic_hash_m2` primitives shared by the CPU and GPU crackers.

`m2` is the CANONICAL Mercenaries 2 name hash (mirrors
`mercs2_formats::hash::pandemic_hash_m2`): FNV-1a with a per-byte `| 0x20` case fold, then a
`^ 0x2A` finalization mixed once more through the prime. Case-insensitive by construction, so
`Bone_RBicep` and `bone_rbicep` hash identically.

`ALPHABET` is the 37-symbol wildcard alphabet the GPU kernel enumerates (`gpu_fast.py` maps a
base-37 global index onto these characters): lowercase a-z, digits 0-9, and underscore. Every
authored bone / hardpoint / asset name observed so far is spelled from exactly this set.
"""

FNV_OFFSET = 0x811C9DC5
FNV_PRIME = 0x01000193
MASK = 0xFFFFFFFF

# 37 symbols. Order is arbitrary but MUST stay fixed — a hit's base-37 global index decodes
# back to a string through this exact ordering (see gpu_fast.wild_str).
ALPHABET = "abcdefghijklmnopqrstuvwxyz0123456789_"
assert len(ALPHABET) == 37


def m2(text: str) -> int:
    """pandemic_hash_m2 of a str (or bytes/bytearray). Empty input hashes to 0."""
    data = text.encode("ascii") if isinstance(text, str) else bytes(text)
    if not data:
        return 0
    h = FNV_OFFSET
    for b in data:
        h ^= b | 0x20
        h = (h * FNV_PRIME) & MASK
    h ^= 0x2A
    return (h * FNV_PRIME) & MASK


if __name__ == "__main__":
    # Cross-check against names cracked+verified this session.
    KNOWN = {
        "bone_root": 0xFAEFB386,
        "Bone_RBicep": 0x20F635D9,
        "bone_attach_hipleft": 0x629B2990,
        "hp_barreltip_a": 0xB1486EF3,
        "pristine": 0x86DE6639,
        "ruin": 0xB5D7712F,
        "civ_veh_truck_transport": 0x02195587,
    }
    ok = True
    for name, want in KNOWN.items():
        got = m2(name)
        flag = "OK" if got == want else "FAIL"
        if got != want:
            ok = False
        print(f"  {name:<26} 0x{got:08X}  want 0x{want:08X}  {flag}")
    # case-insensitivity
    assert m2("Bone_RBicep") == m2("bone_rbicep")
    print("fnv.m2 correctness", "OK" if ok else "FAIL")
    assert ok
