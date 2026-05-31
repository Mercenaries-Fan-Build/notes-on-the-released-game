use mercs2_formats::crc32::crc32_mercs2;
use mercs2_formats::ffcs::read_u32_be;
use mercs2_formats::schema::{ComponentSchema, SchemaFieldType};
use mercs2_formats::tags::ChunkTag;
use mercs2_formats::types;

use crate::report::SchemaCoverageReport;

const TYPE_HASH_ECS_NODE: u32 = types::TYPE_HASH_LAYER; // 0xE6B81A54
const TYPE_HASH_WORLD_ENTITY: u32 = types::TYPE_HASH_WORLD_ENTITY_DATA; // 0x5647C35D

/// Strip a trailing CSUM/MUSC 8-byte trailer from a raw chunk if present.
/// Both Xbox and PC WADs include the CSUM in the entry table's `chunk_size`.
fn strip_csum_trailer(raw: &[u8]) -> &[u8] {
    if raw.len() >= 8 {
        let tail_tag = &raw[raw.len() - 8..raw.len() - 4];
        if tail_tag == b"CSUM" || tail_tag == b"MUSC" {
            return &raw[..raw.len() - 8];
        }
    }
    raw
}

/// Descriptor row parsed from a UCFX container's descriptor table.
struct Descriptor {
    tag: ChunkTag,
    tag_bytes_le: [u8; 4],
    row_u0: u32,
    body_size: u32,
    row_u3: u32,
    row_u4: u32,
}

/// Convert a decompressed BE block to LE format.
/// When `report` is `Some`, collects schema field coverage stats.
pub fn convert_block(
    be_data: &[u8],
    dry_run: bool,
    mut report: Option<&mut SchemaCoverageReport>,
) -> Result<Vec<u8>, String> {
    if be_data.len() < 4 {
        return Err("Block too small".into());
    }

    let entry_count = read_u32_be(be_data, 0) as usize;
    if entry_count > 50000 {
        return Err(format!("Implausible entry count: {}", entry_count));
    }

    let header_size = 4 + entry_count * 16;
    if header_size > be_data.len() {
        return Err("Entry table exceeds block size".into());
    }

    eprintln!("  Entry count: {}", entry_count);

    struct EntryInfo {
        name_hash: u32,
        type_hash: u32,
        #[allow(dead_code)]
        field_c: u32,
        chunk_size: u32,
    }

    let mut entries = Vec::with_capacity(entry_count);
    for i in 0..entry_count {
        let off = 4 + i * 16;
        entries.push(EntryInfo {
            name_hash: read_u32_be(be_data, off),
            type_hash: read_u32_be(be_data, off + 4),
            field_c: read_u32_be(be_data, off + 8),
            chunk_size: read_u32_be(be_data, off + 12),
        });
    }

    // Dry-run: just walk and report tags
    if dry_run {
        let mut offset = header_size;
        for (ei, entry) in entries.iter().enumerate() {
            let container_end = offset + entry.chunk_size as usize;
            if container_end > be_data.len() {
                return Err(format!("Entry {} container exceeds block (offset={}, size={})",
                    ei, offset, entry.chunk_size));
            }

            let container = strip_csum_trailer(&be_data[offset..container_end]);
            let type_name = types::type_name_from_hash(entry.type_hash);
            eprintln!("  Entry {}: name=0x{:08x} type_hash=0x{:08x} ({}) size={}",
                ei, entry.name_hash, entry.type_hash, type_name, entry.chunk_size);

            match walk_container_tags(container, ei) {
                Ok(()) => {}
                Err(e) => eprintln!("    [skip] {}", e),
            }

            offset = container_end;
        }
        return Ok(Vec::new());
    }

    // --- Actual conversion ---
    // Two-pass: first convert all containers to compute correct sizes,
    // then write the entry table with correct chunk_size (including CSUM)
    // and offset (cumulative position in the data area).

    // Pass 1: Convert all containers and collect results.
    // chunk_size INCLUDES the 8-byte CSUM trailer on both Xbox and PC,
    // so strip it before converting and re-add a fresh one afterwards.
    let mut converted_containers: Vec<Vec<u8>> = Vec::with_capacity(entry_count);
    let mut offset = header_size;
    for (ei, entry) in entries.iter().enumerate() {
        let container_end = offset + entry.chunk_size as usize;
        if container_end > be_data.len() {
            return Err(format!("Entry {} container exceeds block (offset={}, size={})",
                ei, offset, entry.chunk_size));
        }

        let container = strip_csum_trailer(&be_data[offset..container_end]);
        let type_name = types::type_name_from_hash(entry.type_hash);
        eprintln!("  Converting entry {}: type=0x{:08x} ({}) size={} (UCFX={})",
            ei, entry.type_hash, type_name, entry.chunk_size, container.len());

        let is_ecs = entry.type_hash == TYPE_HASH_ECS_NODE
            || entry.type_hash == TYPE_HASH_WORLD_ENTITY;
        let converted = convert_container(container, is_ecs, ei, entry.type_hash, report.as_deref_mut())?;
        converted_containers.push(converted);

        offset = container_end;
    }

    // Pass 2: Compute correct chunk_sizes (UCFX + 8 for CSUM trailer).
    // field_c is always 0 on both platforms — engine walks sequentially, no offset lookup.
    let pc_chunk_sizes: Vec<u32> = converted_containers.iter()
        .map(|c| (c.len() as u32) + 8)
        .collect();

    // Write output: entry table then containers
    let mut output = Vec::with_capacity(be_data.len());

    // Write LE entry table
    output.extend_from_slice(&(entry_count as u32).to_le_bytes());
    for (ei, entry) in entries.iter().enumerate() {
        output.extend_from_slice(&entry.name_hash.to_le_bytes());
        output.extend_from_slice(&entry.type_hash.to_le_bytes());
        output.extend_from_slice(&0u32.to_le_bytes());
        output.extend_from_slice(&pc_chunk_sizes[ei].to_le_bytes());
    }

    // Append converted containers with CSUM trailers
    for converted in &converted_containers {
        let crc = crc32_mercs2(converted);
        output.extend_from_slice(converted);
        output.extend_from_slice(b"CSUM");
        output.extend_from_slice(&crc.to_le_bytes());
    }

    eprintln!("  Output size: {} bytes", output.len());
    Ok(output)
}

