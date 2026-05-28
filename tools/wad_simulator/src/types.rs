//! ASET type_id and UCFX type_hash registry (retail vz.wad).

pub const TYPE_ID_WAVEBANK: u32 = 6;
pub const TYPE_ID_SOUNDBANK: u32 = 21;
pub const TYPE_ID_LAYER: u32 = 9;
pub const TYPE_ID_MODEL: u32 = 19;
pub const TYPE_ID_TEXTURE: u32 = 27;
pub const TYPE_ID_SCRIPT: u32 = 35;
pub const TYPE_ID_ANIMATION: u32 = 16;
pub const TYPE_ID_LOWRES_TERRAIN: u32 = 22;
pub const TYPE_ID_TERRAIN_MESH: u32 = 32;
pub const TYPE_ID_FONT: u32 = 15;
pub const TYPE_ID_PATH: u32 = 28;
pub const TYPE_ID_EFFECT: u32 = 29;
pub const TYPE_ID_STRINGDB: u32 = 7;
pub const TYPE_ID_LEVEL: u32 = 20;

pub const TYPE_HASH_WAVEBANK: u32 = 0xF753F6D0;
pub const TYPE_HASH_SOUNDBANK: u32 = 0x9F8BCA10;
pub const TYPE_HASH_LAYER: u32 = 0xE6B81A54;
pub const TYPE_HASH_MODEL: u32 = 0x5B724250;
pub const TYPE_HASH_TEXTURE: u32 = 0xF011157A;
pub const TYPE_HASH_SCRIPT: u32 = 0x42498680;
pub const TYPE_HASH_ANIMATION: u32 = 0x18166555;
pub const TYPE_HASH_LOWRES_TERRAIN: u32 = 0x1602815C;
pub const TYPE_HASH_TERRAIN_MESH: u32 = 0x7C569307;
pub const TYPE_HASH_FONT: u32 = 0x99E77ACE;
pub const TYPE_HASH_PATH: u32 = 0xBCFE6314;
pub const TYPE_HASH_EFFECT: u32 = 0x5608BD5A;
pub const TYPE_HASH_STRINGDB: u32 = 0x39E5E978;
pub const TYPE_HASH_LEVEL: u32 = 0xEA4829D5;

/// All known type_hash → type_id mappings from retail census.
pub const TYPE_HASH_REGISTRY: &[(u32, u32)] = &[
    (0xF011157A, 27),
    (0xBCFE6314, 28),
    (0x5B724250, 19),
    (0x18166555, 16),
    (0x600B904E, 12),
    (0xE6B81A54, 9),
    (0x42498680, 35),
    (0x6310807F, 30),
    (0x7C569307, 32),
    (0x1602815C, 22),
    (0x5608BD5A, 29),
    (0xF753F6D0, 6),
    (0x665EF13E, 5),
    (0xE5273C14, 13),
    (0x9F8BCA10, 21),
    (0xFE0E8320, 23),
    (0x1CF649BB, 34),
    (0xFA0B8DBC, 18),
    (0x207359C7, 11),
    (0x8F0A54E2, 3),
    (0x99E77ACE, 15),
    (0xDE982D61, 14),
    (0x39E5E978, 7),
    (0x59B9DF6A, 0),
    (0x4D7D30C4, 0),
    (0x34612F86, 0),
    (0xACCE47F2, 33),
    (0xC122545A, 26),
    (0xE8DF4D87, 4),
    (0xECE70371, 31),
    (0xEA4829D5, 20),
    (0x3B0AABF8, 1),
    (0x5647C35D, 8),
    (0x140E8728, 10),
    (0xFA46D8A8, 25),
];

pub fn type_hash_for_type_id(type_id: u32) -> Option<u32> {
    TYPE_HASH_REGISTRY
        .iter()
        .find(|(_, id)| *id == type_id)
        .map(|(h, _)| *h)
}

pub fn type_id_for_type_hash(type_hash: u32) -> Option<u32> {
    TYPE_HASH_REGISTRY
        .iter()
        .find(|(h, _)| *h == type_hash)
        .map(|(_, id)| *id)
}

pub fn type_name(type_id: u32) -> &'static str {
    match type_id {
        0 => "singleton",
        3 => "binary",
        4 => "musicdata",
        5 => "mission_flow",
        6 => "wavebank",
        7 => "stringdb",
        8 => "layer_meta",
        9 => "layer",
        10 => "unknown_10",
        11 => "stance",
        12 => "shader_scrb",
        13 => "audio_group",
        14 => "resident_info",
        15 => "font",
        16 => "animation",
        18 => "resident_misc",
        19 => "model",
        20 => "level",
        21 => "soundbank",
        22 => "lowresterrain",
        23 => "cfx_pack",
        25 => "unknown_25",
        26 => "musicdata2",
        27 => "texture",
        28 => "path",
        29 => "effect",
        30 => "object_registry",
        31 => "state_machine",
        32 => "terrainmesh",
        33 => "sequence",
        34 => "starter",
        35 => "script",
        _ => "unknown",
    }
}
