// jc2_rbm — Just Cause 2 RBMDL (RenderBlockModel) -> GLB decoder.
//
// Format verified from JustCause2.exe decomp:
//   loader FUN_00a45d30, CRenderBlockGeneral::Read FUN_00973da0, CRenderBlockCarPaint::Read FUN_00955ef0,
//   buffer readers FUN_00970e70 (VB 0x28) / FUN_00971680 (VB 0x1c) / FUN_00951d80 (VB 0x18) /
//   FUN_0096aa90 (VB 0x1c) / FUN_0092d7f0 (IB u16).
//
//   Header (49B): [u32 len=5]"RBMDL"[u32 major=1][u32 minor=13][u32 rev][f32x3 bboxMin][f32x3 bboxMax][u32 numBlocks]
//   Block: [u32 typeHash][ material/textures (variable) ][ geometry ][ ... ][u32 footer 0x89ABCDEF]
//   Geometry: [u32 vbCount][vb0=vbCount*s0]( [u32 vbCount][vb1=vbCount*s1] )?[u32 ibCount][ib=ibCount*u16]
//     CarPaint (0xcd931e75): s0=24 (f32 pos @0), s1=28, then post-index deform data before the footer.
//     General family: single stream, position = f32x3 @ vertex offset 0.
//
// We skip the polymorphic material section by scanning for the vbCount whose (vb,ib) counts produce
// in-range indices, in-bbox f32 positions, and a reachable footer. Type-aware for known layouts.

mod image;

use std::io::Write;

const FOOTER: u32 = 0x89AB_CDEF;
const STRIDES: [usize; 6] = [32, 40, 28, 24, 20, 36];

fn u32le(b: &[u8], o: usize) -> u32 {
    u32::from_le_bytes([b[o], b[o + 1], b[o + 2], b[o + 3]])
}
fn u32le_safe(b: &[u8], o: usize) -> Option<u32> {
    if o + 4 <= b.len() {
        Some(u32le(b, o))
    } else {
        None
    }
}
fn f32le(b: &[u8], o: usize) -> f32 {
    f32::from_le_bytes([b[o], b[o + 1], b[o + 2], b[o + 3]])
}

struct Header {
    bmin: [f32; 3],
    bmax: [f32; 3],
    num_blocks: u32,
    body: usize,
}

fn parse_header(b: &[u8]) -> Option<Header> {
    if b.len() < 49 || u32le(b, 0) != 5 || &b[4..9] != b"RBMDL" {
        return None;
    }
    let major = u32le(b, 9);
    let minor = u32le(b, 13);
    let bmin = [f32le(b, 21), f32le(b, 25), f32le(b, 29)];
    let bmax = [f32le(b, 33), f32le(b, 37), f32le(b, 41)];
    let num_blocks = u32le(b, 45);
    if major != 1 || minor != 13 {
        eprintln!("  warn: unexpected RBMDL version {}.{}", major, minor);
    }
    Some(Header { bmin, bmax, num_blocks, body: 49 })
}

struct Prim {
    positions: Vec<[f32; 3]>,
    normals: Vec<[f32; 3]>,
    uvs: Vec<[f32; 2]>,
    indices: Vec<u32>,
    joint: u32,     // skin joint index (one per source part)
    part: String,   // source part name (joint node name)
    diffuse: Option<String>,   // _dif  -> baseColorTexture
    normalmap: Option<String>, // _nrm  -> normalTexture
    mrmap: Option<String>,     // _mpm  -> metallicRoughnessTexture
}

// Scan a block's material section for length-prefixed .dds names, categorized by JC2 suffix.
fn extract_textures(region: &[u8]) -> (Option<String>, Option<String>, Option<String>) {
    let mut names = Vec::new();
    let mut i = 0usize;
    while i + 4 <= region.len() {
        let n = u32le(region, i) as usize;
        if n >= 4 && n <= 128 && i + 4 + n <= region.len() {
            let s = &region[i + 4..i + 4 + n];
            if s.iter().all(|&c| (0x20..0x7f).contains(&c)) {
                let name = String::from_utf8_lossy(s).to_string();
                if name.ends_with(".dds") || name.ends_with(".ddsc") {
                    names.push(name);
                    i += 4 + n;
                    continue;
                }
            }
        }
        i += 1;
    }
    // vehicle-specific texture (basename starts vNNN_) beats a shared one (window/lightset/generic)
    let is_vspecific = |n: &&String| {
        let base = n.rsplit(['/', '\\']).next().unwrap_or(n).as_bytes();
        base.len() > 4 && base[0] == b'v' && base[1].is_ascii_digit() && base[2].is_ascii_digit() && base[3].is_ascii_digit() && base[4] == b'_'
    };
    let pick = |suffix: &str| {
        let cands: Vec<&String> = names.iter().filter(|n| n.contains(suffix)).collect();
        cands.iter().find(|n| is_vspecific(n)).or_else(|| cands.first()).map(|n| (*n).clone())
    };
    let dif = pick("_dif").or_else(|| names.first().cloned());
    (dif, pick("_nrm"), pick("_mpm"))
}

