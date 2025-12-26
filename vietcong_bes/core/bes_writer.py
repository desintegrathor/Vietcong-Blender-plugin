# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES File Writer

High-level writer for BES files that handles header, preview, and chunk writing.
"""

from typing import Optional, List
from ..utils.binary_utils import BinaryWriter, ChunkBuilder
from .constants import (
    BES_MAGIC,
    BES_VERSION_8,
    EXPORTER_BLENDER,
    PREVIEW_SIZE,
    ChunkType,
    D3DFVF,
    VERTEX_BASE_SIZE,
    VERTEX_UV_SIZE,
    TransparencyType,
)
from .bes_types import (
    BESFile,
    BESHeader,
    BESPreview,
    BESNode,
    BESMesh,
    BESInfo,
    BESMaterial,
    BESStandardMaterial,
    BESPteroMat,
    BESPteroLayer,
    BESTextureLayer,
    BESCollision,
    BESSkeleton,
)


class BESWriter:
    """High-level BES file writer."""

    def __init__(self, filepath: str):
        """Initialize writer.

        Args:
            filepath: Output file path
        """
        self.filepath = filepath
        self._writer: Optional[BinaryWriter] = None

    def __enter__(self):
        self._writer = BinaryWriter(self.filepath)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self._writer:
            self._writer.close()
        return False

    def write(self, bes_file: BESFile):
        """Write complete BES file.

        Args:
            bes_file: BESFile structure to write
        """
        if not self._writer:
            raise RuntimeError("Writer not initialized. Use 'with' statement.")

        # Write header
        self._write_header(bes_file.header)

        # Version 0005 and 0004 don't have preview images
        is_v0005 = bes_file.header and bes_file.header.version in ('0005', '0004')
        if not is_v0005:
            # Write preview image (only for versions that have it)
            self._write_preview(bes_file.preview)

        # Write INFO chunk at top-level (before OBJECT)
        # Original BES files have: Header -> Preview -> INFO -> OBJECT
        if bes_file.info:
            self._write_info(bes_file.info)

        # Write materials and scene hierarchy
        if bes_file.root_node:
            self._write_root_node(bes_file)

    def _write_header(self, header: Optional[BESHeader]):
        """Write BES file header."""
        if header:
            self._writer.write(header.signature)
            self._writer.write(header.version.encode('ascii'))
            self._writer.write_uint32(header.exporter)
            self._writer.write_uint32(header.reserved)
        else:
            # Default header
            self._writer.write(BES_MAGIC)
            self._writer.write(BES_VERSION_8)
            self._writer.write_uint32(EXPORTER_BLENDER)
            self._writer.write_uint32(0)

    def _write_preview(self, preview: Optional[BESPreview]):
        """Write preview image."""
        if preview and preview.pixels:
            self._writer.write(preview.pixels[:PREVIEW_SIZE])
            # Pad if needed
            if len(preview.pixels) < PREVIEW_SIZE:
                self._writer.write_zeros(PREVIEW_SIZE - len(preview.pixels))
        else:
            # Write empty preview
            self._writer.write_zeros(PREVIEW_SIZE)

    def _write_info(self, info: BESInfo):
        """Write info block (chunk 0x70)."""
        builder = ChunkBuilder(ChunkType.INFO)
        w = builder.writer

        author_bytes = info.author.encode('latin-1')[:63]
        comment_bytes = info.comment.encode('latin-1') if info.comment else b''

        w.write_uint32(len(author_bytes) + 1)

        # Determine comment_len:
        # - has_comment=True: write len+1 (even if comment is empty, for null terminator)
        # - has_comment=False with content: write len+1
        # - has_comment=False without content: write 0
        if info.has_comment or comment_bytes:
            w.write_uint32(len(comment_bytes) + 1)
        else:
            w.write_uint32(0)

        w.write_uint32(info.total_faces)

        # Write author (64 bytes, zero-padded)
        w.write(author_bytes)
        w.write_zeros(64 - len(author_bytes))

        # Write comment if has_comment or has content
        if info.has_comment or comment_bytes:
            w.write(comment_bytes)
            w.write_uint8(0)
        # No bytes written if no comment at all

        self._writer.write(builder.build())

    def _write_root_node(self, bes_file: BESFile):
        """Write root node containing materials and scene hierarchy."""
        builder = ChunkBuilder(ChunkType.OBJECT)
        w = builder.writer

        # Node header
        child_count = len(bes_file.root_node.children)
        w.write_uint32(child_count)

        name = bes_file.root_node.name or "Scene Root"
        w.write_uint32(len(name) + 1)
        w.write_cstring(name)

        # Write material list
        if bes_file.materials:
            self._write_material_list_to_builder(w, bes_file.materials)

        # Write child nodes
        for child in bes_file.root_node.children:
            # Check if this is the skeleton container for v0005 format
            is_skeleton_node = (
                bes_file.is_skeletal and
                bes_file.skeleton and
                child.name == bes_file.skeleton.name
            )
            if is_skeleton_node:
                # Write as ISKE chunk (0x0050) for skeletal models
                self._write_iske_to_builder(w, child, bes_file.skeleton)
            else:
                self._write_node_to_builder(w, child)

        self._writer.write(builder.build())

    def _write_iske_to_builder(self, w: BinaryWriter, node: BESNode,
                                skeleton: Optional[BESSkeleton] = None):
        """Write ISKE skeletal node (chunk 0x0050).

        ISKE is used for skeleton containers in v0005 format.
        Same structure as OBJECT but uses chunk type 0x0050.
        Also writes ISKE_MESH chunk if raw skeleton data is available.

        Args:
            w: Binary writer to write to
            node: ISKE node containing bone part children
            skeleton: Optional skeleton with raw ISKE_MESH data
        """
        iske_builder = ChunkBuilder(ChunkType.ISKE)
        nw = iske_builder.writer

        # Node header (same as OBJECT)
        nw.write_uint32(len(node.children))
        nw.write_uint32(len(node.name) + 1)
        nw.write_cstring(node.name)

        # Write transform if present
        if node.transform:
            self._write_transform_to_builder(nw, node.transform)

        # Write properties if present
        if node.properties is not None:
            self._write_properties_to_builder(nw, node.properties)

        # Write children as regular OBJECT chunks
        for child in node.children:
            self._write_node_to_builder(nw, child)

        # Write ISKE_MESH chunk if we have raw skeleton data
        if skeleton and skeleton.raw_iske_mesh_data:
            self._write_iske_mesh_to_builder(nw, skeleton.raw_iske_mesh_data)

        w.write(iske_builder.build())

    def _write_iske_mesh_to_builder(self, w: BinaryWriter, raw_data: bytes):
        """Write ISKE_MESH chunk (chunk 0x0051) with raw skeleton data.

        ISKE_MESH contains the skeleton hierarchy data including bone names,
        transforms, and indices. For roundtrip preservation, we write the
        raw data unchanged.

        Args:
            w: Binary writer to write to
            raw_data: Raw ISKE_MESH chunk data (without chunk header)
        """
        iske_mesh_builder = ChunkBuilder(ChunkType.ISKE_MESH)
        iske_mesh_builder.writer.write(raw_data)
        w.write(iske_mesh_builder.build())

    def _write_material_list_to_builder(self, w: BinaryWriter, materials: List[BESMaterial]):
        """Write material list to a builder.

        Material list chunk (0x1000) contains:
        - material_count (uint32)
        - Nested material chunks (0x1001, 0x1002, or 0x1004)

        Materials must be INSIDE the material list chunk, not after it!
        """
        # Use ChunkBuilder to calculate correct size including all materials
        mat_list_builder = ChunkBuilder(ChunkType.MATERIAL_LIST)
        mlw = mat_list_builder.writer

        mlw.write_uint32(len(materials))

        # Write each material INSIDE the material list chunk
        for mat in materials:
            if isinstance(mat, BESPteroLayer):
                self._write_pterolayer_to_builder(mlw, mat)
            elif isinstance(mat, BESPteroMat):
                self._write_pteromat_to_builder(mlw, mat)
            elif isinstance(mat, BESStandardMaterial):
                self._write_standard_material_to_builder(mlw, mat)

        w.write(mat_list_builder.build())

    def _write_pteromat_to_builder(self, w: BinaryWriter, mat: BESPteroMat):
        """Write PteroMat material.

        Structure from IDA analysis of BesExport.dlu:
        - Offset 0: Flags (bit 0=twoSided, bit 2=faceted)
        - Offset 4: Texture type bitfield
        - Offset 8: Collision material (2 bytes + 2 zeros)
        - Offset 12: Transparency type
        - Offset 16: Grow type (1 byte) + Grass type (1 byte) + 2 zeros
        - Offset 20: Name length
        - Offset 24: Material name
        - Then: Texture map data
        """
        mat_builder = ChunkBuilder(ChunkType.PTEROMAT)
        mw = mat_builder.writer

        # Flags: bit 0 = two_sided, bit 1 = faceted
        # NOTE: PteroMat uses bit 1 (0x02), PteroLayer uses bit 2 (0x04)
        # From IDA analysis of DumpPteroMat (sub_8BE7BC0) in BesExport.dle
        flags = 0
        if mat.two_sided:
            flags |= 0x01
        if mat.faceted:
            flags |= 0x02  # PteroMat: bit 1
        mw.write_uint32(flags)

        mw.write_uint32(mat.texture_flags)

        # Collision material (2 chars + 2 zeros)
        col_mat = (mat.collision_material or '').ljust(2)[:2]
        mw.write(col_mat.encode('latin-1'))
        mw.write_zeros(2)

        mw.write_uint32(mat.transparency_type)

        # Vegetation type: grow_type (1 byte) + grass_type (1 byte) + 2 zeros
        grow = ord(mat.grow_type[0]) if mat.grow_type else 0
        grass = ord(mat.grass_type[0]) if mat.grass_type else 0
        mw.write_uint8(grow)
        mw.write_uint8(grass)
        mw.write_zeros(2)

        # Material name
        mw.write_uint32(len(mat.name) + 1)
        mw.write_cstring(mat.name)

        # Write textures
        for slot_name, tex in mat.textures.items():
            # Use original flags if available (preserves all bits)
            if tex.flags:
                coord_config = tex.flags
            else:
                # Reconstruct from slot and tile flags
                slot_flags = {
                    'diffuse_1': 0x01,
                    'diffuse_2': 0x02,
                    'diffuse_3': 0x04,
                    'lightmap': 0x08,
                    'environment_1': 0x10,
                    'environment_2': 0x20,
                    'lightmap_engine': 0x40,
                    'overlay_multi': 0x80,
                }
                map_type = slot_flags.get(slot_name, 0)

                tile_flags = 0
                if tex.u_tile:
                    tile_flags |= 0x01
                if tex.v_tile:
                    tile_flags |= 0x02

                coord_config = (map_type << 16) | tile_flags

            mw.write_uint32(coord_config)
            mw.write_uint32(len(tex.filename) + 1)
            mw.write_cstring(tex.filename)

        w.write(mat_builder.build())

    def _write_standard_material_to_builder(self, w: BinaryWriter, mat: BESStandardMaterial):
        """Write standard material."""
        mat_builder = ChunkBuilder(ChunkType.STANDARD_MATERIAL)
        mw = mat_builder.writer

        # Flag to slot name mapping (verified from IDA analysis)
        slot_names = {
            0x001: 'diffuse',       # Slot 1
            0x002: 'opacity',       # Slot 11
            0x004: 'bump',          # Slot 8
            0x008: 'ambient',       # Slot 0
            0x010: 'specular',      # Slot 2
            0x020: 'specular_level',# Slot 3
            0x040: 'glossiness',    # Slot 4
            0x080: 'self_illum',    # Slot 5
            0x200: 'displacement',  # Slot 7
            0x400: 'filter',        # Slot 9
            0x800: 'reflection',    # Slot 10
        }

        # Recalculate map_flags to only include flags for textures we actually have
        actual_map_flags = 0
        for flag, slot in slot_names.items():
            if slot in mat.textures:
                actual_map_flags |= flag

        mw.write_float(mat.material_id)
        mw.write(mat.unknown_field if mat.unknown_field else b'\x00\x00\x00\x00')  # 4 bytes
        mw.write_uint32(actual_map_flags)

        # Write textures in flag order (only for flags that are set)
        for flag in [0x001, 0x002, 0x004, 0x008, 0x010, 0x020, 0x040, 0x080, 0x200, 0x400, 0x800]:
            if actual_map_flags & flag:
                slot = slot_names.get(flag)
                if slot and slot in mat.textures:
                    tex = mat.textures[slot]

                    # Use original flags if available (preserves ALPHA and other bits)
                    if tex.flags:
                        coord_flags = tex.flags
                    else:
                        # Fallback: reconstruct from boolean properties
                        coord_flags = 0
                        if tex.u_tile:
                            coord_flags |= 0x01
                        if tex.v_tile:
                            coord_flags |= 0x02
                        if tex.u_mirror:
                            coord_flags |= 0x04
                        if tex.v_mirror:
                            coord_flags |= 0x08

                    mw.write_uint32(len(tex.filename) + 1)
                    mw.write_uint32(coord_flags)
                    mw.write_cstring(tex.filename)

        w.write(mat_builder.build())

    def _write_pterolayer_to_builder(self, w: BinaryWriter, mat: BESPteroLayer):
        """Write PteroLayer material (chunk 0x1004).

        PteroLayer is an advanced material with up to 13 texture layers.
        """
        mat_builder = ChunkBuilder(ChunkType.PTEROLAYER)
        mw = mat_builder.writer

        # Flags: bit 0 = two_sided, bit 2 = faceted
        flags = 0
        if mat.two_sided:
            flags |= 0x01
        if mat.faceted:
            flags |= 0x04
        mw.write_uint32(flags)

        # Surface (4 chars, zero-padded)
        surface = (mat.surface or '').ljust(4)[:4]
        mw.write(surface.encode('latin-1'))

        # Grass type and grow type (1 byte each + 2 zeros)
        grass = ord(mat.grass_type[0]) if mat.grass_type else 0
        grow = ord(mat.grow_type[0]) if mat.grow_type else 0
        mw.write_uint8(grass)
        mw.write_uint8(grow)
        mw.write_zeros(2)

        # Shader type string
        shader_type = mat.shader_type or ''
        mw.write_uint32(len(shader_type) + 1 if shader_type else 0)
        if shader_type:
            mw.write_cstring(shader_type)

        # Shader filename
        shader_filename = mat.shader_filename or ''
        mw.write_uint32(len(shader_filename) + 1 if shader_filename else 0)
        if shader_filename:
            mw.write_cstring(shader_filename)

        # Transparency type
        mw.write_uint32(mat.transparency_type)

        # Material colors (RGB floats)
        mw.write_vec3(mat.mat_diffuse)
        mw.write_vec3(mat.mat_ambient)
        mw.write_vec3(mat.mat_specular)
        mw.write_vec3(mat.mat_self_illum)

        # Material properties
        mw.write_uint32(mat.mat_opacity)
        mw.write_float(mat.mat_opacity_falloff)
        mw.write_uint32(mat.mat_glossiness)
        mw.write_uint32(mat.mat_spec_level)

        # Glass/water flags
        mw.write_uint32(1 if mat.is_glass else 0)
        mw.write_uint32(1 if mat.is_water else 0)

        # Water properties
        mw.write_float(mat.water_env_blend)
        mw.write_float(mat.water_alpha_angle)
        mw.write_vec3(mat.water_sharpness)
        mw.write_vec2(mat.water_shifting_xy)
        mw.write_vec2(mat.water_shifting_uv)

        # Material name
        mw.write_uint32(len(mat.name) + 1)
        mw.write_cstring(mat.name)

        # Texture layers
        mw.write_uint32(len(mat.layers))
        for layer in mat.layers:
            self._write_texture_layer_to_builder(mw, layer)

        w.write(mat_builder.build())

    def _write_texture_layer_to_builder(self, w: BinaryWriter, layer: BESTextureLayer):
        """Write single texture layer for PteroLayer material."""
        # Layer properties
        w.write_uint32(1 if layer.mipmap else 0)
        w.write_uint32(1 if layer.tile_u else 0)
        w.write_uint32(1 if layer.tile_v else 0)
        w.write_float(layer.tiling_u)
        w.write_float(layer.tiling_v)

        # Crop rectangle
        w.write_float(layer.crop[0])
        w.write_float(layer.crop[1])
        w.write_float(layer.crop[2])
        w.write_float(layer.crop[3])

        # Clip UV
        w.write_float(layer.clip_uv[0])
        w.write_float(layer.clip_uv[1])
        w.write_float(layer.clip_wh[0])
        w.write_float(layer.clip_wh[1])

        # Animation
        w.write_float(layer.move[0])
        w.write_float(layer.move[1])
        w.write_uint32(layer.move_type)
        w.write_uint32(1 if layer.move_soft else 0)
        w.write_uint32(1 if layer.moving else 0)

        # UV channel
        w.write_uint32(layer.uv_channel)

        # Special flags
        w.write_uint32(1 if layer.overlay_multitexture else 0)
        w.write_uint32(1 if layer.lm_apply_light else 0)
        w.write_uint32(layer.env_type)

        # Texture filename
        filename = layer.filename or ''
        w.write_uint32(len(filename) + 1 if filename else 0)
        if filename:
            w.write_cstring(filename)

    def _write_node_to_builder(self, w: BinaryWriter, node: BESNode):
        """Write a scene node recursively."""
        node_builder = ChunkBuilder(ChunkType.OBJECT)
        nw = node_builder.writer

        # Node header
        nw.write_uint32(len(node.children))
        nw.write_uint32(len(node.name) + 1)
        nw.write_cstring(node.name)

        # Write meshes as model (MODEL contains TRANSFORM, PROPERTIES, and MESH chunks)
        if node.meshes:
            self._write_model_to_builder(nw, node)

        # Write collision data if present (at OBJECT level, after MODEL)
        if node.collision:
            self._write_collision_to_builder(nw, node.collision)

        # Write properties at OBJECT level ONLY for helper objects (no meshes)
        # For mesh objects, PROPERTIES is written inside MODEL chunk
        if node.properties is not None and not node.meshes:
            self._write_properties_to_builder(nw, node.properties)

        # Write transform at OBJECT level ONLY for helper objects (no meshes)
        # For mesh objects, TRANSFORM is written inside MODEL chunk
        if node.transform and not node.meshes:
            self._write_transform_to_builder(nw, node.transform)

        # Write bounding box ONLY for nodes WITHOUT mesh (helper objects)
        # In original BES files, mesh objects don't have BBOX chunk
        if node.bbox and any(v != 0.0 for v in node.bbox) and not node.meshes:
            nw.write_chunk_header(ChunkType.BBOX, 12 + 8)
            nw.write_vec3(node.bbox)

        # Write children recursively
        for child in node.children:
            self._write_node_to_builder(nw, child)

        w.write(node_builder.build())

    def _write_model_to_builder(self, w: BinaryWriter, node: BESNode):
        """Write model container with meshes.

        Original BES files have TRANSFORM and PROPERTIES INSIDE MODEL chunk,
        in order: mesh_count, TRANSFORM, PROPERTIES, then MESH chunks.
        """
        model_builder = ChunkBuilder(ChunkType.MODEL)
        mw = model_builder.writer

        mw.write_uint32(len(node.meshes))

        # Write TRANSFORM inside MODEL (for mesh objects)
        if node.transform:
            self._write_transform_to_builder(mw, node.transform)

        # Write PROPERTIES inside MODEL (for mesh objects)
        # Note: Write even if raw_text is empty - original files have empty PROPERTIES chunks
        if node.properties is not None:
            self._write_properties_to_builder(mw, node.properties)

        # Write MESH chunks
        for mesh in node.meshes:
            self._write_mesh_to_builder(mw, mesh)

        w.write(model_builder.build())

    def _write_mesh_to_builder(self, w: BinaryWriter, mesh: BESMesh):
        """Write mesh with vertices and faces."""
        mesh_builder = ChunkBuilder(ChunkType.MESH)
        mw = mesh_builder.writer

        mw.write_uint32(mesh.material_index)

        # Write vertices
        if mesh.vertices:
            self._write_vertices_to_builder(mw, mesh)

        # Write faces
        if mesh.faces:
            self._write_faces_to_builder(mw, mesh)

        w.write(mesh_builder.build())

    def _write_vertices_to_builder(self, w: BinaryWriter, mesh: BESMesh):
        """Write vertices chunk."""
        if not mesh.vertices:
            return

        from .bes_types import BESBoneVertex

        first_vert = mesh.vertices[0]

        # Check if this is a skeletal mesh (BESBoneVertex)
        if isinstance(first_vert, BESBoneVertex):
            self._write_bone_vertices_to_builder(w, mesh)
            return

        # Standard vertex format
        tex_count = len(first_vert.uvs)
        vertex_size = VERTEX_BASE_SIZE + (VERTEX_UV_SIZE * tex_count)
        flags = D3DFVF.XYZ | D3DFVF.NORMAL | (tex_count << D3DFVF.TEXCOUNT_SHIFT)

        vert_builder = ChunkBuilder(ChunkType.VERTICES)
        vw = vert_builder.writer

        vw.write_uint32(len(mesh.vertices))
        vw.write_uint32(vertex_size)
        vw.write_uint32(flags)

        for vert in mesh.vertices:
            vw.write_vec3(vert.position)
            vw.write_vec3(vert.normal)
            for uv in vert.uvs:
                vw.write_vec2(uv)

        w.write(vert_builder.build())

    def _write_bone_vertices_to_builder(self, w: BinaryWriter, mesh: BESMesh):
        """Write skeletal vertices chunk (with bone weights and indices).

        Format per vertex:
        - Position: 3 floats (12 bytes)
        - Weights: N floats (4*N bytes) - bone weights 0.0-1.0
        - BoneIndices: 4 bytes (4 x uint8) - bone indices
        - Normal: 3 floats (12 bytes)
        - UV: 2 floats (8 bytes)

        Total: 32 + 4*N + 4 bytes per vertex (40, 44, 48, 52 for 1-4 weights)
        """
        first_vert = mesh.vertices[0]
        num_weights = len(first_vert.weights)
        # vertex_size = base(32) + weights(4*N) + bone_indices(4)
        vertex_size = 32 + (4 * num_weights) + 4
        flags = first_vert.flags  # Use original flags

        vert_builder = ChunkBuilder(ChunkType.VERTICES)
        vw = vert_builder.writer

        vw.write_uint32(len(mesh.vertices))
        vw.write_uint32(vertex_size)
        vw.write_uint32(flags)

        for vert in mesh.vertices:
            vw.write_vec3(vert.position)
            for weight in vert.weights:
                vw.write_float(weight)
            # Write bone indices (4 bytes, padded with zeros if needed)
            bone_indices = vert.bone_indices if vert.bone_indices else [0, 0, 0, 0]
            for i in range(4):
                idx = bone_indices[i] if i < len(bone_indices) else 0
                vw.write(bytes([idx & 0xFF]))
            vw.write_vec3(vert.normal)
            vw.write_vec2(vert.uv)

        w.write(vert_builder.build())

    def _write_faces_to_builder(self, w: BinaryWriter, mesh: BESMesh):
        """Write faces chunk."""
        if not mesh.faces:
            return

        face_builder = ChunkBuilder(ChunkType.FACES)
        fw = face_builder.writer

        fw.write_uint32(len(mesh.faces))
        for face in mesh.faces:
            fw.write_uint32(face.a)
            fw.write_uint32(face.b)
            fw.write_uint32(face.c)

        w.write(face_builder.build())

    def _write_properties_to_builder(self, w: BinaryWriter, props):
        """Write properties chunk."""
        from .bes_types import BESProperties

        text = props.raw_text if isinstance(props, BESProperties) else str(props)

        prop_builder = ChunkBuilder(ChunkType.PROPERTIES)
        pw = prop_builder.writer

        pw.write_uint32(len(text) + 1)
        pw.write_cstring(text)

        w.write(prop_builder.build())

    def _write_transform_to_builder(self, w: BinaryWriter, transform):
        """Write transform chunk (0x35).

        Transform chunk is exactly 100 bytes:
        - translation: 3 floats (12 bytes)
        - rotation: 3 floats (12 bytes) - in radians
        - scale: 3 floats (12 bytes)
        - matrix: 16 floats (64 bytes) - 4x4 transformation matrix

        Note: Wobble animation is stored in User Defined Properties,
        not in the transform chunk.
        """
        trans_builder = ChunkBuilder(ChunkType.TRANSFORM)
        tw = trans_builder.writer

        # Write translation, rotation, scale (36 bytes total)
        tw.write_vec3(transform.translation)
        tw.write_vec3(transform.rotation)
        tw.write_vec3(transform.scale)

        # Write 4x4 matrix (64 bytes)
        if transform.matrix:
            tw.write_matrix4x4(transform.matrix)
        else:
            # Identity matrix
            identity = [
                [1.0, 0.0, 0.0, 0.0],
                [0.0, 1.0, 0.0, 0.0],
                [0.0, 0.0, 1.0, 0.0],
                [0.0, 0.0, 0.0, 1.0],
            ]
            tw.write_matrix4x4(identity)

        w.write(trans_builder.build())

    def _write_collision_to_builder(self, w: BinaryWriter, collision: BESCollision):
        """Write collision chunk (0x82).

        Structure:
        - collision_type (4) - always 2
        - vertex_data_size (4)
        - face_data_size (4)
        - bone_data_size (4)
        - center: 3 floats (12)
        - vertex_data (vertex_data_size bytes)
        - face_data (face_data_size bytes)
        - bone_data (bone_data_size bytes)
        """
        coll_builder = ChunkBuilder(ChunkType.COLLISION)
        cw = coll_builder.writer

        # Get raw data sizes
        vertex_size = len(collision.raw_vertex_data) if collision.raw_vertex_data else 0
        face_size = len(collision.raw_face_data) if collision.raw_face_data else 0
        bone_size = len(collision.raw_bone_data) if collision.raw_bone_data else 0

        # Write header
        cw.write_uint32(collision.collision_type)
        cw.write_uint32(vertex_size)
        cw.write_uint32(face_size)
        cw.write_uint32(bone_size)

        # Write center point
        cw.write_vec3(collision.center)

        # Write raw data blocks
        if collision.raw_vertex_data:
            cw.write(collision.raw_vertex_data)
        if collision.raw_face_data:
            cw.write(collision.raw_face_data)
        if collision.raw_bone_data:
            cw.write(collision.raw_bone_data)

        # Write trailing padding bytes
        if collision.raw_trailing:
            cw.write(collision.raw_trailing)

        w.write(coll_builder.build())


def write_bes_file(filepath: str, bes_file: BESFile):
    """Convenience function to write a BES file.

    Args:
        filepath: Output file path
        bes_file: BESFile structure to write
    """
    with BESWriter(filepath) as writer:
        writer.write(bes_file)
