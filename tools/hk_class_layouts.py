# -*- coding: utf-8 -*-
"""Havok 5.5.0-r1 class layouts for 32-bit packfiles (Xbox 360 / PC).

Extracted from PredatorCZ/HavokLib auto-generated .inl files (HK550, ptrSize=4,
reusePadding=0). These layouts describe the serialized on-disk format of Havok
objects within the ``__data__`` section of a binary packfile.

Each layout entry maps byte ranges to swap widths:
  4 = swap as u32 (covers u32, f32, pointer, enum)
  2 = swap as u16 (covers i16, u16)
  1 = no swap (u8, padding, raw data)

The ``SWAP_MAP`` for each class is a list of (offset, width) tuples covering
every byte of the object. Gaps between entries are implicitly width=4 (u32).

Reference: https://github.com/PredatorCZ/HavokLib (MIT-licensed class layouts)
"""

from __future__ import annotations


# ---------------------------------------------------------------------------
# Swap width constants
# ---------------------------------------------------------------------------
U32 = 4
U16 = 2
U8 = 1

# ---------------------------------------------------------------------------
# hkReferenceObject — base of all reference-counted Havok objects
# Size: 8 bytes (HK550, 32-bit)
# ---------------------------------------------------------------------------
# [0:4]  vtable pointer (u32)
# [4:6]  memSizeAndFlags (i16)
# [6:8]  referenceCount (i16)
HK_REFERENCE_OBJECT_SIZE = 8
HK_REFERENCE_OBJECT_SWAP = [
    (0, U32),   # vtable ptr
    (4, U16),   # memSizeAndFlags
    (6, U16),   # referenceCount
]

# ---------------------------------------------------------------------------
# QuantizationFormat — embedded struct in delta/wavelet animations
# Size: 20 bytes
# ---------------------------------------------------------------------------
# [0]    maxBitWidth (u8)
# [1]    preserved (u8)
# [2:4]  padding
# [4:8]  numD (u32)
# [8:12] offsetIdx (u32)
# [12:16] scaleIdx (u32)
# [16:20] bitWidthIdx (u32)
QUANTIZATION_FORMAT_SIZE = 20
QUANTIZATION_FORMAT_SWAP = [
    (0, U8),    # maxBitWidth
    (1, U8),    # preserved
    (2, U8),    # pad
    (3, U8),    # pad
    (4, U32),   # numD
    (8, U32),   # offsetIdx
    (12, U32),  # scaleIdx
    (16, U32),  # bitWidthIdx
]

# ---------------------------------------------------------------------------
# hkaAnimation — base class for all animation types
# Size: 36 bytes (HK550, 32-bit)
# Inherits: hkReferenceObject at offset 0
# ---------------------------------------------------------------------------
# [0:8]   hkReferenceObject
# [8:12]  animationType (u32 enum)
# [12:16] duration (f32)
# [16:20] numOfTransformTracks (u32)
# [20:24] numOfFloatTracks (u32)
# [24:28] extractedMotion (ptr)
# [28:32] annotations (ptr)
# [32:36] numAnnotations (u32)
HKA_ANIMATION_SIZE = 36

# ---------------------------------------------------------------------------
# hkaInterleavedUncompressedAnimation
# Size: 52 bytes (HK550, 32-bit)
# Inherits: hkaAnimation at offset 0
# ---------------------------------------------------------------------------
# [0:36]  hkaAnimation base
# [36:40] transforms (ptr → hkQTransform[])
# [40:44] numTransforms (u32)
# [44:48] floats (ptr → float[])
# [48:52] numFloats (u32)
HKA_INTERLEAVED_SIZE = 52
HKA_INTERLEAVED_SWAP = [
    # hkReferenceObject
    (0, U32), (4, U16), (6, U16),
    # hkaAnimation fields (all u32)
    (8, U32), (12, U32), (16, U32), (20, U32), (24, U32), (28, U32), (32, U32),
    # Interleaved-specific
    (36, U32), (40, U32), (44, U32), (48, U32),
]
HKA_INTERLEAVED_ARRAYS = {
    "transforms": {"ptr_off": 36, "count_off": 40, "elem_size": 48, "elem_swap": U32},
    "floats": {"ptr_off": 44, "count_off": 48, "elem_size": 4, "elem_swap": U32},
}