/// Convert a single BE UCFX container to LE.
fn convert_container(
    container: &[u8],
    is_ecs: bool,
    entry_idx: usize,
    type_hash: u32,
    report: Option<&mut SchemaCoverageReport>,
) -> Result<Vec<u8>, String> {
    if container.len() < 20 {
        return Err(format!("Entry {} container too small ({})", entry_idx, container.len()));
    }

    let magic = &container[0..4];
    if magic != b"XFCU" && magic != b"UCFX" {
        return Err(format!("Entry {}: bad UCFX magic {:?}", entry_idx, magic));
    }

    let is_be = magic == b"XFCU";
    let read_u32: fn(&[u8], usize) -> u32 = if is_be { read_u32_be } else { mercs2_formats::ffcs::read_u32_le };

    // Read UCFX header fields (bytes 0..20)
    let data_area_off = read_u32(container, 4) as usize;
    let _unk_08 = read_u32(container, 8);
    let _unk_0c = read_u32(container, 12);
    let n_desc = read_u32(container, 16) as usize;

    if n_desc > 10000 {
        return Err(format!("Entry {}: implausible descriptor count {}", entry_idx, n_desc));
    }

    let desc_table_end = 20 + n_desc * 20;
    if desc_table_end > container.len() {
        return Err(format!("Entry {}: descriptor table exceeds container", entry_idx));
    }

    // Parse all descriptors from BE
    let mut descriptors = Vec::with_capacity(n_desc);
    for di in 0..n_desc {
        let row_start = 20 + di * 20;
        let mut tag_bytes = [0u8; 4];
        tag_bytes.copy_from_slice(&container[row_start..row_start + 4]);
        if is_be {
            tag_bytes.reverse();
        }
        let tag = ChunkTag::from_bytes(tag_bytes);

        let row_u0 = read_u32(container, row_start + 4);
        let body_size = read_u32(container, row_start + 8);
        let row_u3 = read_u32(container, row_start + 12);
        let row_u4 = read_u32(container, row_start + 16);

        descriptors.push(Descriptor {
            tag,
            tag_bytes_le: tag_bytes,
            row_u0,
            body_size,
            row_u3,
            row_u4,
        });
    }

    // Build output container
    let mut out = Vec::with_capacity(container.len());

    // Write LE UCFX header
    out.extend_from_slice(b"UCFX");
    out.extend_from_slice(&(data_area_off as u32).to_le_bytes());
    out.extend_from_slice(&_unk_08.to_le_bytes());
    out.extend_from_slice(&_unk_0c.to_le_bytes());
    out.extend_from_slice(&(n_desc as u32).to_le_bytes());

    // Write LE descriptor table
    for desc in &descriptors {
        out.extend_from_slice(&desc.tag_bytes_le);
        out.extend_from_slice(&desc.row_u0.to_le_bytes());
        out.extend_from_slice(&desc.body_size.to_le_bytes());
        out.extend_from_slice(&desc.row_u3.to_le_bytes());
        out.extend_from_slice(&desc.row_u4.to_le_bytes());
    }

    // Copy/convert the data area
    // The data area starts at either `data_area_off` or right after the desc table
    let data_start = if data_area_off > 0 { data_area_off } else { desc_table_end };

    // Pad from desc_table_end to data_start (if there's a gap)
    if data_start > desc_table_end && data_start <= container.len() {
        out.extend_from_slice(&container[desc_table_end..data_start]);
    }

    // For ECS containers, we need to identify COMP groups and convert them using schemas
    if is_ecs {
        convert_ecs_bodies(&mut out, container, &descriptors, data_area_off, is_be, entry_idx, report)?;
    } else {
        convert_generic_bodies(&mut out, container, &descriptors, data_area_off, is_be, type_hash, entry_idx, report)?;
    }

    Ok(out)
}

