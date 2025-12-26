"""
Blender roundtrip test script.
Run with: blender --background --python tests/blender_roundtrip_test.py
"""

import sys
import os

# Add project to path BEFORE any vietcong_bes imports
project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_dir)

# Force reload of vietcong_bes modules (override any installed addon)
import importlib
for mod_name in list(sys.modules.keys()):
    if mod_name.startswith('vietcong_bes'):
        del sys.modules[mod_name]

# Verify we're using the correct modules
import vietcong_bes.core.bes_writer as bes_writer_module
print(f"Using bes_writer from: {bes_writer_module.__file__}")

import bpy

def clear_scene():
    """Clear all objects from scene."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Clear materials
    for mat in bpy.data.materials:
        bpy.data.materials.remove(mat)

    # Clear meshes
    for mesh in bpy.data.meshes:
        bpy.data.meshes.remove(mesh)

def test_roundtrip(input_file, output_file):
    """Test import/export roundtrip."""
    print(f"\n{'='*60}")
    print(f"Testing: {os.path.basename(input_file)}")
    print(f"{'='*60}")

    # Clear scene
    clear_scene()

    # Import
    print(f"Importing: {input_file}")
    from vietcong_bes.importers.bes_importer import import_bes
    result = import_bes(bpy.context, input_file)

    if result != {'FINISHED'}:
        print(f"ERROR: Import failed!")
        return False

    # Count objects
    obj_count = len([o for o in bpy.context.scene.objects])
    mat_count = len(bpy.data.materials)
    print(f"Imported: {obj_count} objects, {mat_count} materials")


    # Export
    print(f"Exporting: {output_file}")
    from vietcong_bes.exporters.bes_exporter import export_bes
    result = export_bes(bpy.context, output_file)

    if result != {'FINISHED'}:
        print(f"ERROR: Export failed!")
        return False

    # Compare file sizes
    orig_size = os.path.getsize(input_file)
    new_size = os.path.getsize(output_file)
    diff_pct = (new_size / orig_size) * 100

    print(f"Original size: {orig_size:,} bytes")
    print(f"Export size:   {new_size:,} bytes ({diff_pct:.1f}%)")

    # Now compare structures using bes_compare
    print("\nComparing structures...")
    from vietcong_bes.core.bes_reader import read_bes_file
    from vietcong_bes.core.bes_compare import compare_bes_files

    orig = read_bes_file(input_file)
    exported = read_bes_file(output_file)

    result = compare_bes_files(orig, exported)

    if result.equal:
        print("PASS: Structures are equal!")
        return True
    else:
        print(f"FAIL: {len(result.differences)} differences found:")
        for diff in result.differences[:20]:
            print(f"  - {diff}")
        if len(result.differences) > 20:
            print(f"  ... and {len(result.differences) - 20} more")
        return False

def main():
    test_dir = os.path.join(project_dir, 'tests')

    # List of test files (including skeletal models)
    test_files = [
        # Static models
        ('IVQ_BEDNA.bes', 'IVQ_BEDNA_blender_export.bes'),
        ('VVH_KNIFE_FPV.bes', 'VVH_KNIFE_FPV_blender_export.bes'),
        ('CLAYMORE.BES', 'CLAYMORE_blender_export.bes'),
        # Skeletal model
        ('CUP_BANGS.BES', 'CUP_BANGS_blender_export.bes'),
    ]

    all_passed = True

    for input_name, output_name in test_files:
        input_file = os.path.join(test_dir, input_name)
        output_file = os.path.join(test_dir, output_name)

        if not os.path.exists(input_file):
            print(f"SKIP: {input_name} not found")
            continue

        success = test_roundtrip(input_file, output_file)
        if not success:
            all_passed = False

    print(f"\n{'='*60}")
    print(f"OVERALL RESULT: {'PASS' if all_passed else 'FAIL'}")
    print(f"{'='*60}")

    sys.exit(0 if all_passed else 1)

if __name__ == '__main__':
    main()
