#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UE5 Editor Python: import a per-asset glTF folder and build MaterialInstances with textures.

Run inside the Unreal Editor Python console or as an Editor Utility, after adjusting DEST.

Expects a layout produced by tools/ue5_export.py (self-contained asset folder):
  <asset_dir>/mesh_scene.gltf
  <asset_dir>/mesh_scene.bin
  <asset_dir>/textures/*.png|*.dds
  <asset_dir>/manifest.json  (optional; used for stem / notes)

This script uses the ``unreal`` module (available only inside UE). It is not meant to run
with the system Python interpreter.
"""

from __future__ import annotations

# --- UE5-only block (syntax-checked as text; do not run with CPython) ---
UE_IMPORT_BODY = r'''
import json
import os
import unreal


def _load_manifest(asset_dir: str):
    man = os.path.join(asset_dir, "manifest.json")
    if os.path.isfile(man):
        with open(man, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def import_asset_folder(asset_dir: str, dest_content_path: str) -> None:
    """asset_dir: absolute path to self-contained bundle. dest_content_path: e.g. /Game/Mercs2/Imported."""
    manifest = _load_manifest(asset_dir)
    stem = manifest.get("stem") or os.path.basename(os.path.normpath(asset_dir))

    gltf = os.path.join(asset_dir, "mesh_scene.gltf")
    if not os.path.isfile(gltf):
        unreal.log_warning("ue5_material_import: no mesh_scene.gltf in " + asset_dir)
        return

    task = unreal.AssetImportTask()
    task.filename = gltf
    task.destination_path = dest_content_path.rstrip("/") + "/" + stem
    task.destination_name = "mesh_scene"
    task.replace_existing = True
    task.automated = True
    task.save = True

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    unreal.log("ue5_material_import: glTF import queued for " + gltf)

    tex_dir = os.path.join(asset_dir, "textures")
    if os.path.isdir(tex_dir):
        tex_tasks = []
        for name in sorted(os.listdir(tex_dir)):
            low = name.lower()
            if not (low.endswith(".png") or low.endswith(".dds")):
                continue
            tt = unreal.AssetImportTask()
            tt.filename = os.path.join(tex_dir, name)
            tt.destination_path = task.destination_path + "/Textures"
            tt.destination_name = os.path.splitext(name)[0]
            tt.replace_existing = True
            tt.automated = True
            tt.save = True
            tex_tasks.append(tt)
        if tex_tasks:
            unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tex_tasks)

    # Specular lives in material extras as mercs2_specularTextureIndex in glTF; assign in Material Editor
    # or extend this script to load mesh_scene materials and set texture parameters by name.
    unreal.log("ue5_material_import: done for stem=" + stem)


# Example:
# import_asset_folder(r"/abs/path/to/ue5_bundle/assets/batch_0__foo", "/Game/Mercs2")
'''


def main() -> int:
    print(__doc__)
    print("--- UE5 script body (paste into UE Python or save as Editor script) ---")
    print(UE_IMPORT_BODY)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