// Area-weighted smooth normals from the triangle geometry — gives faithful surface shading ("depth").
fn compute_normals(positions: &[[f32; 3]], indices: &[u32]) -> Vec<[f32; 3]> {
    let mut n = vec![[0.0f32; 3]; positions.len()];
    for t in indices.chunks(3) {
        if t.len() < 3 {
            continue;
        }
        let (a, b, c) = (
            positions[t[0] as usize],
            positions[t[1] as usize],
            positions[t[2] as usize],
        );
        let ab = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
        let ac = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
        // cross product (magnitude = 2*area, so it is area-weighted)
        let cr = [
            ab[1] * ac[2] - ab[2] * ac[1],
            ab[2] * ac[0] - ab[0] * ac[2],
            ab[0] * ac[1] - ab[1] * ac[0],
        ];
        for &vi in t {
            let v = &mut n[vi as usize];
            v[0] += cr[0];
            v[1] += cr[1];
            v[2] += cr[2];
        }
    }
    for v in n.iter_mut() {
        let len = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt();
        if len > 1e-8 {
            v[0] /= len;
            v[1] /= len;
            v[2] /= len;
        } else {
            *v = [0.0, 1.0, 0.0];
        }
    }
    n
}

// (vb0_stride, Some(vb1_stride) for two-stream layouts). Position = f32x3 @ vertex offset 0.
fn known_layout(hash: u32) -> Option<(usize, Option<usize>)> {
    match hash {
        0xcd93_1e75 => Some((24, Some(28))), // CarPaint
        _ => None,
    }
}

// Try one concrete layout at vbCount position `p`. Validates indices, positions, and a reachable footer.
fn try_layout(
    b: &[u8],
    p: usize,
    h: &Header,
    eps: f32,
    s0: usize,
    s1: Option<usize>,
) -> Option<(Vec<[f32; 3]>, Vec<[f32; 2]>, Vec<u32>, usize)> {
    let vb_count = u32le_safe(b, p)? as usize;
    if vb_count < 3 || vb_count > 5_000_000 {
        return None;
    }
    let vb0 = p + 4;
    let ib_count_pos = match s1 {
        Some(s1) => {
            let c1_pos = vb0 + vb_count.checked_mul(s0)?;
            if u32le_safe(b, c1_pos)? as usize != vb_count {
                return None; // second-stream count must equal first (strong signal)
            }
            c1_pos + 4 + vb_count.checked_mul(s1)?
        }
        None => vb0 + vb_count.checked_mul(s0)?,
    };
    let ib_count = u32le_safe(b, ib_count_pos)? as usize;
    if ib_count < 3 || ib_count % 3 != 0 || ib_count > 20_000_000 {
        return None;
    }
    let ib0 = ib_count_pos + 4;
    let ib_end = ib0 + ib_count.checked_mul(2)?;
    if ib_end > b.len() {
        return None;
    }
    let mut indices = Vec::with_capacity(ib_count);
    let mut idx_max = 0usize;
    for i in 0..ib_count {
        let idx = u16::from_le_bytes([b[ib0 + i * 2], b[ib0 + i * 2 + 1]]) as usize;
        if idx >= vb_count {
            return None;
        }
        idx_max = idx_max.max(idx);
        indices.push(idx as u32);
    }
    if idx_max < vb_count.saturating_sub(vb_count / 4 + 2) {
        return None; // indices must cover most of the vertex buffer
    }
    let mut positions = Vec::with_capacity(vb_count);
    // UV lives at stream0 offset 16 as u16x2 (USHORT2N) for CarPaint-style layouts (s0>=20).
    let uv_off = if s0 >= 20 { Some(16usize) } else { None };
    let mut uvs = Vec::with_capacity(vb_count);
    for i in 0..vb_count {
        let o = vb0 + i * s0;
        if o + s0 > b.len() {
            return None;
        }
        let v = [f32le(b, o), f32le(b, o + 4), f32le(b, o + 8)];
        for k in 0..3 {
            if !v[k].is_finite() || v[k] < h.bmin[k] - eps || v[k] > h.bmax[k] + eps {
                return None;
            }
        }
        positions.push(v);
        if let Some(uo) = uv_off {
            let u = u16::from_le_bytes([b[o + uo], b[o + uo + 1]]) as f32 / 65535.0;
            let vv = u16::from_le_bytes([b[o + uo + 2], b[o + uo + 3]]) as f32 / 65535.0;
            uvs.push([u, vv]);
        } else {
            uvs.push([0.0, 0.0]);
        }
    }
    // footer may trail the index buffer (CarPaint post-index deform); scan for it
    let scan_end = (ib_end + (1 << 16)).min(b.len().saturating_sub(4));
    let mut fp = ib_end;
    while fp <= scan_end && u32le(b, fp) != FOOTER {
        fp += 2;
    }
    if fp > scan_end || u32le_safe(b, fp)? != FOOTER {
        return None;
    }
    Some((positions, uvs, indices, fp))
}

