pub mod ima;
pub mod soundbank;
pub mod wavebank;

pub use soundbank::consume_soundbank;
pub use wavebank::{
    clip_by_hash, consume_wavebank, consume_wavebank_with_options, LoadedWavebank,
    WavebankConsumeOptions, CODEC_XBOX_ADPCM,
};

pub use crate::types::{
    TYPE_HASH_SOUNDBANK, TYPE_HASH_WAVEBANK, TYPE_ID_SOUNDBANK, TYPE_ID_WAVEBANK,
};
