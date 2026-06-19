#!/usr/bin/env python3
"""Static, exhaustive, parallel texture-mip audit of an FFCS WAD.

Decompresses EVERY block (in parallel across CPU cores) and, for every DXT
texture container, parses the PC INFO (width@0, height@2, mips@6, fourcc@14:18)
and the BODY descriptor's actual byte length, then compares the body against
`linear_mip_chain_size(w, h, fourcc, claimed_mips)`:

  exact      body == linear@claim         (body holds exactly the claimed mips)
  over_body  body  > linear@claim         (body has more than claimed; harmless)
  OVER       body  < linear@claim         (INFO claims more mip bytes than exist)

`OVER` is the static signature of mip over-claim / truncation — the thing the
engine streamer reads past the end of, producing short reads. Also records the
INFO[26:34] stream descriptor so streaming-resident layouts can be told apart
from genuine truncation by comparing against retail ground truth.

Usage:
  python tools/audit_texture_mips.py --wad output/data/vz-patch.wad --out output/_scratch/mips_patch.json
  python tools/audit_texture_mips.py --wad game-files/vz.wad        --out output/_scratch/mips_retail.json --jobs 8
"""
from __future__ import annotations
import sys, struct, mmap, json, argparse
from pathlib import Path
from collections import Counter, defaultdict
from multiprocessing import Pool, cpu_count

sys.path.insert(0, str(Path(__file__).resolve().parent))
import diagnose_unconverted_textures as diag  # noqa: E402
tex = diag.texcodec
FCCS = (b'DXT1', b'DXT3', b'DXT5')


def _first(descs, tag):
    for d in descs:
        if d['tag'] == tag and d['row_u0'] != diag._SENTINEL:
            return d
    return None


def _scan_block(data):
    out = []
    for ent in diag.parse_block_entries(data):
        if ent['type_hash'] != diag._TYPE_TEXTURE:
            continue
        chunk = data[ent['offset']:ent['offset'] + ent['size'] - 8]
        pos = chunk.find(b'UCFX')
        if pos < 0:
            continue
        c = chunk[pos:]
        dao, descs = diag._parse_container_descriptors(c)
        info = _first(descs, 'INFO'); body = _first(descs, 'BODY')
        if not info or not body or info['body_size'] < 34:
            continue
        dte = 8 + 12 + len(descs) * 20
        ia = (dao if dao else dte) + info['row_u0']
        if ia + 34 > len(c):
            continue
        xi = c[ia:ia + 34]
        fcc = xi[14:18]
        if fcc not in FCCS:
            continue
        w, h = struct.unpack_from('<HH', xi, 0)
        mips = struct.unpack_from('<H', xi, 6)[0]
        if not (0 < w <= 8192 and 0 < h <= 8192):
            continue
        claimed = mips if mips else tex.mip_levels(w, h)
        expect = tex.linear_mip_chain_size(w, h, fcc, claimed)
        out.append({
            'hash': ent['hash'], 'fmt': fcc.decode(), 'w': w, 'h': h,
            'mips': mips, 'claimed': claimed, 'body': body['body_size'],
            'expect': expect, 'stream_desc': xi[26:34].hex(),
        })
    return out


_MM = None
_FH = None
def _init(wad):
    global _MM, _FH
    _FH = open(wad, 'rb')
    _MM = mmap.mmap(_FH.fileno(), 0, access=mmap.ACCESS_READ)


def _work(chunk):
    res = []
    for bi, s, e in chunk:
        try:
            data = diag.decompress_sges_block(_MM, s, e)
            recs = _scan_block(data)
        except Exception:
            continue
        for rec in recs:
            rec['block'] = bi
            res.append(rec)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--wad', type=Path, required=True)
    ap.add_argument('--out', type=Path)
    ap.add_argument('--jobs', type=int, default=max(1, cpu_count() - 1))
    a = ap.parse_args()

    paths = diag._load_paths(a.wad)
    dc = diag.find_data_chunk(a.wad)
    _fh = open(a.wad, 'rb')
    mm = mmap.mmap(_fh.fileno(), 0, access=mmap.ACCESS_READ)
    bounds = diag.get_block_boundaries(mm, dc.offset, dc.size)
    mm.close(); _fh.close()
    work = [(i, s, e) for i, (s, e) in enumerate(bounds)]
    J = max(1, a.jobs)
    chunks = [work[i::J] for i in range(J)]

    recs = []
    with Pool(J, initializer=_init, initargs=(str(a.wad),)) as p:
        for part in p.map(_work, chunks):
            recs.extend(part)

    for r in recs:
        r['cls'] = 'OVER' if r['body'] < r['expect'] else ('exact' if r['body'] == r['expect'] else 'over_body')
        r['path'] = paths[r['block']] if r['block'] < len(paths) else f"block_{r['block']}"

    hist = Counter(r['cls'] for r in recs)
    print(f"wad={a.wad}  blocks={len(bounds)}  textures={len(recs)}  hist={dict(hist)}")

    # Per-(fmt,w,h): count, OVER count, dominant stream_desc per class
    bydim = defaultdict(lambda: {'n': 0, 'OVER': 0, 'exact': 0, 'over_body': 0, 'sd': Counter()})
    for r in recs:
        k = (r['fmt'], r['w'], r['h'])
        b = bydim[k]
        b['n'] += 1; b[r['cls']] += 1
        b['sd'][(r['cls'], r['stream_desc'])] += 1
    print("  per-dim (size>=512 shown):  fmt WxH  n  OVER/exact/over_body  top stream_desc")
    for k in sorted(bydim, key=lambda k: -(k[1] * k[2])):
        if k[1] < 512 and k[2] < 512:
            continue
        b = bydim[k]
        top = b['sd'].most_common(2)
        print(f"    {k[0]} {k[1]}x{k[2]:<5} n={b['n']:4d}  {b['OVER']}/{b['exact']}/{b['over_body']}  {top}")

    if a.out:
        a.out.parent.mkdir(parents=True, exist_ok=True)
        a.out.write_text(json.dumps({'wad': str(a.wad), 'blocks': len(bounds),
                                     'hist': dict(hist), 'records': recs}, indent=0))
        print(f"  wrote {a.out} ({a.out.stat().st_size/1024/1024:.1f} MB)")


if __name__ == '__main__':
    main()
