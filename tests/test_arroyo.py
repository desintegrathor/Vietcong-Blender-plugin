# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
ARROYO.BES texture analysis test.

Compares materials between original and exported BES files.
Run with: blender --background --python tests/test_arroyo.py
"""

import sys
import os
import tempfile

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

try:
    import bpy
    HAS_BLENDER = True
except ImportError:
    HAS_BLENDER = False
    print("ERROR: Must run in Blender")
    sys.exit(1)


def analyze_bes_materials(filepath):
    """Analyze materials in a BES file."""
    from vietcong_bes.core.bes_reader import read_bes_file

    bes = read_bes_file(filepath)

    print(f"\nFile: {os.path.basename(filepath)}")
    print(f"  Version: {bes.header.version}")
    print(f"  Materials: {len(bes.materials)}")

    materials = []
    for i, mat in enumerate(bes.materials):
        mat_info = {
            'index': i,
            'name': mat.name,
            'type': mat.material_type,
            'textures': {},
        }

        # Get texture info based on material type
        if hasattr(mat, 'textures'):
            for slot, tex in mat.textures.items():
                mat_info['textures'][slot] = {
                    'filename': tex.filename,
                    'flags': getattr(tex, 'flags', 0),
                    'u_tile': getattr(tex, 'u_tile', 1.0),
                    'v_tile': getattr(tex, 'v_tile', 1.0),
                }

        if hasattr(mat, 'texture_flags'):
            mat_info['texture_flags'] = mat.texture_flags

        if hasattr(mat, 'transparency_type'):
            mat_info['transparency_type'] = mat.transparency_type

        if hasattr(mat, 'two_sided'):
            mat_info['two_sided'] = mat.two_sided

        materials.append(mat_info)

        # Print material info
        print(f"\n  [{i}] {mat.name} (type={mat.material_type})")
        if hasattr(mat, 'texture_flags'):
            print(f"      texture_flags: {mat.texture_flags:#06x}")
        if hasattr(mat, 'transparency_type'):
            print(f"      transparency_type: {mat.transparency_type}")
        if hasattr(mat, 'two_sided'):
            print(f"      two_sided: {mat.two_sided}")

        for slot, tex_info in mat_info['textures'].items():
            print(f"      {slot}: {tex_info['filename']}")
            if tex_info['flags']:
                print(f"        flags: {tex_info['flags']:#06x}")

    return materials


def compare_materials(orig_mats, export_mats):
    """Compare two material lists."""
    print("\n" + "=" * 60)
    print("Material Comparison")
    print("=" * 60)

    if len(orig_mats) != len(export_mats):
        print(f"WARN: Material count differs: {len(orig_mats)} vs {len(export_mats)}")

    issues = []
    for i, (orig, exp) in enumerate(zip(orig_mats, export_mats)):
        diffs = []

        if orig['name'] != exp['name']:
            diffs.append(f"name: '{orig['name']}' -> '{exp['name']}'")

        if orig['type'] != exp['type']:
            diffs.append(f"type: {orig['type']} -> {exp['type']}")

        if orig.get('texture_flags') != exp.get('texture_flags'):
            diffs.append(f"texture_flags: {orig.get('texture_flags'):#06x} -> {exp.get('texture_flags'):#06x}")

        if orig.get('transparency_type') != exp.get('transparency_type'):
            diffs.append(f"transparency_type: {orig.get('transparency_type')} -> {exp.get('transparency_type')}")

        # Compare textures
        orig_tex = orig.get('textures', {})
        exp_tex = exp.get('textures', {})

        all_slots = set(orig_tex.keys()) | set(exp_tex.keys())
        for slot in all_slots:
            if slot not in orig_tex:
                diffs.append(f"texture {slot}: MISSING in original")
            elif slot not in exp_tex:
                diffs.append(f"texture {slot}: MISSING in export")
            else:
                if orig_tex[slot]['filename'] != exp_tex[slot]['filename']:
                    diffs.append(f"texture {slot}: '{orig_tex[slot]['filename']}' -> '{exp_tex[slot]['filename']}'")
                # Compare flags
                orig_flags = orig_tex[slot].get('flags', 0)
                exp_flags = exp_tex[slot].get('flags', 0)
                if orig_flags != exp_flags:
                    diffs.append(f"texture {slot} flags: {orig_flags:#06x} -> {exp_flags:#06x}")

        if diffs:
            issues.append((i, orig['name'], diffs))
            print(f"\n[{i}] {orig['name']} - DIFFERS:")
            for d in diffs:
                print(f"    {d}")
        else:
            print(f"[{i}] {orig['name']} - OK")

    return issues


def test_arroyo_roundtrip():
    """Test ARROYO.BES roundtrip."""
    test_file = os.path.join(PROJECT_ROOT, 'tests', 'ARROYO.BES')

    if not os.path.exists(test_file):
        print(f"ERROR: {test_file} not found")
        return

    print("=" * 60)
    print("ARROYO.BES Material Analysis")
    print("=" * 60)

    # Analyze original
    print("\n--- Original File ---")
    orig_mats = analyze_bes_materials(test_file)

    # Import into Blender
    print("\n--- Importing into Blender ---")
    bpy.ops.wm.read_factory_settings(use_empty=True)

    from vietcong_bes.importers.bes_importer import import_bes
    result = import_bes(bpy.context, test_file)

    if result != {'FINISHED'}:
        print("ERROR: Import failed")
        return

    obj_count = len(bpy.context.scene.objects)
    print(f"  Imported {obj_count} objects")

    # Show Blender material info
    print("\n--- Blender Materials ---")
    for mat in bpy.data.materials:
        print(f"  {mat.name}")
        # Show stored BES properties
        for key in sorted(mat.keys()):
            if key.startswith('bes_'):
                val = mat[key]
                if isinstance(val, str) and len(val) > 50:
                    val = val[:50] + "..."
                print(f"    {key}: {val}")

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
        os.unlink(export_path)
        return

    orig_size = os.path.getsize(test_file)
    exp_size = os.path.getsize(export_path)
    print(f"  Original: {orig_size} bytes")
    print(f"  Exported: {exp_size} bytes")

    # Analyze exported
    print("\n--- Exported File ---")
    exp_mats = analyze_bes_materials(export_path)

    # Compare
    issues = compare_materials(orig_mats, exp_mats)

    if issues:
        print(f"\nFOUND {len(issues)} MATERIAL ISSUES")
    else:
        print("\nALL MATERIALS MATCH")

    # Cleanup
    os.unlink(export_path)


if __name__ == '__main__':
    test_arroyo_roundtrip()
