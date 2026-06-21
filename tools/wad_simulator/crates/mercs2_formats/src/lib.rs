//! Binary format parsers and validators for Mercenaries 2 asset containers.
//!
//! This crate provides comprehensive support for parsing, validating, and transforming
//! Mercenaries 2 WAD file formats across PC and Xbox 360 platforms.
//!
//! # Modules
//!
//! - [`aset_type_ids`] — UCFX `type_hash` to ASET `type_id` lookup registry
//! - [`chunk_validate`] — Validators for documented UCFX chunk layouts
//! - [`crc32`] — Mercenaries 2 CRC-32 checksum (CSUM) computation
//! - [`dlc_input`] — Big-endian Xbox 360 DLC (FFCS/INDX/ASET/PTHS) readers
//! - [`dlc_stfs`] — STFS container (Xbox 360 secure file store) reader + RAR extraction
//! - [`ffcs`] — FFCS WAD header, INDX, ASET, PTHS parsing
//! - [`hash`] — Pandemic Studios FNV-1a hashing (Mercs 1 and Mercs 2 variants)
//! - [`patch_wad`] — FFCS patch-WAD assembly (PC output/writer)
//! - [`safe_slice`] — Bounds-checked byte buffer (models engine pointer dereferences)
//! - [`schema`] — ECS COMP schema field type codes
//! - [`sges`] — sges block compression and decompression (deflate)
//! - [`tags`] — Exhaustive chunk tag enum for UCFX descriptor tags
//! - [`texsize`] — Texture mip-chain sizing (DXT format calculations)
//! - [`types`] — ASET type_id and UCFX type_hash registry
//! - [`ucfx`] — UCFX container parsing and CSUM verification
//! - [`world`] — Game world spatial constants and validation

pub mod aset_type_ids;
pub mod chunk_validate;
pub mod crc32;
pub mod dlc_input;
pub mod dlc_stfs;
pub mod ffcs;
pub mod hash;
pub mod model_cubeize;
pub mod patch_wad;
pub mod safe_slice;
pub mod schema;
pub mod sges;
pub mod tags;
pub mod texsize;
pub mod types;
pub mod ucfx;
pub mod world;
