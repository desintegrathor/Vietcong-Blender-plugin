# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Data Types

Dataclass definitions for all BES format structures including
nodes, meshes, materials, vertices, and transforms.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple, Any
from enum import IntEnum

from .constants import (
    TransparencyType,
    ShaderType,
    VegetationType,
    NO_MATERIAL,
)


# =============================================================================
# Header Types
# =============================================================================

@dataclass
class BESHeader:
    """BES file header (16 bytes)."""

    signature: bytes  # b'BES\x00'
    version: str  # "0004" - "0010"
    exporter: int  # MaxSDK version or custom identifier
    reserved: int  # Usually 0

    @property
    def version_int(self) -> int:
        """Get version as integer for comparison."""
        return int.from_bytes(self.version.encode('ascii'), 'little')


@dataclass
class BESPreview:
    """BES preview image (64x64 BGR)."""

    width: int = 64
    height: int = 64
    pixels: bytes = b''  # BGR pixel data (12288 bytes)

    @property
    def size(self) -> int:
        """Get pixel data size."""
        return self.width * self.height * 3


# =============================================================================
# Chunk Types
# =============================================================================

@dataclass
class BESChunk:
    """Generic BES chunk structure."""

    chunk_type: int
    data_size: int
    data: bytes
    offset: int = 0  # File offset for debugging
    children: List['BESChunk'] = field(default_factory=list)


# =============================================================================
# Geometry Types
# =============================================================================

@dataclass
class BESVertex:
    """BES vertex with position, normal, and UV coordinates."""

    position: Tuple[float, float, float]
    normal: Tuple[float, float, float]
    uvs: List[Tuple[float, float]] = field(default_factory=list)

    # D3DFVF flags from vertex data
    flags: int = 0

    @property
    def tex_count(self) -> int:
        """Get number of texture coordinate sets."""
        return len(self.uvs)


@dataclass
class BESBoneVertex:
    """BES vertex with bone weight data (version 0005 skeletal models).

    Variable-size vertex format (36-52 bytes depending on bone count):
    - Position (12 bytes): vec3
    - Weights (4*N bytes): N floats (0.0-1.0), where N = 1-5 bones
    - Normal (12 bytes): vec3
    - UV (8 bytes): vec2

    Bone indices are stored separately in chunk 0x3B, not in vertex data.
    The number of weights is encoded in flags: (flags & 0xE) = 6,8,10,12,14 for 1-5 bones.
    """

    position: Tuple[float, float, float]
    weights: List[float]  # Variable number of bone weights (1-5)
    normal: Tuple[float, float, float]
    uv: Tuple[float, float]
    bone_indices: List[int] = field(default_factory=list)  # From chunk 0x3B

    # D3DFVF flags from vertex data
    flags: int = 0

    # Backwards compatibility properties
    @property
    def weight(self) -> float:
        """Get first bone weight (backwards compatibility)."""
        return self.weights[0] if self.weights else 0.0

    @property
    def bone_index(self) -> int:
        """Get first bone index (backwards compatibility)."""
        return self.bone_indices[0] if self.bone_indices else -1


@dataclass
class BESFace:
    """BES triangle face (3 vertex indices)."""

    a: int
    b: int
    c: int

    def as_tuple(self) -> Tuple[int, int, int]:
        """Get indices as tuple."""
        return (self.a, self.b, self.c)


@dataclass
class BESMesh:
    """BES mesh containing vertices and faces."""

    vertices: List[BESVertex] = field(default_factory=list)
    faces: List[BESFace] = field(default_factory=list)
    material_index: int = NO_MATERIAL
    flags: int = 0  # D3DFVF flags

    @property
    def vertex_count(self) -> int:
        return len(self.vertices)

    @property
    def face_count(self) -> int:
        return len(self.faces)


# =============================================================================
# Transform Types
# =============================================================================

@dataclass
class BESWobble:
    """Wobble animation parameters for vegetation."""

    amplitude: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    frequency: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    phase: Tuple[float, float, float] = (0.0, 0.0, 0.0)


