#!/usr/bin/env python3
"""Build a rainbow hash table for pandemic_hash_m2 (Mercenaries 2 FNV-1a variant).

Computes pandemic_hash_m2() for thousands of candidate strings drawn from:
- All 114 retail script names
- All 11,370 block path stems from vz.wad
- Known type names (texture, model, script, etc.)
- ECS component names
- Engine class/module names (Mrx*, Wif*, Red*, Pbl*)
- Lua 5.1 builtins and standard library
- Character names, faction names, location names
- Weapon/vehicle/item names
- Pandemic Studios credits and EA-era strings
- Systematic permutations (prefixes, suffixes, numbering)
- ECS/reflection component class names (docs/mercs2-ecs registry, ~232 classes)
- Reflection property/field names + enum members (weapon stats, etc.)
- Identifier strings harvested from the game EXE .rdata/.data sections
- Identifier + string-literal tokens from the decompiled Lua corpus (370 scripts)
- The Saboteur (sibling Pandemic engine) blueprint stat vocabulary

Output: tools/rainbow_table.json — maps hex hash strings to input strings.
        Also prints stats on which unknown hashes from the type registry were cracked.

Usage:
    python build_rainbow_table.py [--wad game-files/vz.wad] [--output tools/rainbow_table.json]
"""
from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandemic_hash import pandemic_hash, pandemic_hash_m2  # noqa: E402

# Keep console output ASCII-safe on cp1252 (Windows) terminals.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent.parent


def gather_ecs_registry_names() -> set[str]:
    """ECS/reflection component class names recovered from the EXE reflection
    registry (docs/mercs2-ecs/_registry_raw.tsv, ~232 classes)."""
    out: set[str] = set()
    tsv = ROOT / "docs" / "mercs2-ecs" / "_registry_raw.tsv"
    if tsv.is_file():
        for line in tsv.read_text(encoding="utf-8", errors="ignore").splitlines():
            name = line.split("\t", 1)[0].strip()
            if name:
                out.add(name)
        print(f"  Loaded {len(out)} ECS class names from registry")
    return out


def gather_reflection_field_names() -> set[str]:
    """Reflection property/field names + enum members recovered from EXE rodata
    during the ECS component RE. These are the hash-keyed stat fields that
    appear in wpn_*/ECS data blocks (the values a blueprint editor would name)."""
    weapon_fields = [
        "iClipSize", "MaxAmmoReserve", "MaxAmmoReserveModifier",
        "iBulletsPerShot", "iRoundsPerReload", "RateOfFire", "iTracerRound",
        "iHideMagazineOnFire", "FireType", "SpecialCaseType", "AmmoTemplate",
        "FireFromReticle", "FirstMagazine", "iMultipleMagazines",
        "MaxAimAngle", "MaxAimAngleAi", "LowSkillScatter", "CenterBias",
        "ScatterAimModeMin", "ScatterAimModeMax", "ScatterMin", "ScatterMax",
        "ScatterPerShot", "RifleSkill", "PhysicalRecoil",
        "MuzzleFlashHardpoint", "MuzzleFlashTemplate", "ShellEjectHardpoint",
        "ShellTemplate", "Velocity", "MinVelocity", "MaxVelocity",
        "Accel", "AccelTime", "HumanBoost", "Damage", "DamageDropoff",
        "DamageDropoffStart", "DamageDropoffStop", "DamageMinimum",
        "HeroMultiplier", "Multiplier", "MaxAge", "MaxForce",
        "MinForceFalloff", "DetonationDistance", "LockOnMinWeight",
        "LockOnMaxAngle", "LockOnMaxDistance", "LockOnTime", "TurnSpeed",
        "BurstOnLength", "BurstOffLength", "BurstOnCloseLength",
        "BurstOffCloseLength", "ChargeTime", "SingleShotWeapon",
        "ReticlePitchLowest", "ReticlePitchMiddle", "ReticlePitchHighest",
        "VelocityAtLowestPitch", "VelocityAtMiddlePitch",
        "VelocityAtHighestPitch", "ThrowAngle", "GravityScale", "bCook",
        "ReticleTexture", "ReticleType", "ReticleHealthType", "ScopeType",
        "MinZoomLevel", "MaxZoomLevel", "ZoomMultiplier", "StartingZoom",
    ]
    other_fields = [
        # AI / perception / population (ECS family 02)
        "AiSkill", "Squad", "Perception", "Stimulus", "StimulusModifier",
        # road / lane graph (family 06)
        "LaneType", "LaneOffset", "LaneData", "RoadIntersection", "SpeedLimit",
        # presentation / audio (family 05)
        "Volume", "Pitch", "BlobShadow",
        # gameplay state (family 07)
        "Health", "ObjectScript", "StateMachine", "FactionValue",
        "FactionMarker", "CashValue", "LandingZone",
    ]
    enums = [
        "WeaponProjectileTypeEnum", "WeaponProjectileSpecialCaseTypeEnum",
        "WeaponCouplingTypeEnum", "WeaponUIReticleTypeEnum",
        "WeaponUIScopeTypeEnum", "WeaponUIReticleHealthTypeEnum",
        "EquipmentTypeEnum", "TurretCouplingTypeEnum", "BoolEnum",
        "AiPatrolModeEnum", "AiPriorityEnum", "NeedTypeEnum",
        "TrafficControlEnum", "DynamicRoadTypeEnum", "FlowControlTypeEnum",
        "AiWaterZoneEnum", "AiHintEnum",
    ]
    enum_members = [
        "Automatic", "SemiAutomatic", "Burst", "Grapple", "Flare",
        "Primary", "Secondary", "LinkedFire", "AlternateFire",
        "Normal", "Wire", "Sniper", "True", "False", "Loop", "Bounce",
        "Movement", "MovementPortal", "FirePoint", "CowerPoint",
        "Curved", "MatchTarget", "MatchYawPitch", "StopSign", "TrafficLight",
        "Overpass", "Wall", "NoTraffic", "NoVehicles", "NoPeds",
    ]
    out = set(weapon_fields) | set(other_fields) | set(enums) | set(enum_members)
    # casing variants (the hash is case-insensitive via |0x20, but harmless)
    out.update(s.lower() for s in list(out))
    return out


