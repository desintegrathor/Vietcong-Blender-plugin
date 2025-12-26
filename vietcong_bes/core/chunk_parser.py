# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Chunk Parser

Parses BES chunk structure recursively, building scene hierarchy.

Based on: old_Blender_plugin/import_bes.py and docs/old_documentation.md
"""

import re
from typing import Optional, List, Union
from ..utils.binary_utils import BinaryReader
from .constants import (
    ChunkType,
    D3DFVF,
    VERTEX_BASE_SIZE,
    VERTEX_UV_SIZE,
    NO_MATERIAL,
    StdMatTexFlag,
    PteroMatTexFlag,
    TransparencyType,
    STANDARD_UV_ORDER,
    PTEROMAT_UV_ORDER,
    NodeType,
)
from .bes_types import (
    BESFile,
    BESChunk,
    BESNode,
    BESMesh,
    BESVertex,
    BESBoneVertex,
    BESFace,
    BESTransform,
    BESWobble,
    BESProperties,
    BESInfo,
    BESMaterial,
    BESStandardMaterial,
    BESPteroMat,
    BESPteroLayer,
    BESTextureLayer,
    BESTexture,
    BESSkeleton,
    BESBonePart,
    BESLight,
    BESHelper,
    BESCollision,
    calculate_name_hash,
)


class ChunkParser:
    """Parser for BES chunk structure."""

    def __init__(self, reader: BinaryReader, bes_file: BESFile):
        """Initialize parser.

        Args:
            reader: Binary reader positioned after header and preview
            bes_file: BESFile to populate with parsed data
        """
        self._reader = reader
        self._bes_file = bes_file
        self._material_count = 0
        self._current_material_index = 0
        # Skeletal model state
        self._current_bone_name: Optional[str] = None
        self._skeleton: Optional[BESSkeleton] = None
        # Version-specific handling
        # BES v0005 is used for skeletal character models
        # All BES versions use chunk sizes that INCLUDE the 8-byte header
        self._is_v0005 = bes_file.is_skeletal

    def _is_bone_part_name(self, name: str) -> bool:
        """Check if name matches bone part format: {LOD}{DAMAGE}_{BODYPART}.

        Bone part names follow the pattern:
        - LOD: 0, 1, or 2 (detail level)
        - DAMAGE: A, B, or C (damage state)
        - BODYPART: head, bodyback, leftarm, etc.

        Examples: 0A_head, 2C_leftarm00, 1B_bodyfront

        Args:
            name: Node name to check

        Returns:
            True if name matches bone part format
        """
        # Pattern: 0A_head, 2C_leftarm00, etc.
        return bool(re.match(r'^[0-2][ABC]_\w+', name))

    def parse(self):
        """Parse all chunks in the file."""
        while self._reader.remaining > 0:
            chunk_start = self._reader.position
            chunk_type, chunk_size = self._reader.read_chunk_header()

            if chunk_type == ChunkType.INFO:
                self._parse_info(chunk_size)
            elif chunk_type == ChunkType.OBJECT:
                self._bes_file.root_node = self._parse_object(chunk_size, depth=0)
            elif chunk_type == ChunkType.MATERIAL_LIST:
                self._parse_material_list(chunk_size)
            elif chunk_type == ChunkType.ISKE:
                # ISKE skeletal node (v0006+)
                node = self._parse_iske(chunk_size)
                if self._bes_file.root_node is None:
                    self._bes_file.root_node = node
                else:
                    node.parent = self._bes_file.root_node
                    self._bes_file.root_node.children.append(node)
            else:
                # Skip unknown top-level chunk
                self._reader.skip(chunk_size)

    def _parse_info(self, size: int):
        """Parse info block (chunk 0x70)."""
        start = self._reader.position

        author_len = self._reader.read_uint32()
        comment_len = self._reader.read_uint32()
        total_faces = self._reader.read_uint32()

        # Author is fixed 64 bytes, zero-padded
        author = self._reader.read_string(64)

        # Comment is variable length
        comment = ''
        if comment_len > 0:
            comment = self._reader.read_string(comment_len)

        self._bes_file.info = BESInfo(
            author=author,
            comment=comment,
            total_faces=total_faces,
            has_comment=comment_len > 0,
        )

        # Ensure we've read the full chunk
        self._reader.seek(start + size)

    def _parse_object(self, size: int, depth: int = 0) -> BESNode:
        """Parse object/node chunk (chunk 0x01).

        Args:
            size: Chunk data size (already adjusted for v0005 root)
            depth: Nesting depth (0 = root, used for v0005 size calculations)

        Returns:
            Parsed BESNode
        """
        start = self._reader.position
        end = start + size

        # Read node header
        child_count = self._reader.read_uint32()
        name_len = self._reader.read_uint32()
        name = self._reader.read_string(name_len)

        node = BESNode(
            name=name,
            name_hash=calculate_name_hash(name),
        )

        # Parse child chunks
        # Note: All BES versions (including v0005) use chunk sizes that INCLUDE
        # the 8-byte header. read_chunk_header() handles this by subtracting 8.
        while self._reader.position < end:
            chunk_type, chunk_size = self._reader.read_chunk_header()
            chunk_data_start = self._reader.position

            if chunk_type == ChunkType.OBJECT:
                child = self._parse_object(chunk_size, depth + 1)
                child.parent = node
                node.children.append(child)
            elif chunk_type == ChunkType.ISKE:
                # Child ISKE skeletal node (v0006+)
                child = self._parse_iske(chunk_size)
                child.parent = node
                node.children.append(child)
            elif chunk_type == ChunkType.MODEL:
                # Check if this MODEL belongs to a bone part
                if self._current_bone_name is not None:
                    bone_node = BESNode(
                        name=self._current_bone_name,
                        name_hash=calculate_name_hash(self._current_bone_name),
                    )
                    self._parse_model(bone_node, chunk_size)
                    # Create bone part from parsed node
                    bone_part = BESBonePart.parse_name(self._current_bone_name)
                    bone_part.meshes = bone_node.meshes
                    bone_part.transform = bone_node.transform
                    if self._skeleton is not None:
                        self._skeleton.add_bone_part(bone_part)
                    # Clear current bone name
                    self._current_bone_name = None
                else:
                    self._parse_model(node, chunk_size)
            elif chunk_type == ChunkType.SKELETON_MARKER:
                # Skeleton marker - creates skeleton object
                skeleton_name = self._reader.read_string(chunk_size)
                self._skeleton = BESSkeleton(name=skeleton_name)
                self._bes_file.skeleton = self._skeleton
                self._bes_file.is_skeletal = True
            elif chunk_type == ChunkType.BONE_NAME:
                # Bone name - next MODEL chunk belongs to this bone
                self._current_bone_name = self._reader.read_string(chunk_size)
            elif chunk_type == ChunkType.PROPERTIES:
                node.properties = self._parse_properties(chunk_size)
            elif chunk_type == ChunkType.TRANSFORM:
                node.transform = self._parse_transform(chunk_size)
            elif chunk_type == ChunkType.BBOX:
                node.bbox = self._reader.read_vec3()
            elif chunk_type == ChunkType.MATERIAL_LIST:
                self._parse_material_list(chunk_size)
            elif chunk_type == ChunkType.STANDARD_MATERIAL:
                mat = self._parse_standard_material(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.PTEROMAT:
                mat = self._parse_pteromat(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.PTEROLAYER:
                mat = self._parse_pterolayer(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.LIGHT:
                # Light block (0x20)
                light = self._parse_light(chunk_size)
                light.name = node.name
                node.light = light
                self._bes_file.lights.append(light)
            elif chunk_type == ChunkType.HELPER:
                # Helper/Dummy block (0x40)
                helper = self._parse_helper(chunk_size)
                helper.name = node.name
                node.helper = helper
                self._bes_file.helpers.append(helper)
            elif chunk_type == ChunkType.COLLISION:
                # Collision block (0x82)
                collision = self._parse_collision(chunk_size)
                collision.name = node.name
                node.collision = collision
                self._bes_file.collisions.append(collision)
            else:
                # Skip unknown chunk
                pass

            # Ensure we're at the end of this chunk
            self._reader.seek(chunk_data_start + chunk_size)

        return node

    def _parse_iske(self, size: int) -> BESNode:
        """Parse ISKE skeletal node (chunk 0x50).

        ISKE shares structure with OBJECT but marks skeletal mesh.
        Used in BES versions 0006+ instead of SKELETON_MARKER (0x67).

        Args:
            size: Chunk data size

        Returns:
            Parsed BESNode with node_type=ISKE
        """
        start = self._reader.position
        end = start + size

        # Read node header (same as OBJECT)
        child_count = self._reader.read_uint32()
        name_len = self._reader.read_uint32()
        name = self._reader.read_string(name_len)

        node = BESNode(
            name=name,
            name_hash=calculate_name_hash(name),
            node_type=NodeType.ISKE,  # Mark as skeletal
        )

        # Create skeleton if this is first ISKE
        if self._bes_file.skeleton is None:
            self._skeleton = BESSkeleton(name=name)
            self._bes_file.skeleton = self._skeleton
            self._bes_file.is_skeletal = True

        # Parse child chunks (same structure as OBJECT)
        while self._reader.position < end:
            chunk_type, chunk_size = self._reader.read_chunk_header()
            chunk_data_start = self._reader.position

            if chunk_type == ChunkType.ISKE:
                # Nested ISKE
                child = self._parse_iske(chunk_size)
                child.parent = node
                node.children.append(child)
            elif chunk_type == ChunkType.OBJECT:
                child = self._parse_object(chunk_size, depth=1)
                child.parent = node
                node.children.append(child)

                # V0005 skeletal models: OBJECT children inside ISKE are bone parts
                # Convert them to BESBonePart if they have meshes and bone part name
                if child.meshes and self._skeleton is not None:
                    if self._is_bone_part_name(child.name):
                        bone_part = BESBonePart.parse_name(child.name)
                        bone_part.meshes = child.meshes
                        bone_part.transform = child.transform
                        self._skeleton.add_bone_part(bone_part)
            elif chunk_type == ChunkType.SKELETON_MARKER:
                # Skeleton marker inside ISKE - update skeleton name
                skeleton_name = self._reader.read_string(chunk_size)
                if self._skeleton is not None:
                    self._skeleton.name = skeleton_name
            elif chunk_type == ChunkType.MODEL:
                self._parse_model(node, chunk_size)
            elif chunk_type == ChunkType.ISKE_MESH:
                # ISKE-specific mesh chunk
                self._parse_iske_mesh(node, chunk_size)
            elif chunk_type == ChunkType.PROPERTIES:
                node.properties = self._parse_properties(chunk_size)
            elif chunk_type == ChunkType.TRANSFORM:
                node.transform = self._parse_transform(chunk_size)
            elif chunk_type == ChunkType.BBOX:
                node.bbox = self._reader.read_vec3()
            elif chunk_type == ChunkType.MATERIAL_LIST:
                self._parse_material_list(chunk_size)
            elif chunk_type == ChunkType.STANDARD_MATERIAL:
                mat = self._parse_standard_material(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.PTEROMAT:
                mat = self._parse_pteromat(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.PTEROLAYER:
                mat = self._parse_pterolayer(chunk_size)
                self._bes_file.materials.append(mat)
            else:
                # Skip unknown chunk
                pass

            self._reader.seek(chunk_data_start + chunk_size)

        return node

    def _parse_iske_mesh(self, node: BESNode, size: int):
        """Parse ISKE mesh chunk (chunk 0x51).

        ISKE_MESH contains skeleton hierarchy data, not mesh sub-chunks.
        Structure:
        - mesh_count (uint32)
        - skeleton_filename_len (uint32)
        - skeleton_filename (null-terminated string)
        - bone hierarchy data (bone names, transforms, indices, etc.)

        For roundtrip preservation, we store the raw chunk data.

        Args:
            node: Node to add mesh data to
            size: Chunk data size
        """
        start = self._reader.position

        # Read the entire chunk data for roundtrip preservation
        raw_data = self._reader.read(size)

        # Store in skeleton if available
        if self._skeleton is not None:
            self._skeleton.raw_iske_mesh_data = raw_data

        # Parse basic info for debugging (optional)
        # mesh_count is at offset 0
        # skeleton_filename_len is at offset 4
        # skeleton_filename starts at offset 8

    def _parse_model(self, node: BESNode, size: int):
        """Parse model container chunk (chunk 0x30)."""
        start = self._reader.position
        end = start + size

        mesh_count = self._reader.read_uint32()

        while self._reader.position < end:
            chunk_type, chunk_size = self._reader.read_chunk_header()
            chunk_data_start = self._reader.position

            if chunk_type == ChunkType.MESH:
                mesh = self._parse_mesh(chunk_size)
                node.meshes.append(mesh)
            elif chunk_type == ChunkType.PROPERTIES:
                if node.properties is None:
                    node.properties = self._parse_properties(chunk_size)
            elif chunk_type == ChunkType.TRANSFORM:
                if node.transform is None:
                    node.transform = self._parse_transform(chunk_size)
            elif chunk_type == ChunkType.BBOX:
                node.bbox = self._reader.read_vec3()

            self._reader.seek(chunk_data_start + chunk_size)

    def _parse_mesh(self, size: int) -> BESMesh:
        """Parse mesh chunk (chunk 0x31)."""
        start = self._reader.position
        end = start + size

        material_index = self._reader.read_uint32()

        mesh = BESMesh(material_index=material_index)

        while self._reader.position < end:
            chunk_type, chunk_size = self._reader.read_chunk_header()
            chunk_data_start = self._reader.position

            if chunk_type == ChunkType.VERTICES:
                self._parse_vertices(mesh, chunk_size)
            elif chunk_type == ChunkType.FACES:
                self._parse_faces(mesh, chunk_size)

            self._reader.seek(chunk_data_start + chunk_size)

        return mesh

    def _parse_vertices(self, mesh: BESMesh, size: int):
        """Parse vertices chunk (chunk 0x32).

        Supports both standard vertices (24-32 bytes) and skeletal vertices (40-52 bytes).

        Skeletal vertex format is detected by VERTEX_SIZE (more reliable than flags):
        - Standard: Position(12) + Normal(12) + UV(8) = 32 bytes base
        - Skeletal: Position(12) + Weights(4*N) + BoneIndices(4) + Normal(12) + UV(8)
          = 32 + 4*N + 4 bytes = 36 + 4*N bytes
          - Size 40: N=1 weight (flags & 0xE = 8)
          - Size 44: N=2 weights (flags & 0xE = 10)
          - Size 48: N=3 weights (flags & 0xE = 12)
          - Size 52: N=4 weights (flags & 0xE = 14)

        Standard vertex format:
        - Format: Position(12) + Normal(12) + UVs(8*N)
        """
        vertex_count = self._reader.read_uint32()
        vertex_size = self._reader.read_uint32()
        flags = self._reader.read_uint32()

        mesh.flags = flags

        # Detect skeletal vertices by VERTEX SIZE
        # Skeletal: extra bytes = weights(4*N) + bone_indices(4)
        # So: extra_bytes = 4*N + 4, meaning N = (extra_bytes - 4) / 4
        extra_bytes = vertex_size - 32
        if extra_bytes >= 8 and (extra_bytes - 4) % 4 == 0:
            num_weights = (extra_bytes - 4) // 4
            if 1 <= num_weights <= 4:
                # Skeletal vertex format detected
                self._parse_skeletal_vertices(mesh, vertex_count, flags, num_weights)
                return

        # Standard vertex format
        # Calculate texture coordinate count from flags
        tex_count = (flags & D3DFVF.TEXCOUNT_MASK) >> D3DFVF.TEXCOUNT_SHIFT

        # Validate vertex size
        expected_size = VERTEX_BASE_SIZE + (VERTEX_UV_SIZE * tex_count)
        if vertex_size != expected_size:
            # Some files have different sizes, adjust
            tex_count = (vertex_size - VERTEX_BASE_SIZE) // VERTEX_UV_SIZE

        for _ in range(vertex_count):
            # Position (3 floats)
            position = self._reader.read_vec3()

            # Normal (3 floats)
            normal = self._reader.read_vec3()

            # UV coordinates
            uvs = []
            for _ in range(tex_count):
                uv = self._reader.read_vec2()
                uvs.append(uv)

            mesh.vertices.append(BESVertex(
                position=position,
                normal=normal,
                uvs=uvs,
                flags=flags,
            ))

    def _parse_skeletal_vertices(self, mesh: BESMesh, vertex_count: int, flags: int, num_weights: int):
        """Parse skeletal vertices with variable bone weights and bone indices.

        Format (variable size based on num_weights):
        - Position: 3 floats (12 bytes)
        - Weights: N floats (4*N bytes) - bone weights 0.0-1.0
        - BoneIndices: 4 bytes (4 x uint8) - up to 4 bone indices
        - Normal: 3 floats (12 bytes)
        - UV: 2 floats (8 bytes)

        Total: 32 + 4*N + 4 bytes per vertex (40, 44, 48, or 52 bytes)

        The bone indices are stored as 4 uint8 values in the vertex data,
        packed into a single uint32. Each weight corresponds to a bone index
        at the same position.
        """
        for _ in range(vertex_count):
            position = self._reader.read_vec3()

            # Read variable number of bone weights
            weights = [self._reader.read_float() for _ in range(num_weights)]

            # Read bone indices (4 x uint8 packed as 4 bytes)
            bone_indices_raw = self._reader.read(4)
            bone_indices = list(bone_indices_raw)  # Convert to list of ints

            normal = self._reader.read_vec3()
            uv = self._reader.read_vec2()

            mesh.vertices.append(BESBoneVertex(
                position=position,
                weights=weights,
                bone_indices=bone_indices,
                normal=normal,
                uv=uv,
                flags=flags,
            ))

    def _parse_faces(self, mesh: BESMesh, size: int):
        """Parse faces chunk (chunk 0x33)."""
        face_count = self._reader.read_uint32()

        for _ in range(face_count):
            a = self._reader.read_uint32()
            b = self._reader.read_uint32()
            c = self._reader.read_uint32()
            mesh.faces.append(BESFace(a=a, b=b, c=c))

    def _parse_properties(self, size: int) -> BESProperties:
        """Parse properties chunk (chunk 0x34)."""
        str_len = self._reader.read_uint32()
        raw_text = self._reader.read_string(str_len)

        props = BESProperties(raw_text=raw_text)
        props.parse()
        return props

    def _parse_transform(self, size: int) -> BESTransform:
        """Parse transform chunk (chunk 0x35).

        Transform chunk is 100 bytes:
        - translation: 3 floats (12 bytes)
        - rotation: 3 floats (12 bytes) - in radians!
        - scale: 3 floats (12 bytes)
        - matrix: 16 floats (64 bytes) - 4x4 transformation matrix

        Note: For v0005 skeletal models, TRANSFORM chunks contain all zeros
        because vertices are already stored in world space. The transform
        data is placeholder only.
        """
        # Standard transform (100 bytes expected)
        translation = self._reader.read_vec3()
        rotation = self._reader.read_vec3()  # Radians!
        scale = self._reader.read_vec3()

        # Read 4x4 matrix (64 bytes)
        matrix = self._reader.read_matrix4x4()

        return BESTransform(
            translation=translation,
            rotation=rotation,
            scale=scale,
            matrix=matrix,
        )

    def _parse_material_list(self, size: int):
        """Parse material list chunk (chunk 0x1000).

        The material list chunk contains:
        - material_count (uint32)
        - Nested material chunks (0x1001 Standard or 0x1002 PteroMat)
        """
        start = self._reader.position
        end = start + size

        self._material_count = self._reader.read_uint32()
        self._current_material_index = 0

        # Parse nested material chunks
        while self._reader.position < end:
            chunk_type, chunk_size = self._reader.read_chunk_header()
            chunk_data_start = self._reader.position

            if chunk_type == ChunkType.STANDARD_MATERIAL:
                mat = self._parse_standard_material(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.PTEROMAT:
                mat = self._parse_pteromat(chunk_size)
                self._bes_file.materials.append(mat)
            elif chunk_type == ChunkType.PTEROLAYER:
                mat = self._parse_pterolayer(chunk_size)
                self._bes_file.materials.append(mat)
            else:
                # Skip unknown material type
                pass

            self._reader.seek(chunk_data_start + chunk_size)

    def _parse_standard_material(self, size: int) -> BESStandardMaterial:
        """Parse standard material (chunk 0x1001)."""
        start = self._reader.position

        material_id = self._reader.read_float()
        unknown_field = self._reader.read(4)  # 4 bytes - may be surface code like "g_de"
        map_flags = self._reader.read_uint32()

        mat = BESStandardMaterial(
            name=f"Material_{self._current_material_index}",
            index=self._current_material_index,
            material_id=material_id,
            unknown_field=unknown_field,
            map_flags=map_flags,
        )

        # Parse texture maps (ordered by flag value)
        for flag in [0x001, 0x002, 0x004, 0x008, 0x010, 0x020, 0x040, 0x080, 0x200, 0x400, 0x800]:
            if map_flags & flag:
                name_len = self._reader.read_uint32()
                coord_flags = self._reader.read_uint32()
                filename = self._reader.read_string(name_len)

                tex = BESTexture(
                    filename=filename,
                    u_tile=bool(coord_flags & 0x01),
                    v_tile=bool(coord_flags & 0x02),
                    u_mirror=bool(coord_flags & 0x04),
                    v_mirror=bool(coord_flags & 0x08),
                    flags=coord_flags,
                )

                # Map flag to slot name (verified from IDA analysis)
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
                mat.textures[slot_names.get(flag, f'map_{flag}')] = tex

        self._current_material_index += 1
        return mat

    def _parse_pteromat(self, size: int) -> BESPteroMat:
        """Parse PteroMat material (chunk 0x1002).

        Structure discovered from IDA analysis of BesExport.dlu:
        - Offset 0: Flags (bit 0=twoSided, bit 2=faceted)
        - Offset 4: Texture type bitfield
        - Offset 8: Collision material (2 bytes + 2 zeros)
        - Offset 12: Transparency type
        - Offset 16: Grow type (1 byte) + Grass type (1 byte) + 2 zeros
        - Offset 20: Name length
        - Offset 24: Material name
        - Then: Texture map data
        """
        start = self._reader.position

        # Flags field: bit 0 = two_sided, bit 1 = faceted
        # NOTE: PteroMat uses bit 1 (0x02), PteroLayer uses bit 2 (0x04)
        # From IDA analysis of DumpPteroMat (sub_8BE7BC0) in BesExport.dle
        flags = self._reader.read_uint32()
        two_sided = bool(flags & 0x01)
        faceted = bool(flags & 0x02)  # PteroMat: bit 1

        texture_flags = self._reader.read_uint32()

        # Collision material (2 chars + 2 zeros)
        collision_data = self._reader.read(4)
        collision_material = collision_data[:2].decode('latin-1').rstrip('\x00')

        transparency_type = self._reader.read_uint32()

        # Vegetation type: grow_type (1 byte) + grass_type (1 byte) + 2 zeros
        veg_data = self._reader.read(4)
        grow_type = chr(veg_data[0]) if veg_data[0] != 0 else ''
        grass_type = chr(veg_data[1]) if veg_data[1] != 0 else ''
        # Legacy vegetation_type for backwards compatibility
        vegetation_type = veg_data[:2].decode('latin-1').rstrip('\x00')

        # Material name
        name_len = self._reader.read_uint32()
        name = self._reader.read_string(name_len)

        mat = BESPteroMat(
            name=name,
            index=self._current_material_index,
            two_sided=two_sided,
            faceted=faceted,
            texture_flags=texture_flags,
            collision_material=collision_material,
            transparency_type=transparency_type,
            vegetation_type=vegetation_type,
            grow_type=grow_type,
            grass_type=grass_type,
        )

        # Parse texture maps
        # PteroMat textures include their type in the coordinates field
        remaining = size - (self._reader.position - start)
        while remaining > 8:
            coord_config = self._reader.read_uint32()
            tex_name_len = self._reader.read_uint32()
            tex_filename = self._reader.read_string(tex_name_len)

            # Upper 2 bytes: map type flag
            map_type = (coord_config >> 16) & 0xFFFF
            # Lower 2 bytes: tiling flags
            tile_flags = coord_config & 0xFFFF

            tex = BESTexture(
                filename=tex_filename,
                u_tile=bool(tile_flags & 0x01),
                v_tile=bool(tile_flags & 0x02),
                flags=coord_config,
            )

            # Map type to slot name
            slot_names = {
                0x01: 'diffuse_1',
                0x02: 'diffuse_2',
                0x04: 'diffuse_3',
                0x08: 'lightmap',
                0x10: 'environment_1',
                0x20: 'environment_2',
                0x40: 'lightmap_engine',
                0x80: 'overlay_multi',
            }
            mat.textures[slot_names.get(map_type, f'map_{map_type}')] = tex

            remaining = size - (self._reader.position - start)

        self._current_material_index += 1
        return mat

    def _parse_pterolayer(self, size: int) -> BESPteroLayer:
        """Parse PteroLayer material (chunk 0x1004).

        PteroLayer is an advanced material type with up to 13 texture layers.
        Each layer has individual properties for tiling, animation, etc.

        Based on IDA analysis of DumpPteroLayer function in BesExport.dlu.
        """
        start = self._reader.position

        # Material properties header (similar to PteroMat but extended)
        # The exact binary format needs verification from actual files
        # For now, we parse what we know from IDA analysis

        # Flags field: bit 0 = two_sided, bit 2 = faceted
        flags = self._reader.read_uint32()
        two_sided = bool(flags & 0x01)
        faceted = bool(flags & 0x04)

        # Surface (4 chars)
        surface_data = self._reader.read(4)
        surface = surface_data.decode('latin-1').rstrip('\x00')

        # Grass type and grow type (1 byte each + 2 zeros)
        veg_data = self._reader.read(4)
        grass_type = chr(veg_data[0]) if veg_data[0] != 0 else ''
        grow_type = chr(veg_data[1]) if veg_data[1] != 0 else ''

        # Shader type string length + string
        shader_type_len = self._reader.read_uint32()
        shader_type = ''
        if shader_type_len > 0:
            shader_type = self._reader.read_string(shader_type_len)

        # Shader filename length + string
        shader_filename_len = self._reader.read_uint32()
        shader_filename = ''
        if shader_filename_len > 0:
            shader_filename = self._reader.read_string(shader_filename_len)

        # Transparency type
        transparency_type = self._reader.read_uint32()

        # Material colors (RGB floats)
        mat_diffuse = self._reader.read_vec3()
        mat_ambient = self._reader.read_vec3()
        mat_specular = self._reader.read_vec3()
        mat_self_illum = self._reader.read_vec3()

        # Material properties
        mat_opacity = self._reader.read_uint32()
        mat_opacity_falloff = self._reader.read_float()
        mat_glossiness = self._reader.read_uint32()
        mat_spec_level = self._reader.read_uint32()

        # Glass/water flags
        is_glass = bool(self._reader.read_uint32())
        is_water = bool(self._reader.read_uint32())

        # Water properties (if water)
        water_env_blend = self._reader.read_float()
        water_alpha_angle = self._reader.read_float()
        water_sharpness = self._reader.read_vec3()
        water_shifting_xy = self._reader.read_vec2()
        water_shifting_uv = self._reader.read_vec2()

        # Material name
        name_len = self._reader.read_uint32()
        name = self._reader.read_string(name_len)

        mat = BESPteroLayer(
            name=name,
            index=self._current_material_index,
            surface=surface,
            grass_type=grass_type,
            grow_type=grow_type,
            shader_type=shader_type,
            shader_filename=shader_filename,
            transparency_type=transparency_type,
            two_sided=two_sided,
            faceted=faceted,
            mat_diffuse=mat_diffuse,
            mat_ambient=mat_ambient,
            mat_specular=mat_specular,
            mat_self_illum=mat_self_illum,
            mat_opacity=mat_opacity,
            mat_opacity_falloff=mat_opacity_falloff,
            mat_glossiness=mat_glossiness,
            mat_spec_level=mat_spec_level,
            is_glass=is_glass,
            is_water=is_water,
            water_env_blend=water_env_blend,
            water_alpha_angle=water_alpha_angle,
            water_sharpness=water_sharpness,
            water_shifting_xy=water_shifting_xy,
            water_shifting_uv=water_shifting_uv,
        )

        # Parse texture layers (up to 13)
        layer_count = self._reader.read_uint32()
        for _ in range(min(layer_count, 13)):
            layer = self._parse_texture_layer()
            mat.layers.append(layer)

        self._current_material_index += 1
        return mat

    def _parse_texture_layer(self) -> BESTextureLayer:
        """Parse single texture layer for PteroLayer material."""
        # Layer properties
        mipmap = bool(self._reader.read_uint32())
        tile_u = bool(self._reader.read_uint32())
        tile_v = bool(self._reader.read_uint32())
        tiling_u = self._reader.read_float()
        tiling_v = self._reader.read_float()

        # Crop rectangle
        crop_x = self._reader.read_float()
        crop_y = self._reader.read_float()
        crop_w = self._reader.read_float()
        crop_h = self._reader.read_float()

        # Clip UV
        clip_u = self._reader.read_float()
        clip_v = self._reader.read_float()
        clip_w = self._reader.read_float()
        clip_h = self._reader.read_float()

        # Animation
        move_x = self._reader.read_float()
        move_y = self._reader.read_float()
        move_type = self._reader.read_uint32()
        move_soft = bool(self._reader.read_uint32())
        moving = bool(self._reader.read_uint32())

        # UV channel
        uv_channel = self._reader.read_uint32()

        # Special flags
        overlay_multitexture = bool(self._reader.read_uint32())
        lm_apply_light = bool(self._reader.read_uint32())
        env_type = self._reader.read_uint32()

        # Texture filename
        filename_len = self._reader.read_uint32()
        filename = ''
        if filename_len > 0:
            filename = self._reader.read_string(filename_len)

        return BESTextureLayer(
            filename=filename,
            mipmap=mipmap,
            tile_u=tile_u,
            tile_v=tile_v,
            tiling_u=tiling_u,
            tiling_v=tiling_v,
            crop=(crop_x, crop_y, crop_w, crop_h),
            clip_uv=(clip_u, clip_v),
            clip_wh=(clip_w, clip_h),
            move=(move_x, move_y),
            move_type=move_type,
            move_soft=move_soft,
            moving=moving,
            uv_channel=uv_channel,
            overlay_multitexture=overlay_multitexture,
            lm_apply_light=lm_apply_light,
            env_type=env_type,
        )

    def _parse_light(self, size: int) -> BESLight:
        """Parse light block (chunk 0x20, 112 bytes).

        Structure from IDA analysis of sub_897AF00:
        - light_type: 1=Omni, 2=Dir, 3=Spot, 4=Area
        - color: RGB (3 floats)
        - intensity: light multiplier
        - hotspot/falloff: cone angles for spot lights
        - far_atten: far attenuation distance
        - matrix: 4x3 transform (12 floats)
        """
        light_type = self._reader.read_uint32()

        # Color RGB
        color_r = self._reader.read_float()
        color_g = self._reader.read_float()
        color_b = self._reader.read_float()

        # Intensity
        intensity = self._reader.read_float()

        # Spot light angles
        hotspot = self._reader.read_float()
        falloff = self._reader.read_float()

        # Far attenuation
        far_atten = self._reader.read_float()

        # 4x3 transform matrix (12 floats)
        matrix = []
        for _ in range(12):
            matrix.append(self._reader.read_float())

        return BESLight(
            light_type=light_type,
            color=(color_r, color_g, color_b),
            intensity=intensity,
            hotspot=hotspot,
            falloff=falloff,
            far_atten=far_atten,
            matrix=matrix,
        )

    def _parse_helper(self, size: int) -> BESHelper:
        """Parse helper/dummy block (chunk 0x40, 36 bytes).

        Structure from IDA analysis of sub_897A620:
        - box_size: helper box dimensions (3 floats)
        - position: world position (3 floats)
        - rotation: euler angles (3 floats)
        """
        # Box size (dimensions of the helper visualization)
        box_x = self._reader.read_float()
        box_y = self._reader.read_float()
        box_z = self._reader.read_float()

        # Position
        pos_x = self._reader.read_float()
        pos_y = self._reader.read_float()
        pos_z = self._reader.read_float()

        # Rotation (euler angles)
        rot_x = self._reader.read_float()
        rot_y = self._reader.read_float()
        rot_z = self._reader.read_float()

        return BESHelper(
            box_size=(box_x, box_y, box_z),
            position=(pos_x, pos_y, pos_z),
            rotation=(rot_x, rot_y, rot_z),
        )

    def _parse_collision(self, size: int) -> BESCollision:
        """Parse collision block (chunk 0x82).

        Structure from IDA analysis of ExportCollision (sub_897D2D0):
        - Offset 0: collision_type (always 2)
        - Offset 4: vertex_data_size (bytes)
        - Offset 8: face_data_size (bytes)
        - Offset 12: bone_data_size (bytes, 0 if no bones)
        - Offset 16-27: center point (3 floats)
        - Offset 28+: vertex_data, face_data, bone_data, trailing padding

        The block_size is calculated as: vertex_size + face_size + bone_size + 39
        where 39 bytes is the header excluding block_type and block_size fields.
        """
        import struct

        start_pos = self._reader.position

        # Read collision header
        collision_type = self._reader.read_uint32()
        vertex_data_size = self._reader.read_uint32()
        face_data_size = self._reader.read_uint32()
        bone_data_size = self._reader.read_uint32()

        # Center point of collision mesh
        center_x = self._reader.read_float()
        center_y = self._reader.read_float()
        center_z = self._reader.read_float()

        # Read raw data blocks
        raw_vertex_data = b''
        if vertex_data_size > 0:
            raw_vertex_data = self._reader.read(vertex_data_size)

        raw_face_data = b''
        if face_data_size > 0:
            raw_face_data = self._reader.read(face_data_size)

        raw_bone_data = None
        if bone_data_size > 0:
            raw_bone_data = self._reader.read(bone_data_size)

        # Read any trailing bytes (padding)
        bytes_read = self._reader.position - start_pos
        raw_trailing = b''
        if bytes_read < size:
            raw_trailing = self._reader.read(size - bytes_read)

        # Parse vertex data (each vertex is 3 floats = 12 bytes)
        vertices = []
        if len(raw_vertex_data) >= 12:
            for i in range(0, len(raw_vertex_data) - 11, 12):
                x, y, z = struct.unpack('<fff', raw_vertex_data[i:i+12])
                vertices.append((x, y, z))

        # Parse face data
        # Face format varies - for now store raw data and parse faces as triplets of u32
        faces = []
        face_materials = []
        if len(raw_face_data) >= 12:
            # Simple triangle format: 3 x u32 indices per face
            for i in range(0, len(raw_face_data) - 11, 12):
                a, b, c = struct.unpack('<III', raw_face_data[i:i+12])
                faces.append((a, b, c))

        return BESCollision(
            collision_type=collision_type,
            center=(center_x, center_y, center_z),
            vertices=vertices,
            faces=faces,
            face_materials=face_materials,
            raw_vertex_data=raw_vertex_data,
            raw_face_data=raw_face_data,
            raw_bone_data=raw_bone_data,
            raw_trailing=raw_trailing,
        )