@dataclass
class BESTransform:
    """BES transformation data."""

    translation: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    rotation: Tuple[float, float, float] = (0.0, 0.0, 0.0)  # Radians!
    scale: Tuple[float, float, float] = (1.0, 1.0, 1.0)

    # 4x4 transformation matrix (may contain errors - prefer decomposed values)
    matrix: Optional[List[List[float]]] = None

    # Wobble animation data
    has_wobble: bool = False
    wobble: Optional[BESWobble] = None


# =============================================================================
# Material Types
# =============================================================================

@dataclass
class BESTexture:
    """BES texture reference."""

    filename: str
    u_tile: bool = True
    v_tile: bool = True
    u_mirror: bool = False
    v_mirror: bool = False
    uv_channel: int = 0
    flags: int = 0

    @property
    def base_name(self) -> str:
        """Get filename without extension."""
        import os
        return os.path.splitext(self.filename)[0]


@dataclass
class BESMaterial:
    """Base class for BES materials."""

    material_type: str = 'unknown'
    name: str = ''
    index: int = 0


@dataclass
class BESStandardMaterial(BESMaterial):
    """3DS Max Standard material (chunk 0x1001)."""

    material_type: str = 'standard'
    material_id: float = 0.0
    unknown_field: bytes = b'\x00\x00\x00\x00'  # 4 bytes after material_id (e.g. "g_de", "DD--")
    map_flags: int = 0

    # Texture maps by slot name
    textures: Dict[str, BESTexture] = field(default_factory=dict)

    # Standard material slots (verified from IDA analysis):
    # diffuse, opacity, bump, ambient, specular, specular_level,
    # glossiness, self_illum, displacement, filter, reflection


@dataclass
class BESPteroMat(BESMaterial):
    """PteroMat material (chunk 0x1002).

    Extended properties discovered from IDA analysis of BesExport.dlu:
    - Material colors (diffuse, ambient, specular, self-illumination)
    - Material properties (opacity, glossiness, spec level)
    - Faceted flag for flat shading
    - Shader type name and filename
    """

    material_type: str = 'pteromat'
    two_sided: bool = False
    faceted: bool = False  # Flat shading instead of smooth
    texture_flags: int = 0
    collision_material: str = ''  # 2-char code
    surface: str = ''  # 4-char surface code (e.g., "GRAS", "CONC", "WOOD")
    transparency_type: int = TransparencyType.OPAQUE
    vegetation_type: str = ''  # 2-char code
    grow_type: str = ''  # 1-char grow type
    grass_type: str = ''  # 1-char grass type
    shader_type: int = ShaderType.STANDARD

    # Texture maps by slot name
    textures: Dict[str, BESTexture] = field(default_factory=dict)

    # PteroMat texture slots:
    # diffuse_1 (ground), diffuse_2 (multitexture), diffuse_3 (overlay),
    # environment_1, environment_2, lightmap, lightmap_engine, overlay_multi

    # Material colors (from IDA analysis of DumpPteroLayer)
    mat_diffuse: Tuple[float, float, float] = (0.8, 0.8, 0.8)
    mat_ambient: Tuple[float, float, float] = (0.2, 0.2, 0.2)
    mat_specular: Tuple[float, float, float] = (1.0, 1.0, 1.0)
    mat_self_illum: Tuple[float, float, float] = (0.0, 0.0, 0.0)

    # Material properties
    mat_opacity: int = 100  # 0-100
    mat_opacity_falloff: float = 0.0
    mat_glossiness: int = 0
    mat_spec_level: int = 0

    # Shader properties (from IDA strings: shaderType, shaderFilename)
    shader_type_name: str = ''  # Shader type as string (e.g., "#0", "#1", etc.)
    shader_filename: str = ''  # Path to shader file

    # Water/glass properties (from PteroLayer)
    water_env_blend: float = 0.0
    water_alpha_angle: float = 0.0
    water_sharpness: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    water_shifting_xy: Tuple[float, float] = (0.0, 0.0)
    water_shifting_uv: Tuple[float, float] = (0.0, 0.0)

    is_glass: bool = False
    is_water: bool = False

    @property
    def is_transparent(self) -> bool:
        """Check if material has transparency."""
        return self.transparency_type != TransparencyType.OPAQUE

    @property
    def has_water_properties(self) -> bool:
        """Check if material has water-specific properties."""
        return self.is_water or self.water_env_blend != 0.0


# =============================================================================
# PteroLayer Material Types (chunk 0x1004)
# =============================================================================