def gather_saboteur_concepts() -> set[str]:
    """The Saboteur (sibling Pandemic 'WildStar' engine) blueprint stat
    vocabulary, from the community Sab-Toolbox hash tables. Same hash algorithm
    (pandemic_hash_m2), so any internal field name shared with Mercs 2 resolves
    (verified: 'Automatic' and 'Model' hash identically in both games)."""
    sab = [
        # Weapon blueprint labels / candidate field names (Sab-Toolbox)
        "Clip Size", "ClipSize", "Amount of Clips", "AmountOfClips", "Clips",
        "Firerate", "FireRate", "Fire Rate", "Damage", "Accuracy",
        "Automatic", "Scope", "Model", "Display Name", "DisplayName",
        "Weapon HUD System", "Weapon HUD", "WeaponHud", "HUD",
        "Weapon Zoom Amount", "WeaponZoom", "Zoom", "ZoomAmount",
        "Zoomed-in Crosshair", "Zoomed-out Crosshair", "Crosshair", "Reticle",
        "Zoomed-in Recoil", "Zoomed-out Recoil", "Recoil",
        # Camera blueprint
        "XYZ Position", "XYZ Rotation", "Position", "Rotation",
        # general Saboteur / Pandemic engine concepts + archive types
        "Blueprint", "WillToFight", "Will To Fight", "WillToFightValue",
        "Megapack", "Tilepack", "Kilopack", "Loosefiles", "EditNodes",
        "WildStar", "Saboteur",
    ]
    out = set(sab)
    out.update(s.lower() for s in sab)
    return out


def _pe_string_sections(data: bytes) -> list[tuple[str, int, int]]:
    """Return [(name, raw_ptr, raw_size)] for a PE's sections (for string harvest)."""
    out: list[tuple[str, int, int]] = []
    if data[:2] != b"MZ":
        return out
    pe_off = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe_off:pe_off + 4] != b"PE\x00\x00":
        return out
    num_sections = struct.unpack_from("<H", data, pe_off + 6)[0]
    opt_size = struct.unpack_from("<H", data, pe_off + 20)[0]
    sec_off = pe_off + 24 + opt_size
    for i in range(num_sections):
        base = sec_off + i * 40
        if base + 40 > len(data):
            break
        name = data[base:base + 8].rstrip(b"\x00").decode("ascii", "ignore")
        raw_size = struct.unpack_from("<I", data, base + 16)[0]
        raw_ptr = struct.unpack_from("<I", data, base + 20)[0]
        out.append((name, raw_ptr, raw_size))
    return out


def harvest_exe_strings(exe_path: Path) -> set[str]:
    """Harvest identifier-like ASCII strings from the game EXE's .rdata/.data
    sections. This is where the reflection property-name table (iClipSize,
    ScatterMin, Velocity, ...), ECS class names, enum members, and engine
    identifiers actually live — none of which are in the WAD."""
    out: set[str] = set()
    try:
        data = exe_path.read_bytes()
    except Exception as e:
        print(f"  EXE string harvest failed: {e}")
        return out
    sections = _pe_string_sections(data)
    targets = [(n, o, s) for (n, o, s) in sections
               if n.lower() in (".rdata", ".data") and s > 0]
    if not targets:  # fallback: scan whole file (noisier)
        targets = [("<all>", 0, len(data))]
    ident = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{2,63}")
    for _name, off, size in targets:
        blob = data[off:off + size]
        for m in ident.finditer(blob):
            out.add(m.group().decode("ascii"))
    print(f"  Harvested {len(out):,} identifier strings from EXE "
          f"sections {[t[0] for t in targets]}")
    return out


