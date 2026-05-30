#!/usr/bin/env python3
"""Rainbow table lookup for Pandemic Studios hashes.

Loads tools/rainbow_table.json (53,937 unique Mercs 2 hashes) and provides
fast hash → name resolution for both pandemic_hash_m2 (Mercs 2) and
pandemic_hash (Mercs 1) variants.

Usage as module:
    from hash_resolver import resolve, get_resolver, HashResolver
    resolve(0xF011157A)              # → "texture"  (quick shorthand)
    resolve("0xF011157A")            # also works with hex strings
    resolver = get_resolver()        # singleton accessor
    resolver.resolve_m2(0xF011157A)  # same result via class API

Usage as CLI:
    python3 tools/hash_resolver.py 0xF011157A 0x5B724250
    python3 tools/hash_resolver.py --v1 0x3884598e
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


_DEFAULT_TABLE_PATH = Path(__file__).resolve().parent / "rainbow_table.json"


class HashResolver:
    """Fast hash-to-name resolver backed by rainbow_table.json."""

    __slots__ = ("_m2", "_v1", "_loaded_from")

    def __init__(self, m2: dict[int, list[str]], v1: dict[int, list[str]], path: Path | None = None):
        self._m2 = m2
        self._v1 = v1
        self._loaded_from = path

    @classmethod
    def load(cls, path: Path | None = None) -> HashResolver:
        """Load rainbow table from JSON. Falls back to default location."""
        p = path or _DEFAULT_TABLE_PATH
        if not p.is_file():
            return cls({}, {}, p)
        with open(p, "r", encoding="utf-8") as f:
            raw = json.load(f)

        m2: dict[int, list[str]] = {}
        for hex_key, names in raw.get("pandemic_hash_m2", {}).items():
            m2[int(hex_key, 16)] = names

        v1: dict[int, list[str]] = {}
        for hex_key, names in raw.get("pandemic_hash", {}).items():
            v1[int(hex_key, 16)] = names

        return cls(m2, v1, p)

    @property
    def m2_count(self) -> int:
        return len(self._m2)

    @property
    def v1_count(self) -> int:
        return len(self._v1)

    def resolve_m2(self, h: int) -> str | None:
        """Resolve a pandemic_hash_m2 hash to a name (first candidate)."""
        names = self._m2.get(h & 0xFFFFFFFF)
        return names[0] if names else None

    def resolve_m2_all(self, h: int) -> list[str]:
        """Resolve a pandemic_hash_m2 hash to all candidate names."""
        return self._m2.get(h & 0xFFFFFFFF, [])

    def resolve_v1(self, h: int) -> str | None:
        """Resolve a pandemic_hash (v1) hash to a name (first candidate)."""
        names = self._v1.get(h & 0xFFFFFFFF)
        return names[0] if names else None

    def resolve_v1_all(self, h: int) -> list[str]:
        """Resolve a pandemic_hash (v1) hash to all candidate names."""
        return self._v1.get(h & 0xFFFFFFFF, [])

    def annotate(self, h: int, *, variant: str = "m2") -> str:
        """Return '0x{h:08X} (name)' or just '0x{h:08X}' if unresolved."""
        name = self.resolve_m2(h) if variant == "m2" else self.resolve_v1(h)
        if name:
            return f"0x{h:08X} ({name})"
        return f"0x{h:08X}"


_singleton: HashResolver | None = None


def get_resolver(path: Path | None = None) -> HashResolver:
    """Get or create the module-level singleton resolver."""
    global _singleton
    if _singleton is None:
        _singleton = HashResolver.load(path)
    return _singleton


def _coerce_hash(h: int | str) -> int:
    """Accept ``0xDEADBEEF`` strings, bare hex strings, or ints."""
    if isinstance(h, str):
        return int(h, 16) if h.startswith("0x") or h.startswith("0X") else int(h, 0)
    return int(h)


def resolve(hash_hex_or_int: int | str, *, variant: str = "m2") -> str | None:
    """Resolve a hash to its first candidate name via the singleton table.

    Accepts ``0xDEADBEEF`` hex strings or plain integers.
    *variant* is ``"m2"`` (default) or ``"v1"``.
    """
    h = _coerce_hash(hash_hex_or_int)
    r = get_resolver()
    return r.resolve_v1(h) if variant == "v1" else r.resolve_m2(h)


def main() -> int:
    ap = argparse.ArgumentParser(description="Rainbow table hash lookup")
    ap.add_argument("hashes", nargs="*", help="Hex hash values to resolve (e.g. 0xF011157A)")
    ap.add_argument("--v1", action="store_true", help="Use Mercs 1 (pandemic_hash) variant")
    ap.add_argument("--table", type=Path, default=None, help="Path to rainbow_table.json")
    ap.add_argument("--stats", action="store_true", help="Print table statistics")
    args = ap.parse_args()

    resolver = HashResolver.load(args.table)

    if args.stats:
        print(f"Rainbow table: {resolver._loaded_from}")
        print(f"  pandemic_hash_m2 entries: {resolver.m2_count:,}")
        print(f"  pandemic_hash (v1) entries: {resolver.v1_count:,}")
        return 0

    if not args.hashes:
        ap.print_help()
        return 0

    variant = "v1" if args.v1 else "m2"
    for h_str in args.hashes:
        h = int(h_str, 0)
        result = resolver.annotate(h, variant=variant)
        all_names = resolver.resolve_v1_all(h) if args.v1 else resolver.resolve_m2_all(h)
        if all_names:
            if len(all_names) == 1:
                print(f"  {result}")
            else:
                print(f"  {result}  [{len(all_names)} candidates: {', '.join(all_names[:5])}]")
        else:
            print(f"  {result}  (no match)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
