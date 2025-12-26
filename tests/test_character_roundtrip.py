# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Character model roundtrip test.

Tests import -> export -> reimport of character BES models.
Run with: blender --background --python tests/test_character_roundtrip.py
"""

import sys
import os
import tempfile
import math

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

try:
    import bpy
    from mathutils import Vector, Matrix
    HAS_BLENDER = True
except ImportError:
    HAS_BLENDER = False
    print("ERROR: Must run in Blender")
    sys.exit(1)

TEST_DIR = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS')


def clear_scene():
    """Clear all objects from scene."""
    bpy.ops.wm.read_factory_settings(use_empty=True)


def get_mesh_bounds(obj):
    """Get mesh bounding box in world space."""
    if obj.type != 'MESH':
        return None

    mesh = obj.data
    if len(mesh.vertices) == 0:
        return None

    # Get world space coordinates
    matrix = obj.matrix_world
    coords = [matrix @ v.co for v in mesh.vertices]

    min_co = Vector((min(c.x for c in coords), min(c.y for c in coords), min(c.z for c in coords)))
    max_co = Vector((max(c.x for c in coords), max(c.y for c in coords), max(c.z for c in coords)))

    return {
        'min': min_co,
        'max': max_co,
        'center': (min_co + max_co) / 2,
        'size': max_co - min_co,
    }


def get_armature_info(arm_obj):
    """Get armature bone info."""
    if arm_obj.type != 'ARMATURE':
        return None

    bones = []
    for bone in arm_obj.data.bones:
        head_world = arm_obj.matrix_world @ bone.head_local
        tail_world = arm_obj.matrix_world @ bone.tail_local
        bones.append({
            'name': bone.name,
            'head': head_world.copy(),
            'tail': tail_world.copy(),
        })

    return bones


def analyze_character_orientation(filepath):
    """Analyze character model orientation after import."""
    clear_scene()

    # Import
    from vietcong_bes.importers.bes_importer import import_bes
    result = import_bes(bpy.context, filepath)

    if result != {'FINISHED'}:
        return None, "Import failed"

    # Find armature and meshes
    armature = None
    meshes = []

    for obj in bpy.context.scene.objects:
        if obj.type == 'ARMATURE':
            armature = obj
        elif obj.type == 'MESH':
            meshes.append(obj)

    info = {
        'filepath': filepath,
        'armature': None,
        'meshes': [],
        'orientation': 'unknown',
    }

    # Analyze armature
    if armature:
        bones = get_armature_info(armature)
        info['armature'] = {
            'name': armature.name,
            'bone_count': len(bones),
            'bones': bones,
        }

        # Find pelvis/root and head bones (various naming conventions)
        pelvis = None
        head = None
        for bone in bones:
            name_lower = bone['name'].lower()
            # Check for pelvis-like bones
            if 'pelvis' in name_lower or 'hips' in name_lower or name_lower == 'bip01' or 'bodyback' in name_lower:
                if pelvis is None or 'bodyback' in name_lower:  # prefer bodyback
                    pelvis = bone
            # Check for head bones
            if 'head' in name_lower and 'nub' not in name_lower:
                head = bone

        if pelvis and head:
            # Check if head is above pelvis (Z should be higher)
            head_z = head['head'].z
            pelvis_z = pelvis['head'].z

            if head_z > pelvis_z + 0.1:
                info['orientation'] = 'upright (Z-up)'
            elif head['head'].y > pelvis['head'].y + 0.1:
                info['orientation'] = 'lying (Y-forward, head forward)'
            elif head['head'].y < pelvis['head'].y - 0.1:
                info['orientation'] = 'lying (Y-forward, head back)'
            else:
                info['orientation'] = 'unknown/sideways'

            info['pelvis_pos'] = pelvis['head'].copy()
            info['head_pos'] = head['head'].copy()

    # Analyze meshes - find head and body meshes for orientation check
    head_mesh_z = None
    body_mesh_z = None

    # Find primary LOD0 damage-A meshes (not damaged variants)
    for mesh_obj in meshes:
        # Get actual vertex positions (in world space)
        if mesh_obj.type != 'MESH' or len(mesh_obj.data.vertices) == 0:
            continue

        # Skip non-A damage states and non-0 LOD levels
        name = mesh_obj.name
        if not name.startswith('0A_') and not name.startswith('0C_'):
            # Try to find the pattern anywhere
            if '_L' in name or '[' in name:  # LOD or damage variant
                continue

        verts = [mesh_obj.matrix_world @ v.co for v in mesh_obj.data.vertices]
        z_coords = [v.z for v in verts]
        avg_z = sum(z_coords) / len(z_coords)
        min_z = min(z_coords)
        max_z = max(z_coords)

        name_lower = mesh_obj.name.lower()
        if 'head' in name_lower and head_mesh_z is None:
            head_mesh_z = avg_z
            info['head_mesh_z'] = (min_z, avg_z, max_z)
            info['head_mesh_name'] = mesh_obj.name
        if ('body' in name_lower or 'torso' in name_lower) and body_mesh_z is None:
            body_mesh_z = avg_z
            info['body_mesh_z'] = (min_z, avg_z, max_z)
            info['body_mesh_name'] = mesh_obj.name

        # Store mesh info
        bounds = get_mesh_bounds(mesh_obj)
        if bounds:
            info['meshes'].append({
                'name': mesh_obj.name,
                'vertex_count': len(mesh_obj.data.vertices),
                'bounds': bounds,
            })

    # Check mesh-based orientation
    if head_mesh_z is not None and body_mesh_z is not None:
        if head_mesh_z > body_mesh_z + 0.1:
            info['mesh_orientation'] = 'upright (head above body)'
        else:
            info['mesh_orientation'] = 'not upright'

    return info, "OK"


def analyze_mesh_vertices(mesh_obj):
    """Get vertex Z range from mesh object directly."""
    if mesh_obj.type != 'MESH':
        return None

    mesh = mesh_obj.data
    if len(mesh.vertices) == 0:
        return None

    # Get local coordinates
    local_z = [v.co.z for v in mesh.vertices]

    # Get world coordinates
    matrix = mesh_obj.matrix_world
    world_z = [(matrix @ v.co).z for v in mesh.vertices]

    return {
        'local_min': min(local_z),
        'local_max': max(local_z),
        'world_min': min(world_z),
        'world_max': max(world_z),
        'matrix': str(matrix),
    }


def test_single_character():
    """Test a single character model."""
    # Find a character model
    char_dirs = [d for d in os.listdir(TEST_DIR) if os.path.isdir(os.path.join(TEST_DIR, d))]

    for char_dir in char_dirs[:3]:
        char_path = os.path.join(TEST_DIR, char_dir)
        bes_files = [f for f in os.listdir(char_path) if f.upper().endswith('.BES') and '[' not in f and '_L' not in f]

        if not bes_files:
            continue

        filepath = os.path.join(char_path, bes_files[0])
        print(f"\nAnalyzing: {bes_files[0]}")

        info, status = analyze_character_orientation(filepath)

        if info:
            print(f"  Bone orientation: {info['orientation']}")
            if 'mesh_orientation' in info:
                print(f"  Mesh orientation: {info['mesh_orientation']}")

            if info['armature']:
                print(f"  Armature: {info['armature']['bone_count']} bones")

                if 'pelvis_pos' in info:
                    p = info['pelvis_pos']
                    h = info['head_pos']
                    print(f"  Body bone pos: ({p.x:.2f}, {p.y:.2f}, {p.z:.2f})")
                    print(f"  Head bone pos: ({h.x:.2f}, {h.y:.2f}, {h.z:.2f})")

            if 'head_mesh_z' in info:
                h = info['head_mesh_z']
                print(f"  Head mesh Z range: {h[0]:.2f} to {h[2]:.2f} (avg {h[1]:.2f}) [{info.get('head_mesh_name', '?')}]")
            if 'body_mesh_z' in info:
                b = info['body_mesh_z']
                print(f"  Body mesh Z range: {b[0]:.2f} to {b[2]:.2f} (avg {b[1]:.2f}) [{info.get('body_mesh_name', '?')}]")

            # Find head and body mesh objects for deeper analysis
            for obj in bpy.context.scene.objects:
                if obj.type == 'MESH' and 'head' in obj.name.lower() and obj.name.startswith('0'):
                    vert_info = analyze_mesh_vertices(obj)
                    if vert_info:
                        print(f"  Direct head mesh check ({obj.name}):")
                        print(f"    Local Z: {vert_info['local_min']:.3f} to {vert_info['local_max']:.3f}")
                        print(f"    World Z: {vert_info['world_min']:.3f} to {vert_info['world_max']:.3f}")
                        print(f"    Parent: {obj.parent.name if obj.parent else 'None'}")
                        mat = obj.matrix_world
                        print(f"    Matrix row 0: [{mat[0][0]:.2f}, {mat[0][1]:.2f}, {mat[0][2]:.2f}, {mat[0][3]:.2f}]")
                        print(f"    Matrix row 1: [{mat[1][0]:.2f}, {mat[1][1]:.2f}, {mat[1][2]:.2f}, {mat[1][3]:.2f}]")
                        print(f"    Matrix row 2: [{mat[2][0]:.2f}, {mat[2][1]:.2f}, {mat[2][2]:.2f}, {mat[2][3]:.2f}]")
                        print(f"    Matrix row 3: [{mat[3][0]:.2f}, {mat[3][1]:.2f}, {mat[3][2]:.2f}, {mat[3][3]:.2f}]")
                        if obj.parent:
                            pmat = obj.parent.matrix_world
                            print(f"    Parent matrix row 2: [{pmat[2][0]:.2f}, {pmat[2][1]:.2f}, {pmat[2][2]:.2f}, {pmat[2][3]:.2f}]")
                        print(f"    Local location: {obj.location}")
                        print(f"    Local scale: {obj.scale}")
                        print(f"    Local rotation: {obj.rotation_euler}")
                        lmat = obj.matrix_local
                        print(f"    Local matrix row 0: [{lmat[0][0]:.2f}, {lmat[0][1]:.2f}, {lmat[0][2]:.2f}, {lmat[0][3]:.2f}]")
                    break


def test_roundtrip():
    """Test import -> export -> reimport roundtrip."""
    char_dirs = [d for d in os.listdir(TEST_DIR) if os.path.isdir(os.path.join(TEST_DIR, d))]

    from vietcong_bes.importers.bes_importer import import_bes
    from vietcong_bes.exporters.bes_exporter import export_bes

    for char_dir in char_dirs[:2]:
        char_path = os.path.join(TEST_DIR, char_dir)
        bes_files = [f for f in os.listdir(char_path) if f.upper().endswith('.BES') and '[' not in f and '_L' not in f]

        if not bes_files:
            continue

        filepath = os.path.join(char_path, bes_files[0])
        print(f"\nRoundtrip test: {bes_files[0]}")

        # First import
        clear_scene()
        result = import_bes(bpy.context, filepath)
        if result != {'FINISHED'}:
            print("  FAIL: First import failed")
            continue

        # Count objects
        obj_count_1 = len([o for o in bpy.context.scene.objects])
        vert_count_1 = sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type == 'MESH')

        # Get original file size
        orig_size = os.path.getsize(filepath)

        # Export
        with tempfile.NamedTemporaryFile(suffix='.bes', delete=False) as tmp:
            export_path = tmp.name

        # Select all for export
        for obj in bpy.context.scene.objects:
            obj.select_set(True)

        result = export_bes(bpy.context, export_path)
        if result != {'FINISHED'}:
            print("  FAIL: Export failed")
            os.unlink(export_path)
            continue

        export_size = os.path.getsize(export_path)

        # Second import
        clear_scene()
        result = import_bes(bpy.context, export_path)
        if result != {'FINISHED'}:
            print("  FAIL: Reimport failed")
            os.unlink(export_path)
            continue

        obj_count_2 = len([o for o in bpy.context.scene.objects])
        vert_count_2 = sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type == 'MESH')

        print(f"  Original: {orig_size} bytes, {obj_count_1} objects, {vert_count_1} verts")
        print(f"  Exported: {export_size} bytes, {obj_count_2} objects, {vert_count_2} verts")

        if obj_count_1 == obj_count_2 and vert_count_1 == vert_count_2:
            print("  PASS: Object and vertex counts match")
        else:
            print("  WARN: Counts differ")

        # Third roundtrip
        with tempfile.NamedTemporaryFile(suffix='.bes', delete=False) as tmp:
            export_path_2 = tmp.name

        for obj in bpy.context.scene.objects:
            obj.select_set(True)

        result = export_bes(bpy.context, export_path_2)
        if result == {'FINISHED'}:
            size_2 = os.path.getsize(export_path_2)
            if size_2 == export_size:
                print(f"  PASS: Second export identical ({size_2} bytes)")
            else:
                print(f"  WARN: Second export differs ({export_size} -> {size_2} bytes)")
            os.unlink(export_path_2)

        os.unlink(export_path)


if __name__ == '__main__':
    print("=" * 60)
    print("Character Model Roundtrip Test")
    print("=" * 60)

    print("\n--- Orientation Analysis ---")
    test_single_character()

    print("\n--- Roundtrip Test ---")
    test_roundtrip()

    print("\n" + "=" * 60)
    print("Tests complete")
    print("=" * 60)
