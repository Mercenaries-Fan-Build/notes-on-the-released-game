"""Editor actor lookup and idempotent spawn helpers for Mercs2 populate scripts.

UE 5.7 can return actor labels as Name/str; duplicate labels get _2/_3 suffixes.
Build an ActorLabelIndex once per populate run and reuse actors by stable label.
"""

from __future__ import annotations

import re
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from collections.abc import Iterable

import mercs2_data_layers as m2dl
import mercs2_mesh_utils as mesh_utils

_DUP_SUFFIX_RE = re.compile(r"^(.+)_(\d+)$")


def normalize_label_key(label: str | unreal.Name | None) -> str:
    """Normalize a label for dict lookup (str strip; Name → str)."""
    if label is None:
        return ""
    return str(label).strip()


def get_actor_label(actor: unreal.Actor) -> str:
    """Return the Outliner label for *actor*, or \"\" on failure."""
    try:
        return normalize_label_key(actor.get_actor_label())
    except Exception:
        return ""


def iter_all_level_actors() -> list[unreal.Actor]:
    """All actors in the current editor level (EditorActorSubsystem + legacy fallback)."""
    merged: list[unreal.Actor] = []
    seen: set[int] = set()

    def _extend(batch: object) -> None:
        try:
            for actor in batch:  # type: ignore[union-attr]
                oid = id(actor)
                if oid in seen:
                    continue
                seen.add(oid)
                merged.append(actor)
        except TypeError:
            pass

    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        _extend(sub.get_all_level_actors())
    except Exception:
        pass
    try:
        _extend(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception:
        pass
    return merged


class ActorLabelIndex:
    """Map actor labels → actors for O(1) idempotent populate lookups."""

    def __init__(self) -> None:
        self._by_label: dict[str, unreal.Actor] = {}

    @classmethod
    def build(cls, actors: Iterable[unreal.Actor] | None = None) -> ActorLabelIndex:
        idx = cls()
        source = list(actors) if actors is not None else iter_all_level_actors()
        for actor in source:
            idx.register(actor)
        return idx

    def register(self, actor: unreal.Actor) -> None:
        label = get_actor_label(actor)
        if label and label not in self._by_label:
            self._by_label[label] = actor

    def remember(self, actor: unreal.Actor, label: str) -> None:
        key = normalize_label_key(label)
        if key:
            self._by_label[key] = actor

    def find(self, label: str) -> unreal.Actor | None:
        key = normalize_label_key(label)
        if not key:
            return None
        hit = self._by_label.get(key)
        if hit is not None:
            return hit
        best_n: int | None = None
        best_actor: unreal.Actor | None = None
        prefix = key + "_"
        for existing_label, actor in self._by_label.items():
            if not existing_label.startswith(prefix):
                continue
            m = _DUP_SUFFIX_RE.match(existing_label)
            if m is None or m.group(1) != key:
                continue
            n = int(m.group(2))
            if best_n is None or n < best_n:
                best_n = n
                best_actor = actor
        return best_actor

    def __len__(self) -> int:
        return len(self._by_label)


def find_actor_by_label(
    label: str,
    index: ActorLabelIndex | None = None,
) -> unreal.Actor | None:
    if index is not None:
        return index.find(label)
    return ActorLabelIndex.build().find(label)


def actor_exists(label: str, index: ActorLabelIndex | None = None) -> bool:
    return find_actor_by_label(label, index) is not None


def _apply_actor_folder_and_visibility(
    actor: unreal.Actor,
    label: str,
    folder: str,
    editor_hidden: bool,
) -> None:
    try:
        actor.set_actor_label(label)
    except Exception:
        pass
    try:
        actor.set_folder_path(folder)
    except Exception:
        pass
    try:
        actor.set_is_temporarily_hidden_in_editor(editor_hidden)
    except Exception:
        pass


def configure_static_mesh_actor(
    actor: unreal.StaticMeshActor,
    mesh_path: str,
    loc: unreal.Vector,
    rot: unreal.Rotator,
    scale: unreal.Vector,
    label: str,
    folder: str,
    data_layer: unreal.DataLayerInstance | None,
    editor_hidden: bool = False,
) -> unreal.StaticMeshActor:
    mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
    if mesh is not None:
        mesh_utils.disable_nanite_on_static_mesh(mesh)  # type: ignore[arg-type]
        actor.static_mesh_component.set_static_mesh(mesh)
        mesh_utils.disable_nanite_on_static_mesh_component(
            actor.static_mesh_component,
        )

    actor.set_actor_location(loc, False, False)
    actor.set_actor_rotation(rot, False)
    actor.set_actor_scale3d(scale)
    _apply_actor_folder_and_visibility(actor, label, folder, editor_hidden)
    m2dl.add_actor_to_data_layer_if_any(actor, data_layer)
    return actor


def place_or_update_static_mesh(
    spawn_fn,
    mesh_path: str,
    loc: unreal.Vector,
    rot: unreal.Rotator,
    scale: unreal.Vector,
    label: str,
    folder: str,
    data_layer: unreal.DataLayerInstance | None,
    editor_hidden: bool = False,
    *,
    label_index: ActorLabelIndex | None = None,
) -> tuple[unreal.StaticMeshActor | None, bool]:
    """Return (actor, created). *created* is False when an existing actor was updated."""
    existing = find_actor_by_label(label, label_index)
    if existing is not None:
        if not isinstance(existing, unreal.StaticMeshActor):
            existing = None
        else:
            configure_static_mesh_actor(
                existing,
                mesh_path,
                loc,
                rot,
                scale,
                label,
                folder,
                data_layer,
                editor_hidden,
            )
            if label_index is not None:
                label_index.remember(existing, label)
            return existing, False

    actor = spawn_fn(unreal.StaticMeshActor, loc, rot)
    if actor is None:
        return None, True
    configure_static_mesh_actor(
        actor,
        mesh_path,
        loc,
        rot,
        scale,
        label,
        folder,
        data_layer,
        editor_hidden,
    )
    if label_index is not None:
        label_index.remember(actor, label)
    return actor, True


def configure_point_light_actor(
    actor: unreal.PointLight,
    loc: unreal.Vector,
    light_color: unreal.Color,
    intensity: float,
    attenuation_radius_ue: float,
    label: str,
    folder: str,
    data_layer: unreal.DataLayerInstance | None,
    editor_hidden: bool = False,
) -> unreal.PointLight:
    actor.set_actor_location(loc, False, False)
    comp = actor.point_light_component
    comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
    comp.set_editor_property("light_color", light_color)
    comp.set_editor_property("intensity", intensity)
    comp.set_editor_property("attenuation_radius", attenuation_radius_ue)
    _apply_actor_folder_and_visibility(actor, label, folder, editor_hidden)
    m2dl.add_actor_to_data_layer_if_any(actor, data_layer)
    return actor


def place_or_update_point_light(
    spawn_fn,
    loc: unreal.Vector,
    light_color: unreal.Color,
    intensity: float,
    attenuation_radius_ue: float,
    label: str,
    folder: str,
    data_layer: unreal.DataLayerInstance | None,
    editor_hidden: bool = False,
    *,
    label_index: ActorLabelIndex | None = None,
) -> tuple[unreal.PointLight | None, bool]:
    """Return (actor, created)."""
    existing = find_actor_by_label(label, label_index)
    if existing is not None:
        if not isinstance(existing, unreal.PointLight):
            existing = None
        else:
            configure_point_light_actor(
                existing,
                loc,
                light_color,
                intensity,
                attenuation_radius_ue,
                label,
                folder,
                data_layer,
                editor_hidden,
            )
            if label_index is not None:
                label_index.remember(existing, label)
            return existing, False

    actor = spawn_fn(unreal.PointLight, loc, unreal.Rotator())
    if actor is None:
        return None, True
    configure_point_light_actor(
        actor,
        loc,
        light_color,
        intensity,
        attenuation_radius_ue,
        label,
        folder,
        data_layer,
        editor_hidden,
    )
    if label_index is not None:
        label_index.remember(actor, label)
    return actor, True