@dataclass
class BESTextureLayer:
    """Single texture layer in PteroLayer material.

    PteroLayer supports up to 13 texture layers with individual properties
    for tiling, animation, and special effects.
    """

    filename: str = ''
    mipmap: bool = True
    tile_u: bool = True
    tile_v: bool = True
    tiling_u: float = 1.0
    tiling_v: float = 1.0
    crop: Tuple[float, float, float, float] = (0.0, 0.0, 1.0, 1.0)  # x, y, w, h
    clip_uv: Tuple[float, float] = (0.0, 0.0)
    clip_wh: Tuple[float, float] = (1.0, 1.0)
    move: Tuple[float, float] = (0.0, 0.0)  # UV animation offset
    move_type: int = 0
    move_soft: bool = False
    moving: bool = False  # Animation enabled
    uv_channel: int = 0
    overlay_multitexture: bool = False
    lm_apply_light: bool = False  # Lightmap applies lighting
    env_type: int = 0  # Environment mapping type

    @property
    def has_animation(self) -> bool:
        """Check if layer has UV animation."""
        return self.moving or self.move != (0.0, 0.0)


@dataclass
class BESPteroLayer(BESMaterial):
    """PteroLayer material (chunk 0x1004) with up to 13 texture layers.

    This is an advanced material type that supports multiple texture layers
    with individual properties for tiling, animation, and special effects.

    Layer indices:
    0-2: Diffuse layers (ground, multitexture, overlay)
    3-4: Environment layers
    5-6: Lightmap layers
    7-12: Additional effect layers
    """

    material_type: str = 'pterolayer'
    surface: str = ''  # 4-char surface code
    grass_type: str = ''
    grow_type: str = ''
    shader_type: str = ''  # Shader type as string
    shader_filename: str = ''  # Path to shader file
    transparency_type: int = TransparencyType.OPAQUE
    two_sided: bool = False
    faceted: bool = False

    # Material colors
    mat_diffuse: Tuple[float, float, float] = (0.8, 0.8, 0.8)
    mat_ambient: Tuple[float, float, float] = (0.2, 0.2, 0.2)
    mat_specular: Tuple[float, float, float] = (1.0, 1.0, 1.0)
    mat_self_illum: Tuple[float, float, float] = (0.0, 0.0, 0.0)

    # Material properties
    mat_opacity: int = 100  # 0-100
    mat_opacity_falloff: float = 0.0
    mat_glossiness: int = 0
    mat_spec_level: int = 0

    # Special flags
    is_glass: bool = False
    is_water: bool = False

    # Water properties
    water_env_blend: float = 0.0
    water_alpha_angle: float = 0.0
    water_sharpness: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    water_shifting_xy: Tuple[float, float] = (0.0, 0.0)
    water_shifting_uv: Tuple[float, float] = (0.0, 0.0)

    # Layer ordering (indices into layers list for render order)
    layer_order: List[int] = field(default_factory=list)

    # 13 texture layers
    layers: List[BESTextureLayer] = field(default_factory=list)

    @property
    def is_transparent(self) -> bool:
        """Check if material has transparency."""
        return self.transparency_type != TransparencyType.OPAQUE

    @property
    def layer_count(self) -> int:
        """Get number of texture layers."""
        return len(self.layers)

    def get_layer(self, index: int) -> Optional[BESTextureLayer]:
        """Get texture layer by index.

        Args:
            index: Layer index (0-12)

        Returns:
            BESTextureLayer or None if index out of range
        """
        if 0 <= index < len(self.layers):
            return self.layers[index]
        return None


# =============================================================================
# Node/Object Types
# =============================================================================

