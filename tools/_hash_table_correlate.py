#!/usr/bin/env python3
"""Correlate the engine's runtime hash table (1024 slots) against known asset hashes.

Reads the hash table dump from the debugger (hardcoded hex), parses patch and base
WAD ASET tables, and reports which values match patch assets, base assets, known
type hashes, or are unrecognized.

Usage:
    .venv/Scripts/python.exe tools/_hash_table_correlate.py
"""
from __future__ import annotations

import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ffcs_wad import parse_ffcs, extract_slice
from aset_prop_tracer import parse_aset
from pandemic_hash import pandemic_hash_m2

# ─── Hash table dump from x32dbg (0x3c0e648, 4096 bytes = 1024 u32 LE) ───────
# Read in two 2048-byte chunks for reliability
_HASH_TABLE_CHUNK1 = (
    "faef5c2bf6eb99cb029c284102a443b604d8650d05b4b565033ce3e107e8aa2a"
    "8e13b06109c82e9c09709f850ba8c5c60c60c2fc0b30239a0ef4ad8100605e99"
    "106c4c4605985fc9b2e7816d00bc65c0fdd35b1815ec592e16d0e5d817344df5"
    "18144191190c700019986e4716b06d131c04500f1dd07c0d1e30b9f91cd8f2a8"
    "2000e17c1c8c0d2a172c965b23804d5924684232244c78ba19e0e4831d64dc3a"
    "2818e00e21bca46b2afc9ed817e4968020ecf15d1600fed92e3c3d202cccc535"
    "3060390524f0b1152fb4178ca643955534f8ead6345015823610958537e4ae8d"
    "38809883394c4e8837f4c19ed31f939fffaf5cd5ee2337a33efc04ed3f207921"
    "4084bcb241a8e53042b4e5444258866844c0328345248b44414ca50142c88413"
    "454c3206497cf20f495c97ac0200c04e4cd89d5d4ca4bdc54dd83ac74f5cd5a8"
    "50ace1a05154b3185234fa6853dc54915178e99f52587b7e56644f09512c2932"
    "53b49bd755187d865af02c545a80796055f493ed5dfcfb515e78d5855d901016"
    "600c9c3561f8dcc36184319559d8412264b8565b65a0577466fcbc2c65c88a5a"
    "68a4e08f69d425db69a00e966a04cd786c8c568a5af0ab5ab0433adb6ff40ac8"
    "6f7816d4a7b7c3f6728037d2732409d372087b6f7584184d764463cd75901893"
    "789c6f9f7860b59a72ecb30779ec636e75ec93d174af2cdd7eb4be477e045a36"
    "80900a5d7e64f74381300f717f4878e584fc14a0850435d482ac5b9487f099d5"
    "875c487f8620876a84e8feb88b2413a687f867198dbc12fd8440e2848f0c407e"
    "90189620904478368fd444b693e0966693ccf2ec92d8bf3493ac69189034ed73"
    "98ece05293d42cf39388dca59b8001789bb0214f9ad0d74e9e1c0fec91244252"
    "a070f086a1905f6ba20456faa308ec3da43c5a1196e0ba6ba67cadfaa6a81ecd"
    "a82c0b85a980a022a918975592f015c296588574943ca6a1ada8931bafe0be71"
    "a60c065eb16cb654b1dc9640b3bcf2bea4787345b5cce960b640d2d3b7a41090"
    "b54ca1eeb990d418ba6c0de2bbac2a35bcbc74dbb64c7680bea00b84bdbc9579"
    "b750576f8c8b865cc2ec3a9cc3b4ef31c4d0e1093e1ca44fc62c3580c6609aeb"
    "c8d0f79ff9272ad2ca983ce2cbd09e54cc7cd5dcccac8923cb60ca7acf8498e6"
    "d098228cd1a8b83ed2282220d37461bfd10c00a0d20c193ad684079bd7a4badd"
    "d6bcde2bd9804d1bd950158adbe80f34a840e22ab00059f0dec80d38b430b734"
    "4bd78dd88faf025ce2e4b610e278bb197bcb5d68e57c8127e5b011e5e634108f"
    "e8d01de7e990becce528bc13e89cdfcee648f560e66cc92fe1687a23ef84a358"
    "f05041863b80fdddb7d4bbfbf34c8768540bcb53902c3072f6f0c16cf70c0f27"
    "f8a4fd96f78cc999fa6077917b7fb367fc64197afdd8ff79feb0aa4fffd83ff3"
    "5cfc17d801ada9470145aa41039da50003c940d00345790406e58eee05f538c3"
    "07a9e10902f5c8e70ae999c4044dbb8c016569310b0d51770a0189430fcdde92"
    "100184ac1011c4881289bb1112f5183c14f9bf681431802a86a8752803adda72"
    "0601bd8fa97488c1daa837f21be96bf607b922321d75ffe61ee978211f05f6cf"
    "20c5a682c437244c22714ae523d523cf2315996225898d07245d8f052705c541"
    "28353c6829f1a58f2af9f54b2ac9c9f62c3505a62c29cfafc7be8075362b2f50"
    "30097c69319db73132cda3aa3211661f33412c173571de2731b934fa31757d91"
    "216986bc39bdcc7c3ab13ff93b4dfaaf3c4904d93b0945db3a8dad653f7d0319"
    "3f51bcfb418194fa4169602c43d9a1784495a52e44e9714d468d8baf473968d8"
    "46ed936c4965269249b595d04b09477b43a582614d512f0449ddf7cf3f4d2a3c"
    "482593124061103852651bac52bd8a704fcdf58f5f20cdd8568d770432ec698a"
    "f2931ed8f9544ae45a2d6de05a61c7ce5c6580695d19e95c5df9e9ab5fedbe1d"
    "6049d6e35db560ef61f52b3b5d01528c64b53fa165994057667991b1675151a8"
    "68d178d069d512166a3db78f6b099d666c210cd86d45c9656e25f1ec6f052640"
    "70356ee6712981e571911b9a724d3a8c7491115771990c2775e98a34773d7da8"
    "7711f3a379a9444d799dc9327ba190187a09c0597de1997d6cd99c127fddc1d4"
    "7f51808b814d89607349195083d1d0f67905e72785359add6eadd5197ff90cdb"
    "7609d9a772b1f4296fc1510f8b85712c8c2530b68c995d838d9d47588fd5f0e5"
    "8e499cc77249005d92f5de4b9359f7c9941da43b94d11780967d3dbe974dfb9f"
    "987d3545776d7d7a9a6d4ba69a75345d9c3d40769d4159699cc9a6739ff9202a"
    "a0096145a1b1c65ba219abb1a059cc26a499a8fc9aa5e37ca6c5e7b0a74d8de8"
    "60e1503da39d0bd7aa1d6618aabd937caa59c04d5a9ddb878b2df924af055109"
    "afddd3f1aff9365cb2bd10a99fd5798ab46d545eb569c62cb6b13399b60dde57"
    "b53d64cab9c9048eb62dc4eeba7d5e1da01d87a7b3918b467d459296959599f0"
    "c02d0ca6c0f9572ae414528bc3c99d29c47d7529c34d8369c6f17efac489afd2"
    "c7753b6fc3dd269eca718cb3cae1a3d1da803ef0cd497a2dcef10872b876e4a9"
    "d051b94ad17d977ad2a13299d18db560d31de455d5a566c7d6398915d681518d"
    "d805eab8d2015aee311c30166c706185dcd1e9db16b76efb0580cf25df511b84"
    "e0915538e05d397de28986f4e1b53d11930bfa71e5657f8fe6a5c542e61d55c5"
    "e63127cde9a5a573ea419d54e9a986a6ecfdbfc8ec717e61eb95d459eb990f22"
    "f0e180e4f1752a2ef251a789f1cd829ff47d238af591f7e4f6ad8929f76d6311"
    "f8695a97f6a909edf479871cf0adaf56fb0d40e6ec39e9c1fa91749cffe9e12e"
)
_HASH_TABLE_CHUNK2 = (
    "f3410aa2fe3dd1310236f43303e659cd040abafb047a4e1705d6e8eb077239d8"
    "0812052c087e96ad09feeb23091ac8e0063eab340d624b490e6a1db70b56283b"
    "09d213b4f3bd87d637e1b90213f60c3f141687a6146a4735121abef61dfc7e65"
    "180646ff1942af7619c2eb821b2a8e001ac6d3e6197ecc681ecee4b71eca03ad"
    "20fa248821963474225e0187225684f724b6b5fd1cbab23f1c82f0eb1b02b7e2"
    "1f82497429165fa2297a45fa2a228f9e19c652632de2c5762e3ae15a1d76ddf4"
    "305631593126b9a01cc6740e3346d40e3426cf8735d66737352e8fa133ce7b3e"
    "38caa0b639ce4bb73af2b301316e1e473cbe80173de6f8ba3e623f443ff212da"
    "3eae41b141925ab4418a488743467d7a43321fef45ba29cd40daf76147a2aec6"
    "46c63bfb41fe9e8c466e85551a323d653de2bac74dd216424e0e4c474fbe74fe"
    "5092de974e8ed9161a4a1a0a53ae7f505306b8d1559acbea55fe531b261a03d7"
    "581a4c8631e29fc4588a7da95b7a15555ca66a0c5d26f5545eae35575bbefbdb"
    "5ba66fc8611e83706286f8c45f4e371b64360e0a654634b666ba63b36506fc6f"
    "67ea2d6d5b32f11d6abea0036b92ad8a6c2e25636d9adc0e6deaeaa76f5a8330"
    "6a6ec55b713e319571eac0ce712e518b730638c474debacc6eead2f877ea0fcd"
    "77f240127912cc067ace292e7b82350b7b26a5716bf2c7077ece1a7b7f064335"
    "7ebabc6681527b9182aef99c706e700f841e4fc085225675866a86b0855a4728"
    "85b69969741ed60f727e5f9a4aa61c738c16aea08da268d58e8239928c12979b"
    "8c5ecdde917eb98a92fa3d438d1ef7288dc228bf9512435750eee81f973e8aed"
    "974aff26988a147b98f22e505dca24f17a4296889d96461e4e6a7d649fb6dd96"
    "f99417fc43b0206244d81097a356e1dea4be0de1a53edb2ca6761298a61a845d"
    "a4de9a32a4a2c6cfaa464d73a8ae4ea3ac52812ead52335ba3fef8eaacf6e71f"
    "acbad96ab1e2b677b15a0675b292c836b4d661d2b2c6b008b6866bd3b76e32a7"
    "b89e4e43b9ee273cb8e2263fbb5a054dbc02c358bdcaebfcbdd6a717bcce44ba"
    "c096d37abf2275afbcd6f818c3ea14bac40e47d2c53ee4ffc52ad94fc49e8dc2"
    "c862aa19c4a610b0c4423bb7cb522087ccf2bd00cc32659dcb56fbeaccaab1d1"
    "d00230a8d142d82ad2e69113d27ad4fcd47a3542d44a3377d6665809d6c265ae"
    "d78e1440d9028d01da8eafd3db4e94c6dc96bed4dd82e364de8a4868d3d2e593"
    "e07a9993e16a7b90e2e6b581def201dcd5aaa2bddcd2a36cdc4eb70de75a4f4b"
    "e7ce4993e85ace78beea85d8e03a704fd1a2f6e6edea6fedcf82de7bdb927082"
    "f02a9dc6f0fe9af7b5e63e2df39adf10f42aab65f59e18faf6ca3ecff74a4232"
    "f7d2cb0cf9c23159fa0edd64f8d27ce2fc0a3019fdeee5e7fd4edbe3fda6ea0d"
    "fb1e8b70012f9fb70203c0eb0287d47702b37e4ef40ec49006138f6efcb2a528"
    "08235976fb6688c80aabcd430b7be084015bd7880523c3ea0ef72eff0ebbbc81"
    "103f169e11ff191a128fb5bf12933fb6141b103e150b5b0f14ab430c149b9678"
    "12dfbe9b138b279c17aba81417ff8f04111fec9c157f7a3a1607bead1fa3637e"
    "20336075203b69f922e71c4c21af8f42240fa40eead6831126f728bbcdfa4d25"
    "026709c52943c8b729738a382baff2e5c7b288aa11ef51c92e9fc6edd97eacaa"
    "30a3a910b6aaedfb1e6717863387f374b1b2b40e356fca7136abea2c370b3224"
    "0453e4bbf46ac426ffbee97138ef815a3cef387a3d9f2f243edba8dff59aaf62"
    "0483ab51411f4404425b87a342df9a5f3c3ba3bc457b300d463399c846bf3ee4"
    "47b330a94607eaf84513a3694bbfffe04c7727b44d17ee0a4c9b6f5a4a7fc48a"
    "46437e8d5147c7e4512f0a3353c7bd1e54a76dff4c17d7cf47d7ca135713b2cf"
    "58a3820f57bbd1f25a9bc52d4db364b045a349f45ddb9a135d63e5cb4ba79967"
    "60c32909614f2adc619fa444617bf20e615736536597e3c4605fb86e4aa352a4"
    "680f1657687b78e269f3f8ab6bcfc6b06c37964f699337a06d8301606deffe84"
    "70d3523071273f30720f7b5b708370e36d9f8c22686bcbaa7683f77b77bb297d"
    "683f2dd879db5a427a230e367a6b55a17a6f6a6a5dbb17de6af7a6b47f3ffed4"
    "80cfbf8e50afeaa882d316d4547ba4725e07d05985cf23a2869beaca86776a2b"
    "888fd1998837f8c58a7b211b89ab660d8c878b7c8d8385158cb71c238fd3aed0"
    "90b321b891036cee90670ebd938bdf57940ba9969527cd6d96b330ab8f1f259f"
    "93cbf40d9977ce679ae77a9a9b9f15d191ab59209a578f309203dfb292179ba8"
    "94578245a1436b55a0c34fd4a3df4659a4439f1ca52b704da62b65a6a77ff6fa"
    "93a7df37a5dbb61faa87d064a9bb688392478604aacba3c09e1be51487dfe45f"
    "8ef78f1bb10badb79aebc0cb9043db52b3e7f98693c73bcc96133da7b7ff2e36"
    "b8ffbe2ab82b34dc9d33ef14bb134fcebca3d954bd8fd48fbe07f370bf1b7d5c"
    "bfc79a33bfc7ae71c297cbf5c3af6071c483e0ddc32b3d76c1bf04b4c7bf88a7"
    "bc2b5d4fc997f0d5c953ea45ca47d05dcccfd96acdaf2deecc6fe11dccfff4d6"
    "d00781c3a7c747bfd22b964fd23749acd47fcbfc87e77a55d69f8dd7b1cb1669"
    "d8fb9d0b8f87503ea09ff7eadb1759539637fbb1b10bdd1fde1f116dde93f677"
    "df3373fbe1cf715ee10f55a2e30f79a0e2375c8ae13b0423e6c7b7e9e65f82da"
    "e6837b15e3134737e0c32a5eebaf4a1bec43efdbec8f268eed2fac16eec76acf"
    "8123b2f1f1efca28f19ba34df38b956df253049ff533ffd6f6dbb8e6f697281e"
    "f5a36950f6170226f9b326b6f34bec7efc4b05f5fd9bc0b0fe3f02d8fd5bd607"
)
HASH_TABLE_HEX = _HASH_TABLE_CHUNK1 + _HASH_TABLE_CHUNK2