/// Resolve a descriptor's body slice within the original container.
fn body_range(container: &[u8], row_u0: u32, body_size: u32, data_area_off: usize) -> Option<(usize, usize)> {
    if row_u0 == 0xFFFFFFFF {
        return None; // sentinel
    }
    let start = if data_area_off > 0 {
        data_area_off + row_u0 as usize
    } else {
        8 + row_u0 as usize
    };
    let end = start + body_size as usize;
    if end <= container.len() {
        Some((start, end))
    } else {
        None
    }
}

/// Convert bodies for ECS (layer / ECS_NODE) containers.
/// Identifies COMP triplets (info/schm/data) and applies schema-driven swap.
fn convert_ecs_bodies(
    out: &mut Vec<u8>,
    container: &[u8],
    descriptors: &[Descriptor],
    data_area_off: usize,
    is_be: bool,
    _entry_idx: usize,
    mut report: Option<&mut SchemaCoverageReport>,
) -> Result<(), String> {
    // We need to write body data at the correct offsets.
    // Strategy: build the entire data area as a mutable copy, then do in-place swaps.
    let data_start = if data_area_off > 0 { data_area_off } else {
        20 + descriptors.len() * 20
    };

    if data_start >= container.len() {
        return Ok(());
    }

    let mut data_area = container[data_start..].to_vec();

    // Identify COMP groups: a COMP sentinel followed by info, schm, data children
    let mut i = 0;
    while i < descriptors.len() {
        let desc = &descriptors[i];

        if desc.tag == ChunkTag::Comp && desc.row_u0 == 0xFFFFFFFF {
            // Found COMP group sentinel — look for info/schm/data triplet
            let _group_start = i;
            i += 1;

            let mut info_idx: Option<usize> = None;
            let mut schm_idx: Option<usize> = None;
            let mut data_idx: Option<usize> = None;

            // Scan children until next group sentinel or end
            while i < descriptors.len() && descriptors[i].row_u0 != 0xFFFFFFFF {
                match descriptors[i].tag {
                    ChunkTag::Info => { info_idx = Some(i); }
                    ChunkTag::Schm => { schm_idx = Some(i); }
                    ChunkTag::Data => { data_idx = Some(i); }
                    _ => {}
                }
                i += 1;
            }

            // Extract component name from info body
            let comp_name = if let Some(ii) = info_idx {
                extract_comp_name(container, &descriptors[ii], data_area_off, is_be)
            } else {
                None
            };
            let comp_name_str = comp_name.as_deref().unwrap_or("unknown");

            // Parse schema from schm body; pre-scan type codes for reporting
            let schm_body_range = schm_idx.and_then(|si| {
                body_range(container, descriptors[si].row_u0, descriptors[si].body_size, data_area_off)
            });

            let schema = schm_body_range.and_then(|(start, end)| {
                ComponentSchema::from_schm_body(&container[start..end], is_be)
            });

            // Report schema field type codes
            if let Some(ref mut rpt) = report {
                if let Some((start, end)) = schm_body_range {
                    let scanned = scan_schm_type_codes(&container[start..end], is_be);
                    let mut unknown_in_body = Vec::new();
                    for &(type_code, name_hash, byte_offset) in &scanned {
                        rpt.record_field(type_code);
                        if SchemaFieldType::from_code(type_code).is_none() {
                            rpt.record_unknown_field(comp_name_str, type_code, name_hash, byte_offset);
                            unknown_in_body.push(type_code);
                        }
                    }
                    if schema.is_none() && !scanned.is_empty() {
                        rpt.record_schema_parse_failure(comp_name_str, unknown_in_body);
                    }
                }
            }

            // Convert the data body using the schema
            if let Some(di) = data_idx {
                let d = &descriptors[di];
                if let Some((start, end)) = body_range(container, d.row_u0, d.body_size, data_area_off) {
                    let body_local_start = start - data_start;
                    let body_local_end = end - data_start;
                    if body_local_end <= data_area.len() {
                        let data_size = body_local_end - body_local_start;
                        let body_slice = &mut data_area[body_local_start..body_local_end];
                        convert_comp_data_inplace(body_slice, schema.as_ref(), comp_name_str, report.as_deref_mut(), data_size);
                    }
                }
            }

            // Swap the info body:
            //   ASCII format: [name\0][u32 hash][u32 a][u32 b][u32 c] — swap trailing u32s
            //   Compact binary (16B): [u32 hash][u32][u32][u32] — swap all u32s
            if let Some(ii) = info_idx {
                let d = &descriptors[ii];
                if let Some((start, end)) = body_range(container, d.row_u0, d.body_size, data_area_off) {
                    let body_local_start = start - data_start;
                    let body_local_end = end - data_start;
                    if body_local_end <= data_area.len() {
                        let info_body = &mut data_area[body_local_start..body_local_end];
                        let nul_pos = info_body.iter().position(|&b| b == 0);
                        match nul_pos {
                            Some(np) if np > 0 && String::from_utf8(info_body[..np].to_vec()).is_ok() => {
                                // ASCII format: swap u32 fields after the null-terminated name
                                let u32_start = np + 1;
                                let remaining = info_body.len() - u32_start;
                                let n_u32 = remaining / 4;
                                for fi in 0..n_u32 {
                                    swap_u32(info_body, u32_start + fi * 4);
                                }
                            }
                            _ => {
                                // Compact binary format: swap all as u32 array
                                swap_u32_array(info_body);
                            }
                        }
                    }
                }
            }

            // Swap the schm body (all u32 fields)
            if let Some(si) = schm_idx {
                let d = &descriptors[si];
                if let Some((start, end)) = body_range(container, d.row_u0, d.body_size, data_area_off) {
                    let body_local_start = start - data_start;
                    let body_local_end = end - data_start;
                    if body_local_end <= data_area.len() {
                        swap_u32_array(&mut data_area[body_local_start..body_local_end]);
                    }
                }
            }

            eprintln!("    COMP group: '{}' (schema: {})",
                comp_name_str,
                if schema.is_some() { "yes" } else { "no" });
        } else {
            // Non-COMP descriptor in an ECS container — swap as appropriate
            if desc.row_u0 != 0xFFFFFFFF {
                if let Some((start, end)) = body_range(container, desc.row_u0, desc.body_size, data_area_off) {
                    let body_local_start = start - data_start;
                    let body_local_end = end - data_start;
                    if body_local_end <= data_area.len() {
                        if desc.tag == ChunkTag::Enum {
                            convert_enum_body_inplace(&mut data_area[body_local_start..body_local_end]);
                        } else if desc.tag == ChunkTag::Deps {
                            let body_len = body_local_end - body_local_start;
                            if body_len > 1 {
                                swap_u32_array(&mut data_area[body_local_start + 1..body_local_end]);
                            }
                        } else if desc.tag == ChunkTag::Flgs {
                            convert_vz_state_flgs_inplace(
                                &mut data_area[body_local_start..body_local_end],
                            );
                        } else if desc.tag.is_native_be() {
                            // No swap
                        } else {
                            swap_u32_array(&mut data_area[body_local_start..body_local_end]);
                        }
                    }
                }
            }
            i += 1;
        }
    }

    out.extend_from_slice(&data_area);
    Ok(())
}