@dataclass
class BESProperties:
    """User-defined properties from INI format string."""

    raw_text: str = ''
    properties: Dict[str, Any] = field(default_factory=dict)

    # Common properties
    lod_distances: List[float] = field(default_factory=list)
    last_lod_alpha: Optional[float] = None
    clip_distance: Optional[float] = None
    lighting: Optional[List[float]] = None
    wobble_params: Optional[Tuple[float, ...]] = None

    def parse(self):
        """Parse raw INI text into properties dict."""
        if not self.raw_text:
            return

        for line in self.raw_text.split('\n'):
            line = line.strip()
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()

                # Try to parse value as number
                parsed_value = self._parse_value(value)

                # Parse known properties
                if key.lower() == 'lod':
                    try:
                        self.lod_distances.append(float(value))
                    except ValueError:
                        pass
                elif key.lower() == 'lastlodalpha':
                    try:
                        self.last_lod_alpha = float(value)
                    except ValueError:
                        pass
                elif key.lower() == 'clipdist':
                    try:
                        self.clip_distance = float(value)
                    except ValueError:
                        pass
                elif key.lower() == 'lighting':
                    try:
                        self.lighting = [float(x) for x in value.split(',')]
                    except ValueError:
                        pass
                elif key.lower() == 'wobble':
                    try:
                        self.wobble_params = tuple(float(x) for x in value.split(','))
                    except ValueError:
                        pass

                # Store with proper type (int/float/string)
                self.properties[key] = parsed_value

    def _parse_value(self, value: str):
        """Parse string value to appropriate type (int, float, or string)."""
        # Try integer first
        try:
            return int(value)
        except ValueError:
            pass

        # Try float
        try:
            return float(value)
        except ValueError:
            pass

        # Return as string
        return value


@dataclass
class BESNode:
    """BES scene node/object."""

    name: str = ''
    name_hash: int = 0

    # Child nodes
    children: List['BESNode'] = field(default_factory=list)

    # Mesh data (if this node has geometry)
    meshes: List[BESMesh] = field(default_factory=list)

    # Transform
    transform: Optional[BESTransform] = None

    # Bounding box dimensions (3 floats)
    bbox: Tuple[float, float, float] = (0.0, 0.0, 0.0)

    # User properties
    properties: Optional[BESProperties] = None

    # Node flags
    flags: int = 0
    node_type: int = 0

    # Parent reference (set during tree building)
    parent: Optional['BESNode'] = None

    # Light data (if this node is a light, populated after parsing)
    light: Optional['BESLight'] = None

    # Helper data (if this node is a helper/dummy, populated after parsing)
    helper: Optional['BESHelper'] = None

    # Collision data (if this node has collision mesh, populated after parsing)
    collision: Optional['BESCollision'] = None

    @property
    def is_hidden(self) -> bool:
        """Check if node is hidden (name starts with '>')."""
        return self.name.startswith('>')

    @property
    def has_mesh(self) -> bool:
        """Check if node has mesh data."""
        return len(self.meshes) > 0

    @property
    def is_light(self) -> bool:
        """Check if node is a light."""
        return self.light is not None

    @property
    def is_helper(self) -> bool:
        """Check if node is a helper/dummy."""
        return self.helper is not None

    @property
    def is_collision(self) -> bool:
        """Check if node has collision data."""
        return self.collision is not None

    @property
    def child_count(self) -> int:
        """Get number of child nodes."""
        return len(self.children)

    def get_visible_name(self) -> str:
        """Get name without hidden prefix."""
        if self.name.startswith('>'):
            return self.name[1:]
        return self.name


# =============================================================================
# Light Types (from IDA analysis of sub_897AF00)
# =============================================================================

@dataclass
class BESLight:
    """BES light object (chunk 0x20, 112 bytes).

    Structure discovered from IDA analysis of ExportLight function:
    - Offset 0: block_type (32)
    - Offset 4: block_size (112)
    - Offset 8: light_type (1=Omni, 2=Dir, 3=Spot, 4=Area)
    - Offset 12-23: color RGB (3 floats)
    - Offset 24-27: intensity (float)
    - Offset 28-31: hotspot angle (float, for spot lights)
    - Offset 32-35: falloff angle (float, for spot lights)
    - Offset 36-39: far attenuation (float)
    - Offset 40-87: transform matrix (4x3 = 12 floats)
    """

    name: str = ''
    light_type: int = 1  # 1=Omni, 2=Dir, 3=Spot, 4=Area
    color: Tuple[float, float, float] = (1.0, 1.0, 1.0)
    intensity: float = 1.0
    hotspot: float = 0.0  # Inner cone angle for spot lights
    falloff: float = 0.0  # Outer cone angle for spot lights
    far_atten: float = 0.0  # Far attenuation distance
    matrix: List[float] = field(default_factory=lambda: [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
    ])  # 4x3 transform matrix (12 floats)