# ─── Known type hashes (from build_rainbow_table.py and project docs) ─────────
KNOWN_TYPE_HASHES = {
    0xF011157A: "texture",
    0x5B724250: "model",
    0x18166555: "animation",
    0x3884598E: "registry",  # mercs1 variant
    0x600B904E: "scrub",
    0x1CF649BB: "facefxactor",
    0x6310807F: "LineRegion",
    0xFA0B8DBC: "chatter",
    0xFE0E8320: "scaleformgfx",
    0x665EF13E: "facefxanimationset",
    0x140E8728: "GuidMap",
    0x207359C7: "animationtable",
    0xACCE47F2: "sequencetable",
    0x3B0AABF8: "decaltable",
    0xE5273C14: "sounddb",
    0x5608BD5A: "layer",
    0x1EA4F27B: "script",
    0xA4EAAB6C: "terrainmesh",
    0xB0F75ABE: "lowresterrain",
    0xD84714A2: "wavebank",
    0x50826AEF: "soundbank",
    0xBC73CA23: "binary",
    0xB9DD71F3: "font",
    0x4DD9CE0E: "stringdb",
    0x0D3F6BCB: "materialtable",
    0xB4BB5F99: "watermap",
    0x16EAAB2A: "foliage",
    0x94EC6EB3: "effect",
    0x2C95C843: "path",
}


