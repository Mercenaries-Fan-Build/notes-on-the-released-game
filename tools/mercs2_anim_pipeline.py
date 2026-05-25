#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
End-to-end animation extraction for Mercenaries 2 ``*animgroup*`` blocks.

Steps per block:
  1. ``animgroup_extractor`` → per-record ``.hkx`` + ``records.json``
  2. ``hk_packfile`` → ``packfile.json`` + ``data_patched.bin`` + ``classnames.json``
  3. Codec sniff on raw ``.hkx`` → ``hk_anim`` decoders (interleaved / delta / wavelet)
  4. ``anim_gltf_export`` → ``<character>.glb`` under ``--animations-out`` (+ ``mesh_skin.json``)

``--filter`` selects ``characternameanimgroup``, ``vehiclenameanimgroup`` /
``vehicleclassanimgroup``, or ``all``.

Use ``--validation-only`` to scan existing ``--animations-out`` and write
``_validation.json`` without reprocessing blocks. Use ``--write-validation`` after
a full run to refresh that file.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from anim_block_pairing import find_review_mesh_scene_gltf, ordered_skeleton_block_bins
from anim_gltf_export import build_skeletal_glb
from hk_animation import AnimationIR, decode_delta, decode_interleaved, decode_wavelet, harvest_annotation_strings
from hk_packfile import load_packfile, write_outputs
from hk_skeleton import build_skeleton_export, save_skeleton_json, unknown_skeleton_document, write_mesh_skin_json
from hk_skeleton_extractor import extract_skeleton_from_block_path
from ucfx_skeleton_codec import extract_bone_hash_table, extract_hier_skeleton


def _is_poor_clip_label(s: str | None) -> bool:
    """True when ``anim_name_guess``-style strings are not useful as a primary clip label."""
    if not s:
        return True
    t = str(s).strip()
    if len(t) < 2:
        return True
    if t.isdigit():
        return True
    if len(t) <= 2 and t.isalnum():
        return True
    return False


def _annotation_name_candidates(raw_hkx: bytes) -> list[str]:
    """Prefer longer Havok ``>Name`` markers (see :func:`harvest_annotation_strings`)."""
    texts: list[str] = []
    seen: set[str] = set()
    for _t, s in harvest_annotation_strings(raw_hkx):
        if _is_poor_clip_label(s) or s in seen:
            continue
        seen.add(s)
        texts.append(s)
    texts.sort(key=len, reverse=True)
    return texts


def _human_clip_name(
    *,
    record_index: int,
    slug: str,
    anim_name_guess: str | None,
    raw_hkx: bytes,
) -> str:
    """Stable, human-readable clip name for glTF + sidecar (avoids numeric-only guesses)."""
    annos = _annotation_name_candidates(raw_hkx)
    if anim_name_guess and not _is_poor_clip_label(anim_name_guess):
        base = str(anim_name_guess).strip()[:96]
    elif annos:
        base = annos[0][:96]
    else:
        tail = re.sub(r"[^A-Za-z0-9_]+", "_", slug).strip("_").lower()[:48] or "clip"
        base = f"rec_{record_index:04d}_{tail}"
    return base[:120]


def _dedupe_clip_display_names(names: list[str]) -> list[str]:
    out: list[str] = []
    counts: dict[str, int] = {}
    for n in names:
        key = n.lower()
        c = counts.get(key, 0)
        counts[key] = c + 1
        out.append(n if c == 0 else f"{n}_{c}")
    return out


def _first_long_digit_token(s: str) -> str | None:
    """First run of 5+ digits (common Mercs id prefix on blocks / review stems)."""
    m = re.search(r"\d{5,}", s)
    return m.group(0) if m else None


def _batch_pack_from_block(block_bin: Path) -> str | None:
    """``…/batch_*/blocks/*.bin`` → ``batch_*``."""
    try:
        if block_bin.parent.name.lower() == "blocks":
            return block_bin.parent.parent.name
    except IndexError:
        pass
    return None


