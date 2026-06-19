import json, struct
from collections import defaultdict
R = json.load(open('output/_scratch/mips_retail.json'))['records']

def words(hexs):
    b = bytes.fromhex(hexs)
    return struct.unpack('<4H', b)

# group by (fmt,w,h) -> stream_desc -> set(body sizes), count, mips seen
g = defaultdict(lambda: defaultdict(lambda: {'n':0,'body':set(),'mips':set(),'lin':set()}))
for r in R:
    if r['cls'] != 'OVER':
        continue
    k = (r['fmt'], r['w'], r['h'])
    d = g[k][r['stream_desc']]
    d['n'] += 1; d['body'].add(r['body']); d['mips'].add(r['mips']); d['lin'].add(r['expect'])

print(f"{'fmt':5}{'WxH':>11} {'desc':>18} {'words(LE u16)':>22} {'n':>5}  bodies / mips")
for k in sorted(g, key=lambda k:-(k[1]*k[2])):
    fmt, w, h = k
    for sd in sorted(g[k]):
        d = g[k][sd]
        w0,w1,w2,w3 = words(sd)
        bodies = sorted(d['body'])
        bsample = bodies[:4]
        print(f"{fmt:5}{w:5}x{h:<5} {sd:>18} [{w0:#06x},{w1:#06x},{w2:#06x},{w3:#06x}] {d['n']:5}  body={bsample} mips={sorted(d['mips'])}")
