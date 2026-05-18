"""CLI ingest tool — walks ALL review/ trees and ingests every data source.

Usage:
    cd webapp/
    python -m app.ingest.cli --output ../output [--database-url postgresql://...]

Ingests:
  - FFCS manifests + paths.txt → wad_archives, blocks
  - review/ trees (vz, english, shell, loading) → ucfx.json, mesh.meta.json,
    submeshes/index.json, dialog_fragments.json, shared_textures.json, havok/
  - placements/layers_static.json → placements
  - placements/vz_state/all_vz_state.json → placements + vz_state_overlays
  - placements/vz_act_layer_manifest.json → overlay metadata enrichment
  - placements/ecs_components.json → ecs_records
  - placements/c3_cell_manifest.json → world_cells
  - block_dependency_graph.json → aset_rows
  - extracted/texture_index.json → texture_index_entries + textures
  - animations_work/*/manifest.json,skeleton.json,clips_manifest.json → animation_groups, clips, skeletons, bones
  - placements/pmc_lua_string_harvest.json → lua_chunks
  - variant_registry.json → variant enrichment on blocks
  - SaveGames/ harvest → save_profiles, save_harvested_data
  - Precache/ → precache_slots
  - cdbsizes.ini → ecs_component_types
"""
from __future__ import annotations

import argparse
import json
import logging
import math
import os
import re
import sys
import time
from pathlib import Path

# Allow running from webapp/ as well as repo root
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.models.base import Base
from app.models.schema import (
    AnimationClip,
    AnimationGroup,
    AsetRow,
    Block,
    BlockMeshMeta,
    Bone,
    DialogFragment,
    EcsComponentType,
    EcsRecord,
    LuaChunk,
    Placement,
    PrecacheSlot,
    Skeleton,
    Submesh,
    Texture,
    TextureIndexEntry,
    VzStateOverlay,
    WadArchive,
    WorldCell,
)
from app.ingest.helpers import (
    base_texture_name,
    classify_block_type,
    compute_distance_from_origin,
    compute_ue_coords,
    compute_ue_yaw,
    elevation_band,
    has_non_trivial_rotation,
    parse_block_stem,
    parse_mission_id,
    parse_vz_state_name,
    texture_channel_from_name,
)

log = logging.getLogger("ingest")

BATCH_SIZE = 2000


def json_for_pg(obj):
    """Recursively convert Python NaN/Inf floats to string markers for PostgreSQL JSONB.

    PostgreSQL rejects NaN/Infinity in JSON per RFC 8259. Rather than discarding
    these values (which could mask extraction pipeline bugs), we convert them to
    queryable string markers.
    """
    if isinstance(obj, float):
        if math.isnan(obj):
            return "__NaN__"
        if math.isinf(obj):
            return "__Inf__" if obj > 0 else "__-Inf__"
        return obj
    if isinstance(obj, dict):
        return {k: json_for_pg(v) for k, v in obj.items()}
    if isinstance(obj, str):
        return obj.replace("\x00", "") if "\x00" in obj else obj
    if isinstance(obj, list):
        return [json_for_pg(v) for v in obj]
    return obj


# ---------------------------------------------------------------------------
# Database session helper
# ---------------------------------------------------------------------------

def make_session(url: str) -> Session:
    engine = create_engine(url, echo=False, pool_pre_ping=True)
    Base.metadata.create_all(engine)
    return Session(engine)


# ---------------------------------------------------------------------------
# WAD archives + block registration from FFCS manifests + paths.txt
# ---------------------------------------------------------------------------