def _related_review_keys(pipeline_root: Path, block_bin: Path, slug: str) -> tuple[str | None, list[str]]:
    """
    Heuristic: same extracted batch folder + shared long numeric id in block stem vs review stem,
    or review stem contains output slug.
    """
    batch_pack = _batch_pack_from_block(block_bin)
    block_stem = block_bin.stem.replace(".block", "")
    digit_key = _first_long_digit_token(block_stem) or _first_long_digit_token(slug)
    if not batch_pack:
        return digit_key, []
    review_pack = pipeline_root / "extracted" / "review" / batch_pack
    if not review_pack.is_dir():
        return digit_key, []
    keys: list[str] = []
    slug_l = slug.lower()
    try:
        for ent in review_pack.iterdir():
            if not ent.is_dir():
                continue
            stem = ent.name
            if digit_key and digit_key in stem:
                keys.append(f"{batch_pack}/{stem}")
            elif slug_l and slug_l in stem.lower():
                keys.append(f"{batch_pack}/{stem}")
    except OSError:
        return digit_key, []
    keys.sort()
    return digit_key, keys


def _sniff_duration(blob: bytes) -> float:
    best = 2.0
    for off in range(0, min(len(blob) - 4, 0x8000), 4):
        v = struct.unpack_from("<f", blob, off)[0]
        if 0.25 <= v <= 720.0 and math.isfinite(v):
            best = v
    return float(best)


def _sniff_track_count(blob: bytes) -> int:
    """Read numTransformTracks from the wavelet struct header in the patched blob."""
    for off in range(0, min(len(blob) - 96, 4096), 4):
        t = struct.unpack_from("<I", blob, off + 8)[0]
        if t != 3:
            continue
        d = struct.unpack_from("<f", blob, off + 12)[0]
        if not (0.001 <= d <= 600.0 and math.isfinite(d)):
            continue
        ntt = struct.unpack_from("<I", blob, off + 16)[0]
        if 1 <= ntt <= 500:
            return ntt
    return 22


def _character_slug(stem: str) -> str:
    m = re.search(r"animgroup_([A-Za-z0-9_]+)", stem, re.I)
    if m:
        return m.group(1).lower()
    return re.sub(r"[^A-Za-z0-9_]+", "_", stem).strip("_").lower()[:64]


def _filter_ok(stem: str, flt: str) -> bool:
    s = stem.lower()
    if flt == "all":
        return "animgroup" in s
    if flt == "character":
        return "characternameanimgroup" in s
    if flt == "vehicle":
        return "vehiclenameanimgroup" in s or "vehicleclassanimgroup" in s
    return "animgroup" in s


def _truncate_skeleton_document(doc: dict[str, object], n_keep: int) -> dict[str, object]:
    """Trim ``hkaSkeleton``-shaped docs down to ``n_keep`` bones (animation track count)."""
    out = dict(doc)
    parents = list(out.get("parent_indices") or [])
    names = list(out.get("bone_names") or [])
    refp = list(out.get("reference_pose") or [])
    parents = [int(p) for p in parents[:n_keep]]
    names = [str(names[i]) if i < len(names) else f"bone_{i}" for i in range(n_keep)]
    rows: list[list[float]] = []
    for i in range(n_keep):
        if i < len(refp) and isinstance(refp[i], list) and len(refp[i]) >= 10:
            rows.append([float(x) for x in refp[i][:10]])
        else:
            rows.append([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0])
    out["bone_count"] = int(n_keep)
    out["parent_indices"] = parents
    out["bone_names"] = names
    out["reference_pose"] = rows
    meta = out.setdefault("meta", {})
    if isinstance(meta, dict):
        meta["truncated_to"] = int(n_keep)
    return out


def _sanitize_pelvis_ty(ir: AnimationIR) -> None:
    """Clamp extreme pelvis (bone 1) Y translation spikes from wavelet decode until parity is proven."""
    if not ir.frames or len(ir.frames[0]) < 2:
        return
    bi = 1
    tys = [float(fr[bi].ty) for fr in ir.frames]
    spread = max(tys) - min(tys)
    if spread <= 1.1:
        return
    mid = sum(tys) / len(tys)
    band = 0.45
    lo, hi = mid - band, mid + band
    for fr in ir.frames:
        ty = float(fr[bi].ty)
        if ty < lo:
            fr[bi].ty = lo
        elif ty > hi:
            fr[bi].ty = hi
    ir.meta["pelvis_ty_sanitized"] = {"spread_before": spread, "mid": mid, "band": band}


def _detect_anim_codec(raw: bytes) -> str:
    if b"hkaInterleavedUncompressedAnimation" in raw:
        return "interleaved"
    if b"hkaDeltaCompressedSkeletalAnimation" in raw:
        return "delta"
    if b"hkaWaveletSkeletalAnimation" in raw:
        return "wavelet"
    return "wavelet"


def _run_py(script: Path, args: list[str]) -> None:
    cmd = [sys.executable, str(script), *args]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)


