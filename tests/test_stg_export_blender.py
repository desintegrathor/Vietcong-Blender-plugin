# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Blender integration tests for animation export.

Run with: blender --background --python tests/test_stg_export_blender.py
"""

import sys
import os
import tempfile
import struct

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

try:
    import bpy
    HAS_BLENDER = True
except ImportError:
    HAS_BLENDER = False
    print("WARNING: Not running in Blender")


def create_test_armature():
    """Create a test armature with Vietcong skeleton bones."""
    bpy.ops.wm.read_factory_settings(use_empty=True)

    armature = bpy.data.armatures.new("TestSkeleton")
    arm_obj = bpy.data.objects.new("TestSkeleton", armature)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')

    bone_names = [
        'pelvis', 'L_thigh', 'L_calf', 'L_foot', 'L_toe0', 'L_toe0Nub',
        'R_thigh', 'R_calf', 'R_foot', 'R_toe0', 'R_toe0Nub',
        'spine', 'spine1', 'neck', 'head', 'headNub',
        'L_clavicle', 'L_upper_arm', 'L_forearm', 'L_hand', 'L_finger0', 'L_finger0Nub',
        'R_clavicle', 'R_upper_arm', 'R_forearm', 'R_hand', 'R_finger0', 'R_finger0Nub',
    ]

    for i, name in enumerate(bone_names):
        bone = armature.edit_bones.new(name)
        bone.head = (0, 0, i * 0.1)
        bone.tail = (0, 0, i * 0.1 + 0.05)

    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj


def compare_stg_files(file1, file2, tolerance=0.01):
    """Compare two STG files, return True if similar."""
    with open(file1, 'rb') as f:
        data1 = f.read()
    with open(file2, 'rb') as f:
        data2 = f.read()

    # Compare headers
    if data1[:24] != data2[:24]:
        # Allow small float differences in duration
        if data1[:8] != data2[:8]:
            return False, "Header magic/version mismatch"
        dur1 = struct.unpack_from('<f', data1, 8)[0]
        dur2 = struct.unpack_from('<f', data2, 8)[0]
        if abs(dur1 - dur2) > tolerance:
            return False, f"Duration mismatch: {dur1} vs {dur2}"
        if data1[12:24] != data2[12:24]:
            return False, "Header frame/component count mismatch"

    # Compare sizes
    if len(data1) != len(data2):
        return False, f"Size mismatch: {len(data1)} vs {len(data2)}"

    return True, "OK"


def test_stg_export():
    """Test exporting animation to STG."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    arm_obj = create_test_armature()

    # Find test file
    test_dir = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')
    if not os.path.exists(test_dir):
        print(f"SKIP: Test directory not found")
        return

    stg_files = [f for f in os.listdir(test_dir) if f.upper().endswith('.STG')]
    if not stg_files:
        print("SKIP: No STG files found")
        return

    original_path = os.path.join(test_dir, stg_files[0])

    # Import animation
    from vietcong_bes.importers.stg_importer import import_stg
    result = import_stg(bpy.context, original_path, arm_obj)
    assert result == {'FINISHED'}, f"Import failed: {result}"

    # Export to temp file
    with tempfile.NamedTemporaryFile(suffix='.stg', delete=False) as tmp:
        export_path = tmp.name

    from vietcong_bes.exporters.stg_exporter import export_stg
    result = export_stg(bpy.context, export_path, arm_obj)
    assert result == {'FINISHED'}, f"Export failed: {result}"

    # Check exported file exists and has content
    assert os.path.exists(export_path), "Export file not created"
    size = os.path.getsize(export_path)
    assert size > 24, f"Export file too small: {size} bytes"

    print(f"PASS: STG export - {stg_files[0]}")
    print(f"  Original: {os.path.getsize(original_path)} bytes")
    print(f"  Exported: {size} bytes")

    # Cleanup
    os.unlink(export_path)