/// Component-name hash → name lookup for compact-format info bodies (16-byte
/// binary, no ASCII string). Values are pandemic_hash_m2(component_name).
const COMP_HASH_TO_NAME: &[(u32, &str)] = &[
    (0x753EB623, "Transform"),
    (0x1DE5C824, "Name"),
    (0x5CF81991, "ModelName"),
    (0x97E8EE92, "LightObject"),
    (0xEA0F3AA3, "Road"),
    (0x6FD048F4, "RoadIntersection"),
    (0xBCE6FAD7, "DestructionLink"),
    (0x7FBCE14E, "PhysicalLink"),
    (0xD81512A1, "ObjectScript"),
    (0x99C2B81F, "ModifierKey"),
    (0xAB92C697, "ScrubObject"),
    (0x6310807F, "LineRegion"),
    (0x49F0D0EC, "MaterialMapping"),
    (0x2A20B640, "LandingZone"),
    (0x06DA8775, "Label"),
    (0xFA55F6BA, "Anchor"),
    (0x2D8D2435, "LowResTerrainObject"),
    (0xE18AFD65, "HibernationControl"),
    (0xB8D2B506, "AtmosphereBase"),
    (0xEB6DE962, "IntersectionToIntersection"),
    (0x514CAD3A, "SoundAmbience"),
    (0xDECD8889, "AiBehavior"),
    (0xBCFE6314, "Path"),
    (0x6FA2F9D4, "LaneData"),
];

/// Extract component name from an `info` descriptor body.
///
/// Two formats exist:
///   1. ASCII format: `[null-terminated name][u32 hash][u32 a][u32 b][u32 c]`
///   2. Compact binary format (16 bytes): `[u32 comp_hash][u32][u32][u32]`
///      Used in blocks without `schm`/`enum` descriptors.
fn extract_comp_name(
    container: &[u8],
    desc: &Descriptor,
    data_area_off: usize,
    is_be: bool,
) -> Option<String> {
    let (start, end) = body_range(container, desc.row_u0, desc.body_size, data_area_off)?;
    let body = &container[start..end];

    // Try ASCII format first
    let nul_pos = body.iter().position(|&b| b == 0).unwrap_or(body.len());
    if nul_pos > 0 {
        if let Ok(name) = String::from_utf8(body[..nul_pos].to_vec()) {
            return Some(name);
        }
    }

    // Compact binary format: first u32 is the component name hash (in BE)
    if body.len() >= 4 {
        let hash = if is_be {
            read_u32_be(body, 0)
        } else {
            mercs2_formats::ffcs::read_u32_le(body, 0)
        };
        for &(h, name) in COMP_HASH_TO_NAME {
            if h == hash {
                return Some(name.to_string());
            }
        }
        // Unknown hash — return a diagnostic placeholder
        return Some(format!("__hash_0x{:08X}", hash));
    }

    None
}

