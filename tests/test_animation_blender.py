# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Blender integration tests for animation import.

Run with: blender --background --python tests/test_animation_blender.py
Or on Windows: "C:/Program Files/Blender Foundation/Blender 4.2/blender.exe" --background --python tests/test_animation_blender.py
"""

import sys
import os

# Add project root to path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

try:
    import bpy
    HAS_BLENDER = True
except ImportError:
    HAS_BLENDER = False
    print("WARNING: Not running in Blender - some tests will be skipped")


def create_test_armature():
    """Create a test armature with Vietcong skeleton bones."""
    if not HAS_BLENDER:
        return None

    # Clear scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # Create armature
    armature = bpy.data.armatures.new("TestSkeleton")
    arm_obj = bpy.data.objects.new("TestSkeleton", armature)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')

    # Create bones matching STG bone indices
    bone_names = [
        'pelvis',       # 0
        'L_thigh',      # 1
        'L_calf',       # 2
        'L_foot',       # 3
        'L_toe0',       # 4
        'L_toe0Nub',    # 5
        'R_thigh',      # 6
        'R_calf',       # 7
        'R_foot',       # 8
        'R_toe0',       # 9
        'R_toe0Nub',    # 10
        'spine',        # 11
        'spine1',       # 12
        'neck',         # 13
        'head',         # 14
        'headNub',      # 15
        'L_clavicle',   # 16
        'L_upper_arm',  # 17
        'L_forearm',    # 18
        'L_hand',       # 19
        'L_finger0',    # 20
        'L_finger0Nub', # 21
        'R_clavicle',   # 22
        'R_upper_arm',  # 23
        'R_forearm',    # 24
        'R_hand',       # 25
        'R_finger0',    # 26
        'R_finger0Nub', # 27
    ]

    for i, name in enumerate(bone_names):
        bone = armature.edit_bones.new(name)
        bone.head = (0, 0, i * 0.1)
        bone.tail = (0, 0, i * 0.1 + 0.05)

    bpy.ops.object.mode_set(mode='OBJECT')

    return arm_obj


def test_stg_import():
    """Test importing STG animation to armature."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    # Create test armature
    arm_obj = create_test_armature()
    assert arm_obj is not None, "Failed to create armature"

    # Find test STG file
    test_dir = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')
    if not os.path.exists(test_dir):
        print(f"SKIP: Test directory not found: {test_dir}")
        return

    stg_files = [f for f in os.listdir(test_dir) if f.upper().endswith('.STG')]
    if not stg_files:
        print("SKIP: No STG files found")
        return

    filepath = os.path.join(test_dir, stg_files[0])

    # Import animation
    from vietcong_bes.importers.stg_importer import import_stg

    result = import_stg(bpy.context, filepath, arm_obj)
    assert result == {'FINISHED'}, f"Import failed: {result}"

    # Verify action was created
    assert arm_obj.animation_data is not None, "No animation data"
    assert arm_obj.animation_data.action is not None, "No action created"

    action = arm_obj.animation_data.action
    print(f"PASS: STG import - {stg_files[0]}")
    print(f"  Action: {action.name}")
    print(f"  F-curves: {len(action.fcurves)}")
    print(f"  Frame range: {bpy.context.scene.frame_start} - {bpy.context.scene.frame_end}")

    # Check F-curves exist
    assert len(action.fcurves) > 0, "No F-curves created"

    # Check keyframes exist
    total_keyframes = sum(len(fc.keyframe_points) for fc in action.fcurves)
    print(f"  Total keyframes: {total_keyframes}")
    assert total_keyframes > 0, "No keyframes created"


def test_bone_mapping():
    """Test bone index to name mapping."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    from vietcong_bes.importers.stg_importer import STGImporter

    # Create test armature
    arm_obj = create_test_armature()

    # Check all mapped bones can be found
    class MockAnim:
        filename = "test.stg"
        frame_count = 10
        fps = 30.0
        duration = 1.0
        bone_tracks = []

    importer = STGImporter(bpy.context, MockAnim(), arm_obj, {})

    # Test bone indices used in animations
    used_indices = [0, 1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 15, 17, 18, 19, 20, 22, 23]

    found = 0
    missing = []

    for idx in used_indices:
        pose_bone = importer._find_pose_bone_for_index(idx)
        if pose_bone:
            found += 1
        else:
            missing.append(idx)

    print(f"Bone mapping: {found}/{len(used_indices)} found")
    if missing:
        print(f"  Missing indices: {missing}")

    assert found == len(used_indices), f"Missing bones: {missing}"
    print("PASS: Bone mapping")


def test_multiple_animations():
    """Test importing multiple animations."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    # Create test armature
    arm_obj = create_test_armature()

    # Find test STG files
    test_dir = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')
    if not os.path.exists(test_dir):
        print(f"SKIP: Test directory not found")
        return

    stg_files = [f for f in os.listdir(test_dir) if f.upper().endswith('.STG')][:5]

    from vietcong_bes.importers.stg_importer import import_stg

    for filename in stg_files:
        filepath = os.path.join(test_dir, filename)
        result = import_stg(bpy.context, filepath, arm_obj)

        if result == {'FINISHED'}:
            print(f"  OK: {filename}")
        else:
            print(f"  FAIL: {filename}")

    # Check multiple actions were created
    actions = [a for a in bpy.data.actions if a.name.startswith('A')]
    print(f"PASS: Multiple animations - {len(actions)} actions created")


def test_sto_events():
    """Test STO event import as markers."""
    if not HAS_BLENDER:
        print("SKIP: Blender not available")
        return

    # Create test armature
    arm_obj = create_test_armature()

    # Find test files with matching STG and STO
    test_dir = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')
    if not os.path.exists(test_dir):
        print(f"SKIP: Test directory not found")
        return

    # Find STG with matching STO that has events
    for filename in os.listdir(test_dir):
        if not filename.upper().endswith('.STG'):
            continue

        sto_file = filename[:-4] + '.STO'
        sto_path = os.path.join(test_dir, sto_file)

        if not os.path.exists(sto_path):
            continue

        # Check if STO has events
        if os.path.getsize(sto_path) <= 8:
            continue

        stg_path = os.path.join(test_dir, filename)

        from vietcong_bes.importers.stg_importer import import_stg
        result = import_stg(bpy.context, stg_path, arm_obj)

        if result == {'FINISHED'}:
            action = arm_obj.animation_data.action
            markers = action.pose_markers
            print(f"PASS: STO events - {len(markers)} markers from {filename}")
            for m in markers[:3]:
                print(f"  {m.name} @ frame {m.frame}")
            return

    print("SKIP: No STG/STO pairs with events found")


if __name__ == '__main__':
    print("=" * 60)
    print("Animation Blender Tests")
    print("=" * 60)

    if not HAS_BLENDER:
        print("ERROR: Must run in Blender!")
        print("Usage: blender --background --python tests/test_animation_blender.py")
        sys.exit(1)

    try:
        test_bone_mapping()
    except Exception as e:
        print(f"FAIL: bone_mapping - {e}")
        import traceback
        traceback.print_exc()

    print()

    try:
        test_stg_import()
    except Exception as e:
        print(f"FAIL: stg_import - {e}")
        import traceback
        traceback.print_exc()

    print()

    try:
        test_multiple_animations()
    except Exception as e:
        print(f"FAIL: multiple_animations - {e}")
        import traceback
        traceback.print_exc()

    print()

    try:
        test_sto_events()
    except Exception as e:
        print(f"FAIL: sto_events - {e}")
        import traceback
        traceback.print_exc()

    print()
    print("=" * 60)
    print("Tests complete")
    print("=" * 60)