fn decode_block(b: &[u8], start: usize, h: &Header) -> Option<(Prim, usize)> {
    let hash = u32le_safe(b, start)?;
    let body0 = start + 4;
    let eps = 0.03f32
        * ((h.bmax[0] - h.bmin[0]).abs() + (h.bmax[1] - h.bmin[1]).abs() + (h.bmax[2] - h.bmin[2]).abs())
            .max(1.0);
    let mut layouts: Vec<(usize, Option<usize>)> = Vec::new();
    if let Some(l) = known_layout(hash) {
        layouts.push(l);
    }
    for &s in &STRIDES {
        layouts.push((s, None));
    }
    let mut p = body0;
    while p + 8 <= b.len() {
        for &(s0, s1) in &layouts {
            if let Some((positions, uvs, indices, fp)) = try_layout(b, p, h, eps, s0, s1) {
                let (mut umn, mut umx) = ([f32::INFINITY; 2], [f32::NEG_INFINITY; 2]);
                for uv in &uvs {
                    for k in 0..2 {
                        umn[k] = umn[k].min(uv[k]);
                        umx[k] = umx[k].max(uv[k]);
                    }
                }
                eprintln!(
                    "  block {:08x}: {} verts (stride {}{}) {} tris  uv[{:.2}..{:.2},{:.2}..{:.2}]",
                    hash,
                    positions.len(),
                    s0,
                    s1.map(|x| format!("+{}", x)).unwrap_or_default(),
                    indices.len() / 3,
                    umn[0], umx[0], umn[1], umx[1]
                );
                let normals = compute_normals(&positions, &indices);
                let (diffuse, normalmap, mrmap) = extract_textures(&b[body0..p]);
                return Some((
                    Prim {
                        positions, normals, uvs, indices, joint: 0, part: String::new(),
                        diffuse, normalmap, mrmap,
                    },
                    fp + 4,
                ));
            }
        }
        p += 4;
    }
    None
}

fn decode_rbm(b: &[u8]) -> Vec<Prim> {
    let mut prims = Vec::new();
    let h = match parse_header(b) {
        Some(h) => h,
        None => {
            eprintln!("  not an RBMDL");
            return prims;
        }
    };
    let mut cur = h.body;
    for _ in 0..h.num_blocks {
        match decode_block(b, cur, &h) {
            Some((prim, next)) => {
                prims.push(prim);
                cur = next;
            }
            None => {
                eprintln!(
                    "  block {:08x} at {} unsolved; skipping to next footer",
                    u32le_safe(b, cur).unwrap_or(0),
                    cur
                );
                let mut f = cur + 4;
                while f + 4 <= b.len() && u32le(b, f) != FOOTER {
                    f += 2;
                }
                if f + 4 > b.len() {
                    break;
                }
                cur = f + 4;
            }
        }
    }
    prims
}