/// Pre-scan a schm body to extract raw type codes for reporting.
/// Unlike ComponentSchema::from_schm_body, this does NOT bail on unknown codes.
/// Returns Vec<(type_code, name_hash, byte_offset)>.
fn scan_schm_type_codes(body: &[u8], is_be: bool) -> Vec<(u32, u32, u16)> {
    if body.len() < 8 {
        return vec![];
    }

    let n_fields = if is_be {
        u32::from_be_bytes([body[0], body[1], body[2], body[3]])
    } else {
        u32::from_le_bytes([body[0], body[1], body[2], body[3]])
    };

    if n_fields > 200 || (8 + n_fields as usize * 16) > body.len() {
        return vec![];
    }

    let mut result = Vec::with_capacity(n_fields as usize);
    for i in 0..n_fields as usize {
        let off = 8 + i * 16;
        let (type_code, name_hash, raw_offset) = if is_be {
            (
                u32::from_be_bytes([body[off], body[off + 1], body[off + 2], body[off + 3]]),
                u32::from_be_bytes([body[off + 4], body[off + 5], body[off + 6], body[off + 7]]),
                u32::from_be_bytes([body[off + 12], body[off + 13], body[off + 14], body[off + 15]]),
            )
        } else {
            (
                u32::from_le_bytes([body[off], body[off + 1], body[off + 2], body[off + 3]]),
                u32::from_le_bytes([body[off + 4], body[off + 5], body[off + 6], body[off + 7]]),
                u32::from_le_bytes([body[off + 12], body[off + 13], body[off + 14], body[off + 15]]),
            )
        };
        let byte_offset = ((raw_offset >> 16) & 0xFFFF) as u16;
        result.push((type_code, name_hash, byte_offset));
    }
    result
}

/// Convert a COMP data body in-place using schema-driven field swaps.
fn convert_comp_data_inplace(
    data: &mut [u8],
    schema: Option<&ComponentSchema>,
    comp_name: &str,
    mut report: Option<&mut SchemaCoverageReport>,
    data_size: usize,
) {
    if data.is_empty() {
        return;
    }

    // Special cases
    match comp_name {
        "Name" => {
            if let Some(ref mut rpt) = report {
                rpt.record_no_schema(comp_name, data_size, "hardcoded handler");
            }
            convert_name_data_inplace(data);
            return;
        }
        "ModelName" => {
            if let Some(ref mut rpt) = report {
                rpt.record_no_schema(comp_name, data_size, "hardcoded handler");
            }
            convert_modelname_data_inplace(data);
            return;
        }
        _ => {}
    }

    // Compact-format COMP groups have info (hash) but no schm; mirror Python
    // `_ECS_COMP_DEFAULT_STRIDE` — do not blind-sweep whole bodies.
    let stride = if comp_name == "Transform" {
        42
    } else if let Some(s) = schema {
        // schm[4:8] is payload_stride; record = 4-byte entity key + payload (docs/ecs_components.md)
        4 + s.payload_stride as usize
    } else if let Some(s) = compact_default_stride(comp_name) {
        s
    } else {
        if let Some(ref mut rpt) = report {
            rpt.record_no_schema(comp_name, data_size, "u32_array sweep (unknown stride)");
        }
        swap_u32_array(data);
        return;
    };

    if stride == 0 {
        if let Some(ref mut rpt) = report {
            rpt.record_no_schema(comp_name, data_size, "u32_array sweep (stride=0)");
        }
        swap_u32_array(data);
        return;
    }

    // Non-Transform ECS components: record-aligned u32 (and u16 tail) swap.
    if comp_name != "Transform" && (schema.is_none() || is_ecs_numeric_component(comp_name)) {
        if let Some(ref mut rpt) = report {
            rpt.record_no_schema(comp_name, data_size, "numeric records (compact stride)");
        }
        swap_numeric_records_inplace(data, stride);
        return;
    }

    let record_count = data.len() / stride;

    for ri in 0..record_count {
        let rec_start = ri * stride;

        // Always swap the u32 entity_key at record start
        if rec_start + 4 <= data.len() {
            swap_u32(data, rec_start);
        }

        if comp_name == "Transform" {
            // Hardcoded Transform layout: 3xf32 pos + f32 pad + 4xf32 quat + 6 raw bytes
            for field_off in [0, 4, 8, 12, 16, 20, 24, 28] {
                let off = rec_start + 4 + field_off;
                if off + 4 <= data.len() {
                    swap_u32(data, off);
                }
            }
            // Tail 6 bytes at +32..+37: no swap (u8 data)
        } else {
            // Schema-driven swap
            let schema = schema.unwrap();
            for field in &schema.fields {
                if !field.field_type.needs_swap() {
                    continue;
                }
                let payload_off = rec_start + 4 + field.byte_offset as usize;
                let unit = field.field_type.swap_unit();
                let count = field.field_type.swap_count();
                for fi in 0..count {
                    let off = payload_off + fi * unit;
                    if off + unit <= data.len() {
                        match unit {
                            2 => swap_u16(data, off),
                            4 => swap_u32(data, off),
                            _ => {}
                        }
                    }
                }
            }
        }
    }
}