def harvest_lua_corpus_strings() -> set[str]:
    """Identifier tokens + quoted string literals from the decompiled base-game
    Lua corpus (docs/mercs2-luacd/src) — captures support-catalog tags
    (aa, ah1z, laserguidedbomb, ...), function names, and table keys across all
    370 scripts (the resident-block scripts the WAD bytecode harvest misses)."""
    out: set[str] = set()
    src = ROOT / "docs" / "mercs2-luacd" / "src"
    if not src.is_dir():
        return out
    ident = re.compile(r"[A-Za-z_][A-Za-z0-9_]{2,63}")
    strlit = re.compile(r'"([^"\n]{1,64})"')
    n = 0
    for lua in src.rglob("*.lua"):
        try:
            text = lua.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        n += 1
        out.update(m.group() for m in ident.finditer(text))
        out.update(m.group(1) for m in strlit.finditer(text))
    if n:
        print(f"  Harvested {len(out):,} strings from {n} decompiled Lua scripts")
    return out


def gather_candidates(wad_path: Path | None = None,
                      exe_path: Path | None = None) -> set[str]:
    """Gather all candidate strings to hash."""
    candidates: set[str] = set()

    # ── 1. Known resolved type names ──────────────────────────────────
    known_types = [
        "texture", "path", "model", "animation", "layer", "script",
        "terrainmesh", "lowresterrain", "effect", "wavebank", "soundbank",
        "binary", "font", "stringdb", "materialtable", "watermap",
        "foliage", "level",
    ]
    candidates.update(known_types)

    # Cracked type names (confirmed via hash match)
    cracked_types = [
        "scrub",              # 0x600B904E — shader resource blocks (SCRB chunks)
        "facefxactor",        # 0x1CF649BB — FaceFX actor data in starter blocks
        "LineRegion",         # 0x6310807F — 625 line region defs in resident block
        "chatter",            # 0xFA0B8DBC — 22 NPC chatter/bark defs in resident
        "scaleformgfx",       # 0xFE0E8320 — Scaleform GFX Flash UI assets
        "facefxanimationset",  # 0x665EF13E — FaceFX anim sets in briefing blocks
        "GuidMap",             # 0x140E8728 — GUID-to-entity mapping (resident)
        "animationtable",     # 0x207359C7 — animation lookup table (resident, 15)
        "sequencetable",      # 0xACCE47F2 — sequence table (sequ/SINF/ITEM)
        "decaltable",         # 0x3B0AABF8 — decal table (resident)
        "facefxanimationset",  # 0x665EF13E — FaceFX anim sets in briefing blocks
        "sounddb",            # 0xE5273C14 — per-entity sound database (veh/wpn)
    ]
    candidates.update(cracked_types)

    # Speculative type names for the remaining unresolved type hashes
    speculative_types = [
        "shader", "material", "sequence", "music", "musicdata",
        "sound", "audio", "audioclip", "voice", "dialog", "dialogue",
        "video", "movie", "cutscene", "cinematic",
        "particle", "emitter", "fx", "vfx",
        "mesh", "geometry", "geom", "terrain", "heightmap", "heightfield",
        "skeleton", "bone", "rig", "havok", "physics", "collision",
        "config", "registry", "data", "database", "table",
        "object", "entity", "actor", "pawn", "npc", "vehicle", "weapon",
        "light", "lightmap", "shadow", "probe",
        "string", "text", "localization", "locale",
        "ui", "hud", "menu", "flash", "scaleform", "gfx",
        "world", "zone", "cell", "region", "area", "sector",
        "navmesh", "navigation", "pathfinding", "waypoint",
        "trigger", "volume", "boundary",
        "prefab", "template", "blueprint", "class", "type",
        "savegame", "save", "profile", "checkpoint",
        "precache", "cache", "streaming", "lod",
        "spline", "curve", "road", "river",
        "decal", "overlay", "billboard",
        "ambient", "atmosphere", "weather", "sky", "skybox", "fog",
        "water", "ocean", "wave",
        "tree", "plant", "vegetation", "foliage_instance",
        "ai", "behavior", "behaviortree", "state", "statemachine",
        "spawn", "spawner", "group", "squad", "formation",
        "damage", "health", "armor", "shield",
        "projectile", "bullet", "rocket", "missile", "grenade",
        "explosion", "debris", "destruction",
        "camera", "viewport", "render", "renderstate",
        "input", "control", "controller", "gamepad",
        "network", "multiplayer", "coop", "session",
        "achievement", "stat", "score", "reward",
        "mission", "contract", "job", "objective", "task",
        "faction", "reputation", "alignment",
        "inventory", "item", "pickup", "drop", "crate", "supply",
        "door", "gate", "barrier", "wall", "fence",
        "bridge", "tunnel", "road", "highway",
        "building", "structure", "tower", "bunker", "base",
        "dock", "port", "harbor", "pier",
        "airport", "runway", "helipad", "hangar",
        "garage", "parking", "lot",
        "resident", "resident2", "common",
        "resourcenode", "resource",
    ]
    candidates.update(speculative_types)

    # ── 2. Engine class names (Mrx / Wif / Red / Pbl / Pandemic) ──────
    mrx_classes = [
        "MrxTask", "MrxTaskContract", "MrxTaskJob", "MrxTaskRace",
        "MrxTaskObjective", "MrxTaskObjectiveDeliver",
        "MrxTaskObjectiveDestroy", "MrxTaskObjectiveEnterVehicle",
        "MrxTaskObjectiveVerify", "MrxTaskObjectiveAction",
        "MrxTaskJobDestroyType", "MrxTaskJobBounty",
        "MrxMissionFlow", "MrxMissionData", "MrxMissionBoundary",
        "MrxPmc", "MrxAi", "MrxUtil", "MrxMusic",
        "MrxSubtitle", "MrxVoSequence", "MrxApcDrop", "MrxCopterDrop",
        "MrxSupportData", "MrxSupportTransit",
        "MrxLayerManager", "MrxStarterManager",
        "MrxShootingGallery", "MrxMultiPageMenu", "MrxTimer",
        "MrxSoundBootstrap", "MrxTutorial",
        "MrxHijackContract", "HijackContractManager",
    ]
    candidates.update(mrx_classes)

    wif_classes = [
        "WifMissionFlow", "WifMissionData", "WifPmcInterior",
        "WifPmcGarage", "WifVzBoundary", "WifVzAmbience",
        "WifStarterData", "WifBriefingData", "WifHqData",
        "WifBios",
    ]
    candidates.update(wif_classes)

    engine_classes = [
        "RedEngine", "RedVirtualDisk", "RedFileInfo",
        "PblHash", "PblHashTable", "PblFixedHashTable",
        "PblCompress", "PblStream", "PblFile",
        "HandyWriteBinaryChunk", "MungeApp",
    ]
    candidates.update(engine_classes)

    # ── 3. Lua 5.1 builtins and standard library ─────────────────────
    lua_builtins = [
        "assert", "collectgarbage", "dofile", "error", "getfenv",
        "getmetatable", "ipairs", "load", "loadfile", "loadstring",
        "module", "next", "pairs", "pcall", "print", "rawequal",
        "rawget", "rawset", "require", "select", "setfenv",
        "setmetatable", "tonumber", "tostring", "type", "unpack",
        "xpcall", "_VERSION", "_G",
        "coroutine", "debug", "io", "math", "os", "package",
        "string", "table",
        "import", "inherit", "dynamic_import", "dynamic_remove",
        "ScriptInit", "ScriptShutdown", "ScriptPostLoad",
        "Activated", "Complete", "Cancel", "Cleanup",
        "LoadAssets", "MissionComplete",
        "CreateChild", "GetMessage", "SendEvent",
        "SetupActivationCriteria", "SetupCancellationCriteria",
        "Refresh", "Reset", "SetFlowData", "GetOriginalFlowData",
        "UnlockMission", "DestroyMission",
        "HasKey", "AwardKey", "GetKeyValue",
        "_MODULES", "_SYS", "_IMPORT", "_INHERIT",
        "_DYNAMIC_IMPORT", "_DYNAMIC_REMOVE", "_GETFENV",
    ]
    candidates.update(lua_builtins)

    # ── 4. Game-specific function/event names ─────────────────────────
    game_funcs = [
        "SetActiveContract", "CancelActiveContract",
        "SpawnPatrols", "SimpleSpawner",
        "CheckpointRegionActivate", "BeachRegionActivate",
        "AASiteRegionActivate", "CopterAttackRegionActivate",
        "VZJeepPursuitRegionActivate",
        "ActivateTutorial", "ActivateMission",
        "SetPmcRadio", "EnterFreeplayMusic",
        "SetJetPilotRecruited", "SetMechanicRecruited",
        "IsOnlineConnected", "IsDLC", "IsMatchmakingInternet",
        "HasPlayerUnlockedCode",
        "SetMasterScriptName", "AddStringDb",
        "SaveSingleton", "LoadSingleton",
        "BoundaryCallback", "SetupBoundary", "RemoveWorldBoundary",
        "EnableExclusionBoundary", "RemoveExclusionBoundaries",
        "SetInteriorMode", "LoadInterior", "RuntimeLayer",
        "RequestAsset", "PrecacheAsset", "FlushPrecache",
        "StartRace", "CompleteVO",
        "SetMaterielScale", "GetMaterielScale",
        "tMissionData", "tStartLocations", "tMilestones",
        "tLayers", "tMaterielScale",
        "sModuleName", "sFactionId", "sStarter",
        "bContract", "bRepeatable", "bCriticalPathMission",
        "bPlayerVisibleMission", "bCompletable",
        "bSkipInitialNotifications", "bSuppressPdaDisplay",
        "nPdaSortOrder", "sPdaTexture", "sTitle",
        "IsMissionAContract", "GetMissionFaction", "GetMissionStarter",
        "SetMissionData",
    ]
    candidates.update(game_funcs)

    # ── 5. Character names ────────────────────────────────────────────
    characters = [
        "Mattias", "MattiasNilsson", "mattias", "mattias_nilsson",
        "Jennifer", "JenniferMui", "jennifer", "jennifer_mui",
        "Chris", "ChrisJacobs", "chris", "chris_jacobs",
        "Fiona", "FionaTaylor", "fiona", "fiona_taylor",
        "Ewan", "EwanDevlin", "ewan", "ewan_devlin",
        "Eva", "EvaNaro", "eva", "eva_naro",
        "Misha", "MishaMilanich", "misha", "misha_milanich",
        "Solano", "RamonSolano", "solano", "ramon_solano",
        "Carmona", "GeneralCarmona", "carmona",
        "Blanco", "blanco",
        "Marlowe", "marlowe",
        "PmcBoss", "HelPmcBoss", "MecPmcBoss", "JetPmcBoss",
        "JetBoss", "MecBoss",
    ]
    candidates.update(characters)

    # ── 6. Faction identifiers ────────────────────────────────────────
    factions = [
        "All", "Chi", "Gur", "Oil", "Pir", "Pmc", "Vza",
        "AN", "UP", "VZ", "PMC", "Pirates",
        "AlliedNations", "UniversalPetroleum", "VenezuelanArmy",
        "Guerrilla", "Chinese", "Pirate",
        "OC", "GR", "CN", "AN", "PI",
    ]
    candidates.update(factions)

    # ── 7. Weapon / vehicle names ─────────────────────────────────────
    weapons_vehicles = [
        "pistol", "rifle", "shotgun", "smg", "sniper", "sniperrifle",
        "rpg", "rocketlauncher", "grenadelauncher", "minigun",
        "lightmg", "heavymg", "atrifle", "atmissile", "heavyatmissile",
        "c4", "claymore", "mine", "airstrike", "bunker_buster",
        "designator", "designator_flare", "grapplegun",
        "machinepistol", "huntingpistol", "covertsmg",
        "emplacedlightmg", "emplacedheavymg",
        "jeep", "truck", "tank", "apc", "humvee", "buggy", "boat",
        "helicopter", "heli", "copter", "jet", "plane",
        "motorcycle", "bike", "sportscar",
        "jetski", "speedboat", "barge",
        "ZBD2000", "ZTZ98", "T72", "M1Abrams", "Bradley",
        "Apache", "Blackhawk", "Huey", "Havoc", "Hind",
    ]
    candidates.update(weapons_vehicles)
    # wpn_ prefixed
    for w in list(weapons_vehicles):
        candidates.add(f"wpn_{w}")

    # ── 8. Location / map area names ──────────────────────────────────
    locations = [
        "maracaibo", "caracas", "merida", "angelfalls", "angel_falls",
        "amazon", "orinoco", "caribbean",
        "altagracia", "cambias", "industrial", "fortress",
        "ciudad_bolivar", "lake_maracaibo",
        "refinery", "oilrig", "oilfield", "pipeline",
        "villa", "mansion", "estate", "plantation",
        "church", "cathedral", "plaza", "market",
        "stadium", "coliseum", "arena",
        "barracks", "outpost", "checkpoint", "watchtower",
        "embassy", "consulate", "parliament",
        "prison", "jail", "compound",
        "jungle", "forest", "mountain", "desert", "swamp",
        "beach", "coast", "island", "peninsula",
        "river", "lake", "dam", "waterfall",
        "city", "town", "village", "slum", "shanty",
        "highway", "freeway", "interstate",
        "mar_altagracia", "mar_industrial", "mar_city",
        "mar_fortress", "mar_airport",
    ]
    candidates.update(locations)

    # ── 9. Pandemic Studios / EA credits ──────────────────────────────
    pandemic_people = [
        # Pandemic Studios leadership
        "Josh Resnick", "Andrew Goldman", "Greg Borrud",
        "Cameron Petty", "Matt Schembari",
        # Known from Mercs 1/2 credits
        "Scott Warner", "Billy Berghammer",
        "Jason Bender", "Randy Shipp",
        # Pandemic studio names
        "Pandemic", "PandemicStudios", "pandemic_studios",
        "pandemic", "Pebble", "RedEngine", "Handy",
        "RetroStrike", "retrostrike",
        # EA names
        "EA", "ElectronicArts", "ea_games", "EA_Games",
        "EALA", "EA_LA", "ea_la",
    ]
    candidates.update(pandemic_people)

    # ── 10. Game slogans / marketing strings ──────────────────────────
    slogans = [
        "WorldInFlames", "world_in_flames",
        "Mercenaries", "mercenaries", "Mercs2", "mercs2",
        "Mercenaries2", "mercenaries2",
        "BlowItUpAgain", "blow_it_up_again",
        "OhNoYouDidnt", "oh_no_you_didnt",
        "EverybodyPaysEverything",
        # DLC
        "MercBlitz", "ArmsRace", "UrbanRampage", "DeathRace",
    ]
    candidates.update(slogans)

    # ── 11. Music / audio production names ────────────────────────────
    music = [
        "Chris Tilton", "Michael Giacchino",
        "chris_tilton", "michael_giacchino",
        "Tilton", "Giacchino",
        "musicdata", "vo_stream", "vo_resident",
        "sfx", "ambient_sfx", "combat_sfx",
    ]
    candidates.update(music)

    # ── 12. UCFX chunk tags and format strings ────────────────────────
    chunk_tags = [
        "UCFX", "FFCS", "INFO", "DEPS", "BINN", "CSUM",
        "GEOM", "MESH", "PRMG", "STRM", "IBUF", "MTRL", "PRMT",
        "HIER", "INDX", "SWIT", "NAME", "CHDR", "COMP",
        "BODY", "SCRB", "SEGM", "BNDS",
        "sequ", "SINF", "ITEM",
        "sges", "ASET", "PTHS", "DATA",
        "CERP",  # precache format
    ]
    candidates.update(chunk_tags)
    # lowercase versions
    candidates.update(t.lower() for t in chunk_tags)

    # ── 13. ECS component names ───────────────────────────────────────
    ecs = [
        "Transform", "Name", "ObjectScript", "LightObject",
        "HibernationControl", "LowResTerrainObject", "ScrubObject",
        "RenderObject", "PhysicsObject", "CollisionObject",
        "AIObject", "VehicleObject", "WeaponObject",
        "SpawnObject", "TriggerObject", "AnimationObject",
        "SoundObject", "ParticleObject", "DecalObject",
        "WaypointObject", "PathObject", "RegionObject",
        "DamageObject", "HealthObject",
        "InventoryObject", "PickupObject",
    ]
    candidates.update(ecs)
    candidates.update(e.lower() for e in ecs)

    # ── 14. Block path stems from the WAD (if available) ──────────────
    if wad_path and wad_path.is_file():
        try:
            from ffcs_wad import parse_ffcs
            arch = parse_ffcs(wad_path)
            pths = next((c for c in arch.chunks if c.tag == "PTHS"), None)
            if pths:
                with open(wad_path, "rb") as f:
                    f.seek(pths.offset)
                    data = f.read(pths.size)
                start = 0
                for i, b in enumerate(data):
                    if b == 0:
                        s = data[start:i].decode("ascii", errors="ignore")
                        if s and len(s) > 1 and not s.startswith("x"):
                            candidates.add(s)
                            # Extract stem
                            name = s.replace("\\", "/").split("/")[-1]
                            base = name.replace(".block", "")
                            base = re.sub(r"_P\d+_Q\d+$", "", base)
                            candidates.add(base)
                            candidates.add(name)
                        start = i + 1
                print(f"  Extracted block paths from WAD PTHS")
        except Exception as e:
            print(f"  WAD path extraction failed: {e}")

    # ── 15. ALL string constants from scripts_vz bytecodes ──────────
    if wad_path and wad_path.is_file():
        try:
            from build_patch_wad import extract_block_metadata
            from sges_decompress import decompress_sges_block
            from wad_patcher import resolve_scripts_vz_block_index

            idx = resolve_scripts_vz_block_index(wad_path)
            meta = extract_block_metadata(wad_path, idx)
            decomp = decompress_sges_block(
                meta["compressed_block_data"], 0,
                len(meta["compressed_block_data"]),
            )
            bc_strings = set()
            for m in re.finditer(rb"[a-zA-Z_][a-zA-Z0-9_]{2,}", decomp):
                bc_strings.add(m.group().decode("ascii"))
            # Also extract dotted paths
            for m in re.finditer(rb"[a-zA-Z_][a-zA-Z0-9_.]+", decomp):
                s = m.group().decode("ascii")
                if "." in s:
                    bc_strings.add(s)
                    for part in s.split("."):
                        if len(part) >= 3:
                            bc_strings.add(part)
            candidates.update(bc_strings)
            print(f"  Extracted {len(bc_strings):,} bytecode string constants")
        except Exception as e:
            print(f"  Bytecode string extraction failed: {e}")

    # ── 15b. Script names from scripts_vz block ─────────────────────
    if wad_path and wad_path.is_file():
        try:
            from build_patch_wad import extract_block_metadata
            from sges_decompress import decompress_sges_block
            from wad_patcher import (
                parse_block_entries,
                resolve_scripts_vz_block_index,
            )

            idx = resolve_scripts_vz_block_index(wad_path)
            meta = extract_block_metadata(wad_path, idx)
            decomp = decompress_sges_block(
                meta["compressed_block_data"], 0,
                len(meta["compressed_block_data"]),
            )
            entries = parse_block_entries(decomp)
            for e in entries:
                off = e["offset"]
                chunk = decomp[off:off + e["size"]]
                luaq_pos = chunk.find(b"\x1bLua")
                if luaq_pos >= 0:
                    binn = chunk[:luaq_pos]
                    for i in range(len(binn) - 4):
                        if binn[i] == 0x05:
                            name_len = int.from_bytes(binn[i+1:i+3], "little")
                            if 0 < name_len < 100:
                                try:
                                    name = binn[i+3:i+3+name_len].decode("ascii")
                                    if name.isprintable():
                                        candidates.add(name)
                                except Exception:
                                    pass
                                break
            print(f"  Extracted {len(entries)} script names from scripts_vz")
        except Exception as e:
            print(f"  Script name extraction failed: {e}")

    # ── 16. Systematic permutations ───────────────────────────────────
    # Contract/job numbering patterns
    faction_prefixes = ["All", "Chi", "Gur", "Oil", "Pir", "Pmc", "Vza",
                        "all", "chi", "gur", "oil", "pir", "pmc", "vza",
                        "Jet", "Mec", "Hel", "Dlc",
                        "jet", "mec", "hel", "dlc"]
    type_suffixes = ["Con", "Job", "con", "job"]
    for prefix in faction_prefixes:
        for suffix in type_suffixes:
            for num in range(1, 60):
                candidates.add(f"{prefix}{suffix}{num:03d}")
                candidates.add(f"{prefix}{suffix}{num:02d}")
            # Starter patterns
            for i in range(10):
                candidates.add(f"{prefix}Starter{i}")
                candidates.add(f"{prefix}starter{i}")
                candidates.add(f"Starter_{prefix}{i}")
                candidates.add(f"starter_{prefix}{i}")
                candidates.add(f"Starter_{prefix}{i}_Start1")
                candidates.add(f"Starter_{prefix}{i}_Start2")
                candidates.add(f"Starter_{prefix}{i}_Entrance")
            # HQ patterns
            candidates.add(f"{prefix}Hq")
            candidates.add(f"{prefix}Outpost")
            candidates.add(f"{prefix}outpost")
            for i in range(10):
                candidates.add(f"{prefix}Outpost{i}")
                candidates.add(f"{prefix}outpost{i}")

    # DLC contracts
    for i in range(1, 10):
        candidates.add(f"dlccon{i:03d}")
        candidates.add(f"DlcCon{i:03d}")
        candidates.add(f"dlc{i:02d}")
        candidates.add(f"dlc0{i}")

    # vz_state layer patterns
    vz_state_bases = [
        "pmcinterior", "pmc_livedin", "cashpickups",
        "amazon", "angel_falls", "merida",
    ]
    for base in vz_state_bases:
        candidates.add(f"vz_state_{base}")
        candidates.add(f"vz_state_{base}_pristine")
        candidates.add(f"vz_state_{base}_ruined")
        candidates.add(f"vz_state_{base}_destroyed")
        candidates.add(f"vz_state_{base}_staging")
        candidates.add(f"vz_state_{base}_act1")
        candidates.add(f"vz_state_{base}_act2")
        candidates.add(f"vz_state_{base}_act3")

    # Common c3 cell patterns
    for i in range(10000):
        candidates.add(f"c3{i:04d}")
    for i in range(100):
        candidates.add(f"c3{i:02d}")

    # ── 17. vz.bin certificate token + FFCS cert blob ──────────────
    # vz.bin is x<256 hex chars>x — decode and add the hex substrings
    # and the u32 values (LE) as candidate lookups
    vz_bin_hex = (
        "a37dd45ffe100bfffcc9753aabac325f07cb3fa231144fe2e33ae4783feead2b"
        "8a73ff021fac326df0ef9753ab9cdf6573ddff0312fab0b0ff39779eaff312a4"
        "f5de65892ffee33a44569bebf21f66d22e54a22347efd375981188743afd99ba"
        "acc342d88a99321235798725fedcbf43252669dade32415fee89da543bf23d4e"
    )
    # Add the full hex string and 4 x 64-char chunks
    candidates.add(vz_bin_hex)
    candidates.add("x" + vz_bin_hex + "x")
    for i in range(0, len(vz_bin_hex), 64):
        candidates.add(vz_bin_hex[i:i+64])
    # Add 32-char and 8-char hex chunks
    for i in range(0, len(vz_bin_hex), 32):
        candidates.add(vz_bin_hex[i:i+32])
    for i in range(0, len(vz_bin_hex), 8):
        candidates.add(vz_bin_hex[i:i+8])
    # Add vz.bin-related strings
    candidates.update(["vz.bin", "vzbin", "vz_bin", "build_cert", "buildcert"])

    # ── 18. Custom mod script names ─────────────────────────────────
    mod_names = [
        "modloader", "pmcpatrol001", "pmcpatrol002", "pmcpatrol003",
        "mod_enable", "mod_loader", "custom_mission",
        "dlc01", "dlc02", "dlc03",
    ]
    candidates.update(mod_names)

    # ── 18. Mercs 1 source code identifiers ───────────────────────────
    mercs1_ids = [
        "registry", "RedVirtualDisk", "RedFileInfo",
        "PblHash", "PblHashTable", "PblCompress",
        "HandyWriteBinaryChunk", "MungeApp", "ScriptMunge",
        "ZeroEditor", "ZeroRecord",
        "ucft", "ucfb", "ucf",
        "RsLoadSaveGameFile", "RsEngine",
    ]
    candidates.update(mercs1_ids)

    # ── 19. Newly-learned: ECS registry, reflection fields, Lua corpus ──────
    candidates |= gather_ecs_registry_names()
    candidates |= gather_reflection_field_names()
    candidates |= harvest_lua_corpus_strings()

    # ── 20. The Saboteur (sibling engine) blueprint stat vocabulary ─────────
    candidates |= gather_saboteur_concepts()

    # ── 21. EXE rodata/data string harvest (reflection field + class names) ─
    if exe_path and Path(exe_path).is_file():
        candidates |= harvest_exe_strings(Path(exe_path))

    return candidates