def process_block(
    block_bin: Path,
    pipeline_root: Path,
    work_root: Path,
    animations_out: Path,
    flt: str,
    *,
    max_clips: int,
    skeleton_source: str = "auto",
) -> None:
    stem = block_bin.stem.replace(".block", "")
    if not _filter_ok(stem, flt):
        return
    slug = _character_slug(stem)
    wdir = work_root / slug
    wdir.mkdir(parents=True, exist_ok=True)
    rec_dir = wdir / "records"
    clips: list[AnimationIR] = []
    clip_manifest_rows: list[dict[str, object]] = []
    _run_py(_TOOLS / "animgroup_extractor.py", [str(block_bin), "--out-dir", str(rec_dir)])
    records = json.loads((rec_dir / "records.json").read_text(encoding="utf-8"))["records"]
    first_rec = records[0]
    first_hkx = rec_dir / first_rec["hkx_file"]
    pf_track = load_packfile(first_hkx)
    pf_dir0 = rec_dir / f"_pf_{int(first_rec['index']):04d}"
    write_outputs(pf_track, pf_dir0)
    cn0 = pf_dir0 / "classnames.json"
    ntt0 = _sniff_track_count(pf_track.patched_data)

    stem_numeric_id, related_keys = _related_review_keys(pipeline_root, block_bin, slug)
    mesh_gltf_path = find_review_mesh_scene_gltf(
        pipeline_root, slug=slug, related_keys=related_keys, stem_numeric_id=stem_numeric_id
    )

    skel_doc: dict[str, object] | None = None
    matched_block: Path | None = None

    if skeleton_source == "none":
        skel_doc = unknown_skeleton_document(ntt0)
    else:
        # Step 1: try hkaSkeleton from packfile (unless hier_v1 only)
        if skeleton_source == "auto":
            candidates: list[tuple[int, dict[str, object], Path]] = []
            for blk in ordered_skeleton_block_bins(pipeline_root, block_bin, slug, related_keys):
                doc = extract_skeleton_from_block_path(blk)
                if not doc:
                    continue
                bc = int(doc.get("bone_count", 0))
                if bc <= 0:
                    continue
                candidates.append((bc, doc, blk))

            for bc, doc, blk in candidates:
                if bc == ntt0:
                    skel_doc = doc
                    matched_block = blk
                    break
                if bc > ntt0:
                    skel_doc = _truncate_skeleton_document(doc, ntt0)
                    matched_block = blk
                    break

        # Step 2: try UCFX HIER decode from mesh blocks
        # Extract bone hash table from first HKX record for track→node mapping
        bone_hashes: list[int] | None = None
        if skel_doc is None and skeleton_source in ("auto", "hier_v1"):
            try:
                first_hkx_bytes = first_hkx.read_bytes()
                bone_hashes = extract_bone_hash_table(first_hkx_bytes, ntt0)
            except OSError:
                bone_hashes = None

            for blk in ordered_skeleton_block_bins(pipeline_root, block_bin, slug, related_keys):
                hier_doc = extract_hier_skeleton(blk, bone_hashes=bone_hashes)
                if hier_doc and int(hier_doc.get("bone_count", 0)) > 0:
                    skel_doc = hier_doc
                    matched_block = blk
                    break

        # Step 3: try manual skeleton from assets/manual_skeletons/<family>/skeleton.json
        if skel_doc is None:
            family_id = f"tracks_{ntt0}"
            manual_path = _TOOLS.parent / "assets" / "manual_skeletons" / family_id / "skeleton.json"
            if manual_path.is_file():
                from hk_skeleton import load_skeleton_json
                manual_doc = load_skeleton_json(manual_path)
                if manual_doc and isinstance(manual_doc.get("parent_indices"), list):
                    manual_doc.setdefault("source", "manual")
                    skel_doc = manual_doc

    if skel_doc is None:
        print(
            f"info: no decoded skeleton for {slug} ({ntt0} tracks); skeleton_status=unknown",
            file=sys.stderr,
        )
        skel_doc = unknown_skeleton_document(ntt0)
    else:
        meta = skel_doc.setdefault("meta", {})
        if isinstance(meta, dict) and matched_block is not None:
            meta["matched_block"] = str(matched_block.resolve())
    save_skeleton_json(skel_doc, wdir / "skeleton.json")

    rigid_mesh_cached = None
    if mesh_gltf_path is not None and mesh_gltf_path.is_file():
        from hk_mesh import load_rigid_skinned_bind0_mesh_from_gltf

        rigid_mesh_cached = load_rigid_skinned_bind0_mesh_from_gltf(mesh_gltf_path)

    skel_written = False
    for rec in records:
        hkx = rec_dir / rec["hkx_file"]
        raw_hkx = hkx.read_bytes()
        pf_dir = rec_dir / f"_pf_{rec['index']:04d}"
        pf = load_packfile(hkx)
        write_outputs(pf, pf_dir)
        blob = pf.patched_data
        ntt = _sniff_track_count(blob)
        if not skel_written:
            cn = pf_dir / "classnames.json"
            skel_doc_ms = build_skeleton_export(
                blob,
                cn if cn.is_file() else None,
                n_bones_hint=ntt,
            )
            if rigid_mesh_cached is not None:
                from hk_mesh import mesh_skin_sidecar_dict

                ms = skel_doc_ms.setdefault("mesh_skin", {})
                if isinstance(ms, dict):
                    ms.update(mesh_skin_sidecar_dict(rigid_mesh_cached))
            write_mesh_skin_json(skel_doc_ms, wdir / "mesh_skin.json")
            skel_written = True
        dur = _sniff_duration(blob)
        ri = int(rec["index"])
        guess = rec.get("anim_name_guess")
        display = _human_clip_name(record_index=ri, slug=slug, anim_name_guess=guess, raw_hkx=raw_hkx)
        codec = _detect_anim_codec(raw_hkx)
        if codec == "interleaved":
            ir = decode_interleaved(blob, 0, name=display)
        elif codec == "delta":
            ir = decode_delta(blob, 0, name=display)
        else:
            ir = decode_wavelet(blob, 0, name=display, duration=dur, n_tracks=ntt)
        if ir is None:
            ir = decode_wavelet(blob, 0, name=display, duration=dur, n_tracks=ntt)
        if ir is None:
            ir = decode_delta(blob, 0, name=display)
        if ir is None:
            ir = decode_interleaved(blob, 0, name=display)
        if ir is None:
            continue
        ir.annotations = harvest_annotation_strings(raw_hkx)
        ir.meta.setdefault("codec_guess", codec)
        ir.meta["record_index"] = ri
        if guess is not None:
            ir.meta["anim_name_guess"] = guess
        if codec == "wavelet" and ir.frames and len(ir.frames[0]) > 1:
            tys = [float(fr[1].ty) for fr in ir.frames]
            sp = max(tys) - min(tys)
            if sp > 1.05:
                ir.meta["pelvis_ty_spread_wavelet_raw"] = round(sp, 5)
        _sanitize_pelvis_ty(ir)
        if "pelvis_ty_spread_wavelet_raw" in ir.meta and ir.frames and len(ir.frames[0]) > 1:
            tys2 = [float(fr[1].ty) for fr in ir.frames]
            ir.meta["pelvis_ty_spread_after_sanitize"] = round(max(tys2) - min(tys2), 5)
        clips.append(ir)
        row: dict[str, object] = {
            "record_index": ri,
            "display_name": display,
            "anim_name_guess": guess,
            "codec_guess": codec,
        }
        for k in (
            "pelvis_ty_spread_wavelet_raw",
            "pelvis_ty_spread_after_sanitize",
            "pelvis_ty_sanitized",
        ):
            if k in ir.meta:
                row[k] = ir.meta[k]
        clip_manifest_rows.append(row)
    clips = clips[:max_clips]
    clip_manifest_rows = clip_manifest_rows[: len(clips)]
    if not clips:
        return

    names = [c.name for c in clips]
    deduped = _dedupe_clip_display_names(names)
    for i, c in enumerate(clips):
        c.name = deduped[i]
        if i < len(clip_manifest_rows):
            clip_manifest_rows[i]["display_name"] = deduped[i]
            clip_manifest_rows[i]["gltf_name"] = deduped[i]

    def clip_doc(c: AnimationIR) -> dict[str, object]:
        d: dict[str, object] = {
            "name": c.name,
            "duration": c.duration,
            "fps": c.fps,
            "bone_names": c.bone_names,
            "frames": [[[tr.tx, tr.ty, tr.tz, tr.qx, tr.qy, tr.qz, tr.qw, tr.sx, tr.sy, tr.sz] for tr in fr] for fr in c.frames],
            "source_class": c.source_class,
        }
        if c.meta:
            d["meta"] = c.meta
        return d

    (wdir / "clips_ir.json").write_text(json.dumps([clip_doc(c) for c in clips], indent=2), encoding="utf-8")
    out_glb = animations_out / slug / f"{slug}.glb"
    out_glb.parent.mkdir(parents=True, exist_ok=True)
    cn = rec_dir / "_pf_0000" / "classnames.json"
    if not cn.is_file():
        cn = None
    gltf = build_skeletal_glb(
        clips,
        character_name=slug,
        classnames_json=cn,
        skeleton_json=wdir / "skeleton.json",
        mesh_gltf_path=mesh_gltf_path,
    )
    gltf.save_binary(str(out_glb))
    for i, row in enumerate(clip_manifest_rows):
        row["gltf_clip_index"] = i
    clips_sidecar = {
        "version": 1,
        "slug": slug,
        "block_stem": stem,
        "source_block": str(block_bin.resolve()),
        "batch_pack": _batch_pack_from_block(block_bin),
        "stem_numeric_id": stem_numeric_id,
        "clips": clip_manifest_rows,
        "related_review_keys": related_keys,
    }
    sidecar_json = json.dumps(clips_sidecar, indent=2)
    (out_glb.parent / "clips_manifest.json").write_text(sidecar_json, encoding="utf-8")
    (wdir / "clips_manifest.json").write_text(sidecar_json, encoding="utf-8")
    (wdir / "manifest.json").write_text(
        json.dumps(
            {
                "block": stem,
                "slug": slug,
                "clips": len(clips),
                "glb": str(out_glb),
                "clips_manifest": "clips_manifest.json",
                "stem_numeric_id": stem_numeric_id,
                "related_review_keys": related_keys,
            },
            indent=2,
        ),
        encoding="utf-8",
    )