# ---------------------------------------------------------------------------
# hkaDeltaCompressedAnimation
# Size: 104 bytes (HK550, 32-bit)
# Inherits: hkaAnimation at offset 0
# ---------------------------------------------------------------------------
# [0:36]   hkaAnimation base
# [36:40]  numberOfPoses (u32)
# [40:44]  blockSize (u32)
# [44:64]  QuantizationFormat (20 bytes — mixed u8/u32)
# [64:68]  quantizedDataIdx (u32)
# [68:72]  quantizedDataSize (u32)
# [72:76]  staticMaskIdx (u32)
# [76:80]  staticMaskSize (u32)
# [80:84]  maskDOFsIdx (u32)
# [84:88]  maskDOFsSize (u32)
# [88:92]  totalBlockSize (u32)
# [92:96]  lastBlockSize (u32)
# [96:100] dataBuffer (ptr → raw bitstream)
# [100:104] numDataBuffer (u32)
HKA_DELTA_SIZE = 104
HKA_DELTA_SWAP = [
    # hkReferenceObject
    (0, U32), (4, U16), (6, U16),
    # hkaAnimation fields
    (8, U32), (12, U32), (16, U32), (20, U32), (24, U32), (28, U32), (32, U32),
    # Delta-specific
    (36, U32), (40, U32),
    # QuantizationFormat at offset 44
    (44, U8), (45, U8), (46, U8), (47, U8),  # maxBW, preserved, pad, pad
    (48, U32), (52, U32), (56, U32), (60, U32),  # numD, offsetIdx, scaleIdx, bitWidthIdx
    # Remaining u32 fields
    (64, U32), (68, U32), (72, U32), (76, U32),
    (80, U32), (84, U32), (88, U32), (92, U32),
    (96, U32), (100, U32),
]
HKA_DELTA_ARRAYS = {
    "dataBuffer": {"ptr_off": 96, "count_off": 100, "elem_size": 1, "elem_swap": U8},
}

# ---------------------------------------------------------------------------
# hkaWaveletCompressedAnimation
# Size: 96 bytes (HK550, 32-bit) — from our wavelet.py _WAVELET_STRUCT_SIZE
# Same layout as delta for the compressed portion (shared base design)
# Inherits: hkaAnimation at offset 0
# ---------------------------------------------------------------------------
# [0:36]   hkaAnimation base
# [36:40]  numberOfPoses (u32)
# [40:44]  blockSize (u32)
# [44:64]  QuantizationFormat (20 bytes — mixed u8/u32)
# [64:68]  staticMaskIdx (u32)
# [68:72]  staticDOFsIdx (u32)
# [72:76]  blockIndexIdx (u32)
# [76:80]  blockIndexSize (u32)
# [80:84]  quantDataIdx (u32)
# [84:88]  quantDataSize (u32)
# [88:92]  dataBuffer (ptr → raw bitstream)
# [92:96]  numDataBuffer (u32)
HKA_WAVELET_SIZE = 96
HKA_WAVELET_SWAP = [
    # hkReferenceObject
    (0, U32), (4, U16), (6, U16),
    # hkaAnimation fields
    (8, U32), (12, U32), (16, U32), (20, U32), (24, U32), (28, U32), (32, U32),
    # Wavelet-specific
    (36, U32), (40, U32),
    # QuantizationFormat at offset 44
    (44, U8), (45, U8), (46, U8), (47, U8),
    (48, U32), (52, U32), (56, U32), (60, U32),
    # Remaining u32 fields
    (64, U32), (68, U32), (72, U32), (76, U32),
    (80, U32), (84, U32), (88, U32), (92, U32),
]
HKA_WAVELET_ARRAYS = {
    "dataBuffer": {"ptr_off": 88, "count_off": 92, "elem_size": 1, "elem_swap": U8},
}

