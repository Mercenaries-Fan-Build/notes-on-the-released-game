#!/usr/bin/env python3
"""Build a Mercenaries 2 helicopter UCFX model from an FBX part-set, driven
through an existing heli's rig (per-submesh geometry swap).

Unlike gltf_to_ucfx_model.py (single mesh cloned into every slot), this maps the
FBX parts onto the reference model's *individual* mesh slots (47 for the Mi-26):
- each slot keeps its own bbox/frame, so the rig (animgroup + ECS BoneCtrl) still
  drives it — origin-centered slots are the spinning rotors;
- model-space slots get the FBX body geometry that spatially falls in their bbox;
- origin-centered (node-local) slots get the FBX rotor part, re-centered + fit.
Slots with no FBX geometry keep their original mesh, so the container stays valid.

Usage: heli_model_build.py <ref_container.bin> <fbx_parts_dir> <out.bin>
"""
import struct
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gltf_to_ucfx_model import (  # noqa: E402
    build_mesh_buffers, crc32_mercs2, find_mesh_leaves, leaf_body, parse_rows,
)

U16 = 65500


def load_parts(d):
    parts = []
    for f in sorted(Path(d).glob("*.npz")):
        m = np.load(f)
        parts.append({"name": f.stem, "pos": m["pos"].astype(np.float64),
                      "nrm": m["nrm"].astype(np.float64), "uv": m["uv"].astype(np.float64),
                      "tris": m["tris"].astype(np.int64)})
    return parts


def bbox(p):
    return p.min(0), p.max(0)


def is_rotor_disc(p):
    """Flat, wide disc = a rotor: thinnest axis << the two big axes, and the two
    big axes are similar (a fuselage is long => its two big axes differ a lot)."""
    mn, mx = bbox(p)
    s = np.sort(mx - mn)  # [thin, mid, big]
    return s[0] < 0.25 * s[1] and s[2] < 1.6 * s[1] and s[1] > 4.0


def clean_tris(tris):
    """Drop degenerate triangles (any two indices equal) — welding can create them."""
    t = np.asarray(tris)
    keep = (t[:, 0] != t[:, 1]) & (t[:, 1] != t[:, 2]) & (t[:, 0] != t[:, 2])
    return t[keep]


def weld(pos, nrm, uv, tris):
    """Dedupe (pos,nrm,uv) corners -> indexed mesh (soup -> shared verts)."""
    key = np.concatenate([pos.round(3), nrm.round(2), uv.round(3)], axis=1)
    _, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    return pos[first], nrm[first], uv[first], inv[tris.reshape(-1)].reshape(-1, 3)


def fit_into(pos, target_min, target_max, uniform=True, recenter=False):
    """Map positions into a target bbox. recenter=True centers source on origin
    first (for node-local rotor slots)."""
    smn, smx = bbox(pos)
    sc_c = (smn + smx) / 2
    tc = (np.array(target_min) + np.array(target_max)) / 2
    sext = np.maximum(smx - smn, 1e-6)
    text = np.array(target_max) - np.array(target_min)
    if uniform:
        s = float(np.min(text / sext))
        s = np.array([s, s, s])
    else:
        s = text / sext
    base_c = np.zeros(3) if recenter else sc_c
    return (pos - base_c) * s + (np.zeros(3) if recenter else tc) + (tc if recenter else 0)


def emit(out, ref, rows, data_off, ndesc, new_bodies):
    new_data = bytearray()
    for idx, row in enumerate(rows):
        if row[1] == 0xFFFFFFFF:
            continue
        body = new_bodies.get(idx, leaf_body(ref, data_off, row[1], row[2]))
        while len(new_data) % 16:
            new_data.append(0)
        row[1] = len(new_data); row[2] = len(body); new_data += body
    o = bytearray(b"UCFX")
    o += struct.pack("<I", 20 + ndesc * 20) + ref[8:16] + struct.pack("<I", ndesc)
    for row in rows:
        o += row[0] + struct.pack("<IIII", row[1], row[2], row[3], row[4])
    o += new_data
    o += b"CSUM" + struct.pack("<I", crc32_mercs2(bytes(o)))
    Path(out).write_bytes(o)
    print(f"wrote {out} ({len(o)} bytes, was {len(ref)})")