def ingest_wad_manifests(session: Session, output: Path) -> dict[str, int]:
    """Ingest FFCS manifest.json + paths.txt for each WAD → wad_archives + blocks.
    Returns {wad_name: wad_id}."""
    wad_ids: dict[str, int] = {}
    extracted = output / "extracted"

    wad_configs = [
        ("vz", "ffcs_vz", "batch_vz"),
        ("english", "ffcs_English", "batch_english"),
        ("shell", "ffcs_shell", "batch_shell"),
        ("loading", "ffcs_Loading", "batch_loading"),
    ]

    for wad_name, ffcs_dir, batch_name in wad_configs:
        manifest_path = extracted / ffcs_dir / "manifest.json"
        paths_path = extracted / ffcs_dir / "paths.txt"
        if not manifest_path.exists():
            log.warning("No manifest for %s at %s, skipping", wad_name, manifest_path)
            continue

        manifest = json.loads(manifest_path.read_text())
        chunks = {c["tag"]: c for c in manifest.get("chunks", [])}

        wad = WadArchive(
            name=wad_name,
            filename=f"{wad_name}.wad",
            file_size_bytes=manifest.get("file_size"),
            ffcs_version=manifest.get("version"),
            block_count=manifest.get("path_strings"),
            indx_offset=chunks.get("INDX", {}).get("offset"),
            indx_entry_count=chunks.get("INDX", {}).get("meta"),
            data_offset=chunks.get("DATA", {}).get("offset"),
            data_segment_count=chunks.get("DATA", {}).get("meta"),
            data_size_bytes=chunks.get("DATA", {}).get("size"),
            csum_entry_count=chunks.get("CSUM", {}).get("meta"),
            aset_offset=chunks.get("ASET", {}).get("offset"),
            aset_entry_count=chunks.get("ASET", {}).get("meta"),
            aset_size_bytes=chunks.get("ASET", {}).get("size"),
            pths_offset=chunks.get("PTHS", {}).get("offset"),
            pths_entry_count=chunks.get("PTHS", {}).get("meta"),
            pths_size_bytes=chunks.get("PTHS", {}).get("size"),
            chunk_summary=json_for_pg(manifest.get("chunks")),
        )
        session.add(wad)
        session.flush()
        wad_ids[wad_name] = wad.id
        log.info("Registered WAD: %s (id=%d)", wad_name, wad.id)

        if paths_path.exists():
            paths = paths_path.read_text().splitlines()
            review_root = extracted / "review" / batch_name
            blocks_to_add: list[Block] = []

            for idx, raw_path in enumerate(paths):
                try:
                    raw_path = raw_path.strip()
                    if not raw_path:
                        continue
                    safe_stem = f"{idx:05d}_{raw_path.replace(chr(92), '__').replace('/', '__')}"
                    parsed = parse_block_stem(safe_stem)

                    review_dir = review_root / f"{safe_stem}.block"
                    has_review = review_dir.is_dir()

                    ucfx_data = None
                    file_size = None
                    has_geometry = False
                    has_textures = False
                    has_havok = False
                    has_dialog = False
                    glb_path = None
                    gltf_path = None
                    obj_path = None

                    if has_review:
                        ucfx_path = review_dir / "ucfx.json"
                        if ucfx_path.exists():
                            try:
                                ucfx_data = json.loads(ucfx_path.read_text())
                                file_size = ucfx_data.get("size")
                            except (json.JSONDecodeError, OSError):
                                pass

                        has_geometry = (review_dir / "mesh.meta.json").exists()
                        has_textures = bool(ucfx_data and ucfx_data.get("dxt_occurrences"))
                        has_havok = (review_dir / "havok").is_dir()
                        has_dialog = (review_dir / "dialog_fragments.json").exists()
                        if (review_dir / "mesh_scene.glb").exists():
                            glb_path = str(review_dir / "mesh_scene.glb")
                        if (review_dir / "mesh_scene.gltf").exists():
                            gltf_path = str(review_dir / "mesh_scene.gltf")
                        if (review_dir / "mesh.obj").exists():
                            obj_path = str(review_dir / "mesh.obj")

                    block = Block(
                        wad_id=wad.id,
                        block_index=idx,
                        path=raw_path,
                        stem=safe_stem,
                        canonical_name=parsed.get("canonical_name"),
                        base_asset_id=parsed.get("base_asset_id"),
                        p_level=parsed.get("p_level"),
                        q_level=parsed.get("q_level"),
                        pack=parsed.get("pack") or batch_name,
                        block_type=parsed.get("block_type"),
                        review_status="unreviewed",
                        file_size_bytes=file_size,
                        has_geometry=has_geometry,
                        has_textures=has_textures,
                        has_havok=has_havok,
                        has_dialog=has_dialog,
                        review_dir_path=str(review_dir) if has_review else None,
                        glb_path=glb_path,
                        gltf_path=gltf_path,
                        obj_path=obj_path,
                        faction_hint=parsed.get("faction_hint"),
                        region_hint=parsed.get("region_hint"),
                        ucfx_offset_count=len(ucfx_data.get("ucfx_offsets", [])) if ucfx_data else None,
                        primary_ucfx_offset=ucfx_data.get("primary_ucfx_offset") if ucfx_data else None,
                        ucfx_offsets=json_for_pg(ucfx_data.get("ucfx_offsets")) if ucfx_data else None,
                        tag_occurrences=json_for_pg(ucfx_data.get("tag_occurrences")) if ucfx_data else None,
                        strings_sample=json_for_pg(ucfx_data.get("strings_sample")) if ucfx_data else None,
                        raw_ucfx_json=json_for_pg(ucfx_data),
                    )
                    blocks_to_add.append(block)

                    if len(blocks_to_add) >= BATCH_SIZE:
                        session.add_all(blocks_to_add)
                        session.flush()
                        blocks_to_add.clear()
                except Exception:
                    log.warning("Skipping bad record in ingest_wad_manifests: %s", raw_path, exc_info=True)
                    try:
                        session.rollback()
                    except Exception:
                        pass
                    continue

            if blocks_to_add:
                session.add_all(blocks_to_add)
                session.flush()
            log.info("  Registered %d blocks for WAD %s", len(paths), wad_name)

    session.commit()
    return wad_ids


# ---------------------------------------------------------------------------
# Build stem → block_id lookup
# ---------------------------------------------------------------------------

def build_stem_lookup(session: Session) -> dict[str, int]:
    rows = session.execute(text("SELECT stem, id FROM blocks")).all()
    return {r[0]: r[1] for r in rows}


# ---------------------------------------------------------------------------
# Mesh metadata + submeshes from review/ trees
# ---------------------------------------------------------------------------