/// Convert Name component data in-place (variable-length records).
///
/// Layout: `[u32 entity_key][null-terminated ASCII name]` repeated.
/// Only the u32 keys need byte-swapping; string bytes are order-independent.
///
/// IMPORTANT: Skip exactly ONE null byte (the terminator) after each string.
/// Do NOT skip additional nulls — the next entity key may start with 0x00
/// (high byte of a small BE u32 like 0x0014E333 → bytes [00 14 E3 33]).
/// Skipping that leading 0x00 shifts the swap by one byte, corrupting all
/// subsequent records.
fn convert_name_data_inplace(data: &mut [u8]) {
    let mut pos = 0;
    while pos + 4 <= data.len() {
        swap_u32(data, pos);
        pos += 4;
        // Skip string bytes until null terminator
        while pos < data.len() && data[pos] != 0 {
            pos += 1;
        }
        // Skip exactly one null terminator
        if pos < data.len() {
            pos += 1;
        }
    }
}

/// Convert ModelName component data in-place (fixed stride 8: u32 key + u32 hash).
fn convert_modelname_data_inplace(data: &mut [u8]) {
    let stride = 8;
    let count = data.len() / stride;
    for i in 0..count {
        let off = i * stride;
        if off + 8 <= data.len() {
            swap_u32(data, off);
            swap_u32(data, off + 4);
        }
    }
}

/// Convert bodies for non-ECS (generic) containers with tag-aware dispatch.
fn convert_generic_bodies(
    out: &mut Vec<u8>,
    container: &[u8],
    descriptors: &[Descriptor],
    data_area_off: usize,
    _is_be: bool,
    type_hash: u32,
    entry_idx: usize,
    mut report: Option<&mut SchemaCoverageReport>,
) -> Result<(), String> {
    let data_start = if data_area_off > 0 { data_area_off } else {
        20 + descriptors.len() * 20
    };

    if data_start >= container.len() {
        return Ok(());
    }

    let mut data_area = container[data_start..].to_vec();
    let is_texture = type_hash == types::TYPE_HASH_TEXTURE;

    for desc in descriptors {
        if desc.row_u0 == 0xFFFFFFFF {
            continue; // group sentinel
        }

        if let Some((start, end)) = body_range(container, desc.row_u0, desc.body_size, data_area_off) {
            let body_local_start = start - data_start;
            let body_local_end = end - data_start;
            if body_local_end <= data_area.len() {
                match desc.tag {
                    ChunkTag::Syek | ChunkTag::Srts => {
                        // Native BE on all platforms — no swap
                    }
                    tag if is_string_tag(tag) => {
                        // String data — no swap
                    }
                    ChunkTag::Prmt => {
                        // Mesh draw-call parameter binding: 16-byte records of u16 fields
                        swap_u16_array(&mut data_area[body_local_start..body_local_end]);
                    }
                    ChunkTag::Enum => {
                        // Enum definitions: mixed strings + u32 fields
                        convert_enum_body_inplace(&mut data_area[body_local_start..body_local_end]);
                    }
                    ChunkTag::Ibuf => {
                        swap_u16_array(&mut data_area[body_local_start..body_local_end]);
                    }
                    ChunkTag::InfoUpper if is_texture => {
                        convert_texture_info(&mut data_area[body_local_start..body_local_end]);
                    }
                    ChunkTag::Body if is_texture => {
                        // DXT compressed pixel data — leave as-is.
                        // Proper texture BODY conversion (untiling) is Phase 3+.
                    }
                    ChunkTag::Decl | ChunkTag::Schm | ChunkTag::Flgs => {
                        swap_u32_array(&mut data_area[body_local_start..body_local_end]);
                    }
                    ChunkTag::Deps => {
                        // DEPS format: [u8 count][u32 hash × count]
                        // Preserve the count byte, only swap the hash array
                        let body_len = body_local_end - body_local_start;
                        if body_len > 1 {
                            swap_u32_array(&mut data_area[body_local_start + 1..body_local_end]);
                        }
                    }
                    other_tag => {
                        if let Some(ref mut rpt) = report {
                            let type_name = types::type_name_from_hash(type_hash);
                            rpt.record_generic_fallback(
                                entry_idx,
                                type_hash,
                                type_name,
                                &format!("{}", other_tag),
                                desc.body_size,
                            );
                        }
                        swap_u32_array(&mut data_area[body_local_start..body_local_end]);
                    }
                }
            }
        }
    }

    out.extend_from_slice(&data_area);
    Ok(())
}

/// Tags whose bodies are string data (no swap needed).
fn is_string_tag(tag: ChunkTag) -> bool {
    matches!(tag, ChunkTag::Name | ChunkTag::Strs)
}