def _gltf_binary_summary(glb: Path) -> dict[str, Any]:
    """Lightweight stats from a pipeline ``.glb`` (requires pygltflib)."""
    from pygltflib import GLTF2

    out: dict[str, Any] = {"glb_bytes": glb.stat().st_size if glb.is_file() else 0}
    try:
        g = GLTF2().load_binary(str(glb))
    except (OSError, ValueError, KeyError) as e:
        out["load_error"] = str(e)[:400]
        return out
    out["animations"] = len(g.animations or [])
    sks = g.skins or []
    out["skins"] = len(sks)
    if sks and sks[0].joints is not None:
        out["skin_joint_count"] = len(sks[0].joints)
    max_v = 0
    for mesh in g.meshes or []:
        for prim in mesh.primitives or []:
            attrs = prim.attributes
            pos = getattr(attrs, "POSITION", None) if attrs is not None else None
            if pos is not None and g.accessors and int(pos) < len(g.accessors):
                max_v = max(max_v, int(g.accessors[int(pos)].count))
    out["max_mesh_vertices"] = max_v
    return out


def _pick_slug_dir_for_needle(anim_out: Path, needle: str) -> Path | None:
    needle_l = needle.lower()
    for d in sorted(anim_out.iterdir()):
        if not d.is_dir() or d.name.startswith("."):
            continue
        if needle_l not in d.name.lower():
            continue
        glb = d / f"{d.name}.glb"
        if glb.is_file():
            return d
    return None


