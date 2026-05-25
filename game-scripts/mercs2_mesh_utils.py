"""Shared StaticMesh helpers for Mercenaries 2 editor scripts.

Interchange enables Nanite on imported glTF by default. Thousands of world-cell
meshes will exhaust the Nanite root-page pool (~49k pages / 2GB) and crash the
editor. Always disable Nanite on pipeline-imported environment meshes.
"""

from __future__ import annotations

import unreal

_LOG_PREFIX = "[Mercs2Mesh]"


def _log(msg: str) -> None:
    unreal.log(f"{_LOG_PREFIX} {msg}")


def disable_nanite_on_static_mesh(mesh: unreal.StaticMesh | None) -> bool:
    """Turn off Nanite on a StaticMesh asset. Returns True if a change was applied."""
    if mesh is None or not isinstance(mesh, unreal.StaticMesh):
        return False

    changed = False
    try:
        ns = mesh.get_editor_property("nanite_settings")
        if ns is not None:
            if ns.get_editor_property("enabled"):
                ns.set_editor_property("enabled", False)
                changed = True
    except Exception:
        pass

    if not changed:
        try:
            ns = unreal.MeshNaniteSettings()
            ns.set_editor_property("enabled", False)
            mesh.set_editor_property("nanite_settings", ns)
            changed = True
        except Exception:
            pass

    if changed:
        try:
            mesh.mark_package_dirty()
        except Exception:
            pass
    return changed


def disable_nanite_on_mesh_path(mesh_path: str) -> bool:
    """Load a mesh by content path and disable Nanite."""
    if not mesh_path:
        return False
    mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
    return disable_nanite_on_static_mesh(mesh)  # type: ignore[arg-type]


def disable_nanite_on_static_mesh_component(comp: unreal.StaticMeshComponent | None) -> None:
    """Force a placed actor to render without Nanite when possible."""
    if comp is None:
        return
    for prop in (
        "bDisallowNanite",
        "disallow_nanite",
        "force_disable_nanite",
        "enable_nanite",
    ):
        try:
            if prop == "enable_nanite":
                comp.set_editor_property(prop, False)
            else:
                comp.set_editor_property(prop, True)
        except Exception:
            continue


def bulk_disable_nanite_under(
    content_path: str,
    *,
    limit: int = 0,
    save: bool = True,
) -> tuple[int, int]:
    """Disable Nanite on every StaticMesh under *content_path*.

    Returns ``(scanned, changed)``.
    """
    if not unreal.EditorAssetLibrary.does_directory_exist(content_path):
        return 0, 0

    scanned = 0
    changed = 0
    for asset_path in unreal.EditorAssetLibrary.list_assets(
        content_path, recursive=True, include_folder=False,
    ):
        obj = unreal.EditorAssetLibrary.load_asset(str(asset_path))
        if obj is None or not isinstance(obj, unreal.StaticMesh):
            continue
        scanned += 1
        if disable_nanite_on_static_mesh(obj):
            changed += 1
        if limit and scanned >= limit:
            break

    if save and changed:
        try:
            unreal.EditorAssetLibrary.save_directory(content_path, only_if_is_dirty=True)
        except Exception:
            pass

    return scanned, changed


def configure_imported_mesh(mesh: unreal.StaticMesh | None) -> None:
    """Post-import hook: disable Nanite on pipeline meshes."""
    if disable_nanite_on_static_mesh(mesh):
        return
    _log("Could not disable Nanite on imported mesh (API mismatch)")
