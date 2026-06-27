#!/usr/bin/env python3
"""Reshape a destructible crate model into a BREAKABLE cube — render mesh AND the
per-piece Havok collision hulls — preserving the destruction structure exactly.

The crate is a multi-piece breakable: HIER (piece skeleton) + SEGM + STAM state
machine + a PHY2 Havok 5.5 packfile holding one hkpConvexVerticesShape per piece.
Earlier injection broke this by re-packing the render mesh so the on-hit code read
off the end. Here we change ONLY vertex *values* (no counts, no layout): every STRM
position and every collision-hull vertex is clamped into the cube, and each hull's
plane-equation distances are refit to the clamped verts. Counts/offsets/fixups are
byte-identical, so the engine's 6-piece destruction reads exactly as it does for the
real crate — it just breaks into cube-face slabs instead of crate planks.

Usage: cubeize_breakable.py <crate_container.bin> <out_container.bin>
"""
import struct, sys, zlib, math

HALF = 0.5
HEIGHT = 1.0
CONVEX = b"hkpConvexVerticesShape"


def crc32_mercs2(d):
    return (zlib.crc32(d, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


def clampv(x, y, z):
    return (min(HALF, max(-HALF, x)), min(HEIGHT, max(0.0, y)), min(HALF, max(-HALF, z)))


# ── render mesh (STRM f16 positions) + PRMG bounds ───────────────────────────
def reshape_render(c, comp=None):
    """Clamp each STRM vertex to the cube; or, if `comp` (mapped companion mesh
    cpos/cuv/cnrm numpy arrays) is given, RESAMPLE each vertex from the nearest
    companion vertex (position + UV + normal) — giving the companion shape + heart
    UVs on the crate's exact topology (so the break structure is preserved)."""
    o = bytearray(c)
    data_off = struct.unpack_from("<I", o, 4)[0]
    ndesc = struct.unpack_from("<I", o, 16)[0]
    base = data_off
    in_strm = False
    stride = None
    drange = None

    def f16r(off):
        return struct.unpack_from("<e", o, off)[0]

    def f16w(off, v):
        struct.pack_into("<e", o, off, max(-65504.0, min(65504.0, v)))

    def do_strm(s, e, stride):
        nonlocal nverts
        for v in range((e - s) // stride):
            p = s + v * stride
            if comp is None:
                nx, ny, nz = clampv(f16r(p), f16r(p + 2), f16r(p + 4))
                f16w(p, nx); f16w(p + 2, ny); f16w(p + 4, nz)
            else:
                # Position = CLAMP (keeps each vert in its octant so the 6 pieces
                # stay coherent and break correctly). UV/normal = the companion
                # cube's value at that clamped position (so the heart-atlas UV is
                # the right one for that face). Best of both: clean break + aligned heart.
                cpos, cuv, cnrm = comp
                import numpy as np
                cx, cy, cz = clampv(f16r(p), f16r(p + 2), f16r(p + 4))
                f16w(p, cx); f16w(p + 2, cy); f16w(p + 4, cz)
                j = int(((cpos - np.array([cx, cy, cz])) ** 2).sum(1).argmin())
                if stride >= 12:  # UV @8 (f16x2)
                    f16w(p + 8, cuv[j, 0]); f16w(p + 10, cuv[j, 1])
                if stride >= 20:  # normal @12 (f16x4)
                    f16w(p + 12, cnrm[j, 0]); f16w(p + 14, cnrm[j, 1])
                    f16w(p + 16, cnrm[j, 2]); f16w(p + 18, 0.0)
            nverts += 1

    nverts = 0
    for i in range(ndesc):
        ro = 20 + i * 20
        tag = bytes(o[ro:ro + 4])
        u0, sz = struct.unpack_from("<II", o, ro + 4)
        cont = u0 == 0xFFFFFFFF
        if cont:
            if in_strm and stride and drange:
                do_strm(drange[0], drange[1], stride)
            in_strm = tag == b"STRM"
            stride = None
            drange = None
            continue
        if in_strm:
            if tag == b"info" and sz >= 12:
                stride = struct.unpack_from("<I", o, base + u0 + 4)[0]
            elif tag == b"data":
                drange = (base + u0, base + u0 + sz)
            continue
        if tag == b"INFO" and sz == 60:  # PRMG bounds
            bo = base + u0
            cy = HEIGHT * 0.5
            r = math.sqrt(HALF * HALF + cy * cy + HALF * HALF)
            for off, val in [(20, 0.0), (24, cy), (28, 0.0), (32, r),
                             (36, -HALF), (40, 0.0), (44, -HALF),
                             (48, HALF), (52, HEIGHT), (56, HALF)]:
                struct.pack_into("<f", o, bo + off, val)
    if in_strm and stride and drange:
        do_strm(drange[0], drange[1], stride)
    return o, nverts


# ── PHY2 Havok collision hulls ───────────────────────────────────────────────
def reshape_phy2(o):
    """Find the PHY2 chunk, clamp every hkpConvexVerticesShape's vertices to the
    cube and refit its plane distances — all in place."""
    data_off = struct.unpack_from("<I", o, 4)[0]
    ndesc = struct.unpack_from("<I", o, 16)[0]
    base = data_off
    phy_abs = None
    for i in range(ndesc):
        ro = 20 + i * 20
        tag = bytes(o[ro:ro + 4])
        u0, sz = struct.unpack_from("<II", o, ro + 4)
        if tag == b"PHY2" and u0 != 0xFFFFFFFF:
            phy_abs, phy_sz = base + u0, sz
    if phy_abs is None:
        return 0, 0
    pk0 = o.find(bytes.fromhex("57e0e05710c0c010"), phy_abs, phy_abs + phy_sz)
    sh = o.find(b"__classnames__", pk0, phy_abs + phy_sz)
    secs = [struct.unpack_from("<7I", o, sh + s * 48 + 20) for s in range(3)]
    cn_end, ty_end = secs[0][6], secs[1][6]
    data_pk = sh + 3 * 48 + cn_end + ty_end  # __data__ section data start (abs)
    d_lf, d_gf, d_vf, d_end = secs[2][1], secs[2][2], secs[2][3], secs[2][4]
    # classnames: {name_off_in_cn : name}
    names = {}
    cn0 = sh + 3 * 48
    cnblob = bytes(o[cn0:cn0 + secs[0][1]])
    i = 0
    while i < len(cnblob) - 6:
        j = cnblob.find(b"\x00", i + 5)
        if j < 0:
            break
        nm = cnblob[i + 5:j]
        if nm and all(32 <= ch < 127 for ch in nm):
            names[i + 5] = nm
        i = j + 1
    # virtual fixups -> object class
    objs = []
    for k in range(data_pk + d_vf, data_pk + d_end - 11, 12):
        src, _sec, cnoff = struct.unpack_from("<3I", o, k)
        if src < 0x7FFFFFFF:
            objs.append((src, names.get(cnoff, b"?")))
    # local fixups: obj_field -> data_off
    lf = {}
    for k in range(data_pk + d_lf, data_pk + d_gf - 7, 8):
        s, dst = struct.unpack_from("<2I", o, k)
        lf[s] = dst

    def pf(off):
        return struct.unpack_from("<f", o, off)[0]

    def pw(off, v):
        struct.pack_into("<f", o, off, v)

    hulls = 0
    verts_clamped = 0
    for src, cname in objs:
        if cname != CONVEX:
            continue
        hulls += 1
        nverts = struct.unpack_from("<I", o, data_pk + src + 76)[0]
        vptr = data_pk + lf[src + 64]
        pcount = struct.unpack_from("<I", o, data_pk + src + 84)[0]
        pptr = data_pk + lf[src + 80]
        # clamp the FourVectors (SoA: X[4],Y[4],Z[4] per 48B block)
        verts = []
        for vi in range(nverts):
            blk, lane = vi // 4, vi % 4
            bo = vptr + blk * 48
            x = pf(bo + lane * 4); y = pf(bo + 16 + lane * 4); z = pf(bo + 32 + lane * 4)
            nx, ny, nz = clampv(x, y, z)
            pw(bo + lane * 4, nx); pw(bo + 16 + lane * 4, ny); pw(bo + 32 + lane * 4, nz)
            verts.append((nx, ny, nz))
            verts_clamped += 1
        # refit each plane distance to the clamped verts: d = max_v dot(n, v)
        for pi in range(pcount):
            po = pptr + pi * 16
            nx, ny, nz = pf(po), pf(po + 4), pf(po + 8)
            dmax = max((nx * vx + ny * vy + nz * vz) for (vx, vy, vz) in verts) if verts else 0.0
            # Havok plane stores (n, -d) such that n·x <= -w (or n·x + w <= 0); the
            # original packs negative offset, so mirror its sign convention.
            pw(po + 12, -dmax)
    return hulls, verts_clamped


def load_companion(npz_path):
    """Load the companion universal mesh and map it into the cube
    [-HALF,HALF]×[0,HEIGHT]×[-HALF,HALF] (per-axis fill)."""
    import numpy as np
    m = np.load(npz_path)
    pos = m["pos"].astype(np.float64)
    mn, mx = pos.min(0), pos.max(0)
    ext = np.maximum(mx - mn, 1e-6)
    cpos = np.empty_like(pos)
    cpos[:, 0] = (pos[:, 0] - mn[0]) / ext[0] * (2 * HALF) - HALF
    cpos[:, 1] = (pos[:, 1] - mn[1]) / ext[1] * HEIGHT
    cpos[:, 2] = (pos[:, 2] - mn[2]) / ext[2] * (2 * HALF) - HALF
    return cpos, m["uv"].astype(np.float64), m["nrm"].astype(np.float64)


def main():
    c = open(sys.argv[1], "rb").read()
    comp = None
    if len(sys.argv) > 3:  # optional companion .npz -> resample render to it
        comp = load_companion(sys.argv[3])
    o, nv = reshape_render(c, comp)
    hulls, hv = reshape_phy2(o)
    # recompute CSUM trailer
    if bytes(o[-8:-4]) == b"CSUM":
        struct.pack_into("<I", o, len(o) - 4, crc32_mercs2(bytes(o[:-8])))
    open(sys.argv[2], "wb").write(o)
    print(f"render verts clamped: {nv}")
    print(f"collision hulls reshaped: {hulls}  (verts clamped: {hv})")
    print(f"wrote {sys.argv[2]} ({len(o)} bytes, same length: {len(o)==len(c)})")


if __name__ == "__main__":
    main()