// --- Byte swap primitives ---

fn swap_u32(data: &mut [u8], offset: usize) {
    data[offset..offset + 4].reverse();
}

fn swap_u16(data: &mut [u8], offset: usize) {
    data[offset..offset + 2].reverse();
}

/// Swap every aligned 2-byte word in a slice. Trailing odd byte is left untouched.
fn swap_u16_array(data: &mut [u8]) {
    let n = data.len() / 2;
    for i in 0..n {
        let off = i * 2;
        data[off..off + 2].reverse();
    }
}

/// Convert a Texture INFO body (34 bytes, mixed u16/u32 fields).
/// Layout verified from format_reference.md:
///   +0: u16 width, +2: u16 height, +4: u32, +8: u32,
///   +12: u16, +14: bytes[8] (fourcc and related — leave as-is),
///   +22: u32 total_size, +26: u32, +30: u32
/// If body is smaller than 34 bytes, fall back to u32 array.
fn convert_texture_info(body: &mut [u8]) {
    if body.len() < 34 {
        swap_u32_array(body);
        return;
    }
    swap_u16(body, 0);  // width
    swap_u16(body, 2);  // height
    swap_u32(body, 4);
    swap_u32(body, 8);
    swap_u16(body, 12);
    // bytes 14..22: fourcc and format data — leave as raw bytes
    swap_u32(body, 22); // total_size
    swap_u32(body, 26);
    swap_u32(body, 30);
}

/// Convert an `enum` body in-place from BE to LE.
///
/// Layout (verified from base game):
///   [u32 total_enum_count]
///   repeated total_enum_count times:
///     [null-terminated ASCII enum name]
///     [u32 name_hash]
///     [u32 value_count]
///     repeated value_count times:
///       [null-terminated ASCII value name]
///       [u32 value_hash]
///       [u32 ordinal]
fn convert_enum_body_inplace(data: &mut [u8]) {
    if data.len() < 4 {
        return;
    }

    let total = u32::from_be_bytes([data[0], data[1], data[2], data[3]]);
    swap_u32(data, 0);
    eprintln!("      enum body: total_enum_count={}", total);

    let mut pos = 4usize;
    for _ in 0..total {
        if pos >= data.len() {
            break;
        }
        // Skip null-terminated enum name string
        match data[pos..].iter().position(|&b| b == 0) {
            Some(nul_rel) => pos += nul_rel + 1,
            None => break,
        }
        // Swap name_hash (u32)
        if pos + 4 > data.len() {
            break;
        }
        swap_u32(data, pos);
        pos += 4;
        // Swap value_count (u32)
        if pos + 4 > data.len() {
            break;
        }
        let val_count = u32::from_be_bytes([data[pos], data[pos + 1], data[pos + 2], data[pos + 3]]);
        swap_u32(data, pos);
        pos += 4;
        // Walk each value: [name\0] [u32 hash] [u32 ordinal]
        for _ in 0..val_count {
            if pos >= data.len() {
                break;
            }
            match data[pos..].iter().position(|&b| b == 0) {
                Some(nul_rel) => pos += nul_rel + 1,
                None => break,
            }
            if pos + 8 > data.len() {
                break;
            }
            swap_u32(data, pos);     // value_hash
            pos += 4;
            swap_u32(data, pos);     // ordinal
            pos += 4;
        }
    }
}

/// vz_state `flgs` body: variable header (ASCII names, endian-neutral) + 42-byte records.
///
/// Record layout (BE input, matches `tools/ucfx_be_to_le._convert_vz_state_flgs`):
///   [0:12]  3×u32, [12:14] u16, [14:42] 7×u32 (entity_id, pos xyz, rot fields).
const FLGS_RECORD_STRIDE: usize = 42;
const BE_ONE_F: [u8; 4] = [0x3F, 0x80, 0x00, 0x00];

fn convert_vz_state_flgs_inplace(data: &mut [u8]) {
    if data.is_empty() {
        return;
    }

    let marker_pos = data
        .windows(BE_ONE_F.len())
        .position(|w| w == BE_ONE_F);
    let rec_start = match marker_pos {
        Some(p) if p >= 4 => p - 4,
        Some(_) => 0,
        None => {
            if data.len().is_multiple_of(4) {
                swap_u32_array(data);
            }
            return;
        }
    };

    let rec_data = &mut data[rec_start..];
    let n_full = rec_data.len() / FLGS_RECORD_STRIDE;
    let mut pos = 0usize;
    for _ in 0..n_full {
        if pos + FLGS_RECORD_STRIDE > rec_data.len() {
            break;
        }
        for off in (0..12).step_by(4) {
            swap_u32(rec_data, pos + off);
        }
        swap_u16(rec_data, pos + 12);
        for off in (14..42).step_by(4) {
            swap_u32(rec_data, pos + off);
        }
        pos += FLGS_RECORD_STRIDE;
    }
    if pos < rec_data.len() && rec_data.len().is_multiple_of(4) {
        swap_u32_array(&mut rec_data[pos..]);
    }
}