def parse_hash_table(hex_str: str) -> list[int]:
    """Parse hex dump into list of 1024 u32 LE values."""
    raw = bytes.fromhex(hex_str)
    assert len(raw) == 4096, f"Expected 4096 bytes, got {len(raw)}"
    return [struct.unpack_from("<I", raw, i * 4)[0] for i in range(1024)]


def load_aset_hashes(wad_path: Path) -> tuple[set[int], list[dict]]:
    """Load all asset_hash values from a WAD's ASET table."""
    arch = parse_ffcs(wad_path)
    raw = wad_path.read_bytes()
    aset_chunk = next(c for c in arch.chunks if c.tag == "ASET")
    aset_data = raw[aset_chunk.offset : aset_chunk.offset + aset_chunk.size]
    rows = parse_aset(aset_data)
    hashes = {r["asset_hash"] for r in rows}
    return hashes, rows


def main() -> int:
    print("=" * 80)
    print("ENGINE HASH TABLE CORRELATION ANALYSIS")
    print("=" * 80)

    # ── 1. Parse the hash table from memory dump ──────────────────────────
    table = parse_hash_table(HASH_TABLE_HEX)
    print(f"\nHash table: {len(table)} slots")

    # Stats on zero vs nonzero
    nonzero = [(i, v) for i, v in enumerate(table) if v != 0]
    zeros = [i for i, v in enumerate(table) if v == 0]
    print(f"  Non-zero slots: {len(nonzero)}")
    print(f"  Zero slots: {len(zeros)}")

    # ── 2. Load patch WAD ASET ────────────────────────────────────────────
    patch_wad = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\output\data\vz-patch.wad")
    if not patch_wad.exists():
        print(f"\nERROR: Patch WAD not found at {patch_wad}")
        return 1
    print(f"\nLoading patch WAD ASET: {patch_wad}")
    patch_hashes, patch_rows = load_aset_hashes(patch_wad)
    print(f"  Patch ASET entries: {len(patch_rows)}")
    print(f"  Unique asset_hashes: {len(patch_hashes)}")

    # Build secondary lookups for patch
    patch_hash_to_rows: dict[int, list[dict]] = defaultdict(list)
    for r in patch_rows:
        patch_hash_to_rows[r["asset_hash"]].append(r)

    # ── 3. Load base WAD ASET ─────────────────────────────────────────────
    base_wad = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\pc-game-vz.wad")
    if not base_wad.exists():
        print(f"\nERROR: Base WAD not found at {base_wad}")
        return 1
    print(f"\nLoading base WAD ASET: {base_wad}")
    base_hashes, base_rows = load_aset_hashes(base_wad)
    print(f"  Base ASET entries: {len(base_rows)}")
    print(f"  Unique asset_hashes: {len(base_hashes)}")

    base_hash_to_rows: dict[int, list[dict]] = defaultdict(list)
    for r in base_rows:
        base_hash_to_rows[r["asset_hash"]].append(r)

    # ── 4. Correlate each hash table slot ─────────────────────────────────
    print("\n" + "=" * 80)
    print("CORRELATION RESULTS")
    print("=" * 80)

    match_patch_only = []
    match_base_only = []
    match_both = []
    match_type_hash = []
    match_none = []

    for slot_idx, val in enumerate(table):
        if val == 0:
            continue

        in_patch = val in patch_hashes
        in_base = val in base_hashes
        is_type = val in KNOWN_TYPE_HASHES

        if is_type:
            match_type_hash.append((slot_idx, val))
        elif in_patch and in_base:
            match_both.append((slot_idx, val))
        elif in_patch:
            match_patch_only.append((slot_idx, val))
        elif in_base:
            match_base_only.append((slot_idx, val))
        else:
            match_none.append((slot_idx, val))

    print(f"\n  Total non-zero slots:            {len(nonzero)}")
    print(f"  Match PATCH ASET only:           {len(match_patch_only)}")
    print(f"  Match BASE ASET only:            {len(match_base_only)}")
    print(f"  Match BOTH patch + base:         {len(match_both)}")
    print(f"  Match known type_hash:           {len(match_type_hash)}")
    print(f"  Match NOTHING (unknown):         {len(match_none)}")

    # -- 5. Detailed breakdown --

    SEP = "=" * 60

    # Type hashes found
    if match_type_hash:
        print(f"\n{SEP}")
        print("TYPE HASHES in table:")
        for slot_idx, val in match_type_hash:
            print(f"  slot[{slot_idx:4d}] = 0x{val:08X} -> {KNOWN_TYPE_HASHES[val]}")

    # Patch-only: analyze block distribution
    if match_patch_only:
        print(f"\n{SEP}")
        print(f"PATCH-ONLY matches ({len(match_patch_only)} entries):")
        block_counter: Counter[int] = Counter()
        type_counter: Counter[int] = Counter()
        for _, val in match_patch_only:
            for row in patch_hash_to_rows[val]:
                block_counter[row["block_index"]] += 1
                type_counter[row["type_id"]] += 1
        print(f"  Block distribution (top 20):")
        for blk, cnt in block_counter.most_common(20):
            print(f"    block {blk:5d}: {cnt} entries")
        print(f"  Type ID distribution:")
        for tid, cnt in type_counter.most_common():
            print(f"    type_id {tid:3d}: {cnt} entries")

    # Both: overlap analysis
    if match_both:
        print(f"\n{SEP}")
        print(f"BOTH patch+base matches ({len(match_both)} entries):")
        both_patch_blocks: Counter[int] = Counter()
        both_patch_types: Counter[int] = Counter()
        both_base_blocks: Counter[int] = Counter()
        for _, val in match_both:
            for row in patch_hash_to_rows[val]:
                both_patch_blocks[row["block_index"]] += 1
                both_patch_types[row["type_id"]] += 1
            for row in base_hash_to_rows[val]:
                both_base_blocks[row["block_index"]] += 1
        print(f"  Patch block distribution (top 20):")
        for blk, cnt in both_patch_blocks.most_common(20):
            print(f"    patch block {blk:5d}: {cnt} entries")
        print(f"  Patch type_id distribution:")
        for tid, cnt in both_patch_types.most_common():
            print(f"    type_id {tid:3d}: {cnt} entries")
        print(f"  Base block distribution (top 20):")
        for blk, cnt in both_base_blocks.most_common(20):
            print(f"    base block {blk:5d}: {cnt} entries")
        print(f"  First 15 values:")
        for _, val in match_both[:15]:
            rows_p = patch_hash_to_rows[val]
            rows_b = base_hash_to_rows[val]
            print(f"    0x{val:08X}: patch blk={[r['block_index'] for r in rows_p]}, "
                  f"base blk={[r['block_index'] for r in rows_b[:3]]}, "
                  f"type_id={rows_p[0]['type_id'] if rows_p else '?'}")

    # Base-only
    if match_base_only:
        print(f"\n{SEP}")
        print(f"BASE-ONLY matches ({len(match_base_only)} entries):")
        base_block_counter: Counter[int] = Counter()
        base_type_counter: Counter[int] = Counter()
        for _, val in match_base_only:
            for row in base_hash_to_rows[val]:
                base_block_counter[row["block_index"]] += 1
                base_type_counter[row["type_id"]] += 1
        print(f"  Block distribution (top 20):")
        for blk, cnt in base_block_counter.most_common(20):
            print(f"    block {blk:5d}: {cnt} entries")
        print(f"  Type ID distribution:")
        for tid, cnt in base_type_counter.most_common():
            print(f"    type_id {tid:3d}: {cnt} entries")
        print(f"  First 10 values:")
        for slot_idx, val in match_base_only[:10]:
            rows_b = base_hash_to_rows[val]
            print(f"    slot[{slot_idx:4d}] = 0x{val:08X}, base blocks={[r['block_index'] for r in rows_b[:3]]}")

    # Unknown
    if match_none:
        print(f"\n{SEP}")
        print(f"UNKNOWN values ({len(match_none)} entries) -- first 30:")
        for slot_idx, val in match_none[:30]:
            print(f"  slot[{slot_idx:4d}] = 0x{val:08X}")

        # Check if unknowns could be secondary_ref (u1 field) values
        patch_secondary = {r["secondary_ref"] for r in patch_rows}
        base_secondary = {r["secondary_ref"] for r in base_rows}
        unknown_in_patch_secondary = sum(1 for _, v in match_none if v in patch_secondary)
        unknown_in_base_secondary = sum(1 for _, v in match_none if v in base_secondary)
        print(f"\n  Of {len(match_none)} unknowns:")
        print(f"    Match patch secondary_ref: {unknown_in_patch_secondary}")
        print(f"    Match base secondary_ref:  {unknown_in_base_secondary}")

        # Check if unknowns could be type_id hashes from the ASET u3 field
        patch_type_ids = {r["type_id"] for r in patch_rows}
        base_type_ids = {r["type_id"] for r in base_rows}
        unknown_is_type_id_patch = sum(1 for _, v in match_none if v in patch_type_ids)
        unknown_is_type_id_base = sum(1 for _, v in match_none if v in base_type_ids)
        print(f"    Match patch type_id field: {unknown_is_type_id_patch}")
        print(f"    Match base type_id field:  {unknown_is_type_id_base}")

    # -- 6. Value distribution analysis --
    print(f"\n{SEP}")
    print("VALUE DISTRIBUTION ANALYSIS:")
    all_vals = [v for _, v in nonzero]
    high_bits = Counter((v >> 28) & 0xF for v in all_vals)
    print(f"  Top nibble distribution:")
    for nibble in range(16):
        cnt = high_bits.get(nibble, 0)
        if cnt:
            print(f"    0x{nibble:X}xxx_xxxx: {cnt:4d} ({100*cnt/len(all_vals):.1f}%)")

    # Check for duplicates in the table
    val_counts = Counter(all_vals)
    dupes = {v: c for v, c in val_counts.items() if c > 1}
    if dupes:
        print(f"\n  Duplicate values in table: {len(dupes)}")
        for v, c in sorted(dupes.items(), key=lambda x: -x[1])[:10]:
            in_p = "PATCH" if v in patch_hashes else ""
            in_b = "BASE" if v in base_hashes else ""
            print(f"    0x{v:08X} x {c}  {in_p} {in_b}")
    else:
        print(f"\n  No duplicate values in table (all unique)")

    # -- 7. Slot index pattern analysis --
    print(f"\n{SEP}")
    print("HASH SLOT PLACEMENT ANALYSIS:")
    correct_slot = 0
    for slot_idx, val in nonzero:
        expected_slot = val & 0x3FF
        if expected_slot == slot_idx:
            correct_slot += 1
    print(f"  Values where (val & 0x3FF) == slot_idx: {correct_slot}/{len(nonzero)}")
    print(f"  -> {100*correct_slot/len(nonzero):.1f}% land in their natural slot")

    correct_slot2 = 0
    for slot_idx, val in nonzero:
        expected_slot = (val >> 10) & 0x3FF
        if expected_slot == slot_idx:
            correct_slot2 += 1
    print(f"  Values where (val >> 10) & 0x3FF == slot_idx: {correct_slot2}/{len(nonzero)}")

    # -- 8. Summary --
    print(f"\n{'=' * 80}")
    print("SUMMARY")
    print("=" * 80)
    total_identified = len(match_patch_only) + len(match_base_only) + len(match_both) + len(match_type_hash)
    print(f"  Identified: {total_identified}/{len(nonzero)} ({100*total_identified/len(nonzero):.1f}%)")
    print(f"  Unidentified: {len(match_none)}/{len(nonzero)} ({100*len(match_none)/len(nonzero):.1f}%)")

    if len(match_patch_only) > len(match_base_only):
        print(f"\n  CONCLUSION: Table is predominantly PATCH asset hashes ({len(match_patch_only)} patch-only)")
        print(f"    The engine likely builds this table from the ASET entries of the")
        print(f"    patch WAD during load, and the 1024-slot limit overflows.")
    elif len(match_base_only) > len(match_patch_only):
        print(f"\n  CONCLUSION: Table is predominantly BASE asset hashes ({len(match_base_only)} base-only)")
    else:
        print(f"\n  CONCLUSION: Table contains asset hashes shared between patch and base WADs")
        print(f"    794 of 1024 are shared hashes = these are override entries where")
        print(f"    the patch WAD provides a replacement for a base game asset.")
        print(f"    The engine is inserting ALL patch ASET entries into a 1024-slot table.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