def build_table(candidates: set[str]) -> dict[str, list[str]]:
    """Compute pandemic_hash_m2 for all candidates, return {hex_hash: [inputs]}."""
    table: dict[int, list[str]] = {}
    for s in candidates:
        h = pandemic_hash_m2(s)
        table.setdefault(h, []).append(s)
    # Convert to hex-keyed dict for JSON
    return {f"0x{k:08X}": sorted(v) for k, v in sorted(table.items())}


def check_unknowns(table: dict[str, list[str]]) -> None:
    """Check if any previously-unresolved type hashes got cracked."""
    unknown_hashes = [
        0x600B904E, 0x6310807F, 0x665EF13E, 0xE5273C14,
        0xFE0E8320, 0x1CF649BB, 0xFA0B8DBC, 0x207359C7,
        0xDE982D61, 0xACCE47F2, 0xC122545A, 0xE8DF4D87,
        0xECE70371, 0x3B0AABF8, 0x5647C35D, 0x140E8728,
        0xFA46D8A8,
    ]
    print("\nPreviously-unresolved type hash check:")
    cracked = 0
    for h in unknown_hashes:
        key = f"0x{h:08X}"
        if key in table:
            print(f"  CRACKED: {key} -> {table[key]}")
            cracked += 1
        else:
            print(f"  still unknown: {key}")
    print(f"  {cracked}/{len(unknown_hashes)} newly cracked")