/// Compact `info` bodies without `schm` — full record strides (4 + payload_stride).
/// Values match `docs/ecs_components.md` (not raw schm payload_stride alone).
fn compact_default_stride(comp_name: &str) -> Option<usize> {
    match comp_name {
        "Transform" => Some(42),
        // Name is variable-length; handled by convert_name_data_inplace
        "Name" => None,
        "HibernationControl" => Some(10),
        "Label" => Some(8),
        "ScrubObject" => Some(8),
        "LineRegion" => Some(8),
        "Road" => Some(44),
        "RoadIntersection" => Some(128),
        "ObjectScript" => Some(12),
        "Anchor" => Some(20),
        "AiBehavior" => Some(52),
        "SoundAmbience" => Some(24),
        "AtmosphereBase" => Some(744),
        "IntersectionToIntersection" => Some(12),
        // ModelName handled by convert_modelname_data_inplace (stride 8)
        "ModelName" => None,
        "LightObject" => Some(56),
        "DestructionLink" => Some(20),
        "PhysicalLink" => Some(20),
        "ModifierKey" => Some(12),
        "MaterialMapping" => Some(8),
        "LandingZone" => Some(8),
        "LowResTerrainObject" => Some(12),
        "Path" => Some(8),
        "LaneData" => Some(8),
        _ => None,
    }
}

fn is_ecs_numeric_component(comp_name: &str) -> bool {
    matches!(
        comp_name,
        "LightObject"
            | "Road"
            | "RoadIntersection"
            | "DestructionLink"
            | "PhysicalLink"
            | "ObjectScript"
            | "ModifierKey"
            | "ScrubObject"
            | "LineRegion"
            | "MaterialMapping"
            | "LandingZone"
            | "Label"
            | "Anchor"
            | "LowResTerrainObject"
            | "HibernationControl"
            | "AtmosphereBase"
            | "IntersectionToIntersection"
            | "SoundAmbience"
            | "AiBehavior"
            | "Path"
            | "LaneData"
    )
}

/// Fixed-stride numeric ECS records (Python `_convert_numeric_records`).
fn swap_numeric_records_inplace(data: &mut [u8], stride: usize) {
    if stride == 0 {
        return;
    }
    let mut pos = 0usize;
    while pos + stride <= data.len() {
        let n_u32 = stride / 4;
        for i in 0..n_u32 {
            swap_u32(data, pos + i * 4);
        }
        let tail = stride % 4;
        if tail >= 2 {
            swap_u16(data, pos + n_u32 * 4);
        }
        pos += stride;
    }
    if pos < data.len() && data[pos..].len().is_multiple_of(4) {
        swap_u32_array(&mut data[pos..]);
    }
}

/// Swap every aligned 4-byte word in a slice. Trailing bytes (< 4) are left untouched.
fn swap_u32_array(data: &mut [u8]) {
    let n = data.len() / 4;
    for i in 0..n {
        let off = i * 4;
        data[off..off + 4].reverse();
    }
}

/// Walk a BE UCFX container's descriptor table, identifying all chunk tags (diagnostic only).
fn walk_container_tags(container: &[u8], entry_idx: usize) -> Result<(), String> {
    if container.len() < 20 {
        return Err(format!("Entry {} container too small", entry_idx));
    }

    let magic = &container[0..4];
    if magic != b"XFCU" && magic != b"UCFX" {
        return Err(format!("Entry {}: bad UCFX magic {:?}", entry_idx, magic));
    }

    let is_be = magic == b"XFCU";
    let read_u32: fn(&[u8], usize) -> u32 = if is_be { read_u32_be } else { mercs2_formats::ffcs::read_u32_le };

    let data_area_off = read_u32(container, 4) as usize;
    let n_desc = read_u32(container, 16) as usize;

    if n_desc > 10000 {
        return Err(format!("Entry {}: implausible descriptor count {}", entry_idx, n_desc));
    }

    for di in 0..n_desc {
        let row_start = 20 + di * 20;
        if row_start + 20 > container.len() {
            break;
        }

        let mut tag_bytes = [0u8; 4];
        tag_bytes.copy_from_slice(&container[row_start..row_start + 4]);
        if is_be {
            tag_bytes.reverse();
        }

        let tag = ChunkTag::from_bytes(tag_bytes);
        let row_u0 = read_u32(container, row_start + 4);
        let body_size = read_u32(container, row_start + 8);

        let is_sentinel = row_u0 == 0xFFFFFFFF;

        if is_sentinel {
            eprintln!("    desc[{}]: {} (group marker)", di, tag);
        } else {
            let body_off = if data_area_off > 0 {
                data_area_off + row_u0 as usize
            } else {
                8 + row_u0 as usize
            };

            if tag.is_native_be() {
                eprintln!("    desc[{}]: {} @{} size={} [NATIVE BE - NO SWAP]",
                    di, tag, body_off, body_size);
            } else {
                eprintln!("    desc[{}]: {} @{} size={}", di, tag, body_off, body_size);
            }
        }
    }

    Ok(())
}