# ---------------------------------------------------------------------------
# hkaAnimationContainer
# Size: 40 bytes (HK500-HK660, 32-bit) — no hkReferenceObject base in HK550!
# ---------------------------------------------------------------------------
# [0:4]   skeletons (ptr)
# [4:8]   numSkeletons (u32)
# [8:12]  animations (ptr)
# [12:16] numAnimations (u32)
# [16:20] bindings (ptr)
# [20:24] numBindings (u32)
# [24:28] attachments (ptr)
# [28:32] numAttachments (u32)
# [32:36] skins (ptr)
# [36:40] numSkins (u32)
HKA_ANIMATION_CONTAINER_SIZE = 40
HKA_ANIMATION_CONTAINER_SWAP = [
    (0, U32), (4, U32), (8, U32), (12, U32), (16, U32),
    (20, U32), (24, U32), (28, U32), (32, U32), (36, U32),
]

# ---------------------------------------------------------------------------
# hkaSkeleton
# Size: 36 bytes (HK550, 32-bit) — no hkReferenceObject base in HK550!
# ---------------------------------------------------------------------------
# [0:4]   name (ptr → char[])
# [4:8]   parentIndices (ptr → i16[])
# [8:12]  numParentIndices (u32)
# [12:16] bones (ptr → hkaBone[])
# [16:20] numBones (u32)
# [20:24] transforms (ptr → hkQTransform[])
# [24:28] numTransforms (u32)
# [28:32] floatSlots (ptr → char*[])
# [32:36] numFloatSlots (u32)
HKA_SKELETON_SIZE = 36
HKA_SKELETON_SWAP = [
    (0, U32), (4, U32), (8, U32), (12, U32), (16, U32),
    (20, U32), (24, U32), (28, U32), (32, U32),
]
HKA_SKELETON_ARRAYS = {
    "parentIndices": {"ptr_off": 4, "count_off": 8, "elem_size": 2, "elem_swap": U16},
    "bones": {"ptr_off": 12, "count_off": 16, "elem_size": 8, "elem_swap": U32},
    "transforms": {"ptr_off": 20, "count_off": 24, "elem_size": 48, "elem_swap": U32},
}

# ---------------------------------------------------------------------------
# hkaAnnotationTrack
# Size: 12 bytes (HK500-HK660, 32-bit)
# ---------------------------------------------------------------------------
# [0:4]   name (ptr → char[])
# [4:8]   annotations (ptr → hkaAnnotation[])
# [8:12]  numAnnotations (u32)
HKA_ANNOTATION_TRACK_SIZE = 12
HKA_ANNOTATION_TRACK_SWAP = [
    (0, U32), (4, U32), (8, U32),
]

# ---------------------------------------------------------------------------
# hkaAnnotation
# Size: 8 bytes (HK500-HK2019, 32-bit)
# ---------------------------------------------------------------------------
# [0:4]   time (f32)
# [4:8]   text (ptr → char[])
HKA_ANNOTATION_SIZE = 8
HKA_ANNOTATION_SWAP = [
    (0, U32), (4, U32),
]

# ---------------------------------------------------------------------------
# hkaBone
# Size: 8 bytes (HK500-HK2019, 32-bit)
# ---------------------------------------------------------------------------
# [0:4]   name (ptr → char[])
# [4:8]   lockTranslation (i32)
HKA_BONE_SIZE = 8
HKA_BONE_SWAP = [
    (0, U32), (4, U32),
]

# ---------------------------------------------------------------------------
# hkRootLevelContainer (top-level container)
# Comprised of hkVariant entries: [ptr object, ptr classDesc] = 8 bytes each
# The container itself is typically just a pointer+count.
# For HK550 32-bit without hkReferenceObject, it's likely a named variant array.
# All fields are pointers (u32) and counts (u32).
# Size varies but all fields are u32-swappable.
# ---------------------------------------------------------------------------
HK_ROOT_LEVEL_CONTAINER_SIZE = 12  # ptr + count + (varies)
HK_ROOT_LEVEL_CONTAINER_SWAP = "all_u32"  # entirely u32-swappable