@dataclass
class BESHelper:
    """BES helper/dummy object (chunk 0x40, 36 bytes).

    Structure discovered from IDA analysis of ExportHelper function:
    - Offset 0: block_type (64)
    - Offset 4: block_size (36)
    - Offset 8-19: box size (3 floats)
    - Offset 20-31: position (3 floats)
    - Offset 32-35: rotation euler angles start (continues beyond 36?)

    Note: Helper objects are typically used as attachment points,
    effect locations, or other non-rendered reference points.
    """

    name: str = ''
    box_size: Tuple[float, float, float] = (1.0, 1.0, 1.0)
    position: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    rotation: Tuple[float, float, float] = (0.0, 0.0, 0.0)  # Euler angles


@dataclass
class BESCollision:
    """BES collision object (chunk 0x82).

    Structure discovered from IDA analysis of ExportCollision (sub_897D2D0):
    - Offset 0: block_type (0x82 = 130)
    - Offset 4: block_size (= vertex_size + face_size + bone_size + 39)
    - Offset 8: collision_type (always 2)
    - Offset 12: vertex_data_size (bytes)
    - Offset 16: face_data_size (bytes)
    - Offset 20: bone_data_size (bytes, 0 if no bones)
    - Offset 24-35: center point (3 floats)
    - Offset 36+: vertex_data, face_data, bone_data

    Collision triangles are stored internally as 60-byte structures:
    - Byte 0: type (0=triangle, 1=sphere)
    - For triangles: 3 vertices (9 floats) + material hash
    - For spheres: position (3 floats) + radius + material hash
    """

    name: str = ''
    collision_type: int = 2  # Always 2 from IDA analysis
    center: Tuple[float, float, float] = (0.0, 0.0, 0.0)

    # Parsed vertex positions
    vertices: List[Tuple[float, float, float]] = field(default_factory=list)

    # Parsed face indices (triangles)
    faces: List[Tuple[int, int, int]] = field(default_factory=list)

    # Material hash per face
    face_materials: List[int] = field(default_factory=list)

    # Raw data for further analysis if needed
    raw_vertex_data: bytes = b''
    raw_face_data: bytes = b''
    raw_bone_data: Optional[bytes] = None
    raw_trailing: bytes = b''  # Trailing padding bytes

    @property
    def vertex_count(self) -> int:
        """Get number of vertices."""
        return len(self.vertices)

    @property
    def face_count(self) -> int:
        """Get number of faces."""
        return len(self.faces)

    @property
    def has_bone_data(self) -> bool:
        """Check if collision has bone weight data."""
        return self.raw_bone_data is not None and len(self.raw_bone_data) > 0


# =============================================================================
# Skeleton Types (Version 0005)
# =============================================================================

@dataclass
class BESBonePart:
    """BES body part for skeletal models (version 0005).

    Each bone part represents a body part at a specific LOD/damage level.
    Name format: {LOD}{DAMAGE}_{BODYPART}{INDEX}
    - LOD: 0=high, 1=medium, 2=low detail
    - DAMAGE: A=clean, B=damaged, C=heavily damaged
    - BODYPART: head, bodyback, bodyfront, leftarm, rightarm, leftleg, rightleg
    - INDEX: 00-10 for sub-parts (e.g., arm segments)
    """

    name: str = ''
    lod_level: int = 0  # 0, 1, 2
    damage_state: str = 'A'  # A, B, C
    body_part: str = ''  # e.g., "head", "leftarm"
    part_index: int = 0  # 00-10

    transform: Optional['BESTransform'] = None
    meshes: List['BESMesh'] = field(default_factory=list)

    @classmethod
    def parse_name(cls, name: str) -> 'BESBonePart':
        """Parse bone part name into components.

        Args:
            name: Bone name like "0A_head" or "2C_leftarm05"

        Returns:
            BESBonePart with parsed components
        """
        part = cls(name=name)

        if len(name) >= 3 and name[1] in 'ABC' and name[2] == '_':
            try:
                part.lod_level = int(name[0])
                part.damage_state = name[1]

                # Parse body part and optional index
                rest = name[3:]
                # Check for trailing digits
                i = len(rest)
                while i > 0 and rest[i-1].isdigit():
                    i -= 1

                if i < len(rest):
                    part.body_part = rest[:i]
                    part.part_index = int(rest[i:])
                else:
                    part.body_part = rest
            except (ValueError, IndexError):
                pass

        return part


