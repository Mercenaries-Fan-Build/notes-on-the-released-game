"""Report world-cell actor transforms vs expected c3 grid positions.

Run in UE5 Editor after populate_world (Tools → Execute Python Script).
Use when buildings appear as a thin horizontal/vertical strip in top-down view.
"""

from __future__ import annotations

import importlib
import os
import sys

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_c3_grid as c3grid
import mercs2_coords as coords

importlib.reload(c3grid)
importlib.reload(coords)

LOG = "[Mercs2CellDiag]"


def _log(msg: str) -> None:
    unreal.log(f"{LOG} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG} {msg}")


def _cell_actors() -> list[unreal.StaticMeshActor]:
    out: list[unreal.StaticMeshActor] = []
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        actors = list(sub.get_all_level_actors())
    except Exception:
        actors = list(unreal.EditorLevelLibrary.get_all_level_actors())
    for actor in actors:
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        try:
            folder = str(actor.get_folder_path())
        except Exception:
            folder = ""
        if folder.startswith("World/Cells") or "Cell_c3" in actor.get_actor_label():
            out.append(actor)
    return out


def run() -> None:
    ok, detail = c3grid.verify_grid_logic()
    _log(f"grid self-test: {'OK' if ok else 'FAIL'} — {detail}")
    if not ok:
        _warn("Restart UE Editor and re-run populate from this repo's game-scripts/.")

    actors = _cell_actors()
    _log(f"found {len(actors)} World/Cells actors")
    if not actors:
        _warn("No cell actors — run import_world + populate_world with MERCS2_POPULATE_WORLD_CELLS=1")
        return

    xs: list[float] = []
    ys: list[float] = []
    mismatches = 0
    samples_logged = 0
    for actor in actors[:2000]:
        label = actor.get_actor_label()
        cid = c3grid.cell_id_from_actor_label(label) or c3grid.cell_id_from_asset_path(
            label
        )
        if cid is None:
            continue
        gx, gy, gz = c3grid.cell_id_to_world_xyz(cid)
        ex, ey, ez = coords.game_to_ue(gx, gy, gz)
        loc = actor.get_actor_location()
        xs.append(loc.x)
        ys.append(loc.y)
        dz = abs(loc.z - ez)
        if abs(loc.x - ex) > 500.0 or abs(loc.y - ey) > 500.0 or dz > 500.0:
            mismatches += 1
            if mismatches <= 8:
                _warn(
                    f"{label}: Details=({loc.x:.0f},{loc.y:.0f},{loc.z:.0f}) "
                    f"expected_ue=({ex:.0f},{ey:.0f},{ez:.0f}) "
                    f"game_m=({gx:.1f},{gy:.1f},{gz:.1f}) id={cid}"
                )
        elif samples_logged < 3:
            _log(
                f"sample {label}: Details=({loc.x:.0f},{loc.y:.0f},{loc.z:.0f}) "
                f"game_m=({gx:.1f},{gy:.1f},{gz:.1f})"
            )
            samples_logged += 1

    if not xs:
        _warn("No Cell_c3* labels decoded — check actor labels / folder paths")
        return

    span_x = max(xs) - min(xs)
    span_y = max(ys) - min(ys)
    _log(
        f"UE spread: X span={span_x:.0f} cm [{min(xs):.0f}..{max(xs):.0f}], "
        f"Y span={span_y:.0f} cm [{min(ys):.0f}..{max(ys):.0f}], "
        f"transform mismatches>{500}cm: {mismatches}"
    )
    unique_y = len({round(y, -2) for y in ys})
    _log(f"unique UE Y buckets (~1 m): {unique_y} (game north–south / Details Y)")

    if span_x < 500_000 and span_y < 500_000:
        _warn("Both spans tiny — strip/cluster bug (stale Python or transforms not applied).")
    elif span_y < 500_000:
        _warn("Y span tiny — likely one grid row (old c3#### decode). Restart UE + repopulate.")
    elif unique_y < 20:
        _warn(
            f"Only {unique_y} distinct UE Y values across {len(xs)} actors — "
            "actor origins cluster north–south; check import/populate counts."
        )
    else:
        _log(
            "Actor origins span X and Y — axis swap looks correct. "
            "If buildings still look like a strip, mesh pivots may be world-baked in GLB "
            "(re-run stage 2 / regen GLBs) or only a subset of cells imported."
        )


if __name__ == "__main__":
    run()
