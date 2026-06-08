import json, struct, sys
sys.path.insert(0, 'tools')
import xbox_texture_codec as tex
from collections import defaultdict

R = json.load(open('output/_scratch/mips_retail.json'))['records']

def mip_dims(w, h, n):
    return [(max(1, w >> i), max(1, h >> i)) for i in range(n)]

def linear_one(w, h, fcc):
    return tex.linear_mip_chain_size(w, h, fcc.encode() if isinstance(fcc, str) else fcc, 1)

# For each retail OVER texture, find how many BOTTOM mips the body contains.
def resident_bottom_mips(w, h, fcc, claimed, body):
    # full claimed chain dims
    dims = mip_dims(w, h, claimed)
    # cumulative from the bottom
    tot = 0
    for k in range(claimed):
        lvl = claimed - 1 - k           # bottom-up
        mw, mh = dims[lvl]
        tot += linear_one(mw, mh, fcc)
        if tot == body:
            return k + 1                 # resident bottom-mip count
    return None

rows = []
for r in R:
    if r['cls'] != 'OVER':
        continue
    fcc = r['fmt']
    claimed = r['mips'] or tex.mip_levels(r['w'], r['h'])
    res = resident_bottom_mips(r['w'], r['h'], fcc, claimed, r['body'])
    w0, w1, w2, w3 = struct.unpack('<4H', bytes.fromhex(r['stream_desc']))
    rows.append((fcc, r['w'], r['h'], claimed, res, r['body'], w0, w1, w2, w3))

# dedup by (fmt,w,h,desc)
seen = {}
for t in rows:
    key = (t[0], t[1], t[2], t[6], t[7], t[8], t[9])
    seen[key] = t
print(f"{'fmt':5}{'WxH':>10} {'claim':>5}{'res':>4}{'strm':>5}  {'w0':>3}{'w1':>4}{'w2':>4}{'w3':>6}   hypotheses")
ok = 0; tot = 0
for t in sorted(seen.values(), key=lambda t:-(t[1]*t[2])):
    fcc, w, h, claimed, res, body, w0, w1, w2, w3 = t
    if res is None:
        print(f"{fcc:5}{w:5}x{h:<4} {claimed:5}{'?':>4}  body={body} desc=[{w0},{w1},{w2},{w3}]  (resident-tail != body)")
        continue
    strm = claimed - res
    tot += 1
    # HYPOTHESES (square-derived): w2=2^(strm-1); w1=w2-(2 if strm>=3 else 1); w0=(strm>=3)
    pw2 = (1 << (strm - 1)) if strm >= 1 else 0
    pw1 = pw2 - (2 if strm >= 3 else 1) if strm >= 1 else 0
    if pw1 < 0: pw1 = 0
    pw0 = 1 if strm >= 3 else 0
    match = (pw0 == w0 and pw1 == w1 and pw2 == w2)
    if match: ok += 1
    flag = 'OK' if match else f'MISS pred=[{pw0},{pw1},{pw2}]'
    print(f"{fcc:5}{w:5}x{h:<4} {claimed:5}{res:4}{strm:5}  {w0:3}{w1:4}{w2:4}{w3:6}   {flag}")
print(f"\nw0/w1/w2 formula match: {ok}/{tot}")