@dataclass
class BESSkeleton:
    """Complete skeleton data for version 0005 character models."""

    name: str = 'Skeleton Object'
    bone_parts: List[BESBonePart] = field(default_factory=list)

    # Raw ISKE_MESH chunk data for roundtrip preservation
    # This contains the complete skeleton hierarchy (bone names, transforms, etc.)
    raw_iske_mesh_data: Optional[bytes] = None

    # Index mapping for quick lookup
    _bone_map: Dict[str, int] = field(default_factory=dict)

    def add_bone_part(self, bone: BESBonePart):
        """Add a bone part and update index."""
        self._bone_map[bone.name] = len(self.bone_parts)
        self.bone_parts.append(bone)

    def get_bone_by_name(self, name: str) -> Optional[BESBonePart]:
        """Get bone part by name."""
        idx = self._bone_map.get(name)
        if idx is not None:
            return self.bone_parts[idx]
        return None

    def get_bones_by_lod(self, lod: int) -> List[BESBonePart]:
        """Get all bone parts at specific LOD level."""
        return [b for b in self.bone_parts if b.lod_level == lod]

    def get_bones_by_damage(self, damage: str) -> List[BESBonePart]:
        """Get all bone parts at specific damage state."""
        return [b for b in self.bone_parts if b.damage_state == damage]

    def get_clean_high_detail(self) -> List[BESBonePart]:
        """Get high-detail clean bones (LOD 0, damage A)."""
        return [b for b in self.bone_parts
                if b.lod_level == 0 and b.damage_state == 'A']


# =============================================================================
# Info Block Type
# =============================================================================

@dataclass
class BESInfo:
    """BES file metadata (chunk 0x70)."""

    author: str = ''
    comment: str = ''
    total_faces: int = 0
    has_comment: bool = False  # True if comment_len > 0 (even for empty comment)


# =============================================================================
# Complete BES File Type
# =============================================================================

@dataclass
class BESFile:
    """Complete BES file structure."""

    # File metadata
    filepath: str = ''
    header: Optional[BESHeader] = None
    preview: Optional[BESPreview] = None
    info: Optional[BESInfo] = None

    # Scene data
    root_node: Optional[BESNode] = None
    materials: List[BESMaterial] = field(default_factory=list)

    # Lights, helpers, and collisions (discovered from IDA analysis)
    lights: List[BESLight] = field(default_factory=list)
    helpers: List[BESHelper] = field(default_factory=list)
    collisions: List[BESCollision] = field(default_factory=list)

    # Skeleton data (version 0005)
    skeleton: Optional[BESSkeleton] = None

    # Statistics
    total_nodes: int = 0
    total_meshes: int = 0
    total_vertices: int = 0
    total_faces: int = 0
    total_lights: int = 0
    total_helpers: int = 0
    total_collisions: int = 0

    # Version-specific flags
    is_skeletal: bool = False  # True for version 0005 character models

    def get_material(self, index: int) -> Optional[BESMaterial]:
        """Get material by index."""
        if 0 <= index < len(self.materials):
            return self.materials[index]
        return None

    def count_nodes(self) -> int:
        """Count total nodes in scene tree."""
        def count_recursive(node: BESNode) -> int:
            count = 1
            for child in node.children:
                count += count_recursive(child)
            return count

        if self.root_node:
            return count_recursive(self.root_node)
        return 0


# =============================================================================
# Name Hash Function
# =============================================================================

def calculate_name_hash(name: str) -> int:
    """Calculate 64-bit name hash used by Ptero-Engine-II.

    Args:
        name: Node name to hash

    Returns:
        64-bit hash value
    """
    hash_val = 0

    for char in name:
        c = ord(char)

        # Convert to uppercase
        if ord('a') <= c <= ord('z'):
            c = c - 32

        # Skip invalid characters
        if c < 0x20 or c >= 0x60:
            continue

        # Hash formula: hash = (hash - 2) * 16 + char
        hash_val = ((hash_val - 2) * 16 + c) & 0xFFFFFFFFFFFFFFFF

    return hash_val