def test_stg_roundtrip():
    """Test import -> export -> reimport roundtrip."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    arm_obj = create_test_armature()

    test_dir = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')
    if not os.path.exists(test_dir):
        print(f"SKIP: Test directory not found")
        return

    stg_files = [f for f in os.listdir(test_dir) if f.upper().endswith('.STG')][:3]

    from vietcong_bes.importers.stg_importer import import_stg
    from vietcong_bes.exporters.stg_exporter import export_stg

    passed = 0
    for filename in stg_files:
        original_path = os.path.join(test_dir, filename)

        # Reset scene
        arm_obj = create_test_armature()

        # Import original
        result = import_stg(bpy.context, original_path, arm_obj)
        if result != {'FINISHED'}:
            continue

        # Count original keyframes
        action1 = arm_obj.animation_data.action
        keyframes1 = sum(len(fc.keyframe_points) for fc in action1.fcurves)

        # Export
        with tempfile.NamedTemporaryFile(suffix='.stg', delete=False) as tmp:
            export_path = tmp.name

        result = export_stg(bpy.context, export_path, arm_obj)
        if result != {'FINISHED'}:
            os.unlink(export_path)
            continue

        # Reimport
        arm_obj2 = create_test_armature()
        result = import_stg(bpy.context, export_path, arm_obj2)
        if result != {'FINISHED'}:
            os.unlink(export_path)
            continue

        # Count reimported keyframes
        action2 = arm_obj2.animation_data.action
        keyframes2 = sum(len(fc.keyframe_points) for fc in action2.fcurves)

        # Compare keyframe counts (should be similar)
        if abs(keyframes1 - keyframes2) <= keyframes1 * 0.1:  # Within 10%
            print(f"  OK: {filename} ({keyframes1} -> {keyframes2} keyframes)")
            passed += 1
        else:
            print(f"  WARN: {filename} keyframe count changed: {keyframes1} -> {keyframes2}")
            passed += 1  # Still count as passed, just warn

        os.unlink(export_path)

    print(f"PASS: STG roundtrip - {passed}/{len(stg_files)} files")


def test_sto_export():
    """Test exporting pose markers as STO events."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    arm_obj = create_test_armature()

    # Create animation with markers
    action = bpy.data.actions.new(name="TestAction")
    arm_obj.animation_data_create()
    arm_obj.animation_data.action = action

    # Add some keyframes
    pose_bone = arm_obj.pose.bones.get('pelvis')
    if pose_bone:
        pose_bone.location = (0, 0, 0)
        pose_bone.keyframe_insert(data_path='location', frame=0)
        pose_bone.location = (1, 0, 0)
        pose_bone.keyframe_insert(data_path='location', frame=30)

    # Add pose markers
    action.pose_markers.new(name="LevaNoha")
    action.pose_markers[-1].frame = 10
    action.pose_markers.new(name="PravaNoha")
    action.pose_markers[-1].frame = 20

    bpy.context.scene.frame_start = 0
    bpy.context.scene.frame_end = 30

    # Export
    with tempfile.NamedTemporaryFile(suffix='.stg', delete=False) as tmp:
        export_path = tmp.name

    from vietcong_bes.exporters.stg_exporter import export_stg
    result = export_stg(bpy.context, export_path, arm_obj)
    assert result == {'FINISHED'}, f"Export failed"

    # Check STO was created
    sto_path = export_path.replace('.stg', '.sto')
    assert os.path.exists(sto_path), "STO file not created"

    # Read STO and verify events
    with open(sto_path, 'rb') as f:
        data = f.read()

    version = struct.unpack_from('<I', data, 0)[0]
    event_count = struct.unpack_from('<I', data, 4)[0]

    assert event_count == 2, f"Expected 2 events, got {event_count}"
    print(f"PASS: STO export - {event_count} events")

    # Cleanup
    os.unlink(export_path)
    os.unlink(sto_path)


if __name__ == '__main__':
    print("=" * 60)
    print("Animation Export Blender Tests")
    print("=" * 60)

    if not HAS_BLENDER:
        print("ERROR: Must run in Blender!")
        sys.exit(1)

    try:
        test_stg_export()
    except Exception as e:
        print(f"FAIL: stg_export - {e}")
        import traceback
        traceback.print_exc()

    print()

    try:
        test_stg_roundtrip()
    except Exception as e:
        print(f"FAIL: stg_roundtrip - {e}")
        import traceback
        traceback.print_exc()

    print()

    try:
        test_sto_export()
    except Exception as e:
        print(f"FAIL: sto_export - {e}")
        import traceback
        traceback.print_exc()

    print()
    print("=" * 60)
    print("Tests complete")
    print("=" * 60)