def ingest_mesh_metadata(session: Session, output: Path, stem_to_id: dict[str, int]) -> None:
    """Walk review/ trees and ingest mesh.meta.json + submeshes/index.json."""
    review_root = output / "extracted" / "review"
    count_meta = 0
    count_sub = 0

    for batch_dir in sorted(review_root.iterdir()):
        if not batch_dir.is_dir() or batch_dir.name.startswith("."):
            continue
        for block_dir in sorted(batch_dir.iterdir()):
            if not block_dir.is_dir():
                continue
            try:
                stem = block_dir.name
                block_id = stem_to_id.get(stem)
                if block_id is None:
                    continue

                meta_path = block_dir / "mesh.meta.json"
                if meta_path.exists():
                    try:
                        meta = json.loads(meta_path.read_text())
                    except (json.JSONDecodeError, OSError):
                        continue

                    ext = meta.get("extract", {})
                    bbox_vol = None
                    bbox_fields: dict = {}

                    structured = ext.get("structured_attempt", {})
                    submesh_list = structured.get("submeshes", [])
                    if submesh_list:
                        all_mins = [s.get("prmg_bbox", [0]*6)[:3] for s in submesh_list if s.get("prmg_bbox")]
                        all_maxs = [s.get("prmg_bbox", [0]*6)[3:6] for s in submesh_list if s.get("prmg_bbox")]
                        if all_mins and all_maxs:
                            mn = [min(v[i] for v in all_mins) for i in range(3)]
                            mx = [max(v[i] for v in all_maxs) for i in range(3)]
                            extents = [mx[i] - mn[i] for i in range(3)]
                            bbox_vol = extents[0] * extents[1] * extents[2]
                            bbox_fields = {
                                "bbox_min_x": mn[0], "bbox_min_y": mn[1], "bbox_min_z": mn[2],
                                "bbox_max_x": mx[0], "bbox_max_y": mx[1], "bbox_max_z": mx[2],
                                "bbox_center_x": (mn[0]+mx[0])/2,
                                "bbox_center_y": (mn[1]+mx[1])/2,
                                "bbox_center_z": (mn[2]+mx[2])/2,
                                "extent_x": extents[0], "extent_y": extents[1], "extent_z": extents[2],
                                "max_extent": max(extents),
                                "is_flat": extents[1] < 0.1,
                            }

                    _STRIP_KEYS = {"submeshes", "normals", "uvs", "tangents",
                                    "vertices_data", "indices_data", "positions"}
                    _MAX_JSONB_FILE = 5 * 1024 * 1024  # 5 MB

                    file_size = meta_path.stat().st_size

                    if file_size > _MAX_JSONB_FILE:
                        slim_json = None
                    else:
                        slim_meta = {
                            k: v for k, v in meta.items()
                            if k != "extract"
                        }
                        if ext:
                            slim_ext = {k: v for k, v in ext.items() if k not in (
                                "structured_attempt", "fallback_attempt",
                            )}
                            for attempt_key in ("structured_attempt", "fallback_attempt"):
                                attempt = ext.get(attempt_key)
                                if attempt and isinstance(attempt, dict):
                                    slim_ext[attempt_key] = {
                                        k: v for k, v in attempt.items()
                                        if k not in _STRIP_KEYS
                                    }
                            slim_meta["extract"] = slim_ext
                        slim_json = json_for_pg(slim_meta)

                    mm = BlockMeshMeta(
                        block_id=block_id,
                        mesh_meta_path=str(meta_path),
                        mesh_meta_size_bytes=file_size,
                        total_vertices=meta.get("vertices"),
                        total_faces=meta.get("faces"),
                        topology=meta.get("topology"),
                        extraction_method=ext.get("extraction"),
                        mesh_group_count=meta.get("mesh_group_count"),
                        transparent_count=meta.get("transparent_count"),
                        lod_mode=meta.get("lod_mode"),
                        material_indices=json_for_pg(meta.get("material_indices")),
                        notes=meta.get("note"),
                        bbox_volume=bbox_vol,
                        raw_meta_json=slim_json,
                        **bbox_fields,
                    )
                    session.add(mm)
                    count_meta += 1

                sub_index_path = block_dir / "submeshes" / "index.json"
                if sub_index_path.exists():
                    try:
                        sub_list = json.loads(sub_index_path.read_text())
                    except (json.JSONDecodeError, OSError):
                        continue
                    for entry in sub_list:
                        bbox = entry.get("decoded_bbox", [None]*6)
                        prmg = entry.get("prmg_bbox", [None]*6)
                        wt = entry.get("world_translation", [None]*3)
                        sub_vol = None
                        if bbox and len(bbox) == 6 and bbox[0] is not None:
                            ext_vals = [bbox[3]-bbox[0], bbox[4]-bbox[1], bbox[5]-bbox[2]]
                            sub_vol = ext_vals[0] * ext_vals[1] * ext_vals[2]

                        sm = Submesh(
                            block_id=block_id,
                            submesh_index=entry.get("index", 0),
                            obj_filename=entry.get("file"),
                            vertex_count=entry.get("vertices"),
                            face_count=entry.get("faces"),
                            material_index=entry.get("material_index"),
                            is_transparent=entry.get("transparency_flag", 0) > 0 if entry.get("transparency_flag") is not None else None,
                            transparency_flag=entry.get("transparency_flag"),
                            lod_group=entry.get("lod_group"),
                            lod_rank=entry.get("lod_rank"),
                            is_vehicle_lod=entry.get("is_vehicle_lod"),
                            lod_alternatives=json_for_pg(entry.get("lod_alternatives")),
                            mesh_group_id=entry.get("mesh_group_id"),
                            mesh_draw_index=entry.get("mesh_draw_index"),
                            prmt_draw_index=entry.get("prmt_draw_index"),
                            texture_diffuse=entry.get("texture_diffuse"),
                            texture_normal=entry.get("texture_normal"),
                            texture_specular=entry.get("texture_specular"),
                            hier_node_idx=entry.get("hier_node_idx"),
                            damage_state=entry.get("damage_state"),
                            instanced_from=entry.get("instanced_from"),
                            bbox_min_x=bbox[0] if bbox and len(bbox)==6 else None,
                            bbox_min_y=bbox[1] if bbox and len(bbox)==6 else None,
                            bbox_min_z=bbox[2] if bbox and len(bbox)==6 else None,
                            bbox_max_x=bbox[3] if bbox and len(bbox)==6 else None,
                            bbox_max_y=bbox[4] if bbox and len(bbox)==6 else None,
                            bbox_max_z=bbox[5] if bbox and len(bbox)==6 else None,
                            bbox_volume=sub_vol,
                            prmg_bbox_min_x=prmg[0] if prmg and len(prmg)==6 else None,
                            prmg_bbox_min_y=prmg[1] if prmg and len(prmg)==6 else None,
                            prmg_bbox_min_z=prmg[2] if prmg and len(prmg)==6 else None,
                            prmg_bbox_max_x=prmg[3] if prmg and len(prmg)==6 else None,
                            prmg_bbox_max_y=prmg[4] if prmg and len(prmg)==6 else None,
                            prmg_bbox_max_z=prmg[5] if prmg and len(prmg)==6 else None,
                            world_translation_x=wt[0] if wt and len(wt)==3 else None,
                            world_translation_y=wt[1] if wt and len(wt)==3 else None,
                            world_translation_z=wt[2] if wt and len(wt)==3 else None,
                            world_rotation_3x3=json_for_pg(entry.get("world_rotation_3x3")),
                            hier_instance_nodes=json_for_pg(entry.get("hier_instance_nodes")),
                        )
                        session.add(sm)
                        count_sub += 1

                session.flush()
            except Exception:
                log.warning("Skipping bad record in ingest_mesh_metadata: %s", block_dir.name, exc_info=True)
                try:
                    session.rollback()
                except Exception:
                    pass
                continue

    session.commit()
    log.info("Ingested %d mesh metas, %d submeshes", count_meta, count_sub)