# ---------------------------------------------------------------------------
# hkaAnimationBinding
# Size varies by version. For HK550, 32-bit, all fields are ptr/u32/i16 arrays.
# The binding itself is all pointers and u32 counts.
# From HavokLib: originalSkeletonName(ptr), animation(ptr),
#   transformTrackToBoneIndices(ptr), numTTBI(u32),
#   floatTrackToFloatSlotIndices(ptr), numFTFSI(u32), blendHint(u32)
# All u32-swappable in the object body. The arrays contain i16 elements.
# ---------------------------------------------------------------------------
HKA_ANIMATION_BINDING_SIZE = 28  # estimated for HK550 32-bit
HKA_ANIMATION_BINDING_SWAP = "all_u32"
HKA_ANIMATION_BINDING_ARRAYS = {
    "transformTrackToBoneIndices": {"elem_size": 2, "elem_swap": U16},
    "floatTrackToFloatSlotIndices": {"elem_size": 2, "elem_swap": U16},
}

# ---------------------------------------------------------------------------
# hkQTransform — used in transform arrays (48 bytes = 3 × hkVector4)
# Each hkVector4 is 16 bytes = 4 × f32
# [0:16]  translation (4 × f32)
# [16:32] rotation (4 × f32 quaternion)
# [32:48] scale (4 × f32)
# ---------------------------------------------------------------------------
HK_QTRANSFORM_SIZE = 48
HK_QTRANSFORM_SWAP = U32  # all f32, swap as u32

# ---------------------------------------------------------------------------
# hkpMoppCode — collision MOPP (Memory-Optimised Partial Polytope) bytecode.
# Size 48 (HK550, 32-bit), then an INLINE u8 bytecode buffer at +48.
# [0:8]   hkReferencedObject (vtable u32; memSize/refCount u16 — zero in packfile)
# [16:32] m_info hkVector4 (4 × f32)
# [32:36] m_data.ptr (→ +48), [36:40] m_data.size, [40:44] capacityAndFlags
# [44]    m_buildType (u8) + pad
# [48:..] m_data buffer: the MOPP bytecode, a u8 ARRAY — must NOT be u32-swapped
#         (a blind sweep reverses every 4 bytes → the whole MOPP tree is garbage →
#         broken collision; and the load-time MOPP walk can read out of bounds).
# ---------------------------------------------------------------------------
HKP_MOPP_CODE_SIZE = 48
HKP_MOPP_CODE_ARRAYS = {
    "m_data": {"ptr_off": 32, "count_off": 36, "elem_size": 1, "elem_swap": U8},
}

# ---------------------------------------------------------------------------
# WpMeshShape16 — Pandemic custom 16-bit-indexed collision-mesh shape.
# Fixed struct (hkReferencedObject base + radius + bound vectors + array
# descriptors), then TWO u16 index arrays reached via local fixups:
#   {ptr@+28, count@+32}  → f32 vector array (handled by the default u32 sweep)
#   {ptr@+80, count@+84}  → u16 index array  (must be u16-swapped, not u32)
#   {ptr@+88, count@+92}  → u16 index array  (must be u16-swapped, not u32)
# A blind u32 sweep transposes each u16 pair → wrong triangle indices → broken
# collision. Size kept minimal (the base) so the array fixups drive the swap and
# the fixed struct / f32 buffers fall through to the default u32 fill.
# ---------------------------------------------------------------------------
WP_MESH_SHAPE16_SIZE = 8
WP_MESH_SHAPE16_ARRAYS = {
    "indices_b": {"ptr_off": 80, "count_off": 84, "elem_size": 2, "elem_swap": U16},
    "indices_c": {"ptr_off": 88, "count_off": 92, "elem_size": 2, "elem_swap": U16},
}