def main():
    ref_path, parts_dir, out = sys.argv[1], sys.argv[2], sys.argv[3]
    ref = Path(ref_path).read_bytes()
    data_off, ndesc, rows = parse_rows(ref)
    meshes = find_mesh_leaves(rows)
    parts = load_parts(parts_dir)

    # Split FBX into rotor discs vs body; orient FBX (Y=length,Z=up) -> Mercs
    # (Z=length, Y=up): (x,y,z) -> (x, z, -y).
    def orient(p):
        return np.column_stack([p[:, 0], p[:, 2], -p[:, 1]])
    rotor = [p for p in parts if is_rotor_disc(p["pos"])]
    body = [p for p in parts if not is_rotor_disc(p["pos"])]
    rotor.sort(key=lambda p: -(p["pos"].max(0) - p["pos"].min(0)).max())  # biggest first
    print(f"FBX: {len(body)} body parts, {len(rotor)} rotor disc(s) "
          f"({[p['name'].split('_',1)[-1][:14] for p in rotor]})")

    # Body assembled in Mercs model space, fit to the reference model bbox.
    bpos = orient(np.vstack([p["pos"] for p in body]))
    voff = 0; btris = []
    for p in body:
        n = len(p["pos"]); btris.append(p["tris"] + voff); voff += n
    btris = np.vstack(btris)
    bnrm = orient(np.vstack([p["nrm"] for p in body]))
    buv = np.vstack([p["uv"] for p in body])
    # reference model bbox = union of all PRMG INFO bboxes
    def prmg_bbox(mh):
        pi = rows[mh["prmg_info"]]; b = leaf_body(ref, data_off, pi[1], pi[2])
        return (np.array(struct.unpack_from("<3f", b, 36)),
                np.array(struct.unpack_from("<3f", b, 48)))
    boxes = [prmg_bbox(mh) for mh in meshes]
    model_min = np.min([b[0] for b in boxes], 0); model_max = np.max([b[1] for b in boxes], 0)
    bpos = fit_into(bpos, model_min, model_max, uniform=True)

    rotor_oriented = None
    if rotor:
        rp = rotor[0]
        rnrm = orient(rp["nrm"]); rpos = orient(rp["pos"])
        rotor_oriented = (rpos, rnrm, rp["uv"], rp["tris"])

    new_bodies = {}
    used = 0
    for mh, (mn, mx) in zip(meshes, boxes):
        ext = mx - mn; cen = (mn + mx) / 2
        symmetric = np.all(np.abs(mn + mx) < 0.25 * ext.max()) and np.linalg.norm(cen) < 0.35
        if symmetric and rotor_oriented is not None:
            rpos, rnrm, ruv, rtris = rotor_oriented
            mpos = fit_into(rpos, mn, mx, uniform=True, recenter=True)
            geo = (mpos, rnrm, ruv, rtris)
        else:
            c = bpos[btris].mean(1)  # triangle centroids
            pad = 0.1 * ext
            inside = np.all((c >= mn - pad) & (c <= mx + pad), axis=1)
            if inside.sum() < 4:
                continue  # keep original mesh geometry
            sel = btris[inside]
            # compact the selected verts
            uniq = np.unique(sel.reshape(-1))
            remap = {int(v): i for i, v in enumerate(uniq)}
            sel2 = np.vectorize(remap.get)(sel)
            geo = (bpos[uniq], bnrm[uniq], buv[uniq], sel2)

        pos, nrm, uv, tris = weld(*geo)
        tris = clean_tris(tris)
        # subsample triangles if over u16
        if len(pos) > U16 or len(tris) * 6 > U16:
            keep = max(1, len(tris) * 6 // U16 + 1)
            tris = tris[::keep]
            pos, nrm, uv, tris = weld(pos, nrm, uv, tris)
            tris = clean_tris(tris)
            if len(pos) > U16:
                continue
        if len(tris) < 1:
            continue
        try:
            vb, ib, area, strip_len, vcount = build_mesh_buffers(
                pos.astype(np.float32), nrm.astype(np.float32), uv.astype(np.float32), tris)
        except Exception as e:
            print(f"  slot skip ({e})"); continue

        bmin, bmax = pos.min(0), pos.max(0)
        si = rows[mh["strm_info"]]
        flag = struct.unpack("<III", leaf_body(ref, data_off, si[1], si[2]))[0]
        new_bodies[mh["strm_info"]] = struct.pack("<III", flag, 20, vcount)
        new_bodies[mh["strm_data"]] = vb
        new_bodies[mh["ibuf_info"]] = struct.pack("<I", strip_len)
        new_bodies[mh["ibuf_data"]] = ib
        new_bodies[mh["area_info"]] = struct.pack("<I", strip_len - 2)
        new_bodies[mh["area_data"]] = area
        pi = rows[mh["prmg_info"]]; pbody = bytearray(leaf_body(ref, data_off, pi[1], pi[2]))
        cx, cy, cz = (bmin + bmax) / 2; r = float(np.linalg.norm((bmax - bmin) / 2))
        struct.pack_into("<10f", pbody, 20, cx, cy, cz, r, *bmin, *bmax)
        new_bodies[mh["prmg_info"]] = bytes(pbody)
        pr = rows[mh["prmt"]]; mat = struct.unpack_from("<I", leaf_body(ref, data_off, pr[1], pr[2]), 0)[0]
        new_bodies[mh["prmt"]] = struct.pack("<IIHHHH", mat, 0, strip_len, 0, vcount - 1, vcount)
        used += 1

    print(f"filled {used}/{len(meshes)} mesh slots with FBX geometry")
    emit(out, ref, rows, data_off, ndesc, new_bodies)


if __name__ == "__main__":
    main()
