use mercs2_formats::crc32::crc32_mercs2;
use mercs2_formats::ffcs::read_u32_be;
use mercs2_formats::schema::ComponentSchema;
use mercs2_formats::tags::ChunkTag;
use mercs2_formats::types;

const TYPE_HASH_ECS_NODE: u32 = types::TYPE_HASH_LAYER; // 0xE6B81A54

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
pub fn convert_block(be_data: &[u8], dry_run: bool) -> Result<Vec<u8>, String> {
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

            let container = &be_data[offset..container_end];
            let type_name = types::type_name_from_hash(entry.type_hash);
            eprintln!("  Entry {}: name=0x{:08x} type_hash=0x{:08x} ({}) size={}",
                ei, entry.name_hash, entry.type_hash, type_name, entry.chunk_size);

            match walk_container_tags(container, ei) {
                Ok(()) => {}
                Err(e) => eprintln!("    [skip] {}", e),
            }

            offset = container_end;
            if offset + 8 <= be_data.len() {
                offset += 8;
            }
        }
        return Ok(Vec::new());
    }

    // --- Actual conversion ---
    let mut output = Vec::with_capacity(be_data.len());

    // Write LE entry table
    output.extend_from_slice(&(entry_count as u32).to_le_bytes());
    for entry in &entries {
        output.extend_from_slice(&entry.name_hash.to_le_bytes());
        output.extend_from_slice(&entry.type_hash.to_le_bytes());
        output.extend_from_slice(&entry.field_c.to_le_bytes());
        output.extend_from_slice(&entry.chunk_size.to_le_bytes());
    }

    // Convert each container
    let mut offset = header_size;
    for (ei, entry) in entries.iter().enumerate() {
        let container_end = offset + entry.chunk_size as usize;
        if container_end > be_data.len() {
            return Err(format!("Entry {} container exceeds block (offset={}, size={})",
                ei, offset, entry.chunk_size));
        }

        let container = &be_data[offset..container_end];
        let type_name = types::type_name_from_hash(entry.type_hash);
        eprintln!("  Converting entry {}: type=0x{:08x} ({}) size={}",
            ei, entry.type_hash, type_name, entry.chunk_size);

        let is_ecs = entry.type_hash == TYPE_HASH_ECS_NODE;
        let converted = convert_container(container, is_ecs, ei, entry.type_hash)?;

        // Compute CSUM and append trailer
        let crc = crc32_mercs2(&converted);
        output.extend_from_slice(&converted);
        output.extend_from_slice(b"CSUM");
        output.extend_from_slice(&crc.to_le_bytes());

        offset = container_end;
        // Skip original CSUM trailer
        if offset + 8 <= be_data.len() {
            let maybe_csum = &be_data[offset..offset + 4];
            if maybe_csum == b"CSUM" || maybe_csum == b"MUSC" {
                offset += 8;
            }
        }
    }

    eprintln!("  Output size: {} bytes", output.len());
    Ok(output)
}

/// Convert a single BE UCFX container to LE.
fn convert_container(container: &[u8], is_ecs: bool, entry_idx: usize, type_hash: u32) -> Result<Vec<u8>, String> {
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

    if n_desc > 5000 {
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
        convert_ecs_bodies(&mut out, container, &descriptors, data_area_off, is_be, entry_idx)?;
    } else {
        convert_generic_bodies(&mut out, container, &descriptors, data_area_off, is_be, type_hash)?;
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

            // Parse schema from schm body
            let schema = if let Some(si) = schm_idx {
                if let Some((start, end)) = body_range(container, descriptors[si].row_u0, descriptors[si].body_size, data_area_off) {
                    ComponentSchema::from_schm_body(&container[start..end], is_be)
                } else {
                    None
                }
            } else {
                None
            };

            // Convert the data body using the schema
            if let Some(di) = data_idx {
                let d = &descriptors[di];
                if let Some((start, end)) = body_range(container, d.row_u0, d.body_size, data_area_off) {
                    let body_local_start = start - data_start;
                    let body_local_end = end - data_start;
                    if body_local_end <= data_area.len() {
                        let body_slice = &mut data_area[body_local_start..body_local_end];
                        convert_comp_data_inplace(body_slice, schema.as_ref(), comp_name_str);
                    }
                }
            }

            // Swap the info body (it's just ASCII name — no swap needed, but swap
            // any leading u32 fields if the info has a hash prefix)
            // Actually info bodies for ECS are just null-terminated ASCII — leave them.

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
                        if desc.tag.is_native_be() {
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

/// Extract component name string from an `info` descriptor body.
fn extract_comp_name(
    container: &[u8],
    desc: &Descriptor,
    data_area_off: usize,
    _is_be: bool,
) -> Option<String> {
    let (start, end) = body_range(container, desc.row_u0, desc.body_size, data_area_off)?;
    let body = &container[start..end];
    // Info body is null-terminated ASCII
    let nul_pos = body.iter().position(|&b| b == 0).unwrap_or(body.len());
    if nul_pos == 0 {
        return None;
    }
    String::from_utf8(body[..nul_pos].to_vec()).ok()
}

/// Convert a COMP data body in-place using schema-driven field swaps.
fn convert_comp_data_inplace(data: &mut [u8], schema: Option<&ComponentSchema>, comp_name: &str) {
    if data.is_empty() {
        return;
    }

    // Special cases
    match comp_name {
        "Name" => {
            convert_name_data_inplace(data);
            return;
        }
        "ModelName" => {
            convert_modelname_data_inplace(data);
            return;
        }
        _ => {}
    }

    let total_stride = if let Some(s) = schema {
        4 + s.payload_stride as usize
    } else {
        // No schema: fallback to u32 array swap
        swap_u32_array(data);
        return;
    };

    // Transform override: actual stride is 42, not schm's 56
    let stride = if comp_name == "Transform" { 42 } else { total_stride };

    if stride == 0 {
        swap_u32_array(data);
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
fn convert_name_data_inplace(data: &mut [u8]) {
    let mut pos = 0;
    while pos + 4 <= data.len() {
        swap_u32(data, pos);
        pos += 4;
        // Skip string until null terminator
        while pos < data.len() && data[pos] != 0 {
            pos += 1;
        }
        // Skip null terminator(s) / padding
        while pos < data.len() && data[pos] == 0 {
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
                    _ => {
                        // Default: safe for GEOM, STRM positions, BNDS, HIER, PRMG, etc.
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

    if n_desc > 5000 {
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
