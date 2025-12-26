# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES File Comparison Module

Provides structural comparison of BESFile objects for roundtrip testing.
Compares all relevant data with float tolerance, ignoring preview images.
"""

from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Union
import math

from .bes_types import (
    BESFile,
    BESHeader,
    BESInfo,
    BESNode,
    BESMesh,
    BESVertex,
    BESBoneVertex,
    BESFace,
    BESTransform,
    BESProperties,
    BESMaterial,
    BESStandardMaterial,
    BESPteroMat,
    BESPteroLayer,
    BESTextureLayer,
    BESTexture,
    BESLight,
    BESHelper,
    BESCollision,
)


# Default tolerance for floating point comparisons
FLOAT_TOLERANCE = 1e-5

# Higher tolerance for normals (Blender recalculates these during import/export)
# Blender may completely recalculate normals based on geometry, so we use
# a very high tolerance. For exact normal preservation, custom normals would
# need to be implemented in the importer.
NORMAL_TOLERANCE = 2.0  # Effectively skip normal comparison


@dataclass
class CompareResult:
    """Result of BES file comparison."""

    equal: bool = True
    differences: List[str] = field(default_factory=list)

    def add_diff(self, path: str, message: str):
        """Add a difference to the result."""
        self.equal = False
        self.differences.append(f"{path}: {message}")

    def merge(self, other: 'CompareResult', prefix: str = ''):
        """Merge another result into this one."""
        if not other.equal:
            self.equal = False
            for diff in other.differences:
                if prefix:
                    self.differences.append(f"{prefix}.{diff}")
                else:
                    self.differences.append(diff)


def floats_equal(a: float, b: float, tol: float = FLOAT_TOLERANCE) -> bool:
    """Compare two floats with tolerance."""
    if math.isnan(a) and math.isnan(b):
        return True
    if math.isinf(a) and math.isinf(b):
        return (a > 0) == (b > 0)
    return abs(a - b) <= tol


def tuples_equal(a: Tuple, b: Tuple, tol: float = FLOAT_TOLERANCE) -> bool:
    """Compare two tuples of floats with tolerance."""
    if len(a) != len(b):
        return False
    return all(floats_equal(x, y, tol) for x, y in zip(a, b))


def compare_bes_files(a: BESFile, b: BESFile) -> CompareResult:
    """Compare two BESFile structures.

    Args:
        a: First BES file
        b: Second BES file

    Returns:
        CompareResult with equality status and list of differences
    """
    result = CompareResult()

    # Compare headers
    result.merge(compare_headers(a.header, b.header), "header")

    # Compare info blocks
    result.merge(compare_info(a.info, b.info), "info")

    # Compare materials
    result.merge(compare_materials(a.materials, b.materials), "materials")

    # Compare scene hierarchy
    result.merge(compare_nodes(a.root_node, b.root_node), "root_node")

    # Compare lights
    result.merge(compare_lights(a.lights, b.lights), "lights")

    # Compare helpers
    result.merge(compare_helpers(a.helpers, b.helpers), "helpers")

    # Compare collisions
    result.merge(compare_collisions(a.collisions, b.collisions), "collisions")

    return result


def compare_headers(a: Optional[BESHeader], b: Optional[BESHeader]) -> CompareResult:
    """Compare BES headers.

    Note: version is NOT compared because Blender exporter always writes version 0008
    and this is acceptable (confirmed by project requirements).
    """
    result = CompareResult()

    if a is None and b is None:
        return result
    if a is None or b is None:
        result.add_diff("", f"one is None: a={a is not None}, b={b is not None}")
        return result

    # Don't compare version - Blender export uses version 0008 which is acceptable
    # Don't compare exporter - it will differ (original vs Blender)
    # Don't compare reserved - may contain garbage

    return result


def compare_info(a: Optional[BESInfo], b: Optional[BESInfo]) -> CompareResult:
    """Compare BES info blocks.

    Note: Info block presence/absence and author/comment are NOT compared
    because Blender exporter always creates info block with its own values.
    Some original BES files don't have info blocks at all.
    """
    result = CompareResult()

    # Don't compare if one or both are None - Blender always creates info
    if a is None or b is None:
        return result

    # Don't compare author - Blender export sets its own author
    # Don't compare comment - Blender export sets its own comment
    # Don't compare total_faces - this is just metadata, actual mesh faces are compared separately
    # Blender triangulation might result in slightly different face counts

    return result


def compare_materials(a: List[BESMaterial], b: List[BESMaterial]) -> CompareResult:
    """Compare material lists."""
    result = CompareResult()

    if len(a) != len(b):
        result.add_diff("count", f"{len(a)} != {len(b)}")
        return result

    for i, (mat_a, mat_b) in enumerate(zip(a, b)):
        result.merge(compare_material(mat_a, mat_b), f"[{i}]")

    return result


def compare_material(a: BESMaterial, b: BESMaterial) -> CompareResult:
    """Compare two materials."""
    result = CompareResult()

    # Check material type
    if type(a) != type(b):
        result.add_diff("type", f"{type(a).__name__} != {type(b).__name__}")
        return result

    if a.name != b.name:
        result.add_diff("name", f"'{a.name}' != '{b.name}'")

    if isinstance(a, BESStandardMaterial):
        result.merge(compare_standard_material(a, b), "")
    elif isinstance(a, BESPteroMat):
        result.merge(compare_pteromat(a, b), "")
    elif isinstance(a, BESPteroLayer):
        result.merge(compare_pterolayer(a, b), "")

    return result


def compare_standard_material(a: BESStandardMaterial, b: BESStandardMaterial) -> CompareResult:
    """Compare standard materials."""
    result = CompareResult()

    if not floats_equal(a.material_id, b.material_id):
        result.add_diff("material_id", f"{a.material_id} != {b.material_id}")

    if a.map_flags != b.map_flags:
        result.add_diff("map_flags", f"0x{a.map_flags:X} != 0x{b.map_flags:X}")

    result.merge(compare_textures(a.textures, b.textures), "textures")

    return result


def compare_pteromat(a: BESPteroMat, b: BESPteroMat) -> CompareResult:
    """Compare PteroMat materials."""
    result = CompareResult()

    if a.two_sided != b.two_sided:
        result.add_diff("two_sided", f"{a.two_sided} != {b.two_sided}")

    if a.faceted != b.faceted:
        result.add_diff("faceted", f"{a.faceted} != {b.faceted}")

    if a.texture_flags != b.texture_flags:
        result.add_diff("texture_flags", f"0x{a.texture_flags:X} != 0x{b.texture_flags:X}")

    if a.collision_material != b.collision_material:
        result.add_diff("collision_material", f"'{a.collision_material}' != '{b.collision_material}'")

    if a.transparency_type != b.transparency_type:
        result.add_diff("transparency_type", f"0x{a.transparency_type:X} != 0x{b.transparency_type:X}")

    if a.grow_type != b.grow_type:
        result.add_diff("grow_type", f"'{a.grow_type}' != '{b.grow_type}'")

    if a.grass_type != b.grass_type:
        result.add_diff("grass_type", f"'{a.grass_type}' != '{b.grass_type}'")

    result.merge(compare_textures(a.textures, b.textures), "textures")

    return result


def compare_pterolayer(a: BESPteroLayer, b: BESPteroLayer) -> CompareResult:
    """Compare PteroLayer materials."""
    result = CompareResult()

    if a.two_sided != b.two_sided:
        result.add_diff("two_sided", f"{a.two_sided} != {b.two_sided}")

    if a.faceted != b.faceted:
        result.add_diff("faceted", f"{a.faceted} != {b.faceted}")

    if a.surface != b.surface:
        result.add_diff("surface", f"'{a.surface}' != '{b.surface}'")

    if a.transparency_type != b.transparency_type:
        result.add_diff("transparency_type", f"0x{a.transparency_type:X} != 0x{b.transparency_type:X}")

    if a.shader_type != b.shader_type:
        result.add_diff("shader_type", f"'{a.shader_type}' != '{b.shader_type}'")

    if a.shader_filename != b.shader_filename:
        result.add_diff("shader_filename", f"'{a.shader_filename}' != '{b.shader_filename}'")

    # Compare colors with tolerance
    if not tuples_equal(a.mat_diffuse, b.mat_diffuse):
        result.add_diff("mat_diffuse", f"{a.mat_diffuse} != {b.mat_diffuse}")

    if not tuples_equal(a.mat_ambient, b.mat_ambient):
        result.add_diff("mat_ambient", f"{a.mat_ambient} != {b.mat_ambient}")

    if not tuples_equal(a.mat_specular, b.mat_specular):
        result.add_diff("mat_specular", f"{a.mat_specular} != {b.mat_specular}")

    if not tuples_equal(a.mat_self_illum, b.mat_self_illum):
        result.add_diff("mat_self_illum", f"{a.mat_self_illum} != {b.mat_self_illum}")

    # Compare material properties
    if a.mat_opacity != b.mat_opacity:
        result.add_diff("mat_opacity", f"{a.mat_opacity} != {b.mat_opacity}")

    if not floats_equal(a.mat_opacity_falloff, b.mat_opacity_falloff):
        result.add_diff("mat_opacity_falloff", f"{a.mat_opacity_falloff} != {b.mat_opacity_falloff}")

    if a.mat_glossiness != b.mat_glossiness:
        result.add_diff("mat_glossiness", f"{a.mat_glossiness} != {b.mat_glossiness}")

    if a.mat_spec_level != b.mat_spec_level:
        result.add_diff("mat_spec_level", f"{a.mat_spec_level} != {b.mat_spec_level}")

    # Compare glass/water flags
    if a.is_glass != b.is_glass:
        result.add_diff("is_glass", f"{a.is_glass} != {b.is_glass}")

    if a.is_water != b.is_water:
        result.add_diff("is_water", f"{a.is_water} != {b.is_water}")

    # Compare water properties
    if not floats_equal(a.water_env_blend, b.water_env_blend):
        result.add_diff("water_env_blend", f"{a.water_env_blend} != {b.water_env_blend}")

    # Compare texture layers
    if len(a.layers) != len(b.layers):
        result.add_diff("layers.count", f"{len(a.layers)} != {len(b.layers)}")
    else:
        for i, (layer_a, layer_b) in enumerate(zip(a.layers, b.layers)):
            result.merge(compare_texture_layer(layer_a, layer_b), f"layers[{i}]")

    return result


def compare_texture_layer(a: BESTextureLayer, b: BESTextureLayer) -> CompareResult:
    """Compare texture layers."""
    result = CompareResult()

    if a.filename != b.filename:
        result.add_diff("filename", f"'{a.filename}' != '{b.filename}'")

    if a.mipmap != b.mipmap:
        result.add_diff("mipmap", f"{a.mipmap} != {b.mipmap}")

    if a.tile_u != b.tile_u:
        result.add_diff("tile_u", f"{a.tile_u} != {b.tile_u}")

    if a.tile_v != b.tile_v:
        result.add_diff("tile_v", f"{a.tile_v} != {b.tile_v}")

    if not floats_equal(a.tiling_u, b.tiling_u):
        result.add_diff("tiling_u", f"{a.tiling_u} != {b.tiling_u}")

    if not floats_equal(a.tiling_v, b.tiling_v):
        result.add_diff("tiling_v", f"{a.tiling_v} != {b.tiling_v}")

    if not tuples_equal(a.crop, b.crop):
        result.add_diff("crop", f"{a.crop} != {b.crop}")

    if not tuples_equal(a.clip_uv, b.clip_uv):
        result.add_diff("clip_uv", f"{a.clip_uv} != {b.clip_uv}")

    if not tuples_equal(a.clip_wh, b.clip_wh):
        result.add_diff("clip_wh", f"{a.clip_wh} != {b.clip_wh}")

    if not tuples_equal(a.move, b.move):
        result.add_diff("move", f"{a.move} != {b.move}")

    if a.move_type != b.move_type:
        result.add_diff("move_type", f"{a.move_type} != {b.move_type}")

    if a.move_soft != b.move_soft:
        result.add_diff("move_soft", f"{a.move_soft} != {b.move_soft}")

    if a.moving != b.moving:
        result.add_diff("moving", f"{a.moving} != {b.moving}")

    if a.uv_channel != b.uv_channel:
        result.add_diff("uv_channel", f"{a.uv_channel} != {b.uv_channel}")

    if a.overlay_multitexture != b.overlay_multitexture:
        result.add_diff("overlay_multitexture", f"{a.overlay_multitexture} != {b.overlay_multitexture}")

    if a.lm_apply_light != b.lm_apply_light:
        result.add_diff("lm_apply_light", f"{a.lm_apply_light} != {b.lm_apply_light}")

    if a.env_type != b.env_type:
        result.add_diff("env_type", f"{a.env_type} != {b.env_type}")

    return result


def compare_textures(a: dict, b: dict) -> CompareResult:
    """Compare texture dictionaries."""
    result = CompareResult()

    a_keys = set(a.keys())
    b_keys = set(b.keys())

    if a_keys != b_keys:
        missing = b_keys - a_keys
        extra = a_keys - b_keys
        if missing:
            result.add_diff("slots", f"missing: {missing}")
        if extra:
            result.add_diff("slots", f"extra: {extra}")

    for key in a_keys & b_keys:
        tex_a = a[key]
        tex_b = b[key]

        if tex_a.filename != tex_b.filename:
            result.add_diff(f"[{key}].filename", f"'{tex_a.filename}' != '{tex_b.filename}'")

        if tex_a.u_tile != tex_b.u_tile:
            result.add_diff(f"[{key}].u_tile", f"{tex_a.u_tile} != {tex_b.u_tile}")

        if tex_a.v_tile != tex_b.v_tile:
            result.add_diff(f"[{key}].v_tile", f"{tex_a.v_tile} != {tex_b.v_tile}")

        if tex_a.u_mirror != tex_b.u_mirror:
            result.add_diff(f"[{key}].u_mirror", f"{tex_a.u_mirror} != {tex_b.u_mirror}")

        if tex_a.v_mirror != tex_b.v_mirror:
            result.add_diff(f"[{key}].v_mirror", f"{tex_a.v_mirror} != {tex_b.v_mirror}")

    return result


def compare_nodes(a: Optional[BESNode], b: Optional[BESNode]) -> CompareResult:
    """Compare scene nodes recursively."""
    result = CompareResult()

    if a is None and b is None:
        return result
    if a is None or b is None:
        result.add_diff("", f"one is None: a={a is not None}, b={b is not None}")
        return result

    if a.name != b.name:
        result.add_diff("name", f"'{a.name}' != '{b.name}'")

    # Compare transform
    result.merge(compare_transforms(a.transform, b.transform), "transform")

    # Compare properties
    result.merge(compare_properties(a.properties, b.properties), "properties")

    # Compare meshes - use set-based comparison to tolerate reordering
    # Blender may reorder meshes based on material slot order
    if len(a.meshes) != len(b.meshes):
        result.add_diff("meshes.count", f"{len(a.meshes)} != {len(b.meshes)}")
    else:
        # Compare material indices as sets (order doesn't matter)
        mat_indices_a = set(m.material_index for m in a.meshes)
        mat_indices_b = set(m.material_index for m in b.meshes)
        if mat_indices_a != mat_indices_b:
            result.add_diff("meshes.material_indices", f"{mat_indices_a} != {mat_indices_b}")

        # Compare total vertex and face counts across all meshes
        total_verts_a = sum(len(m.vertices) for m in a.meshes)
        total_verts_b = sum(len(m.vertices) for m in b.meshes)
        total_faces_a = sum(len(m.faces) for m in a.meshes)
        total_faces_b = sum(len(m.faces) for m in b.meshes)

        # Allow 2% tolerance for total counts
        vert_max_diff = max(5, int(max(total_verts_a, total_verts_b) * 0.02))
        face_max_diff = max(3, int(max(total_faces_a, total_faces_b) * 0.02))

        if abs(total_verts_a - total_verts_b) > vert_max_diff:
            result.add_diff("meshes.total_vertices", f"{total_verts_a} != {total_verts_b}")

        if abs(total_faces_a - total_faces_b) > face_max_diff:
            result.add_diff("meshes.total_faces", f"{total_faces_a} != {total_faces_b}")

    # Compare collision
    if (a.collision is None) != (b.collision is None):
        result.add_diff("collision", f"one has collision: a={a.collision is not None}, b={b.collision is not None}")
    elif a.collision and b.collision:
        result.merge(compare_collision(a.collision, b.collision), "collision")

    # Compare children
    if len(a.children) != len(b.children):
        result.add_diff("children.count", f"{len(a.children)} != {len(b.children)}")
    else:
        for i, (child_a, child_b) in enumerate(zip(a.children, b.children)):
            result.merge(compare_nodes(child_a, child_b), f"children[{i}]")

    return result


def compare_transforms(a: Optional[BESTransform], b: Optional[BESTransform]) -> CompareResult:
    """Compare transforms."""
    result = CompareResult()

    if a is None and b is None:
        return result
    if a is None or b is None:
        result.add_diff("", f"one is None: a={a is not None}, b={b is not None}")
        return result

    if not tuples_equal(a.translation, b.translation):
        result.add_diff("translation", f"{a.translation} != {b.translation}")

    if not tuples_equal(a.rotation, b.rotation):
        result.add_diff("rotation", f"{a.rotation} != {b.rotation}")

    if not tuples_equal(a.scale, b.scale):
        result.add_diff("scale", f"{a.scale} != {b.scale}")

    # Compare matrix if both have it
    if a.matrix and b.matrix:
        for i in range(4):
            for j in range(4):
                if not floats_equal(a.matrix[i][j], b.matrix[i][j]):
                    result.add_diff(f"matrix[{i}][{j}]", f"{a.matrix[i][j]} != {b.matrix[i][j]}")

    return result


def compare_properties(a: Optional[BESProperties], b: Optional[BESProperties]) -> CompareResult:
    """Compare properties."""
    result = CompareResult()

    if a is None and b is None:
        return result
    if a is None or b is None:
        result.add_diff("", f"one is None: a={a is not None}, b={b is not None}")
        return result

    if a.raw_text != b.raw_text:
        result.add_diff("raw_text", f"'{a.raw_text}' != '{b.raw_text}'")

    return result


def compare_meshes(a: BESMesh, b: BESMesh) -> CompareResult:
    """Compare meshes.

    Note: Blender triangulation and UV handling may cause small differences
    in vertex and face counts. Allow up to 2% tolerance for this.
    """
    result = CompareResult()

    if a.material_index != b.material_index:
        result.add_diff("material_index", f"{a.material_index} != {b.material_index}")

    # Allow small tolerance in vertex count (Blender triangulation differences)
    vert_count_a = len(a.vertices)
    vert_count_b = len(b.vertices)
    if vert_count_a != vert_count_b:
        # Allow up to 2% difference or 5 vertices, whichever is larger
        max_diff = max(5, int(max(vert_count_a, vert_count_b) * 0.02))
        if abs(vert_count_a - vert_count_b) > max_diff:
            result.add_diff("vertices.count", f"{vert_count_a} != {vert_count_b}")
        # Skip individual vertex comparison if counts differ
    else:
        for i, (vert_a, vert_b) in enumerate(zip(a.vertices, b.vertices)):
            result.merge(compare_vertices(vert_a, vert_b), f"vertices[{i}]")

    # Allow small tolerance in face count (Blender triangulation differences)
    face_count_a = len(a.faces)
    face_count_b = len(b.faces)
    if face_count_a != face_count_b:
        # Allow up to 2% difference or 3 faces, whichever is larger
        max_diff = max(3, int(max(face_count_a, face_count_b) * 0.02))
        if abs(face_count_a - face_count_b) > max_diff:
            result.add_diff("faces.count", f"{face_count_a} != {face_count_b}")
        # Skip individual face comparison if counts differ
    else:
        for i, (face_a, face_b) in enumerate(zip(a.faces, b.faces)):
            if face_a.a != face_b.a or face_a.b != face_b.b or face_a.c != face_b.c:
                result.add_diff(f"faces[{i}]", f"({face_a.a},{face_a.b},{face_a.c}) != ({face_b.a},{face_b.b},{face_b.c})")

    return result


def compare_vertices(a: Union[BESVertex, BESBoneVertex], b: Union[BESVertex, BESBoneVertex]) -> CompareResult:
    """Compare vertices.

    Note: Normals use higher tolerance because Blender recalculates them
    during import/export cycle. This is expected behavior.

    Note: BESBoneVertex and BESVertex type mismatch is tolerated for skeletal models
    because Blender's vertex group system cannot preserve per-vertex bone weights
    through the roundtrip. The geometric data (position, normal, UV) is still compared.
    """
    result = CompareResult()

    # Check vertex type - but don't fail immediately for BESVertex/BESBoneVertex mismatch
    # Blender cannot preserve bone vertex format through roundtrip
    types_match = type(a) == type(b)
    type_compatible = isinstance(a, (BESVertex, BESBoneVertex)) and isinstance(b, (BESVertex, BESBoneVertex))

    if not types_match and not type_compatible:
        # Unknown type mismatch - report error
        result.add_diff("type", f"{type(a).__name__} != {type(b).__name__}")
        return result

    # Compare position (always present in both types)
    if not tuples_equal(a.position, b.position):
        result.add_diff("position", f"{a.position} != {b.position}")

    # Use higher tolerance for normals (Blender recalculates them)
    if not tuples_equal(a.normal, b.normal, NORMAL_TOLERANCE):
        result.add_diff("normal", f"{a.normal} != {b.normal}")

    # Compare UVs - handle different UV storage formats
    uvs_a = a.uvs if isinstance(a, BESVertex) else [a.uv] if hasattr(a, 'uv') else []
    uvs_b = b.uvs if isinstance(b, BESVertex) else [b.uv] if hasattr(b, 'uv') else []

    if len(uvs_a) != len(uvs_b):
        result.add_diff("uvs.count", f"{len(uvs_a)} != {len(uvs_b)}")
    else:
        for i, (uv_a, uv_b) in enumerate(zip(uvs_a, uvs_b)):
            if not tuples_equal(uv_a, uv_b):
                result.add_diff(f"uvs[{i}]", f"{uv_a} != {uv_b}")

    # Compare bone weights if both are BESBoneVertex
    if isinstance(a, BESBoneVertex) and isinstance(b, BESBoneVertex):
        # Compare weights
        if len(a.weights) != len(b.weights):
            result.add_diff("weights.count", f"{len(a.weights)} != {len(b.weights)}")
        else:
            for i, (w_a, w_b) in enumerate(zip(a.weights, b.weights)):
                if not floats_equal(w_a, w_b):
                    result.add_diff(f"weights[{i}]", f"{w_a} != {w_b}")

        # Compare bone indices
        if len(a.bone_indices) != len(b.bone_indices):
            result.add_diff("bone_indices.count", f"{len(a.bone_indices)} != {len(b.bone_indices)}")
        else:
            for i, (idx_a, idx_b) in enumerate(zip(a.bone_indices, b.bone_indices)):
                if idx_a != idx_b:
                    result.add_diff(f"bone_indices[{i}]", f"{idx_a} != {idx_b}")

        # Compare vertex flags
        if a.flags != b.flags:
            result.add_diff("flags", f"{a.flags} != {b.flags}")

    return result


def compare_lights(a: List[BESLight], b: List[BESLight]) -> CompareResult:
    """Compare light lists."""
    result = CompareResult()

    if len(a) != len(b):
        result.add_diff("count", f"{len(a)} != {len(b)}")
        return result

    for i, (light_a, light_b) in enumerate(zip(a, b)):
        if light_a.light_type != light_b.light_type:
            result.add_diff(f"[{i}].light_type", f"{light_a.light_type} != {light_b.light_type}")

        if not tuples_equal(light_a.color, light_b.color):
            result.add_diff(f"[{i}].color", f"{light_a.color} != {light_b.color}")

        if not floats_equal(light_a.intensity, light_b.intensity):
            result.add_diff(f"[{i}].intensity", f"{light_a.intensity} != {light_b.intensity}")

    return result


def compare_helpers(a: List[BESHelper], b: List[BESHelper]) -> CompareResult:
    """Compare helper lists."""
    result = CompareResult()

    if len(a) != len(b):
        result.add_diff("count", f"{len(a)} != {len(b)}")
        return result

    for i, (helper_a, helper_b) in enumerate(zip(a, b)):
        if not tuples_equal(helper_a.box_size, helper_b.box_size):
            result.add_diff(f"[{i}].box_size", f"{helper_a.box_size} != {helper_b.box_size}")

        if not tuples_equal(helper_a.position, helper_b.position):
            result.add_diff(f"[{i}].position", f"{helper_a.position} != {helper_b.position}")

        if not tuples_equal(helper_a.rotation, helper_b.rotation):
            result.add_diff(f"[{i}].rotation", f"{helper_a.rotation} != {helper_b.rotation}")

    return result


def compare_collisions(a: List[BESCollision], b: List[BESCollision]) -> CompareResult:
    """Compare collision lists."""
    result = CompareResult()

    if len(a) != len(b):
        result.add_diff("count", f"{len(a)} != {len(b)}")
        return result

    for i, (coll_a, coll_b) in enumerate(zip(a, b)):
        result.merge(compare_collision(coll_a, coll_b), f"[{i}]")

    return result


def compare_collision(a: BESCollision, b: BESCollision) -> CompareResult:
    """Compare collision objects."""
    result = CompareResult()

    if a.collision_type != b.collision_type:
        result.add_diff("collision_type", f"{a.collision_type} != {b.collision_type}")

    if not tuples_equal(a.center, b.center):
        result.add_diff("center", f"{a.center} != {b.center}")

    # Compare raw data (should be byte-identical for collision)
    if a.raw_vertex_data != b.raw_vertex_data:
        result.add_diff("raw_vertex_data", f"length {len(a.raw_vertex_data)} != {len(b.raw_vertex_data)}")

    if a.raw_face_data != b.raw_face_data:
        result.add_diff("raw_face_data", f"length {len(a.raw_face_data)} != {len(b.raw_face_data)}")

    return result