# ---------------------------------------------------------------------------
# Dialog fragments from review/ trees
# ---------------------------------------------------------------------------

def ingest_dialog_fragments(session: Session, output: Path, stem_to_id: dict[str, int]) -> None:
    review_root = output / "extracted" / "review"
    count = 0

    for batch_dir in sorted(review_root.iterdir()):
        if not batch_dir.is_dir() or batch_dir.name.startswith("."):
            continue
        for block_dir in sorted(batch_dir.iterdir()):
            if not block_dir.is_dir():
                continue
            df_path = block_dir / "dialog_fragments.json"
            if not df_path.exists():
                continue
            stem = block_dir.name
            block_id = stem_to_id.get(stem)
            if block_id is None:
                continue
            try:
                data = json.loads(df_path.read_text())
            except (json.JSONDecodeError, OSError):
                continue

            for ftype in ("bracket_keys", "generic_keys", "utf16_bracket_keys"):
                for val in data.get(ftype, []):
                    try:
                        clean_val = val.replace("\x00", "") if isinstance(val, str) else val
                        namespace = clean_val.split(".")[0] if "." in clean_val else None
                        df = DialogFragment(
                            block_id=block_id,
                            fragment_type=ftype.rstrip("s"),
                            value=clean_val,
                            namespace=namespace,
                            key_path=clean_val if "." in clean_val else None,
                            is_mission_ref=bool(re.match(r"[A-Za-z]{2,3}(Con|Job|Rec)\d{3}", clean_val)),
                            is_localization=clean_val.startswith("Generic.") or clean_val.startswith("ContextAction."),
                            is_objective="Objective" in clean_val,
                            is_subtitle="subtitles" in stem.lower(),
                        )
                        session.add(df)
                        count += 1
                    except Exception:
                        log.warning("Skipping bad record in ingest_dialog_fragments: %s", val, exc_info=True)
                        try:
                            session.rollback()
                        except Exception:
                            pass
                        continue

            try:
                if count % 500 == 0:
                    session.flush()
            except Exception:
                log.warning("Flush failed in ingest_dialog_fragments at count=%d", count, exc_info=True)
                try:
                    session.rollback()
                except Exception:
                    pass

    session.commit()
    log.info("Ingested %d dialog fragments", count)


# ---------------------------------------------------------------------------
# Placements (layers_static + vz_state)
# ---------------------------------------------------------------------------

def ingest_placements(session: Session, output: Path) -> None:
    count = 0

    # --- layers_static ---
    ls_path = output / "placements" / "layers_static.json"
    if ls_path.exists():
        data = json.loads(ls_path.read_text())
        batch: list[Placement] = []
        for p in data.get("placements", []):
            try:
                pos = p.get("position", {})
                px, py, pz = pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)
                ue_x, ue_y, ue_z = compute_ue_coords(px, py, pz)
                qx = p.get("rotation_quat_x", 0)
                qy = p.get("rotation_quat_y", 0)
                qz = p.get("rotation_quat_z", 0)
                qw = p.get("rotation_quat_w", 1)

                eid = p.get("entity_id", "")
                ekey = int(eid, 16) if eid.startswith("0x") else None

                placement = Placement(
                    entity_id=eid,
                    entity_key=ekey,
                    entity_name=p.get("entity_name"),
                    block_type="layers_static",
                    source_block=p.get("source"),
                    sub_block=p.get("sub_block"),
                    pos_x=px, pos_y=py, pos_z=pz,
                    quat_x=qx, quat_y=qy, quat_z=qz, quat_w=qw,
                    rotation_y_deg=p.get("rotation_y_deg"),
                    rotation_y_rad=p.get("rotation_y_rad"),
                    has_non_trivial_rotation=has_non_trivial_rotation(qx, qy, qz, qw),
                    ue_pos_x=ue_x, ue_pos_y=ue_y, ue_pos_z=ue_z,
                    ue_yaw=compute_ue_yaw(qy, qw),
                    visibility_default=True,
                    distance_from_origin=compute_distance_from_origin(px, pz),
                    elevation_band=elevation_band(py),
                )
                batch.append(placement)
                if len(batch) >= BATCH_SIZE:
                    session.add_all(batch)
                    session.flush()
                    count += len(batch)
                    batch.clear()
            except Exception:
                log.warning("Skipping bad record in ingest_placements: %s", p.get("entity_id", "?"), exc_info=True)
                try:
                    session.rollback()
                except Exception:
                    pass
                continue

        if batch:
            session.add_all(batch)
            session.flush()
            count += len(batch)
        session.commit()
        log.info("Ingested %d layers_static placements", count)

    # --- vz_state ---
    vz_path = output / "placements" / "vz_state" / "all_vz_state.json"
    if vz_path.exists():
        vz_data = json.loads(vz_path.read_text())
        vz_count = 0

        overlay_manifest_path = output / "placements" / "vz_act_layer_manifest.json"
        overlay_meta: dict = {}
        if overlay_manifest_path.exists():
            manifest = json.loads(overlay_manifest_path.read_text())
            overlay_meta = manifest.get("overlays", {})

        overlay_ids: dict[str, int] = {}

        for source_file, meta in overlay_meta.items():
            parsed = parse_vz_state_name(source_file)
            overlay = VzStateOverlay(
                source_name=source_file,
                source_block_stem=meta.get("stem"),
                faction=parsed.get("faction") or meta.get("faction"),
                stage=parsed.get("stage"),
                parent_kind=meta.get("parent_kind"),
                act=parsed.get("act") or meta.get("act"),
                is_act_overlay=parsed.get("is_act_overlay", False),
                region=meta.get("region"),
                mission_id=parsed.get("mission_id") or meta.get("mission_id"),
                placement_count=meta.get("placement_count"),
                visibility_default=parsed.get("visibility_default"),
            )
            session.add(overlay)
            session.flush()
            overlay_ids[source_file] = overlay.id

        batch_vz: list[Placement] = []
        for p in vz_data.get("placements", []):
            try:
                pos = p.get("position", {})
                px, py, pz = pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)
                ue_x, ue_y, ue_z = compute_ue_coords(px, py, pz)

                eid = p.get("entity_id", "")
                ekey = int(eid, 16) if eid.startswith("0x") else None

                source = p.get("source", "")
                ov_id = overlay_ids.get(source)
                parsed_ov = parse_vz_state_name(source) if not ov_id else {}

                placement = Placement(
                    entity_id=eid,
                    entity_key=ekey,
                    entity_name=p.get("entity_name"),
                    block_type="vz_state",
                    source_block=source,
                    pos_x=px, pos_y=py, pos_z=pz,
                    rotation_y_sin=p.get("rotation_y_sin"),
                    type_hash=p.get("type_hash"),
                    boot_float=p.get("boot_float"),
                    boot_u32=p.get("boot_u32"),
                    vz_state_source=source,
                    vz_state_overlay_id=ov_id,
                    ue_pos_x=ue_x, ue_pos_y=ue_y, ue_pos_z=ue_z,
                    visibility_default=parsed_ov.get("visibility_default", True),
                    distance_from_origin=compute_distance_from_origin(px, pz),
                    elevation_band=elevation_band(py),
                )
                batch_vz.append(placement)
                if len(batch_vz) >= BATCH_SIZE:
                    session.add_all(batch_vz)
                    session.flush()
                    vz_count += len(batch_vz)
                    batch_vz.clear()
            except Exception:
                log.warning("Skipping bad record in ingest_placements: %s", p.get("entity_id", "?"), exc_info=True)
                try:
                    session.rollback()
                except Exception:
                    pass
                continue

        if batch_vz:
            session.add_all(batch_vz)
            session.flush()
            vz_count += len(batch_vz)
        session.commit()
        log.info("Ingested %d vz_state placements, %d overlays", vz_count, len(overlay_ids))