def main() -> int:
    ap = argparse.ArgumentParser(description="Build pandemic_hash_m2 rainbow table")
    ap.add_argument("--wad", type=Path, default=None,
                    help="Retail vz.wad for extracting script/block names")
    ap.add_argument("--exe", type=Path, default=None,
                    help="Game EXE for harvesting .rdata/.data reflection "
                         "field + class name strings")
    ap.add_argument("--output", "-o", type=Path,
                    default=Path(__file__).resolve().parent / "rainbow_table.json",
                    help="Output JSON file")
    args = ap.parse_args()

    # Auto-detect WAD
    wad = args.wad
    if wad is None:
        for candidate in [
            Path("game-files/vz.wad"),
            Path(__file__).resolve().parent.parent / "game-files" / "vz.wad",
        ]:
            if candidate.is_file():
                wad = candidate
                break

    # Auto-detect EXE (for reflection field/class name harvest)
    exe = args.exe
    if exe is None:
        for candidate in [
            Path("output/mercs2_v1.1_uncracked.exe"),
            ROOT / "output" / "mercs2_v1.1_uncracked.exe",
            Path("game-files/Mercenaries2.exe"),
            ROOT / "game-files" / "Mercenaries2.exe",
        ]:
            if candidate.is_file():
                exe = candidate
                break

    print("Building pandemic_hash_m2 rainbow table")
    print("=" * 60)
    if exe:
        print(f"  EXE for string harvest: {exe}")
    else:
        print("  (no EXE found — pass --exe to harvest reflection field/class names)")

    print("\nGathering candidates...")
    candidates = gather_candidates(wad, exe)
    print(f"  Total unique strings: {len(candidates):,}")

    print("\nComputing hashes...")
    table = build_table(candidates)
    print(f"  Unique hashes: {len(table):,}")
    collisions = sum(1 for v in table.values() if len(v) > 1)
    print(f"  Collisions: {collisions} (multiple inputs -> same hash)")

    check_unknowns(table)

    # Also build a pandemic_hash (v1, no m2 finalization) table
    table_v1: dict[str, list[str]] = {}
    for s in candidates:
        h = pandemic_hash(s)
        table_v1.setdefault(f"0x{h:08X}", []).append(s)
    for k in table_v1:
        table_v1[k] = sorted(table_v1[k])

    output = {
        "_meta": {
            "description": "Rainbow table for Pandemic Studios hash functions (Mercenaries 2)",
            "algorithms": {
                "pandemic_hash_m2": "FNV-1a + |0x20 case suppression + ^0x2A * prime finalization (Mercs 2)",
                "pandemic_hash": "FNV-1a + |0x20 case suppression (Mercs 1, no finalization)",
            },
            "candidate_count": len(candidates),
            "unique_m2_hashes": len(table),
            "unique_v1_hashes": len(table_v1),
        },
        "pandemic_hash_m2": table,
        "pandemic_hash": table_v1,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=False))
    size_mb = args.output.stat().st_size / 1024 / 1024
    print(f"\nWrote: {args.output} ({size_mb:.1f} MB)")
    print(f"  pandemic_hash_m2 entries: {len(table):,}")
    print(f"  pandemic_hash entries:    {len(table_v1):,}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
