# SPDX-License-Identifier: GPL-3.0-or-later
"""
MVJ_M151.BES roundtrip test.
Run with: blender --background --python tests/test_m151.py
"""

import sys
import os
import tempfile

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

try:
    import bpy
except ImportError:
    print("ERROR: Must run in Blender")
    sys.exit(1)


def analyze_bes_file(filepath):
    """Analyze BES file structure."""
    from vietcong_bes.core.bes_reader import read_bes_file

    bes = read_bes_file(filepath)

    print(f"\nFile: {os.path.basename(filepath)}")
    print(f"  Size: {os.path.getsize(filepath)} bytes")
    print(f"  Version: {bes.header.version}")
    print(f"  Materials: {len(bes.materials)}")

    # Count nodes and meshes
    node_count = 0
    mesh_count = 0

    def count_nodes(node):
        nonlocal node_count, mesh_count
        node_count += 1
        mesh_count += len(node.meshes) if node.meshes else 0
        for child in node.children:
            count_nodes(child)

    if bes.root_node:
        count_nodes(bes.root_node)

    print(f"  Nodes: {node_count}")
    print(f"  Meshes: {mesh_count}")

    if bes.skeleton:
        print(f"  Skeleton: {bes.skeleton.name}")
        print(f"  Bone parts: {len(bes.skeleton.bone_parts)}")

    # Show materials
    for i, mat in enumerate(bes.materials):
        tex_info = ""
        if hasattr(mat, 'textures') and mat.textures:
            tex_names = [f"{slot}:{tex.filename}" for slot, tex in mat.textures.items()]
            tex_info = f" -> {', '.join(tex_names)}"
        print(f"  [{i}] {mat.name} ({mat.material_type}){tex_info}")

    return bes


def test_m151_roundtrip():
    """Test MVJ_M151.BES roundtrip."""
    test_file = os.path.join(PROJECT_ROOT, 'tests', 'MVJ_M151.BES')

    if not os.path.exists(test_file):
        print(f"ERROR: {test_file} not found")
        return

    print("=" * 60)
    print("MVJ_M151.BES Roundtrip Test")
    print("=" * 60)

    # Analyze original
    print("\n--- Original File ---")
    orig_bes = analyze_bes_file(test_file)

    # Import into Blender
    print("\n--- Importing into Blender ---")
    bpy.ops.wm.read_factory_settings(use_empty=True)

    from vietcong_bes.importers.bes_importer import import_bes
    result = import_bes(bpy.context, test_file)

    if result != {'FINISHED'}:
        print("ERROR: Import failed")
        return

    obj_count = len(bpy.context.scene.objects)
    mesh_count = len([o for o in bpy.context.scene.objects if o.type == 'MESH'])
    armature_count = len([o for o in bpy.context.scene.objects if o.type == 'ARMATURE'])
    vert_count = sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type == 'MESH')

    print(f"  Objects: {obj_count}")
    print(f"  Meshes: {mesh_count}")
    print(f"  Armatures: {armature_count}")
    print(f"  Total vertices: {vert_count}")

    # Export
    print("\n--- Exporting ---")
    with tempfile.NamedTemporaryFile(suffix='.bes', delete=False) as tmp:
        export_path = tmp.name

    # Select all for export
    for obj in bpy.context.scene.objects:
        obj.select_set(True)

    from vietcong_bes.exporters.bes_exporter import export_bes
    result = export_bes(bpy.context, export_path)

    if result != {'FINISHED'}:
        print("ERROR: Export failed")
        if os.path.exists(export_path):
            os.unlink(export_path)
        return

    # Analyze exported
    print("\n--- Exported File ---")
    exp_bes = analyze_bes_file(export_path)

    # Compare
    print("\n--- Comparison ---")
    orig_size = os.path.getsize(test_file)
    exp_size = os.path.getsize(export_path)
    print(f"  Original size: {orig_size} bytes")
    print(f"  Exported size: {exp_size} bytes")
    print(f"  Size diff: {exp_size - orig_size:+d} bytes")

    print(f"  Materials: {len(orig_bes.materials)} -> {len(exp_bes.materials)}")

    # Reimport test
    print("\n--- Reimport Test ---")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = import_bes(bpy.context, export_path)

    if result != {'FINISHED'}:
        print("ERROR: Reimport failed")
    else:
        reimport_obj_count = len(bpy.context.scene.objects)
        reimport_vert_count = sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type == 'MESH')
        print(f"  Objects: {obj_count} -> {reimport_obj_count}")
        print(f"  Vertices: {vert_count} -> {reimport_vert_count}")

        if obj_count == reimport_obj_count and vert_count == reimport_vert_count:
            print("  PASS: Counts match")
        else:
            print("  WARN: Counts differ")

    # Cleanup
    os.unlink(export_path)
    print("\n" + "=" * 60)
    print("Test complete")
    print("=" * 60)


if __name__ == '__main__':
    test_m151_roundtrip()