# ---------------------------------------------------------------------------
# ECS records
# ---------------------------------------------------------------------------

def ingest_ecs_records(session: Session, output: Path) -> None:
    ecs_path = output / "placements" / "ecs_components.json"
    if not ecs_path.exists():
        log.warning("No ecs_components.json found")
        return

    data = json.loads(ecs_path.read_text())
    batch: list[EcsRecord] = []
    count = 0

    comp_type_cache: dict[str, int] = {}
    for row in session.execute(text("SELECT id, name FROM ecs_component_types")).all():
        comp_type_cache[row[1]] = row[0]

    for rec in data.get("records", []):
        try:
            comp_name = rec.get("comp_info_name", "")
            ct_id = comp_type_cache.get(comp_name)

            er = EcsRecord(
                entity_key=rec.get("entity_key"),
                comp_type_id=ct_id,
                comp_name=comp_name,
                source_block=rec.get("source"),
                block_type=rec.get("block_type"),
                sub_block=rec.get("sub_block"),
                payload_size=rec.get("payload_size"),
                payload_hex=rec.get("payload_hex"),
                model_name_hash=rec.get("model_name_hash"),
                hibernation_u8_0=rec.get("hibernation_u8_0"),
                hibernation_u8_1=rec.get("hibernation_u8_1"),
                hibernation_f16_or_u16=rec.get("hibernation_f16_or_u16"),
                hibernation_u16_4=rec.get("hibernation_u16_4"),
                script_hash_0=rec.get("script_hash_0"),
                script_u32_1=rec.get("script_u32_1"),
                destruction_ref_key=rec.get("destruction_ref_key"),
                destruction_u32_1=rec.get("destruction_u32_1"),
                light_u32_0=rec.get("light_u32_0"),
                light_color_r=rec.get("light_color_r"),
                light_color_g=rec.get("light_color_g"),
                light_color_b=rec.get("light_color_b"),
                light_intensity=rec.get("light_intensity"),
                light_radius=rec.get("light_radius"),
                light_radius_ue=rec.get("light_radius", 0) * 100 if rec.get("light_radius") else None,
            )
            batch.append(er)
            if len(batch) >= BATCH_SIZE:
                session.add_all(batch)
                session.flush()
                count += len(batch)
                batch.clear()
        except Exception:
            log.warning("Skipping bad record in ingest_ecs_records: %s", rec.get("entity_key", "?"), exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    if batch:
        session.add_all(batch)
        session.flush()
        count += len(batch)
    session.commit()
    log.info("Ingested %d ECS records", count)


# ---------------------------------------------------------------------------
# ASET rows
# ---------------------------------------------------------------------------

def ingest_aset_rows(session: Session, output: Path, wad_ids: dict[str, int]) -> None:
    graph_path = output / "block_dependency_graph.json"
    if not graph_path.exists():
        log.warning("No block_dependency_graph.json found")
        return

    data = json.loads(graph_path.read_text())
    vz_wad_id = wad_ids.get("vz")
    batch: list[AsetRow] = []
    count = 0

    for row in data.get("rows", []):
        try:
            u32_0 = row.get("u32_0", "")
            u32_1 = row.get("u32_1", "")
            ar = AsetRow(
                wad_id=vz_wad_id,
                row_index=row.get("row_index", 0),
                u32_0=u32_0,
                u32_0_int=int(u32_0, 16) if u32_0.startswith("0x") else None,
                u32_1=u32_1,
                u32_1_int=int(u32_1, 16) if u32_1.startswith("0x") else None,
                u32_2=row.get("u32_2"),
                u32_3=row.get("u32_3"),
                texture_index_hit=row.get("texture_index_hit"),
                matched_texture_name=row.get("matched_texture_name"),
            )
            batch.append(ar)
            if len(batch) >= BATCH_SIZE:
                session.add_all(batch)
                session.flush()
                count += len(batch)
                batch.clear()
        except Exception:
            log.warning("Skipping bad record in ingest_aset_rows: %s", row.get("row_index", "?"), exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    if batch:
        session.add_all(batch)
        session.flush()
        count += len(batch)
    session.commit()
    log.info("Ingested %d ASET rows", count)


# ---------------------------------------------------------------------------
# Texture index entries
# ---------------------------------------------------------------------------

def ingest_texture_index(session: Session, output: Path) -> None:
    ti_path = output / "extracted" / "texture_index.json"
    if not ti_path.exists():
        log.warning("No texture_index.json found")
        return

    data = json.loads(ti_path.read_text())
    tex_count = 0
    entry_count = 0
    seen_names: dict[str, int] = {}

    for asset_hash, entries in data.items():
        try:
            hash_int = int(asset_hash, 16) if asset_hash.startswith("0x") else None

            for entry in entries:
                tex_name = entry.get("name")

                if tex_name and tex_name not in seen_names:
                    tex = Texture(
                        name=tex_name,
                        asset_hash=asset_hash,
                        asset_hash_int=hash_int,
                        is_global=tex_name.startswith("global_") if tex_name else None,
                        texture_channel=texture_channel_from_name(tex_name) if tex_name else None,
                        base_texture_name=base_texture_name(tex_name) if tex_name else None,
                        total_size_bytes=entry.get("size"),
                    )
                    session.add(tex)
                    session.flush()
                    seen_names[tex_name] = tex.id
                    tex_count += 1

                tie = TextureIndexEntry(
                    asset_hash=asset_hash,
                    asset_hash_int=hash_int,
                    texture_name=tex_name,
                    source_block_path=entry.get("block"),
                    body_offset=entry.get("body_offset"),
                    body_size=entry.get("size"),
                )
                session.add(tie)
                entry_count += 1

            if entry_count % 500 == 0:
                session.flush()
        except Exception:
            log.warning("Skipping bad record in ingest_texture_index: %s", asset_hash, exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    session.commit()
    log.info("Ingested %d textures, %d texture index entries", tex_count, entry_count)


# ---------------------------------------------------------------------------
# World cells
# ---------------------------------------------------------------------------

def ingest_world_cells(session: Session, output: Path, stem_to_id: dict[str, int]) -> None:
    c3_path = output / "placements" / "c3_cell_manifest.json"
    if not c3_path.exists():
        log.warning("No c3_cell_manifest.json found")
        return

    data = json.loads(c3_path.read_text())
    count = 0
    seen_cell_ids: set[int] = set()
    for cell in data.get("cells", []):
        try:
            cid = cell.get("cell_id")
            if cid in seen_cell_ids:
                continue
            seen_cell_ids.add(cid)
            stem = cell.get("stem", "")
            block_id = stem_to_id.get(stem)
            pos = cell.get("position", {})
            wc = WorldCell(
                cell_id=cid,
                block_id=block_id,
                center_x=pos.get("x"),
                center_y=pos.get("y"),
                center_z=pos.get("z"),
                vertex_count=cell.get("vertices"),
                has_glb=cell.get("has_glb"),
                has_gltf=cell.get("has_gltf"),
            )
            session.add(wc)
            count += 1
            if count % 2000 == 0:
                session.flush()
        except Exception:
            log.warning("Skipping bad record in ingest_world_cells: %s", cell.get("cell_id", "?"), exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    session.commit()
    log.info("Ingested %d world cells (%d duplicates skipped)", count, len(data.get("cells", [])) - count)


# ---------------------------------------------------------------------------
# Animations, skeletons, bones
# ---------------------------------------------------------------------------

def ingest_animations(session: Session, output: Path) -> None:
    anim_work = output / "animations_work"
    anim_out = output / "animations"
    if not anim_work.is_dir():
        log.warning("No animations_work/ directory")
        return

    group_count = 0
    clip_count = 0
    skel_count = 0
    bone_count = 0

    for slug_dir in sorted(anim_work.iterdir()):
        if not slug_dir.is_dir():
            continue
        try:
            manifest_path = slug_dir / "manifest.json"
            clips_path = slug_dir / "clips_manifest.json"
            skel_path = slug_dir / "skeleton.json"

            if not manifest_path.exists():
                continue

            try:
                manifest = json.loads(manifest_path.read_text())
            except (json.JSONDecodeError, OSError):
                continue

            slug = manifest.get("slug", slug_dir.name)
            glb_path = manifest.get("glb")

            ag = AnimationGroup(
                slug=slug,
                block_stem=manifest.get("block"),
                stem_numeric_id=manifest.get("stem_numeric_id"),
                clip_count=manifest.get("clips"),
                glb_path=glb_path,
                related_review_keys=json_for_pg(manifest.get("related_review_keys")),
            )
            session.add(ag)
            session.flush()
            group_count += 1

            if clips_path.exists():
                try:
                    clips_data = json.loads(clips_path.read_text())
                except (json.JSONDecodeError, OSError):
                    clips_data = {}

                for clip in clips_data.get("clips", []):
                    ac = AnimationClip(
                        animation_group_id=ag.id,
                        record_index=clip.get("record_index"),
                        gltf_clip_index=clip.get("gltf_clip_index"),
                        display_name=clip.get("display_name"),
                        gltf_name=clip.get("gltf_name"),
                        anim_name_guess=clip.get("anim_name_guess"),
                        codec_guess=clip.get("codec_guess"),
                        pelvis_ty_spread_wavelet_raw=clip.get("pelvis_ty_spread_wavelet_raw"),
                        pelvis_ty_spread_after_sanitize=clip.get("pelvis_ty_spread_after_sanitize"),
                        pelvis_ty_sanitized=json_for_pg(clip.get("pelvis_ty_sanitized")),
                    )
                    session.add(ac)
                    clip_count += 1

            if skel_path.exists():
                try:
                    skel_data = json.loads(skel_path.read_text())
                except (json.JSONDecodeError, OSError):
                    skel_data = {}

                bone_names = skel_data.get("bone_names", [])
                parent_indices = skel_data.get("parent_indices", [])
                ref_pose = skel_data.get("reference_pose", [])

                sk = Skeleton(
                    animation_group_id=ag.id,
                    bone_count=skel_data.get("bone_count", len(bone_names)),
                    source=skel_data.get("source", "ucfx_hier"),
                    track_count=skel_data.get("track_count"),
                    ancestor_count=skel_data.get("ancestor_count"),
                )
                session.add(sk)
                session.flush()
                skel_count += 1

                for bi, bname in enumerate(bone_names):
                    parent_idx = parent_indices[bi] if bi < len(parent_indices) else -1
                    rp = ref_pose[bi] if bi < len(ref_pose) else None
                    if isinstance(rp, dict):
                        rp_vals = (rp.get("tx"), rp.get("ty"), rp.get("tz"),
                                   rp.get("qx"), rp.get("qy"), rp.get("qz"), rp.get("qw"),
                                   rp.get("sx"), rp.get("sy"), rp.get("sz"))
                    elif isinstance(rp, (list, tuple)) and len(rp) >= 10:
                        rp_vals = tuple(rp[:10])
                    else:
                        rp_vals = (None,) * 10
                    bone = Bone(
                        skeleton_id=sk.id,
                        bone_index=bi,
                        bone_name=bname,
                        parent_index=parent_idx,
                        ref_pos_x=rp_vals[0],
                        ref_pos_y=rp_vals[1],
                        ref_pos_z=rp_vals[2],
                        ref_quat_x=rp_vals[3],
                        ref_quat_y=rp_vals[4],
                        ref_quat_z=rp_vals[5],
                        ref_quat_w=rp_vals[6],
                        ref_scale_x=rp_vals[7],
                        ref_scale_y=rp_vals[8],
                        ref_scale_z=rp_vals[9],
                    )
                    session.add(bone)
                    bone_count += 1

            if group_count % 50 == 0:
                session.flush()
        except Exception:
            log.warning("Skipping bad record in ingest_animations: %s", slug_dir.name, exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    session.commit()
    log.info(
        "Ingested %d animation groups, %d clips, %d skeletons, %d bones",
        group_count, clip_count, skel_count, bone_count,
    )


# ---------------------------------------------------------------------------
# Lua chunks
# ---------------------------------------------------------------------------

def ingest_lua_chunks(session: Session, output: Path, stem_to_id: dict[str, int]) -> None:
    harvest_path = output / "placements" / "pmc_lua_string_harvest.json"
    if not harvest_path.exists():
        log.warning("No pmc_lua_string_harvest.json found")
        return

    data = json.loads(harvest_path.read_text())
    count = 0

    scripts_block_id = None
    for stem, bid in stem_to_id.items():
        if "scripts_vz" in stem.lower():
            scripts_block_id = bid
            break

    for chunk in data.get("chunks", []):
        try:
            lc = LuaChunk(
                block_id=scripts_block_id,
                chunk_index=chunk.get("chunk_index"),
                byte_offset=chunk.get("byte_offset"),
                byte_length=chunk.get("byte_length"),
                bin_path=chunk.get("bin_path"),
                string_count=chunk.get("string_count"),
                pmc_related_strings=json_for_pg(chunk.get("pmc_related_strings")),
            )
            session.add(lc)
            count += 1
            if count % 500 == 0:
                session.flush()
        except Exception:
            log.warning("Skipping bad record in ingest_lua_chunks: %s", chunk.get("chunk_index", "?"), exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    session.commit()
    log.info("Ingested %d Lua chunks", count)


# ---------------------------------------------------------------------------
# ECS component types (from cdbsizes.ini)
# ---------------------------------------------------------------------------

def ingest_ecs_component_types(session: Session, repo_root: Path) -> None:
    """Seed ECS component types from cdbsizes.ini."""
    candidates = [
        repo_root / "output" / "data" / "cdbsizes.ini",
        repo_root / "Mercenaries 2 World in Flames DEMO" / "data" / "cdbsizes.ini",
    ]
    ini_path = None
    for c in candidates:
        if c.exists():
            ini_path = c
            break

    if not ini_path:
        log.warning("No cdbsizes.ini found, skipping ECS component types")
        return

    existing = {
        r[0]
        for r in session.execute(text("SELECT name FROM ecs_component_types")).all()
    }

    count = 0
    for line in ini_path.read_text().splitlines():
        try:
            line = line.strip()
            if not line or line.startswith("[") or line.startswith(";") or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) < 2:
                continue
            name = parts[0]
            if name in existing:
                continue
            primary = int(parts[1])
            secondary = int(parts[2]) if len(parts) > 2 else None
            is_runtime = name.startswith("Runtime") or name.startswith("Rt")

            ct = EcsComponentType(
                name=name,
                prealloc_primary=primary,
                prealloc_secondary=secondary,
                is_runtime=is_runtime,
            )
            session.add(ct)
            existing.add(name)
            count += 1
        except Exception:
            log.warning("Skipping bad record in ingest_ecs_component_types: %s", line, exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    session.commit()
    log.info("Ingested %d ECS component types from cdbsizes.ini", count)


# ---------------------------------------------------------------------------
# Precache slots
# ---------------------------------------------------------------------------

def ingest_precache_slots(session: Session, output: Path) -> None:
    precache_dir = output / "Precache"
    if not precache_dir.is_dir():
        log.warning("No Precache/ directory found")
        return

    count = 0
    for entry in sorted(precache_dir.iterdir()):
        if not entry.is_dir():
            continue
        m = re.match(r"^(\d+)$", entry.name)
        if not m:
            continue
        slot_num = int(m.group(1))
        sizes: dict[str, int] = {}
        for f in entry.iterdir():
            if f.is_file():
                key = f.stem.lower()
                sizes[key] = f.stat().st_size

        ps = PrecacheSlot(
            slot_number=slot_num,
            vertex_size=sizes.get("vertex"),
            index_size=sizes.get("index"),
            display_size=sizes.get("display"),
            texture_size=sizes.get("texture"),
            surface_size=sizes.get("surface"),
            pshader_size=sizes.get("pshader"),
            vshader_size=sizes.get("vshader"),
            vertdecl_size=sizes.get("vertdecl"),
            total_size=sum(sizes.values()) if sizes else None,
        )
        session.add(ps)
        count += 1

    session.commit()
    log.info("Ingested %d precache slots", count)


# ---------------------------------------------------------------------------
# Variant registry enrichment
# ---------------------------------------------------------------------------

def enrich_variant_registry(session: Session, output: Path) -> None:
    vr_path = output / "variant_registry.json"
    if not vr_path.exists():
        return

    data = json.loads(vr_path.read_text())
    count = 0
    for entry in data.get("entries", []):
        try:
            stem = entry.get("stem")
            if not stem:
                continue
            result = session.execute(
                text("UPDATE blocks SET variant_type = :vt, variant_tags = :tags, "
                     "base_asset_id = COALESCE(base_asset_id, :ba), "
                     "texture_channel_hint = COALESCE(texture_channel_hint, :tch) "
                     "WHERE stem LIKE :pattern"),
                {
                    "vt": entry.get("variant_type"),
                    "tags": json.dumps(json_for_pg(entry.get("variant_tags"))),
                    "ba": entry.get("base_asset_id"),
                    "tch": entry.get("texture_channel_hint"),
                    "pattern": f"%{stem}%",
                },
            )
            count += result.rowcount
        except Exception:
            log.warning("Skipping bad record in enrich_variant_registry: %s", entry.get("stem", "?"), exc_info=True)
            try:
                session.rollback()
            except Exception:
                pass
            continue

    session.commit()
    log.info("Enriched %d blocks from variant_registry", count)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingest all Mercenaries 2 pipeline data into the asset database"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("../output"),
        help="Pipeline output root (default: ../output)",
    )
    parser.add_argument(
        "--database-url",
        default=os.environ.get(
            "MERCS2_DATABASE_URL_SYNC",
            "postgresql+psycopg2://mercs2:mercs2@localhost:5432/mercs2",
        ),
        help="Sync SQLAlchemy database URL (or set MERCS2_DATABASE_URL_SYNC env var)",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(".."),
        help="Repository root (for cdbsizes.ini, SaveGames/)",
    )
    parser.add_argument(
        "--skip",
        nargs="*",
        default=[],
        help="Steps to skip (wads, mesh, dialog, placements, ecs, aset, textures, "
             "cells, animations, lua, precache, variants)",
    )
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)-5s %(name)s: %(message)s",
        datefmt="%H:%M:%S",
    )

    output = args.output.resolve()
    repo_root = args.repo_root.resolve()
    skip = set(args.skip)

    log.info("Output root: %s", output)
    log.info("Repo root:   %s", repo_root)
    t0 = time.time()

    session = make_session(args.database_url)

    try:
        if "ecs_types" not in skip:
            log.info("=== Ingesting ECS component types ===")
            ingest_ecs_component_types(session, repo_root)

        wad_ids: dict[str, int] = {}
        if "wads" not in skip:
            log.info("=== Ingesting WAD manifests + blocks ===")
            wad_ids = ingest_wad_manifests(session, output)
        else:
            for r in session.execute(text("SELECT name, id FROM wad_archives")).all():
                wad_ids[r[0]] = r[1]

        stem_to_id = build_stem_lookup(session)
        log.info("Block lookup: %d entries", len(stem_to_id))

        if "mesh" not in skip:
            log.info("=== Ingesting mesh metadata + submeshes ===")
            ingest_mesh_metadata(session, output, stem_to_id)

        if "dialog" not in skip:
            log.info("=== Ingesting dialog fragments ===")
            ingest_dialog_fragments(session, output, stem_to_id)

        if "placements" not in skip:
            log.info("=== Ingesting placements ===")
            ingest_placements(session, output)

        if "ecs" not in skip:
            log.info("=== Ingesting ECS records ===")
            ingest_ecs_records(session, output)

        if "aset" not in skip:
            log.info("=== Ingesting ASET rows ===")
            ingest_aset_rows(session, output, wad_ids)

        if "textures" not in skip:
            log.info("=== Ingesting texture index ===")
            ingest_texture_index(session, output)

        if "cells" not in skip:
            log.info("=== Ingesting world cells ===")
            ingest_world_cells(session, output, stem_to_id)

        if "animations" not in skip:
            log.info("=== Ingesting animations ===")
            ingest_animations(session, output)

        if "lua" not in skip:
            log.info("=== Ingesting Lua chunks ===")
            ingest_lua_chunks(session, output, stem_to_id)

        if "precache" not in skip:
            log.info("=== Ingesting precache slots ===")
            ingest_precache_slots(session, output)

        if "variants" not in skip:
            log.info("=== Enriching variant registry ===")
            enrich_variant_registry(session, output)

    finally:
        session.close()

    elapsed = time.time() - t0
    log.info("Ingest complete in %.1fs", elapsed)


if __name__ == "__main__":
    main()