// Load + decode a diffuse texture to PNG bytes (searches tex_dir case-insensitively).
fn load_texture_png(tex_dir: &std::path::Path, name: &str) -> Option<Vec<u8>> {
    let base = name.rsplit(['/', '\\']).next().unwrap_or(name).to_lowercase();
    let mut path = tex_dir.join(&base);
    if !path.exists() {
        // case-insensitive scan
        for e in std::fs::read_dir(tex_dir).ok()?.flatten() {
            if e.file_name().to_string_lossy().to_lowercase() == base {
                path = e.path();
                break;
            }
        }
    }
    let dds = std::fs::read(&path).ok()?;
    let img = image::dds_to_rgba(&dds)?;
    Some(image::rgba_to_png(&img))
}

// ---- GLB writer: POSITION + NORMAL + TEXCOORD_0 + JOINTS_0/WEIGHTS_0 + skeleton + textured materials ----
fn write_glb(prims: &[Prim], joint_names: &[String], tex_dir: Option<&std::path::Path>, out: &str) {
    let mut bin: Vec<u8> = Vec::new();
    let mut accessors = String::new();
    let mut buffer_views = String::new();
    let mut meshes_prims = String::new();
    let mut acc = 0usize;
    let mut bv = 0usize;

    // ---- build images (deduped by name) + PBR materials (dif/nrm/mpm) ----
    use std::collections::BTreeMap;
    let mut tex_of: BTreeMap<String, usize> = BTreeMap::new(); // texture name -> texture index
    let mut mat_of: BTreeMap<String, usize> = BTreeMap::new(); // "dif|nrm|mpm" -> material index
    let mut images_json = String::new();
    let mut textures_json = String::new();
    let mut materials_json = String::new();
    let mut nmat = 0usize;
    let mut nimg = 0usize;
    if let Some(td) = tex_dir {
        // 1. load every unique texture referenced by any prim, once
        let mut load_tex = |name: &str,
                            bin: &mut Vec<u8>,
                            buffer_views: &mut String,
                            bv: &mut usize|
         -> Option<usize> {
            if let Some(&t) = tex_of.get(name) {
                return Some(t);
            }
            let png = load_texture_png(td, name)?;
            let off = bin.len();
            bin.extend_from_slice(&png);
            while bin.len() % 4 != 0 {
                bin.push(0);
            }
            buffer_views.push_str(&format!(
                "{{\"buffer\":0,\"byteOffset\":{},\"byteLength\":{}}},",
                off,
                png.len()
            ));
            images_json.push_str(&format!("{{\"bufferView\":{},\"mimeType\":\"image/png\"}},", *bv));
            *bv += 1;
            textures_json.push_str(&format!("{{\"source\":{},\"sampler\":0}},", nimg));
            let t = nimg;
            nimg += 1;
            tex_of.insert(name.to_string(), t);
            Some(t)
        };
        // 2. one material per unique (dif,nrm,mpm) tuple
        for p in prims {
            let key = format!(
                "{}|{}|{}",
                p.diffuse.as_deref().unwrap_or(""),
                p.normalmap.as_deref().unwrap_or(""),
                p.mrmap.as_deref().unwrap_or("")
            );
            if mat_of.contains_key(&key) {
                continue;
            }
            let dif = p.diffuse.as_ref().and_then(|n| load_tex(n, &mut bin, &mut buffer_views, &mut bv));
            let nrm = p.normalmap.as_ref().and_then(|n| load_tex(n, &mut bin, &mut buffer_views, &mut bv));
            let mr = p.mrmap.as_ref().and_then(|n| load_tex(n, &mut bin, &mut buffer_views, &mut bv));
            if dif.is_none() && nrm.is_none() && mr.is_none() {
                continue;
            }
            let mut pbr = String::from("\"pbrMetallicRoughness\":{");
            if let Some(d) = dif {
                pbr.push_str(&format!("\"baseColorTexture\":{{\"index\":{}}},", d));
            }
            if let Some(m) = mr {
                pbr.push_str(&format!("\"metallicRoughnessTexture\":{{\"index\":{}}},\"metallicFactor\":1.0,\"roughnessFactor\":1.0", m));
            } else {
                pbr.push_str("\"metallicFactor\":0.0,\"roughnessFactor\":0.75");
            }
            pbr.push('}');
            let normal_tex = nrm.map(|n| format!(",\"normalTexture\":{{\"index\":{}}}", n)).unwrap_or_default();
            materials_json.push_str(&format!(
                "{{\"name\":\"{}\",{}{},\"doubleSided\":true}},",
                p.diffuse.as_deref().unwrap_or("mat").trim_end_matches(".dds"),
                pbr,
                normal_tex
            ));
            mat_of.insert(key, nmat);
            nmat += 1;
        }
        eprintln!("  PBR: {} materials, {} textures (dif/nrm/mpm)", nmat, nimg);
    }
    let align = |bin: &mut Vec<u8>| {
        while bin.len() % 4 != 0 {
            bin.push(0);
        }
    };
    let mut push_bv = |bin: &Vec<u8>, buffer_views: &mut String, off: usize, len: usize, target: Option<u32>| -> usize {
        let t = target.map(|t| format!(",\"target\":{}", t)).unwrap_or_default();
        buffer_views.push_str(&format!(
            "{{\"buffer\":0,\"byteOffset\":{},\"byteLength\":{}{}}},",
            off, len, t
        ));
        let _ = bin;
        let id = bv;
        bv += 1;
        id
    };
    for prim in prims {
        let vc = prim.positions.len();
        // indices (u32)
        let ioff = bin.len();
        for &i in &prim.indices {
            bin.extend_from_slice(&i.to_le_bytes());
        }
        let ibv = push_bv(&bin, &mut buffer_views, ioff, prim.indices.len() * 4, Some(34963));
        align(&mut bin);
        // positions (f32x3) with min/max
        let poff = bin.len();
        let mut mn = [f32::INFINITY; 3];
        let mut mx = [f32::NEG_INFINITY; 3];
        for v in &prim.positions {
            for k in 0..3 {
                mn[k] = mn[k].min(v[k]);
                mx[k] = mx[k].max(v[k]);
                bin.extend_from_slice(&v[k].to_le_bytes());
            }
        }
        let pbv = push_bv(&bin, &mut buffer_views, poff, vc * 12, Some(34962));
        align(&mut bin);
        // normals (f32x3)
        let noff = bin.len();
        for v in &prim.normals {
            for k in 0..3 {
                bin.extend_from_slice(&v[k].to_le_bytes());
            }
        }
        let nbv = push_bv(&bin, &mut buffer_views, noff, vc * 12, Some(34962));
        align(&mut bin);
        // uvs (f32x2)
        let uvoff = bin.len();
        for uv in &prim.uvs {
            bin.extend_from_slice(&uv[0].to_le_bytes());
            bin.extend_from_slice(&uv[1].to_le_bytes());
        }
        let uvbv = push_bv(&bin, &mut buffer_views, uvoff, vc * 8, Some(34962));
        align(&mut bin);
        // joints (u8x4) — every vertex bound rigidly to this part's joint
        let joff = bin.len();
        for _ in 0..vc {
            bin.extend_from_slice(&[prim.joint as u8, 0, 0, 0]);
        }
        let jbv = push_bv(&bin, &mut buffer_views, joff, vc * 4, None);
        align(&mut bin);
        // weights (f32x4) = (1,0,0,0)
        let woff = bin.len();
        for _ in 0..vc {
            bin.extend_from_slice(&1.0f32.to_le_bytes());
            bin.extend_from_slice(&[0u8; 12]);
        }
        let wbv = push_bv(&bin, &mut buffer_views, woff, vc * 16, None);
        align(&mut bin);
        // accessors: idx, pos, nrm, joints, weights
        let a_idx = acc;
        accessors.push_str(&format!(
            "{{\"bufferView\":{},\"componentType\":5125,\"count\":{},\"type\":\"SCALAR\"}},",
            ibv, prim.indices.len()
        ));
        let a_pos = acc + 1;
        accessors.push_str(&format!(
            "{{\"bufferView\":{},\"componentType\":5126,\"count\":{},\"type\":\"VEC3\",\"min\":[{},{},{}],\"max\":[{},{},{}]}},",
            pbv, vc, mn[0], mn[1], mn[2], mx[0], mx[1], mx[2]
        ));
        let a_nrm = acc + 2;
        accessors.push_str(&format!(
            "{{\"bufferView\":{},\"componentType\":5126,\"count\":{},\"type\":\"VEC3\"}},",
            nbv, vc
        ));
        let a_uv = acc + 3;
        accessors.push_str(&format!(
            "{{\"bufferView\":{},\"componentType\":5126,\"count\":{},\"type\":\"VEC2\"}},",
            uvbv, vc
        ));
        let a_joint = acc + 4;
        accessors.push_str(&format!(
            "{{\"bufferView\":{},\"componentType\":5121,\"count\":{},\"type\":\"VEC4\"}},",
            jbv, vc
        ));
        let a_weight = acc + 5;
        accessors.push_str(&format!(
            "{{\"bufferView\":{},\"componentType\":5126,\"count\":{},\"type\":\"VEC4\"}},",
            wbv, vc
        ));
        acc += 6;
        let mat_key = format!(
            "{}|{}|{}",
            prim.diffuse.as_deref().unwrap_or(""),
            prim.normalmap.as_deref().unwrap_or(""),
            prim.mrmap.as_deref().unwrap_or("")
        );
        let mat_attr = mat_of
            .get(&mat_key)
            .map(|m| format!(",\"material\":{}", m))
            .unwrap_or_default();
        meshes_prims.push_str(&format!(
            "{{\"attributes\":{{\"POSITION\":{},\"NORMAL\":{},\"TEXCOORD_0\":{},\"JOINTS_0\":{},\"WEIGHTS_0\":{}}},\"indices\":{}{}}},",
            a_pos, a_nrm, a_uv, a_joint, a_weight, a_idx, mat_attr
        ));
    }
    // inverse-bind matrices: identity per joint (parts already in model space)
    let njoints = joint_names.len().max(1);
    let ibm_off = bin.len();
    for _ in 0..njoints {
        let id: [f32; 16] = [
            1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0,
        ];
        for x in id {
            bin.extend_from_slice(&x.to_le_bytes());
        }
    }
    let ibm_bv = push_bv(&bin, &mut buffer_views, ibm_off, njoints * 64, None);
    let ibm_acc = acc;
    accessors.push_str(&format!(
        "{{\"bufferView\":{},\"componentType\":5126,\"count\":{},\"type\":\"MAT4\"}},",
        ibm_bv, njoints
    ));
    align(&mut bin);

    // nodes: [0..njoints) = joint nodes (children of skeleton root); then root; then mesh node
    let root_node = njoints;
    let mesh_node = njoints + 1;
    let mut nodes = String::new();
    for jn in joint_names.iter() {
        let safe: String = jn.chars().filter(|c| c.is_ascii_alphanumeric() || *c == '_' || *c == '-').collect();
        nodes.push_str(&format!("{{\"name\":\"{}\"}},", safe));
    }
    if joint_names.is_empty() {
        nodes.push_str("{\"name\":\"joint0\"},");
    }
    // skeleton root with all joints as children
    let joint_list: Vec<String> = (0..njoints).map(|i| i.to_string()).collect();
    nodes.push_str(&format!("{{\"name\":\"skeleton\",\"children\":[{}]}},", joint_list.join(",")));
    nodes.push_str(&format!("{{\"name\":\"mesh\",\"mesh\":0,\"skin\":0}},"));

    let tex_json = if nmat > 0 {
        format!(
            "\"samplers\":[{{\"magFilter\":9729,\"minFilter\":9987,\"wrapS\":10497,\"wrapT\":10497}}],\
\"images\":[{}],\"textures\":[{}],\"materials\":[{}],",
            images_json.trim_end_matches(','),
            textures_json.trim_end_matches(','),
            materials_json.trim_end_matches(',')
        )
    } else {
        String::new()
    };
    let json = format!(
        "{{\"asset\":{{\"version\":\"2.0\",\"generator\":\"jc2_rbm\"}},\
\"scene\":0,\"scenes\":[{{\"nodes\":[{},{}]}}],\
\"nodes\":[{}],\
\"skins\":[{{\"joints\":[{}],\"inverseBindMatrices\":{},\"skeleton\":{}}}],\
{}\
\"meshes\":[{{\"primitives\":[{}]}}],\
\"accessors\":[{}],\"bufferViews\":[{}],\"buffers\":[{{\"byteLength\":{}}}]}}",
        root_node,
        mesh_node,
        nodes.trim_end_matches(','),
        joint_list.join(","),
        ibm_acc,
        root_node,
        tex_json,
        meshes_prims.trim_end_matches(','),
        accessors.trim_end_matches(','),
        buffer_views.trim_end_matches(','),
        bin.len()
    );
    let mut json_bytes = json.into_bytes();
    while json_bytes.len() % 4 != 0 {
        json_bytes.push(b' ');
    }
    align(&mut bin);
    let total = 12 + 8 + json_bytes.len() + 8 + bin.len();
    let mut f = std::fs::File::create(out).unwrap();
    f.write_all(b"glTF").unwrap();
    f.write_all(&2u32.to_le_bytes()).unwrap();
    f.write_all(&(total as u32).to_le_bytes()).unwrap();
    f.write_all(&(json_bytes.len() as u32).to_le_bytes()).unwrap();
    f.write_all(b"JSON").unwrap();
    f.write_all(&json_bytes).unwrap();
    f.write_all(&(bin.len() as u32).to_le_bytes()).unwrap();
    f.write_all(b"BIN\0").unwrap();
    f.write_all(&bin).unwrap();
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    if a.len() < 3 {
        eprintln!("usage: jc2_rbm glb <in.rbm | dir-of-rbms> <out.glb>");
        return;
    }
    let input = &a[2];
    let out = a.get(3).cloned().unwrap_or_else(|| "out.glb".into());
    let mut files: Vec<std::path::PathBuf> = Vec::new();
    let meta = std::fs::metadata(input).unwrap();
    // --prefix vNNN: only parts of one vehicle (from a shared multi-vehicle dir)
    let prefix: Option<String> = a.iter().position(|s| s == "--prefix").and_then(|i| a.get(i + 1).cloned());
    if meta.is_dir() {
        for e in std::fs::read_dir(input).unwrap().flatten() {
            let p = e.path();
            let name = p.file_name().unwrap().to_string_lossy().to_string();
            if let Some(pre) = &prefix {
                if !(name.starts_with(&format!("{}-", pre)) || name.starts_with(&format!("{}_", pre))) {
                    continue;
                }
            }
            if name.ends_with(".rbm")
                && !name.contains("_lod2")
                && !name.contains("_lod3")
                && !name.contains("_lod4")
            {
                files.push(p);
            }
        }
        files.sort();
    } else {
        files.push(input.into());
    }
    let mut all = Vec::new();
    let mut joint_names: Vec<String> = Vec::new();
    for f in &files {
        let name = f.file_stem().unwrap().to_string_lossy().to_string();
        eprintln!("{}", f.file_name().unwrap().to_string_lossy());
        let b = std::fs::read(f).unwrap();
        let prims = decode_rbm(&b);
        if prims.is_empty() {
            continue;
        }
        let joint = joint_names.len() as u32; // one skin joint per source part
        joint_names.push(name.clone());
        for mut p in prims {
            p.joint = joint;
            p.part = name.clone();
            all.push(p);
        }
    }
    let nverts: usize = all.iter().map(|p| p.positions.len()).sum();
    let ntris: usize = all.iter().map(|p| p.indices.len() / 3).sum();
    // sanity: overall bounds + degenerate-triangle ratio (real geometry ~ few degenerate)
    let mut mn = [f32::INFINITY; 3];
    let mut mx = [f32::NEG_INFINITY; 3];
    let (mut deg, mut tot) = (0usize, 0usize);
    for prim in &all {
        for v in &prim.positions {
            for k in 0..3 {
                mn[k] = mn[k].min(v[k]);
                mx[k] = mx[k].max(v[k]);
            }
        }
        for t in prim.indices.chunks(3) {
            if t.len() == 3 {
                tot += 1;
                if t[0] == t[1] || t[1] == t[2] || t[0] == t[2] {
                    deg += 1;
                }
            }
        }
    }
    // textures live alongside the .rbm parts (same unpack dir); allow override with --textures <dir>
    let tex_dir: Option<std::path::PathBuf> = a
        .iter()
        .position(|s| s == "--textures")
        .and_then(|i| a.get(i + 1).map(std::path::PathBuf::from))
        .or_else(|| {
            let m = std::fs::metadata(input).ok()?;
            if m.is_dir() {
                Some(std::path::PathBuf::from(input))
            } else {
                std::path::Path::new(input).parent().map(|p| p.to_path_buf())
            }
        });
    write_glb(&all, &joint_names, tex_dir.as_deref(), &out);
    eprintln!(
        "wrote {} ({} primitives, {} joints, {} verts, {} tris)",
        out,
        all.len(),
        joint_names.len(),
        nverts,
        ntris
    );
    eprintln!(
        "  bounds: [{:.2},{:.2},{:.2}]..[{:.2},{:.2},{:.2}]  size {:.2}x{:.2}x{:.2}m  degenerate tris: {}/{} ({:.1}%)",
        mn[0], mn[1], mn[2], mx[0], mx[1], mx[2],
        mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2],
        deg, tot, 100.0 * deg as f32 / tot.max(1) as f32
    );
}
