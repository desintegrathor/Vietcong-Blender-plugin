# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Exporter

Main export function that converts Blender scene to BES format.
"""

import os
import bpy
import base64
import json
from mathutils import Vector
from typing import Dict, List, Optional, Set

from ..core.bes_writer import write_bes_file
from ..core.bes_types import (
    BESFile,
    BESHeader,
    BESPreview,
    BESInfo,
    BESNode,
    BESMesh,
    BESVertex,
    BESBoneVertex,
    BESFace,
    BESTransform,
    BESMaterial,
    BESPteroMat,
    BESTexture,
    BESProperties,
    BESCollision,
    BESSkeleton,
    BESBonePart,
    calculate_name_hash,
)
from ..core.constants import (
    BES_MAGIC,
    BES_VERSION_8,
    EXPORTER_BLENDER,
    TransparencyType,
    NO_MATERIAL,
    COLLISION_PREFIXES,
    SPECIAL_PREFIXES,
)
from ..utils.math_utils import (
    blender_to_bes_uv,
    calculate_bounding_sphere_radius,
)
from ..properties import read_properties_from_object, serialize_user_properties


def export_bes(context, filepath: str, **options) -> set:
    """Export Blender scene to BES file.

    Args:
        context: Blender context
        filepath: Output file path
        **options: Export options
            - export_selected: Export only selected objects
            - generate_preview: Generate preview image

    Returns:
        {'FINISHED'} on success, {'CANCELLED'} on failure
    """
    try:
        exporter = BESExporter(context, filepath, options)
        exporter.export()
        return {'FINISHED'}

    except Exception as e:
        print(f"BES Export Error: {e}")
        import traceback
        traceback.print_exc()
        return {'CANCELLED'}


class BESExporter:
    """Blender to BES exporter."""

    def __init__(self, context, filepath: str, options: dict):
        """Initialize exporter.

        Args:
            context: Blender context
            filepath: Output file path
            options: Export options
        """
        self.context = context
        self.filepath = filepath
        self.options = options

        # Material mapping: Blender material -> BES index
        self._material_indices: Dict[bpy.types.Material, int] = {}
        self._material_indices_by_name: Dict[str, int] = {}  # Fallback for object identity issues
        self._materials: List[BESMaterial] = []

        # Objects to export
        self._objects: List[bpy.types.Object] = []

    def export(self):
        """Export the scene to BES file."""
        # Gather objects to export
        self._gather_objects()

        # Collect and create materials
        self._collect_materials()

        # Build BES file structure
        bes_file = self._build_bes_file()

        # Write to file
        write_bes_file(self.filepath, bes_file)

        print(f"Exported BES file: {self.filepath}")

    def _gather_objects(self):
        """Gather objects to export, preserving original import order."""
        if self.options.get('export_selected', False):
            all_objects = [obj for obj in self.context.selected_objects
                           if obj.type == 'MESH' or obj.type == 'EMPTY']
        else:
            all_objects = [obj for obj in self.context.scene.objects
                           if obj.type == 'MESH' or obj.type == 'EMPTY']

        # Filter to root objects (no parent or parent not in list)
        root_objects = []
        for obj in all_objects:
            if obj.parent is None or obj.parent not in all_objects:
                root_objects.append(obj)

        # Sort by import order if available (preserves original BES order)
        def get_order(obj):
            return obj.get('bes_import_order', float('inf'))

        self._objects = sorted(root_objects, key=get_order)

    def _collect_materials(self):
        """Collect all materials preserving original order.

        If materials have 'bes_index' property (from BES import), we use that
        to reconstruct the original order. This preserves all materials including
        unused ones (like collision materials C---, D---, etc.).

        If no bes_index properties exist, falls back to collecting from mesh objects.
        """
        # First, check if we have imported BES materials with indices
        indexed_materials: Dict[int, bpy.types.Material] = {}
        used_materials: Set[bpy.types.Material] = set()

        # Collect materials from objects (to know which ones are used)
        for obj in self._objects:
            self._collect_materials_recursive(obj, used_materials)

        # Check all materials in the blend file for bes_index
        for mat in bpy.data.materials:
            if 'bes_index' in mat:
                idx = mat['bes_index']
                indexed_materials[idx] = mat

        # If we have indexed materials, use them in order
        if indexed_materials:
            max_index = max(indexed_materials.keys()) + 1

            # Create materials in original index order
            for i in range(max_index):
                if i in indexed_materials:
                    mat = indexed_materials[i]
                    bes_mat = self._create_bes_material(mat)
                    idx = len(self._materials)
                    self._material_indices[mat] = idx
                    self._material_indices_by_name[mat.name] = idx
                    self._materials.append(bes_mat)
        else:
            # Fallback: collect only from used materials (sorted by name for consistency)
            for mat in sorted(used_materials, key=lambda m: m.name):
                bes_mat = self._create_bes_material(mat)
                idx = len(self._materials)
                self._material_indices[mat] = idx
                self._material_indices_by_name[mat.name] = idx
                self._materials.append(bes_mat)

    def _collect_materials_recursive(self, obj: bpy.types.Object, materials_set: Set):
        """Recursively collect materials from object hierarchy."""
        if obj.type == 'MESH' and obj.data:
            for mat in obj.data.materials:
                if mat:
                    materials_set.add(mat)

        for child in obj.children:
            if child in self._objects or child.type == 'MESH':
                self._collect_materials_recursive(child, materials_set)

    def _create_bes_material(self, mat: bpy.types.Material) -> BESMaterial:
        """Create BES material from Blender material.

        Args:
            mat: Blender material

        Returns:
            BES material

        Properties exported from IDA analysis of BesExport.dlu:
        - faceted: Flat shading (from bes_faceted custom property)
        - grow_type, grass_type: Vegetation types
        - Material colors: diffuse, ambient, specular, self-illumination
        - Material properties: opacity, glossiness, spec_level
        - Water properties: env_blend, alpha_angle, sharpness, shifting
        """
        # Check if this was originally a BES material
        mat_type = mat.get('bes_material_type', 'pteromat')

        if mat_type == 'pteromat':
            bes_mat = BESPteroMat(
                name=mat.name,
                index=len(self._materials),
                two_sided=mat.get('bes_two_sided', not mat.use_backface_culling),
                faceted=mat.get('bes_faceted', False),
                collision_material=mat.get('bes_collision_material', ''),
                surface=mat.get('bes_surface', ''),
                transparency_type=mat.get('bes_transparency_type', TransparencyType.OPAQUE),
                grow_type=mat.get('bes_grow_type', ''),
                grass_type=mat.get('bes_grass_type', ''),
            )

            # Material colors from Blender material or custom properties
            if mat.use_nodes:
                # Try to get colors from Principled BSDF node
                base_color = self._get_principled_color(mat, 'Base Color')
                if base_color:
                    bes_mat.mat_diffuse = base_color[:3]

            # Override with custom properties if present
            if 'bes_mat_diffuse' in mat:
                bes_mat.mat_diffuse = tuple(mat['bes_mat_diffuse'])
            if 'bes_mat_ambient' in mat:
                bes_mat.mat_ambient = tuple(mat['bes_mat_ambient'])
            if 'bes_mat_specular' in mat:
                bes_mat.mat_specular = tuple(mat['bes_mat_specular'])
            if 'bes_mat_self_illum' in mat:
                bes_mat.mat_self_illum = tuple(mat['bes_mat_self_illum'])

            # Material properties
            bes_mat.mat_opacity = mat.get('bes_mat_opacity', 100)
            bes_mat.mat_opacity_falloff = mat.get('bes_mat_opacity_falloff', 0.0)
            bes_mat.mat_glossiness = mat.get('bes_mat_glossiness', 0)
            bes_mat.mat_spec_level = mat.get('bes_mat_spec_level', 0)

            # Shader properties
            bes_mat.shader_type_name = mat.get('bes_shader_type_name', '')
            bes_mat.shader_filename = mat.get('bes_shader_filename', '')

            # Water/glass properties
            bes_mat.is_water = mat.get('bes_is_water', False)
            bes_mat.is_glass = mat.get('bes_is_glass', False)
            bes_mat.water_env_blend = mat.get('bes_water_env_blend', 0.0)
            bes_mat.water_alpha_angle = mat.get('bes_water_alpha_angle', 0.0)
            if 'bes_water_sharpness' in mat:
                bes_mat.water_sharpness = tuple(mat['bes_water_sharpness'])
            if 'bes_water_shifting_xy' in mat:
                bes_mat.water_shifting_xy = tuple(mat['bes_water_shifting_xy'])
            if 'bes_water_shifting_uv' in mat:
                bes_mat.water_shifting_uv = tuple(mat['bes_water_shifting_uv'])

            # Restore textures - first try stored texture info, then try to find in nodes
            if 'bes_texture_flags' in mat and 'bes_texture_names' in mat:
                # Use stored texture information from import
                bes_mat.texture_flags = mat['bes_texture_flags']
                try:
                    texture_names = json.loads(mat['bes_texture_names'])
                    for tex_slot, tex_filename in texture_names.items():
                        bes_mat.textures[tex_slot] = BESTexture(
                            filename=tex_filename,
                            u_tile=True,
                            v_tile=True,
                        )
                except (json.JSONDecodeError, ValueError):
                    pass
            elif mat.use_nodes:
                # Fallback: find diffuse texture from shader nodes
                diffuse_tex = self._find_diffuse_texture(mat)
                if diffuse_tex:
                    bes_mat.textures['diffuse_1'] = BESTexture(
                        filename=diffuse_tex,
                        u_tile=True,
                        v_tile=True,
                    )
                    bes_mat.texture_flags |= 0x010000  # DIFFUSE_1 flag

            return bes_mat

        else:
            # Standard material (for compatibility)
            from ..core.bes_types import BESStandardMaterial
            bes_mat = BESStandardMaterial(
                name=mat.name,
                index=len(self._materials),
            )

            # Restore material_id from custom property
            bes_mat.material_id = mat.get('bes_material_id', 0.0)

            # Restore unknown_field from custom property (stored as list of ints)
            # Note: Blender's IDProperty stores Python lists as int32 arrays,
            # so we need to extract just the lower byte of each element
            unknown_field_list = mat.get('bes_unknown_field')
            if unknown_field_list:
                # Extract lower bytes from each element (Blender stores as int32)
                bes_mat.unknown_field = bytes([x & 0xFF for x in unknown_field_list[:4]])
            else:
                bes_mat.unknown_field = b'\x00\x00\x00\x00'

            # Restore map_flags from custom property
            bes_mat.map_flags = mat.get('bes_map_flags', 0)

            # Restore textures from stored custom properties
            # Check for each possible texture slot
            texture_slots = ['diffuse', 'opacity', 'bump', 'ambient', 'specular',
                            'specular_level', 'glossiness', 'self_illum',
                            'displacement', 'filter', 'reflection']

            for slot in texture_slots:
                filename = mat.get(f'bes_tex_{slot}_filename')
                if filename:
                    bes_mat.textures[slot] = BESTexture(
                        filename=filename,
                        flags=mat.get(f'bes_tex_{slot}_flags', 0),
                        u_tile=mat.get(f'bes_tex_{slot}_u_tile', True),
                        v_tile=mat.get(f'bes_tex_{slot}_v_tile', True),
                        u_mirror=mat.get(f'bes_tex_{slot}_u_mirror', False),
                        v_mirror=mat.get(f'bes_tex_{slot}_v_mirror', False),
                    )

            # If no stored textures, try to find from nodes (for newly created materials)
            if not bes_mat.textures and mat.use_nodes:
                diffuse_tex = self._find_diffuse_texture(mat)
                if diffuse_tex:
                    bes_mat.textures['diffuse'] = BESTexture(
                        filename=diffuse_tex,
                        u_tile=True,
                        v_tile=True,
                    )
                    # Only add DIFFUSE flag if not already set
                    if not (bes_mat.map_flags & 0x001):
                        bes_mat.map_flags |= 0x001

            return bes_mat

    def _find_diffuse_texture(self, mat: bpy.types.Material) -> Optional[str]:
        """Find diffuse texture filename from material nodes.

        Args:
            mat: Blender material

        Returns:
            Texture filename or None
        """
        if not mat.use_nodes:
            return None

        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE' and node.image:
                # Get filename from image path
                filepath = node.image.filepath
                if filepath:
                    return os.path.basename(filepath)
                elif node.image.name:
                    return node.image.name

        return None

    def _get_principled_color(self, mat: bpy.types.Material, input_name: str) -> Optional[tuple]:
        """Get color value from Principled BSDF node input.

        Args:
            mat: Blender material
            input_name: Name of the input (e.g., 'Base Color', 'Emission')

        Returns:
            Color as tuple (R, G, B, A) or None
        """
        if not mat.use_nodes:
            return None

        for node in mat.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED':
                if input_name in node.inputs:
                    input_socket = node.inputs[input_name]
                    if hasattr(input_socket, 'default_value'):
                        return tuple(input_socket.default_value)
        return None

    def _build_bes_file(self) -> BESFile:
        """Build complete BES file structure.

        Returns:
            BESFile ready for writing
        """
        bes_file = BESFile(filepath=self.filepath)

        # Detect if this is a skeletal model (has bone parts)
        bone_part_objects = self._find_bone_part_objects()
        is_skeletal = len(bone_part_objects) > 0

        # Create header - use version 0005 for skeletal models
        version = '0005' if is_skeletal else '0008'
        bes_file.header = BESHeader(
            signature=BES_MAGIC,
            version=version,
            exporter=EXPORTER_BLENDER,
            reserved=0,
        )
        bes_file.is_skeletal = is_skeletal

        # Create preview (placeholder - could be rendered)
        bes_file.preview = BESPreview()
        if self.options.get('generate_preview', True):
            bes_file.preview.pixels = self._generate_preview()

        # Add materials
        bes_file.materials = self._materials

        # Check if this is a skeletal model (has bone parts)
        bone_part_objects = self._find_bone_part_objects()
        if bone_part_objects:
            # Build as skeletal model
            self._build_skeletal_model(bes_file, bone_part_objects)
        else:
            # Build as regular model
            self._build_regular_model(bes_file)

        # Calculate statistics
        bes_file.total_faces = self._count_faces(bes_file.root_node)

        # Create info
        bes_file.info = BESInfo(
            author='Blender Export',
            comment=f'Exported from Blender {bpy.app.version_string}',
            total_faces=bes_file.total_faces,
        )

        return bes_file

    def _find_bone_part_objects(self) -> List[bpy.types.Object]:
        """Find all objects that are bone parts.

        Returns:
            List of bone part objects
        """
        bone_parts = []
        for obj in self.context.scene.objects:
            if obj.get('bes_is_bone_part', False):
                bone_parts.append(obj)
        return bone_parts

    def _build_skeletal_model(self, bes_file: BESFile, bone_part_objects: List[bpy.types.Object]):
        """Build BES file structure for skeletal model.

        For BES version 0005 skeletal models, bone parts are stored as OBJECT
        children inside the skeleton container node.

        Args:
            bes_file: BES file to populate
            bone_part_objects: List of bone part mesh objects
        """
        # Mark as skeletal
        bes_file.is_skeletal = True

        # Find armature (parent of bone parts)
        armature_obj = None
        for obj in bone_part_objects:
            if obj.parent and obj.parent.type == 'ARMATURE':
                armature_obj = obj.parent
                break

        # Use stored original skeleton name (Blender may have added .001 suffix)
        if armature_obj:
            skeleton_name = armature_obj.get('bes_skeleton_name', armature_obj.name)
        else:
            skeleton_name = "Skeleton Object"

        # Create skeleton for metadata
        skeleton = BESSkeleton(name=skeleton_name)
        bes_file.skeleton = skeleton

        # Create root node
        bes_file.root_node = BESNode(
            name="Scene Root",
            name_hash=calculate_name_hash("Scene Root"),
        )

        # Create skeleton container node
        skeleton_node = BESNode(
            name=skeleton_name,
            name_hash=calculate_name_hash(skeleton_name),
        )
        skeleton_node.parent = bes_file.root_node
        bes_file.root_node.children.append(skeleton_node)

        # Sort bone parts by import order
        sorted_parts = sorted(bone_part_objects,
                              key=lambda o: o.get('bes_import_order', float('inf')))

        # Convert each bone part object to BESNode and add as child
        for obj in sorted_parts:
            bone_node = self._convert_bone_part_to_node(obj)
            if bone_node:
                bone_node.parent = skeleton_node
                skeleton_node.children.append(bone_node)

                # Also track as BESBonePart for metadata
                bone_part = BESBonePart.parse_name(bone_node.name)
                bone_part.meshes = bone_node.meshes
                bone_part.transform = bone_node.transform
                skeleton.add_bone_part(bone_part)

    def _convert_bone_part_to_node(self, obj: bpy.types.Object) -> Optional[BESNode]:
        """Convert a Blender bone part object to BESNode.

        This uses the regular node conversion but preserves bone part naming
        and uses stored original transform for roundtrip accuracy.
        For bone parts, creates BESBoneVertex to preserve bone weights.

        Args:
            obj: Blender mesh object with bes_is_bone_part property

        Returns:
            BESNode or None if conversion fails
        """
        if obj.type != 'MESH':
            return None

        # Get the original bone name (not Blender object name which may have .001 suffix)
        bone_name = obj.get('bes_bone_name', obj.name)

        node = BESNode(
            name=bone_name,
            name_hash=calculate_name_hash(bone_name),
        )

        # Use original transform if available for roundtrip accuracy
        if 'bes_original_matrix' in obj:
            try:
                bes_matrix = json.loads(obj['bes_original_matrix'])
                translation = tuple(obj.get('bes_original_translation', [0, 0, 0]))
                rotation = tuple(obj.get('bes_original_rotation', [0, 0, 0]))
                scale = tuple(obj.get('bes_original_scale', [1, 1, 1]))

                node.transform = BESTransform(
                    translation=translation,
                    rotation=rotation,
                    scale=scale,
                    matrix=bes_matrix,
                )
            except (json.JSONDecodeError, ValueError):
                node.transform = self._convert_transform(obj)
        else:
            node.transform = self._convert_transform(obj)

        # Convert mesh data - use bone vertex format if we have stored bone weights
        if obj.data:
            if 'bes_bone_weights' in obj:
                # Bone part with stored weights - use BESBoneVertex format
                meshes = self._convert_bone_meshes(obj)
            else:
                # Regular mesh conversion
                meshes = self._convert_meshes(obj)
            node.meshes.extend(meshes)

        # Restore properties if present
        if 'bes_user_properties' in obj:
            props_text = obj['bes_user_properties']
            node.properties = BESProperties(raw_text=props_text)

        return node

    def _convert_transform(self, obj: bpy.types.Object) -> BESTransform:
        """Convert Blender object transform to BES transform.

        Args:
            obj: Blender object

        Returns:
            BESTransform with matrix and location/rotation/scale
        """
        # Use original BES matrix if available (for roundtrip), otherwise compute from Blender
        if 'bes_original_matrix' in obj:
            try:
                bes_matrix = json.loads(obj['bes_original_matrix'])
            except (json.JSONDecodeError, ValueError):
                bes_matrix = [[obj.matrix_local[col][row] for col in range(4)] for row in range(4)]
        else:
            # BES stores matrices column-major (translation in column 3)
            # Blender Matrix is indexed [row][col] but stores column-major internally
            # We need to transpose to get the correct layout for BES
            bes_matrix = [[obj.matrix_local[col][row] for col in range(4)] for row in range(4)]

        return BESTransform(
            translation=tuple(obj.location),
            rotation=tuple(obj.rotation_euler),
            scale=tuple(obj.scale),
            matrix=bes_matrix,
        )

    def _build_regular_model(self, bes_file: BESFile):
        """Build BES file structure for regular (non-skeletal) model.

        Args:
            bes_file: BES file to populate
        """
        # Create root node - always named "Scene Root" to match original BES format
        # If there's exactly one top-level object named "Scene Root", use its children directly
        root_candidates = [obj for obj in self._objects if obj.name == "Scene Root"]

        if len(root_candidates) == 1 and len(self._objects) == 1:
            # Re-imported scene: "Scene Root" is the only top-level object
            # Use it as root and export its children
            scene_root_obj = root_candidates[0]
            bes_file.root_node = BESNode(
                name="Scene Root",
                name_hash=calculate_name_hash("Scene Root"),
            )
            # Add Scene Root's children directly (sorted by import order)
            sorted_children = sorted(scene_root_obj.children,
                                     key=lambda c: c.get('bes_import_order', float('inf')))
            for child_obj in sorted_children:
                child_node = self._convert_object(child_obj)
                if child_node:
                    child_node.parent = bes_file.root_node
                    bes_file.root_node.children.append(child_node)
        else:
            # New scene or multiple top-level objects
            bes_file.root_node = BESNode(
                name="Scene Root",
                name_hash=calculate_name_hash("Scene Root"),
            )
            # Add objects as children of root
            for obj in self._objects:
                child_node = self._convert_object(obj)
                if child_node:
                    child_node.parent = bes_file.root_node
                    bes_file.root_node.children.append(child_node)

    def _get_export_name(self, obj: bpy.types.Object) -> str:
        """Get the proper export name with prefix restored.

        Args:
            obj: Blender object

        Returns:
            Object name with proper prefix for BES export
        """
        name = obj.name

        # Check if we have stored prefix from import
        original_prefix = obj.get('bes_original_prefix', '')
        if original_prefix and not name.startswith(original_prefix):
            return original_prefix + name

        # Check collision type and reconstruct prefix
        obj_type = obj.get('bes_object_type', 'normal')

        if obj_type == 'player' and not name.startswith('^K'):
            return '^K' + name
        elif obj_type == 'bullets' and not name.startswith('^SF'):
            return '^SF' + name
        elif obj_type == 'sphere' and not name.startswith('^SK'):
            return '^SK' + name
        elif obj_type == 'auxiliary' and not name.startswith('!'):
            return '!' + name
        elif obj_type == 'effect':
            # Reconstruct effect sphere name
            if not name.startswith('@'):
                mat = obj.get('bes_effect_material', '')
                slowdown = obj.get('bes_effect_slowdown', 0)
                if mat:
                    return f'@{mat}{slowdown}-{name}'
                return '@' + name
        elif obj_type == 'lod_hidden':
            # Reconstruct LOD prefix
            lod_level = obj.get('bes_lod_level', 1)
            prefix = '>' * lod_level
            if not name.startswith('>'):
                return prefix + name

        return name

    def _convert_object(self, obj: bpy.types.Object) -> Optional[BESNode]:
        """Convert Blender object to BES node.

        Args:
            obj: Blender object

        Returns:
            BES node or None
        """
        # Get proper export name with prefix
        export_name = self._get_export_name(obj)

        node = BESNode(
            name=export_name,
            name_hash=calculate_name_hash(export_name),
        )

        # Set transform
        # NOTE: Use raw coordinates without conversion to match importer behavior
        # The importer uses raw BES coords for location/rotation/scale

        # Use original BES matrix if available (for roundtrip), otherwise compute from Blender
        if 'bes_original_matrix' in obj:
            try:
                bes_matrix = json.loads(obj['bes_original_matrix'])
            except (json.JSONDecodeError, ValueError):
                bes_matrix = [[obj.matrix_local[col][row] for col in range(4)] for row in range(4)]
        else:
            # BES stores matrices column-major (translation in column 3)
            # Blender Matrix is indexed [row][col] but stores column-major internally
            # We need to transpose to get the correct layout for BES
            bes_matrix = [[obj.matrix_local[col][row] for col in range(4)] for row in range(4)]

        node.transform = BESTransform(
            translation=tuple(obj.location),
            rotation=tuple(obj.rotation_euler),
            scale=tuple(obj.scale),
            matrix=bes_matrix,
        )

        # Convert mesh data - one mesh per material
        if obj.type == 'MESH' and obj.data:
            meshes = self._convert_meshes(obj)
            node.meshes.extend(meshes)

            # Calculate bounding box from all meshes
            if meshes:
                all_verts = []
                for mesh in meshes:
                    all_verts.extend([v.position for v in mesh.vertices])
                radius = calculate_bounding_sphere_radius(all_verts)
                node.bbox = (radius, radius, radius)

        # Convert custom properties
        # Check if original had properties (even empty ones)
        if 'bes_user_properties' in obj:
            props_text = obj['bes_user_properties']
            node.properties = BESProperties(raw_text=props_text)
        else:
            # For new objects, generate from custom properties
            props_text = self._convert_properties(obj)
            if props_text:
                node.properties = BESProperties(raw_text=props_text)

        # Restore collision chunk data if present
        if 'bes_collision_chunk' in obj:
            try:
                collision_data = json.loads(obj['bes_collision_chunk'])
                node.collision = BESCollision(
                    name=node.name,
                    collision_type=collision_data.get('collision_type', 2),
                    center=tuple(collision_data.get('center', [0.0, 0.0, 0.0])),
                    raw_vertex_data=base64.b64decode(collision_data.get('raw_vertex_data', '')) if collision_data.get('raw_vertex_data') else b'',
                    raw_face_data=base64.b64decode(collision_data.get('raw_face_data', '')) if collision_data.get('raw_face_data') else b'',
                    raw_bone_data=base64.b64decode(collision_data.get('raw_bone_data', '')) if collision_data.get('raw_bone_data') else b'',
                    raw_trailing=base64.b64decode(collision_data.get('raw_trailing', '')) if collision_data.get('raw_trailing') else b'',
                )
            except (json.JSONDecodeError, KeyError, ValueError):
                pass  # Skip if collision data is corrupted

        # Convert children (sorted by import order for consistency)
        sorted_children = sorted(obj.children, key=lambda c: c.get('bes_import_order', float('inf')))
        for child in sorted_children:
            child_node = self._convert_object(child)
            if child_node:
                child_node.parent = node
                node.children.append(child_node)

        return node

    def _convert_bone_meshes(self, obj: bpy.types.Object) -> List[BESMesh]:
        """Convert Blender mesh with bone weights to BES meshes with BESBoneVertex.

        This method is used for bone part objects that have stored bone weight data.
        It creates BESBoneVertex instead of BESVertex to preserve the skeletal data.

        Args:
            obj: Blender mesh object with bes_bone_weights custom property

        Returns:
            List of BES meshes with BESBoneVertex vertices
        """
        # Get stored bone weight data
        try:
            bone_weights = json.loads(obj['bes_bone_weights'])
        except (KeyError, json.JSONDecodeError):
            bone_weights = []

        try:
            bone_indices = json.loads(obj['bes_bone_indices'])
        except (KeyError, json.JSONDecodeError):
            bone_indices = []

        vertex_flags = obj.get('bes_vertex_flags', 0)

        # Get evaluated mesh (with modifiers applied)
        depsgraph = self.context.evaluated_depsgraph_get()
        eval_obj = obj.evaluated_get(depsgraph)
        mesh_data = eval_obj.to_mesh()

        if not mesh_data:
            return []

        # Triangulate
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(mesh_data)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bm.to_mesh(mesh_data)
        bm.free()

        # Get UV layer
        uv_layer = mesh_data.uv_layers.active

        # Calculate loop triangles
        mesh_data.calc_loop_triangles()

        # Group triangles by material index
        tris_by_material: Dict[int, list] = {}
        for tri in mesh_data.loop_triangles:
            mat_idx = tri.material_index
            if mat_idx not in tris_by_material:
                tris_by_material[mat_idx] = []
            tris_by_material[mat_idx].append(tri)

        # Create one BESMesh per material
        result = []
        for blender_mat_idx in sorted(tris_by_material.keys()):
            tris = tris_by_material[blender_mat_idx]

            # Get BES material index
            bes_mat_index = NO_MATERIAL
            if blender_mat_idx < len(mesh_data.materials) and mesh_data.materials[blender_mat_idx]:
                mat = mesh_data.materials[blender_mat_idx]
                bes_mat_index = self._material_indices.get(mat, None)
                if bes_mat_index is None:
                    bes_mat_index = self._material_indices_by_name.get(mat.name, NO_MATERIAL)

            bes_mesh = BESMesh(material_index=bes_mat_index)

            # Map: (original_vert_idx, uv_tuple) -> new_vert_idx
            vertex_map: Dict[tuple, int] = {}

            for tri in tris:
                face_indices = []

                for i, orig_vert_idx in enumerate(tri.vertices):
                    loop_idx = tri.loops[i]

                    # Get vertex data (raw coordinates)
                    vert = mesh_data.vertices[orig_vert_idx]
                    pos = tuple(vert.co)
                    normal = tuple(vert.normal)

                    # Get UV
                    if uv_layer:
                        uv = uv_layer.data[loop_idx].uv
                        bes_uv = blender_to_bes_uv(tuple(uv))
                        uv_key = (round(bes_uv[0], 6), round(bes_uv[1], 6))
                    else:
                        bes_uv = (0.0, 0.0)
                        uv_key = None

                    vertex_key = (orig_vert_idx, uv_key)

                    if vertex_key in vertex_map:
                        new_vert_idx = vertex_map[vertex_key]
                    else:
                        new_vert_idx = len(bes_mesh.vertices)

                        # Get bone weights and indices from stored data
                        if orig_vert_idx < len(bone_weights):
                            weights = bone_weights[orig_vert_idx]
                        else:
                            weights = [1.0]

                        if orig_vert_idx < len(bone_indices):
                            indices = bone_indices[orig_vert_idx]
                        else:
                            indices = []

                        bes_vert = BESBoneVertex(
                            position=pos,
                            weights=weights,
                            normal=normal,
                            uv=bes_uv,
                            bone_indices=indices,
                            flags=vertex_flags,
                        )
                        bes_mesh.vertices.append(bes_vert)
                        vertex_map[vertex_key] = new_vert_idx

                    face_indices.append(new_vert_idx)

                bes_mesh.faces.append(BESFace(
                    a=face_indices[0],
                    b=face_indices[1],
                    c=face_indices[2],
                ))

            if bes_mesh.vertices and bes_mesh.faces:
                result.append(bes_mesh)

        # Clean up
        eval_obj.to_mesh_clear()

        return result

    def _convert_meshes(self, obj: bpy.types.Object) -> List[BESMesh]:
        """Convert Blender mesh to multiple BES meshes (one per material).

        BES format requires separate MESH chunks for each material.
        Blender stores UVs per-loop (per triangle corner), but BES format
        stores UVs per-vertex. When a vertex is shared by triangles with
        different UVs, we must duplicate the vertex.

        Args:
            obj: Blender mesh object

        Returns:
            List of BES meshes (one per material used)
        """
        # Get evaluated mesh (with modifiers applied)
        depsgraph = self.context.evaluated_depsgraph_get()
        eval_obj = obj.evaluated_get(depsgraph)
        mesh_data = eval_obj.to_mesh()

        if not mesh_data:
            return []

        # Triangulate
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(mesh_data)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bm.to_mesh(mesh_data)
        bm.free()

        # Get UV layer
        uv_layer = mesh_data.uv_layers.active

        # Calculate loop triangles
        mesh_data.calc_loop_triangles()

        # Group triangles by material index
        tris_by_material: Dict[int, list] = {}
        for tri in mesh_data.loop_triangles:
            mat_idx = tri.material_index
            if mat_idx not in tris_by_material:
                tris_by_material[mat_idx] = []
            tris_by_material[mat_idx].append(tri)

        # Create one BESMesh per material
        result = []
        for blender_mat_idx in sorted(tris_by_material.keys()):
            tris = tris_by_material[blender_mat_idx]

            # Get BES material index
            bes_mat_index = NO_MATERIAL
            if blender_mat_idx < len(mesh_data.materials) and mesh_data.materials[blender_mat_idx]:
                mat = mesh_data.materials[blender_mat_idx]
                # Look up by object first, then by name (handle object identity issues)
                bes_mat_index = self._material_indices.get(mat, None)
                if bes_mat_index is None:
                    # Fallback: look up by name
                    bes_mat_index = self._material_indices_by_name.get(mat.name, NO_MATERIAL)

            bes_mesh = BESMesh(material_index=bes_mat_index)

            # Map: (original_vert_idx, uv_tuple) -> new_vert_idx for this mesh
            vertex_map: Dict[tuple, int] = {}

            for tri in tris:
                face_indices = []

                for i, orig_vert_idx in enumerate(tri.vertices):
                    loop_idx = tri.loops[i]

                    # Get vertex data (raw coordinates)
                    vert = mesh_data.vertices[orig_vert_idx]
                    pos = tuple(vert.co)
                    normal = tuple(vert.normal)

                    # Get UV (or empty if no UV layer)
                    if uv_layer:
                        uv = uv_layer.data[loop_idx].uv
                        bes_uv = blender_to_bes_uv(tuple(uv))
                        # Round UV for comparison (avoid floating point issues)
                        uv_key = (round(bes_uv[0], 6), round(bes_uv[1], 6))
                        uvs_list = [bes_uv]
                    else:
                        # No UV layer means no UVs in original mesh - preserve this
                        uv_key = None
                        uvs_list = []

                    vertex_key = (orig_vert_idx, uv_key)

                    if vertex_key in vertex_map:
                        new_vert_idx = vertex_map[vertex_key]
                    else:
                        new_vert_idx = len(bes_mesh.vertices)
                        bes_vert = BESVertex(
                            position=pos,
                            normal=normal,
                            uvs=uvs_list,
                        )
                        bes_mesh.vertices.append(bes_vert)
                        vertex_map[vertex_key] = new_vert_idx

                    face_indices.append(new_vert_idx)

                bes_mesh.faces.append(BESFace(
                    a=face_indices[0],
                    b=face_indices[1],
                    c=face_indices[2],
                ))

            if bes_mesh.vertices and bes_mesh.faces:
                result.append(bes_mesh)

        # Clean up
        eval_obj.to_mesh_clear()

        return result

    def _convert_properties(self, obj: bpy.types.Object) -> str:
        """Convert object custom properties to INI format.

        Syncs UI PropertyGroup values to raw text format before export.
        This ensures any changes made in the UI panels are exported.

        Args:
            obj: Blender object

        Returns:
            INI format string
        """
        # Sync from UI PropertyGroup if available
        if hasattr(obj, 'bes'):
            try:
                props = read_properties_from_object(obj)
                if props:
                    return serialize_user_properties(props)
            except Exception:
                pass  # Fall back to stored raw text

        # Fall back to stored raw property text from import
        if 'bes_user_properties' in obj:
            return obj['bes_user_properties']

        # Internal properties that shouldn't be exported to BES
        INTERNAL_PROPS = {
            'bes_object_type',
            'bes_original_prefix',
            'bes_is_collision',
            'bes_collision_type',
            'bes_collision_name',
            'bes_is_effect_sphere',
            'bes_effect_material',
            'bes_effect_slowdown',
            'bes_is_auxiliary',
            'bes_is_lod',
            'bes_lod_level',
            'bes_user_properties',
            'bes_lod_distance',
            'bes_import_order',
            'bes_original_matrix',
            'bes_collision_chunk',
            # Bone part related
            'bes_is_bone_part',
            'bes_bone_name',
            'bes_damage_state',
            'bes_body_part',
            'bes_part_index',
            'bes_original_translation',
            'bes_original_rotation',
            'bes_original_scale',
            # Bone weight data (stored as JSON)
            'bes_bone_weights',
            'bes_bone_indices',
            'bes_vertex_flags',
            # Skeleton related
            'bes_skeleton_name',
        }

        lines = []

        for key, value in obj.items():
            if key.startswith('bes_') and key not in INTERNAL_PROPS:
                prop_name = key[4:]  # Remove 'bes_' prefix

                # Format value appropriately
                if isinstance(value, bool):
                    lines.append(f'{prop_name}={int(value)}')
                elif isinstance(value, float):
                    lines.append(f'{prop_name}={value:.6f}')
                else:
                    lines.append(f'{prop_name}={value}')

        return '\n'.join(lines)

    def _count_faces(self, node: BESNode) -> int:
        """Count total faces in node hierarchy.

        Args:
            node: Root node

        Returns:
            Total face count
        """
        count = sum(len(mesh.faces) for mesh in node.meshes)

        for child in node.children:
            count += self._count_faces(child)

        return count

    def _generate_preview(self) -> bytes:
        """Generate 64x64 preview image.

        Returns:
            BGR pixel data (12288 bytes)
        """
        # For now, return empty preview
        # TODO: Render actual preview from viewport
        return b'\x80\x80\x80' * (64 * 64)  # Gray preview