# ---------------------------------------------------------------------------
# Master class registry: maps classname → (object_size, swap_map, arrays)
# swap_map is either a list of (offset, width) or "all_u32" for pure-u32 classes
# ---------------------------------------------------------------------------
CLASS_REGISTRY: dict[str, dict] = {
    "hkRootLevelContainer": {
        "size": HK_ROOT_LEVEL_CONTAINER_SIZE,
        "swap": "all_u32",
        "arrays": {},
    },
    "hkaAnimationContainer": {
        "size": HKA_ANIMATION_CONTAINER_SIZE,
        "swap": HKA_ANIMATION_CONTAINER_SWAP,
        "arrays": {},
    },
    "hkaSkeleton": {
        "size": HKA_SKELETON_SIZE,
        "swap": HKA_SKELETON_SWAP,
        "arrays": HKA_SKELETON_ARRAYS,
    },
    "hkaInterleavedUncompressedAnimation": {
        "size": HKA_INTERLEAVED_SIZE,
        "swap": HKA_INTERLEAVED_SWAP,
        "arrays": HKA_INTERLEAVED_ARRAYS,
    },
    "hkaInterleavedSkeletalAnimation": {
        "size": HKA_INTERLEAVED_SIZE,
        "swap": HKA_INTERLEAVED_SWAP,
        "arrays": HKA_INTERLEAVED_ARRAYS,
    },
    "hkaDeltaCompressedAnimation": {
        "size": HKA_DELTA_SIZE,
        "swap": HKA_DELTA_SWAP,
        "arrays": HKA_DELTA_ARRAYS,
    },
    "hkaDeltaCompressedSkeletalAnimation": {
        "size": HKA_DELTA_SIZE,
        "swap": HKA_DELTA_SWAP,
        "arrays": HKA_DELTA_ARRAYS,
    },
    "hkaDeltaSkeletalAnimation": {
        "size": HKA_DELTA_SIZE,
        "swap": HKA_DELTA_SWAP,
        "arrays": HKA_DELTA_ARRAYS,
    },
    "hkaWaveletCompressedAnimation": {
        "size": HKA_WAVELET_SIZE,
        "swap": HKA_WAVELET_SWAP,
        "arrays": HKA_WAVELET_ARRAYS,
    },
    "hkaWaveletCompressedSkeletalAnimation": {
        "size": HKA_WAVELET_SIZE,
        "swap": HKA_WAVELET_SWAP,
        "arrays": HKA_WAVELET_ARRAYS,
    },
    "hkaWaveletSkeletalAnimation": {
        "size": HKA_WAVELET_SIZE,
        "swap": HKA_WAVELET_SWAP,
        "arrays": HKA_WAVELET_ARRAYS,
    },
    "hkaAnimationBinding": {
        "size": HKA_ANIMATION_BINDING_SIZE,
        "swap": "all_u32",
        "arrays": HKA_ANIMATION_BINDING_ARRAYS,
    },
    "hkaAnnotationTrack": {
        "size": HKA_ANNOTATION_TRACK_SIZE,
        "swap": HKA_ANNOTATION_TRACK_SWAP,
        "arrays": {},
    },
    "hkaBone": {
        "size": HKA_BONE_SIZE,
        "swap": HKA_BONE_SWAP,
        "arrays": {},
    },
    # ── physics (PHY2 collision packfiles) ──
    "hkpMoppCode": {
        "size": HKP_MOPP_CODE_SIZE,
        "swap": "all_u32",
        "arrays": HKP_MOPP_CODE_ARRAYS,
    },
    "WpMeshShape16": {
        "size": WP_MESH_SHAPE16_SIZE,
        "swap": "all_u32",
        "arrays": WP_MESH_SHAPE16_ARRAYS,
    },
}


def build_swap_width_map(swap_spec: list[tuple[int, int]] | str, obj_size: int) -> list[int]:
    """Build a per-byte swap-width array for an object.

    Returns a list of length ``obj_size`` where each element is the swap width
    (1, 2, or 4) for that byte position. Bytes that are part of a multi-byte
    swap unit share the same width value at the unit's START position; subsequent
    bytes in the unit are 0 (meaning "skip, handled by previous start").
    """
    if swap_spec == "all_u32":
        widths = [0] * obj_size
        for i in range(0, obj_size - 3, 4):
            widths[i] = 4
        return widths

    widths = [0] * obj_size
    for off, w in swap_spec:
        if off < obj_size:
            widths[off] = w
    return widths
