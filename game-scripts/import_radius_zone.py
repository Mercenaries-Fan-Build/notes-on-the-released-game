"""Import GLBs for a radius zone into UE (see ``output/radius_zones/<zone_id>/``).

Run ``make filter-pool-200m`` first, then execute this script in the UE editor.
"""

from __future__ import annotations

import importlib
import os
import sys

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_radius_zone as rz


def main() -> None:
    zpath = rz.zone_json_path()
    if not zpath.is_file():
        print(f"[RadiusImport] zone.json not found: {zpath}", flush=True)
        print("[RadiusImport] Run: make filter-pool-200m OUTPUT=./output", flush=True)
        return

    zone = rz.load_zone(zpath)
    asset_rel = zone.get("paths", {}).get("asset_list", "")
    if not asset_rel:
        print("[RadiusImport] zone.json missing paths.asset_list", flush=True)
        return

    asset_path = rz.resolve_data_path(asset_rel, zpath)
    if not asset_path.is_file():
        print(f"[RadiusImport] Asset list not found: {asset_path}", flush=True)
        return

    os.environ["MERCS2_ASSET_LIST"] = str(asset_path)
    os.environ["MERCS2_MESH_ROOT"] = zone.get(
        "ue_mesh_root", "/Game/Mercs2/Meshes/RadiusZones/pool_200m",
    )

    import import_pmc_base as imp

    importlib.reload(imp)
    imp.run_import()


if __name__ == "__main__":
    main()
