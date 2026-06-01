#!/usr/bin/env python3
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from correlate_entity_ptr import _iter_transform_records

data = Path(sys.argv[1]).read_bytes()
indices = [int(x) for x in sys.argv[2:]]
recs = _iter_transform_records(data)
for ri in indices:
    r = recs[ri]
    b = r["record_bytes"]
    print(
        f"rec {ri} key={r['entity_key_hex']} "
        f"xyz=({r['x']:.3f},{r['y']:.3f},{r['z']:.3f}) blob_off=0x{r.get('blob_file_offset',0):x}"
    )
    for delta in (-2, -1, 0, 2, 22, 26, 30):
        vals = []
        for ent_off in (4, 8, 0xC):
            ro = delta + ent_off
            if 0 <= ro <= 38:
                u = struct.unpack_from("<I", b, ro)[0]
                f = struct.unpack_from("<f", b, ro)[0]
                vals.append(f"[ent+{ent_off}]=rec+{ro} u32=0x{u:08x} f={f:.4g}")
        if vals:
            print(f"  entity=rec+{delta}: " + " | ".join(vals))
    print(f"  hex: {b.hex()}")