def write_animations_validation_json(
    *,
    pipeline_root: Path,
    animations_out: Path,
    validation_out: Path,
) -> dict[str, Any]:
    """
    Scan ``animations_out/*/<slug>.glb`` + ``clips_manifest.json`` and write a summary file
    (spot checks for mattias / amx30 / ah1z-style slugs when present).
    """
    summaries: list[dict[str, Any]] = []
    if animations_out.is_dir():
        for d in sorted(animations_out.iterdir()):
            if not d.is_dir() or d.name.startswith("."):
                continue
            slug = d.name
            glb = d / f"{slug}.glb"
            if not glb.is_file():
                continue
            manifest_path = d / "clips_manifest.json"
            clips_n = 0
            manifest: dict[str, Any] = {}
            if manifest_path.is_file():
                try:
                    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
                    clips = manifest.get("clips")
                    clips_n = len(clips) if isinstance(clips, list) else 0
                except (OSError, json.JSONDecodeError):
                    manifest = {}
            summaries.append(
                {
                    "slug": slug,
                    "clips": clips_n,
                    "glb_bytes": glb.stat().st_size,
                    "batch_pack": manifest.get("batch_pack"),
                    "stem_numeric_id": manifest.get("stem_numeric_id"),
                }
            )

    spot_needles = ("mattias", "amx30", "ah1z")
    spot_checks: dict[str, Any] = {}
    for needle in spot_needles:
        picked = _pick_slug_dir_for_needle(animations_out, needle)
        if picked is None:
            spot_checks[needle] = {"matched_slug": None}
            continue
        slug = picked.name
        glb = picked / f"{slug}.glb"
        man: dict[str, Any] = {}
        mp = picked / "clips_manifest.json"
        if mp.is_file():
            try:
                man = json.loads(mp.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                man = {}
        spot_checks[needle] = {
            "matched_slug": slug,
            "clips_manifest_clip_count": len(man["clips"]) if isinstance(man.get("clips"), list) else 0,
            "related_review_keys": man.get("related_review_keys"),
            "gltf": _gltf_binary_summary(glb),
        }

    doc: dict[str, Any] = {
        "version": 1,
        "generated": datetime.now(timezone.utc).isoformat(),
        "pipeline_root": str(pipeline_root.resolve()),
        "animations_out": str(animations_out.resolve()),
        "totals": {
            "slug_dirs_with_glb": len(summaries),
            "clips_total": int(sum(int(s.get("clips") or 0) for s in summaries)),
        },
        "slugs": summaries,
        "spot_checks": spot_checks,
    }
    validation_out.parent.mkdir(parents=True, exist_ok=True)
    validation_out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    return doc


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 animgroup → glTF/GLB pipeline")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument(
        "--filter",
        choices=("character", "vehicle", "all"),
        default="all",
        help="Which animgroup stems to process",
    )
    ap.add_argument(
        "--animations-out",
        type=Path,
        default=None,
        help="Output directory for <slug>/<slug>.glb (default: <pipeline-root>/animations)",
    )
    ap.add_argument(
        "--work-dir",
        type=Path,
        default=None,
        help="Scratch dir (default: <pipeline-root>/animations_work)",
    )
    ap.add_argument(
        "--stem-contains",
        type=str,
        default=None,
        help="Only process blocks whose stem contains this substring (case-insensitive)",
    )
    ap.add_argument(
        "--max-clips",
        type=int,
        default=32,
        help="Max animation clips merged into each output .glb (default: 32)",
    )
    ap.add_argument(
        "--write-validation",
        action="store_true",
        help="After processing, write JSON summary to --validation-out (default: <animations-out>/_validation.json)",
    )
    ap.add_argument(
        "--validation-out",
        type=Path,
        default=None,
        help="Path for validation JSON (default: <animations-out>/_validation.json)",
    )
    ap.add_argument(
        "--validation-only",
        action="store_true",
        help="Only scan existing --animations-out and write validation JSON; do not process blocks",
    )
    ap.add_argument(
        "--skeleton-source",
        choices=("auto", "hier_v1", "none"),
        default="auto",
        help=(
            "Skeleton source: 'auto' tries hkaSkeleton then HIER then unknown; "
            "'hier_v1' uses UCFX HIER decode from mesh blocks; "
            "'none' always emits skeleton_status=unknown (default: auto)"
        ),
    )
    args = ap.parse_args()
    root = args.pipeline_root.resolve()
    anim_out = (args.animations_out or root / "animations").resolve()
    work = (args.work_dir or root / "animations_work").resolve()
    vout = (args.validation_out or (anim_out / "_validation.json")).resolve()

    if args.validation_only:
        if not anim_out.is_dir():
            print(f"error: animations directory missing: {anim_out}", file=sys.stderr)
            return 1
        write_animations_validation_json(
            pipeline_root=root, animations_out=anim_out, validation_out=vout
        )
        print(json.dumps({"validation_out": str(vout), "animations_out": str(anim_out)}, indent=2))
        return 0

    anim_out.mkdir(parents=True, exist_ok=True)
    work.mkdir(parents=True, exist_ok=True)

    blocks: list[Path] = []
    extr = root / "extracted"
    if extr.is_dir():
        for p in extr.glob("batch_*/blocks/*animgroup*.block.bin"):
            blocks.append(p)
    for p in sorted(blocks):
        if args.stem_contains and args.stem_contains.lower() not in p.stem.lower():
            continue
        try:
            process_block(
                p, root, work, anim_out, args.filter,
                max_clips=args.max_clips,
                skeleton_source=args.skeleton_source,
            )
        except (OSError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as e:
            print(f"skip {p.name}: {e}", file=sys.stderr)
    out_summary: dict[str, Any] = {"animations_out": str(anim_out), "blocks_seen": len(blocks)}
    if args.write_validation:
        write_animations_validation_json(
            pipeline_root=root, animations_out=anim_out, validation_out=vout
        )
        out_summary["validation_out"] = str(vout)
    print(json.dumps(out_summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
