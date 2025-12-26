# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Format Constants

Complete specification of chunk IDs, flags, magic numbers, and other constants
used in the BES (Binary Export Scene) format for Ptero-Engine-II.

Reference: docs/old_documentation.md
"""

from enum import IntEnum, IntFlag

# =============================================================================
# File Header Constants
# =============================================================================

BES_MAGIC = b'BES\x00'  # File signature (0x00534542)
BES_MAGIC_INT = 0x00534542

# Version strings (ASCII, 4 bytes)
BES_VERSION_4 = b'0004'
BES_VERSION_5 = b'0005'
BES_VERSION_6 = b'0006'
BES_VERSION_7 = b'0007'
BES_VERSION_8 = b'0008'  # Most common
BES_VERSION_10 = b'0010'

# Version integers for comparison
BES_VERSION_4_INT = 0x30303034
BES_VERSION_5_INT = 0x30303035
BES_VERSION_6_INT = 0x30303036
BES_VERSION_7_INT = 0x30303037
BES_VERSION_8_INT = 0x30303038  # Most common
BES_VERSION_10_INT = 0x30313030

# Exporter/MaxSDK versions
EXPORTER_AUTO = 0x00000000
EXPORTER_3DSMAX6 = 0x17700d00
EXPORTER_3DSMAX7 = 0x1b580f00
EXPORTER_3DSMAX8 = 0x1f401100
EXPORTER_BLENDER = 0x424C4E44  # "BLND" - our custom identifier

# Header size (bytes)
HEADER_SIZE = 16

# Preview image
PREVIEW_WIDTH = 64
PREVIEW_HEIGHT = 64
PREVIEW_BPP = 3  # Bytes per pixel (BGR)
PREVIEW_SIZE = PREVIEW_WIDTH * PREVIEW_HEIGHT * PREVIEW_BPP  # 12288 bytes


# =============================================================================
# Chunk Type IDs
# =============================================================================

class ChunkType(IntEnum):
    """BES chunk type identifiers."""

    # Scene hierarchy
    OBJECT = 0x0001  # Object/Node - main scene node

    # Special object types (discovered from IDA analysis)
    LIGHT = 0x0020  # Light object (112 bytes)
    HELPER = 0x0040  # Helper/Dummy object (36 bytes)

    # Model/Mesh chunks
    MODEL = 0x0030  # Model container
    MESH = 0x0031  # Mesh reference (links to material)
    VERTICES = 0x0032  # Vertex data
    FACES = 0x0033  # Face indices
    PROPERTIES = 0x0034  # User properties (INI format)
    TRANSFORM = 0x0035  # Transformation matrix
    UNKNOWN_36 = 0x0036  # Unknown chunk type
    BBOX = 0x0038  # Bounding box (3 floats)

    # Skeletal animation (version 0008+)
    ISKE = 0x0050  # ISKE skeletal node
    ISKE_MESH = 0x0051  # ISKE mesh data
    ISKE_UNKNOWN = 0x0054  # Unknown ISKE data (skip 28 bytes)

    # Skeletal animation (version 0005)
    BONE_NAME = 0x0000  # Bone/body part name (followed by MODEL)
    SKELETON_MARKER = 0x0067  # "Skeleton Object" marker string

    # Metadata
    INFO = 0x0070  # File info (author, comment, face count)

    # Collision
    COLLISION = 0x0082  # Collision mesh data

    # Materials
    MATERIAL_LIST = 0x1000  # Material count header
    STANDARD_MATERIAL = 0x1001  # 3DS Max Standard material
    PTEROMAT = 0x1002  # PteroMat material
    PTEROLAYER = 0x1004  # PteroLayer material (13 texture layers)


# =============================================================================
# D3D Flexible Vertex Format Flags
# =============================================================================

class D3DFVF(IntFlag):
    """Direct3D Flexible Vertex Format flags."""

    XYZ = 0x002  # Position (3 floats)
    NORMAL = 0x010  # Normal vector (3 floats)

    # Texture coordinate count (upper bits)
    TEX0 = 0x000
    TEX1 = 0x100
    TEX2 = 0x200
    TEX3 = 0x300
    TEX4 = 0x400
    TEX5 = 0x500
    TEX6 = 0x600
    TEX7 = 0x700
    TEX8 = 0x800

    # Mask for texture count extraction
    TEXCOUNT_MASK = 0xF00
    TEXCOUNT_SHIFT = 8


# Vertex size calculation
VERTEX_BASE_SIZE = 24  # Position (12) + Normal (12)
VERTEX_UV_SIZE = 8  # Per texture coordinate set (U + V, 4 bytes each)


# =============================================================================
# Standard Material Texture Flags
# =============================================================================

class StdMatTexFlag(IntFlag):
    """Standard material texture map flags.

    Mapping verified from IDA analysis of BesExport.dlu (sub_8981D60):
    - Slot 1 (Diffuse)      → 0x001
    - Slot 11 (Opacity)     → 0x002
    - Slot 8 (Bump)         → 0x004
    - Slot 0 (Ambient)      → 0x008
    - Slot 2 (Specular)     → 0x010
    - Slot 3 (Spec Level)   → 0x020
    - Slot 4 (Glossiness)   → 0x040
    - Slot 5 (Self-Illum)   → 0x080
    - Slot 7 (Displacement) → 0x200
    - Slot 9 (Filter)       → 0x400
    - Slot 10 (Reflection)  → 0x800

    IMPORTANT: UV order in vertex data differs from flag bit order!
    See STANDARD_UV_ORDER for correct vertex data ordering.
    """

    DIFFUSE = 0x001  # Slot 1 - Diffuse color map
    OPACITY = 0x002  # Slot 11 - Opacity map
    BUMP = 0x004  # Slot 8 - Bump map
    AMBIENT = 0x008  # Slot 0 - Ambient color map
    SPECULAR = 0x010  # Slot 2 - Specular color map
    SPECULAR_LEVEL = 0x020  # Slot 3 - Specular level map
    GLOSSINESS = 0x040  # Slot 4 - Glossiness map
    SELF_ILLUM = 0x080  # Slot 5 - Self-illumination map
    # 0x100 - unused
    DISPLACEMENT = 0x200  # Slot 7 - Displacement map
    FILTER = 0x400  # Slot 9 - Filter color map
    REFLECTION = 0x800  # Slot 10 - Reflection map


# UV coordinate order in vertex data for Standard materials
# Maps from vertex UV index to StdMatTexFlag
# Order verified from IDA analysis - matches 3ds Max slot indices
STANDARD_UV_ORDER = [
    StdMatTexFlag.AMBIENT,        # UV0 - Slot 0
    StdMatTexFlag.DIFFUSE,        # UV1 - Slot 1
    StdMatTexFlag.SPECULAR,       # UV2 - Slot 2
    StdMatTexFlag.SPECULAR_LEVEL, # UV3 - Slot 3
    StdMatTexFlag.GLOSSINESS,     # UV4 - Slot 4
    StdMatTexFlag.SELF_ILLUM,     # UV5 - Slot 5
    StdMatTexFlag.FILTER,         # UV6 - Slot 9 (Filter moved to UV6)
    StdMatTexFlag.BUMP,           # UV7 - Slot 8
    StdMatTexFlag.REFLECTION,     # UV8 - Slot 10
    StdMatTexFlag.OPACITY,        # UV9 - Slot 11
    StdMatTexFlag.DISPLACEMENT,   # UV10 - Slot 7
]


# =============================================================================
# PteroMat Texture Flags
# =============================================================================

class PteroMatTexFlag(IntFlag):
    """PteroMat texture map flags.

    IMPORTANT: UV order in vertex data differs from flag bit order!
    See PTEROMAT_UV_ORDER for correct vertex data ordering.
    """

    DIFFUSE_1 = 0x010000  # Diffuse #1 (Ground)
    DIFFUSE_2 = 0x020000  # Diffuse #2 (Multitexture)
    DIFFUSE_3 = 0x040000  # Diffuse #3 (Overlay)
    LIGHTMAP = 0x080000  # LightMap
    ENVIRONMENT_1 = 0x100000  # Environment #1
    ENVIRONMENT_2 = 0x200000  # Environment #2 (unused, never exported)
    LIGHTMAP_ENGINE = 0x400000  # LightMap Engine Lights
    OVERLAY_MULTI = 0x800000  # Overlay Multitexture


# UV coordinate order in vertex data for PteroMat
PTEROMAT_UV_ORDER = [
    PteroMatTexFlag.DIFFUSE_1,     # UV0 - Ground
    PteroMatTexFlag.DIFFUSE_3,     # UV1 - Overlay (or OVERLAY_MULTI)
    PteroMatTexFlag.DIFFUSE_2,     # UV2 - Multitexture
    PteroMatTexFlag.ENVIRONMENT_1, # UV3 - Environment
    PteroMatTexFlag.LIGHTMAP,      # UV4 - LightMap (or LIGHTMAP_ENGINE)
]


# =============================================================================
# PteroLayer Texture Channel Indices
# =============================================================================

class TextureChannel(IntEnum):
    """Texture channel indices for PteroLayer material.

    These are the internal channel indices used by 3DS Max and the
    Ptero-Engine-II for mapping texture slots.
    """

    DIFFUSE = 13  # Diffuse/Ground texture
    STRUCTURE = 14  # Structure/Multitexture
    OVERLAY = 15  # Overlay texture
    ENVIRONMENT = 19  # Environment map
    LIGHTMAP = 20  # Lightmap


# Layer index mapping for PteroLayer (13 layers total)
PTEROLAYER_INDICES = {
    0: 'diffuse_1',  # Ground
    1: 'diffuse_2',  # Multitexture
    2: 'diffuse_3',  # Overlay
    3: 'environment_1',
    4: 'environment_2',
    5: 'lightmap',
    6: 'lightmap_engine',
    7: 'effect_1',
    8: 'effect_2',
    9: 'effect_3',
    10: 'effect_4',
    11: 'effect_5',
    12: 'effect_6',
}


# =============================================================================
# PteroMat Transparency Types
# =============================================================================

class TransparencyType(IntEnum):
    """PteroMat transparency modes."""

    OPAQUE = 0x202D  # None (opaque)
    TRANSPARENT_0 = 0x3023  # #0 - transparent, zbufwrite, sort
    TRANSPARENT_1 = 0x3123  # #1 - transparent, zbufwrite, sort, 1-bit alpha
    TRANSLUCENT_2 = 0x3223  # #2 - translucent, no_zbufwrite, sort
    TRANSPARENT_3 = 0x3323  # #3 - transparent, zbufwrite, nosort, 1-bit alpha
    TRANSLUCENT_4 = 0x3423  # #4 - translucent, add with background, no_zbufwrite, sort


TRANSPARENCY_NAMES = {
    TransparencyType.OPAQUE: "Opaque",
    TransparencyType.TRANSPARENT_0: "#0 - Transparent (zbuf, sort)",
    TransparencyType.TRANSPARENT_1: "#1 - Transparent (zbuf, sort, 1-bit alpha)",
    TransparencyType.TRANSLUCENT_2: "#2 - Translucent (no zbuf, sort)",
    TransparencyType.TRANSPARENT_3: "#3 - Transparent (zbuf, no sort, 1-bit alpha)",
    TransparencyType.TRANSLUCENT_4: "#4 - Translucent additive (no zbuf, sort)",
}


# =============================================================================
# Texture Coordinate Flags
# =============================================================================

class TexCoordFlag(IntFlag):
    """Texture coordinate tiling/mirroring flags."""

    U_TILE = 0x01
    V_TILE = 0x02
    U_MIRROR = 0x04
    V_MIRROR = 0x08
    UNKNOWN = 0x10  # Unknown flag seen in some files


# =============================================================================
# Shader Types (from texture name prefix)
# =============================================================================

class ShaderType(IntEnum):
    """Material shader types derived from texture name prefixes."""

    STANDARD = 0  # Default
    GLASS = 1  # #1 prefix - Glass/transparent
    LIGHTMAP = 2  # #3 prefix - Lightmap
    EMISSIVE = 3  # #0 prefix - Emissive/glowing
    DETAIL = 4  # #2 prefix - Detail map
    SPECIAL = 5  # #4 prefix - Special effects


SHADER_PREFIXES = {
    '#0': ShaderType.EMISSIVE,
    '#1': ShaderType.GLASS,
    '#2': ShaderType.DETAIL,
    '#3': ShaderType.LIGHTMAP,
    '#4': ShaderType.SPECIAL,
}


# =============================================================================
# Node Types
# =============================================================================

class NodeType(IntEnum):
    """Node types stored at offset +0x7C in engine memory."""

    ISKE = 4  # Skeletal animation node
    STATIC_MESH = 6  # Static mesh
    LOD_GROUP = 18  # LOD group


# =============================================================================
# Node Flags
# =============================================================================

class NodeFlag(IntFlag):
    """Node flags stored at offset +0x58 in engine memory."""

    HIDDEN = 0x800000  # Hidden/disabled node (name starts with '>')
    HAS_LOD = 0x1000000  # Has LOD data
    HAS_DIFFUSE = 0x10000  # Has texture layer 1 (diffuse)
    HAS_OPACITY = 0x20000  # Has texture layer 2 (opacity)
    HAS_LIGHTMAP = 0x40000  # Has lightmap
    HAS_DETAIL = 0x80000  # Has detail map
    HAS_BUMP = 0x100000  # Has bump map
    HAS_SPECULAR = 0x200000  # Has specular map
    HAS_GLOW = 0x400000  # Has glow/self-illumination map


# =============================================================================
# Vegetation Types
# =============================================================================

class VegetationType(IntEnum):
    """Vegetation animation types for wobble effect."""

    GROW = 0  # Grow type
    GRASS = 1  # Grass type


# =============================================================================
# Material Index Constants
# =============================================================================

NO_MATERIAL = 0xFFFFFFFF  # No material assigned (-1 as unsigned)


# =============================================================================
# Transform Chunk Constants
# =============================================================================

TRANSFORM_SIZE = 105  # Total size of transform chunk data (0x69 bytes)
TRANSFORM_MATRIX_OFFSET = 37  # Offset to 4x4 matrix in transform data


# =============================================================================
# Info Block Constants
# =============================================================================

INFO_AUTHOR_MAX_LEN = 64  # Maximum author name length


# =============================================================================
# Collision Material Codes
# =============================================================================

# 2-character collision material codes
COLLISION_MATERIALS = {
    'B-': 'Building - default',
    'BB': 'Building - brick',
    'BM': 'Building - metal',
    'BO': 'Building - wood',
    'C-': 'Concrete - default',
    'CA': 'Concrete - asphalt',
    'CB': 'Concrete - brick',
    'CP': 'Concrete - pavement',
    'D-': 'Dirt - default',
    'DC': 'Dirt - clay',
    'DD': 'Dirt - dry',
    'DK': 'Dirt - dark',
    'DM': 'Dirt - mud',
    'DR': 'Dirt - rock',
    'DS': 'Dirt - sand',
    'DW': 'Dirt - wet',
    'E-': 'Earth - default',
    'F-': 'Foliage - default',
    'FD': 'Foliage - dry',
    'FG': 'Foliage - grass',
    'FL': 'Foliage - leaves',
    'FW': 'Foliage - wet',
    'G-': 'Glass - default',
    'GB': 'Glass - bulletproof',
    'GW': 'Glass - window',
    'H-': 'Human - default',
    'J-': 'Jungle - default',
    'K-': 'Cork - default',
    'M-': 'Metal - default',
    'MD': 'Metal - drum',
    'MF': 'Metal - fence',
    'MH': 'Metal - heavy',
    'ML': 'Metal - light',
    'MR': 'Metal - rusty',
    'MS': 'Metal - sheet',
    'P-': 'Plastic - default',
    'R-': 'Rubber - default',
    'S-': 'Stone - default',
    'SB': 'Stone - brick',
    'SC': 'Stone - concrete',
    'SM': 'Stone - marble',
    'SP': 'Stone - pebbles',
    'T-': 'Textile - default',
    'TC': 'Textile - canvas',
    'TL': 'Textile - leather',
    'TR': 'Textile - rug',
    'V-': 'Vegetation - default',
    'W-': 'Water - default',
    'WD': 'Water - deep',
    'WM': 'Water - marsh',
    'WP': 'Water - puddle',
    'WS': 'Water - shallow',
    'X-': 'Wood - default',
    'XB': 'Wood - bamboo',
    'XC': 'Wood - crate',
    'XF': 'Wood - floor',
    'XP': 'Wood - plank',
    'Y-': 'Sandbag - default',
    'Z-': 'Special - default',
    'ZI': 'Special - invisible',
    'ZN': 'Special - no collision',
}


# =============================================================================
# File Extensions
# =============================================================================

BES_EXTENSION = '.bes'
TEXTURE_EXTENSIONS = ['.dds', '.tga', '.bmp', '.png', '.jpg', '.jpeg']
IFL_EXTENSION = '.ifl'  # Animated texture list


# =============================================================================
# Object Prefix Types (from Pteromatic documentation)
# =============================================================================

# Collision mesh prefixes
COLLISION_PREFIXES = {
    '^K': 'player',      # Player collision (default collision mesh)
    '^SF': 'bullets',    # Bullet-only collision (shoot-through for players)
    '^SK': 'sphere',     # Sphere Dummy collision
}

# Special object prefixes
SPECIAL_PREFIXES = {
    '!': 'auxiliary',    # Auxiliary/helper object (not rendered)
    '@': 'effect',       # Effect sphere (water, slowdown zones)
    '>': 'lod_hidden',   # Hidden LOD level (can stack: >>, >>>)
}

# All prefixes combined for detection (longest first for proper matching)
ALL_PREFIXES = ['^SF', '^SK', '^K', '!', '@', '>']


# =============================================================================
# Transparency Type to Blender Blend Mode Mapping
# =============================================================================

TRANSPARENCY_TO_BLENDER = {
    TransparencyType.OPAQUE: 'OPAQUE',
    TransparencyType.TRANSPARENT_0: 'BLEND',
    TransparencyType.TRANSPARENT_1: 'CLIP',
    TransparencyType.TRANSLUCENT_2: 'BLEND',
    TransparencyType.TRANSPARENT_3: 'CLIP',
    TransparencyType.TRANSLUCENT_4: 'BLEND',  # Additive, needs special handling
}


# =============================================================================
# Physics Shape Types
# =============================================================================

class PhysicsShape(IntEnum):
    """Physics collision shape types (Phy_colshp, Phy_misshp)."""

    MESH = 0      # Mesh collision
    BOX = 1       # Box collision
    SPHERE = 2    # Sphere collision
    CAPSULE = 3   # Capsule collision


# =============================================================================
# Physics Status Types
# =============================================================================

class PhysicsStatus(IntEnum):
    """Physics object status (Phy_status)."""

    STATIC = 0     # Static object (doesn't move)
    DYNAMIC = 1    # Dynamic object (physics simulated)
    KINEMATIC = 2  # Kinematic object (animated, affects physics)


# =============================================================================
# Light Types (from IDA analysis of sub_897AF00)
# =============================================================================

class LightType(IntEnum):
    """Light types in BES format.

    Mapping discovered from IDA analysis of ExportLight function.
    3ds Max light type (v76[0]) -> BES light type (v3[2]):
    - case 0 (Omni)  -> 1
    - case 1 (Spot)  -> 3
    - case 2 (Area)  -> 4
    - case 3 (Dir)   -> 2
    """

    OMNI = 1         # Omni/Point light
    DIRECTIONAL = 2  # Directional light
    SPOT = 3         # Spot light
    AREA = 4         # Area light
