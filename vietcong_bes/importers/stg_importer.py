# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
STG Animation Importer

Imports Vietcong STG animation files into Blender.
"""

import bpy
import math
from mathutils import Quaternion, Vector, Euler
from typing import Optional, Dict, List

from ..core.stg_parser import read_stg_file, STGAnimation, STGBoneTrack
from ..core.sto_parser import read_sto_file, STOAnimation


def import_stg(context, filepath: str, armature: bpy.types.Object = None, **options) -> set:
    """Import an STG animation file into Blender.

    Args:
        context: Blender context
        filepath: Path to STG file
        armature: Target armature object (optional, auto-detect if None)
        **options: Import options

    Returns:
        {'FINISHED'} on success, {'CANCELLED'} on failure
    """
    try:
        # Parse STG file
        stg_anim = read_stg_file(filepath)

        # Find target armature
        if armature is None:
            armature = find_armature(context)

        if armature is None:
            print("STG Import Error: No armature found")
            return {'CANCELLED'}

        # Create importer instance
        importer = STGImporter(context, stg_anim, armature, options)
        importer.import_animation()

        # Try to load matching STO file
        sto_path = filepath.replace('.STG', '.STO').replace('.stg', '.sto')
        try:
            sto_anim = read_sto_file(sto_path)
            importer.import_events(sto_anim)
        except FileNotFoundError:
            pass  # STO file is optional

        return {'FINISHED'}

    except Exception as e:
        print(f"STG Import Error: {e}")
        import traceback
        traceback.print_exc()
        return {'CANCELLED'}


def find_armature(context) -> Optional[bpy.types.Object]:
    """Find armature in scene.

    Priority:
    1. Selected armature
    2. Active object if armature
    3. First armature in scene

    Args:
        context: Blender context

    Returns:
        Armature object or None
    """
    # Check selection first
    for obj in context.selected_objects:
        if obj.type == 'ARMATURE':
            return obj

    # Check active object
    if context.active_object and context.active_object.type == 'ARMATURE':
        return context.active_object

    # Find first armature in scene
    for obj in context.scene.objects:
        if obj.type == 'ARMATURE':
            return obj

    return None


class STGImporter:
    """STG to Blender animation importer."""

    # Bone name mapping from STG index to skeleton bone names
    # Multiple aliases for different naming conventions
    # Format: index -> (primary_name, [alternative_names])
    BONE_INDEX_MAP = {
        0: ('pelvis', ['Hips', 'Root', 'Bip01']),
        1: ('L_thigh', ['LeftHip', 'Bip01 L Thigh']),
        2: ('L_calf', ['LeftKnee', 'Bip01 L Calf']),
        3: ('L_foot', ['LeftAnkle', 'LFoot', 'Bip01 L Foot']),
        4: ('L_toe0', ['LToe', 'Bip01 L Toe0']),
        5: ('L_toe0Nub', ['LToeNub']),
        6: ('R_thigh', ['RightHip', 'Bip01 R Thigh']),
        7: ('R_calf', ['RightKnee', 'Bip01 R Calf']),
        8: ('R_foot', ['RightAnkle', 'RFoot', 'Bip01 R Foot']),
        9: ('R_toe0', ['RToe', 'Bip01 R Toe0']),
        10: ('R_toe0Nub', ['RToeNub']),
        11: ('spine', ['Chest', 'Bip01 Spine']),
        12: ('spine1', ['Chest2', 'Bip01 Spine1']),
        13: ('neck', ['Neck', 'Bip01 Neck']),
        14: ('head', ['Head', 'Bip01 Head']),
        15: ('headNub', ['HeadTop', 'HeadNub']),
        16: ('L_clavicle', ['LeftCollar', 'Bip01 L Clavicle']),
        17: ('L_upper_arm', ['LeftShoulder', 'Bip01 L UpperArm']),
        18: ('L_forearm', ['LeftElbow', 'Bip01 L Forearm']),
        19: ('L_hand', ['LeftWrist', 'Bip01 L Hand']),
        20: ('L_finger0', ['LeftFingers', 'Bip01 L Finger0']),
        21: ('L_finger0Nub', ['LeftFingersNub']),
        22: ('R_clavicle', ['RightCollar', 'Bip01 R Clavicle']),
        23: ('R_upper_arm', ['RightShoulder', 'Bip01 R UpperArm']),
        24: ('R_forearm', ['RightElbow', 'Bip01 R Forearm']),
        25: ('R_hand', ['RightWrist', 'Bip01 R Hand']),
        26: ('R_finger0', ['RightFingers', 'Bip01 R Finger0']),
        27: ('R_finger0Nub', ['RightFingersNub']),
    }

    def __init__(self, context, stg_anim: STGAnimation, armature: bpy.types.Object, options: dict):
        """Initialize importer.

        Args:
            context: Blender context
            stg_anim: Parsed STG animation
            armature: Target armature
            options: Import options
        """
        self.context = context
        self.stg_anim = stg_anim
        self.armature = armature
        self.options = options

    def import_animation(self):
        """Import animation data to armature."""
        import os

        # Get animation name from filename
        anim_name = os.path.splitext(os.path.basename(self.stg_anim.filename))[0]

        # Create or get action
        action = bpy.data.actions.new(name=anim_name)
        self.armature.animation_data_create()
        self.armature.animation_data.action = action

        # Set scene FPS
        self.context.scene.render.fps = int(round(self.stg_anim.fps))
        if self.stg_anim.fps > 0:
            self.context.scene.render.fps_base = 1.0

        # Set frame range
        self.context.scene.frame_start = 0
        self.context.scene.frame_end = self.stg_anim.frame_count - 1

        # Import each bone track
        for track in self.stg_anim.bone_tracks:
            # Find matching bone in armature
            pose_bone = self._find_pose_bone_for_index(track.bone_index)
            if pose_bone is None:
                print(f"Warning: No bone found for index {track.bone_index}")
                continue

            # Import position keyframes
            if track.has_position and track.positions:
                self._import_position_track(pose_bone, track.positions, action)

            # Import rotation keyframes
            if track.has_rotation and track.rotations:
                self._import_rotation_track(pose_bone, track.rotations, action)

    def _build_bone_mapping(self) -> Dict[int, str]:
        """Build mapping from bone index to bone name.

        Returns:
            Dict mapping bone index to name
        """
        mapping = {}

        # Use armature bone names if available
        for bone in self.armature.data.bones:
            # Try to match by common naming patterns
            name_lower = bone.name.lower()

            for idx, std_name in self.BONE_INDEX_MAP.items():
                if std_name.lower() in name_lower or name_lower == std_name.lower():
                    mapping[idx] = bone.name
                    break

        # Fall back to standard mapping for unmapped bones
        for idx, name in self.BONE_INDEX_MAP.items():
            if idx not in mapping:
                if name in self.armature.data.bones:
                    mapping[idx] = name

        return mapping

    def _get_bone_names(self, bone_index: int) -> List[str]:
        """Get all possible bone names for an index.

        Args:
            bone_index: STG bone index

        Returns:
            List of bone names (primary + aliases), or empty list
        """
        entry = self.BONE_INDEX_MAP.get(bone_index)
        if entry is None:
            return []
        primary, aliases = entry
        return [primary] + aliases

    def _find_pose_bone_for_index(self, bone_index: int) -> Optional[bpy.types.PoseBone]:
        """Find pose bone by bone index, trying all name aliases.

        Args:
            bone_index: STG bone index

        Returns:
            Pose bone or None
        """
        names = self._get_bone_names(bone_index)

        for name in names:
            # Exact match
            if name in self.armature.pose.bones:
                return self.armature.pose.bones[name]

            # Case-insensitive match
            name_lower = name.lower()
            for pb in self.armature.pose.bones:
                if pb.name.lower() == name_lower:
                    return pb

        # Fuzzy partial match as last resort
        for name in names:
            name_lower = name.lower()
            for pb in self.armature.pose.bones:
                if name_lower in pb.name.lower() or pb.name.lower() in name_lower:
                    return pb

        return None

    def _import_position_track(self, pose_bone: bpy.types.PoseBone,
                               positions: List[tuple], action: bpy.types.Action):
        """Import position keyframes.

        Args:
            pose_bone: Target pose bone
            positions: List of (x, y, z) positions
            action: Blender action
        """
        data_path = f'pose.bones["{pose_bone.name}"].location'

        # Create F-curves for X, Y, Z
        for i in range(3):
            fcurve = action.fcurves.new(data_path=data_path, index=i)

            for frame, pos in enumerate(positions):
                # Convert position (BES to Blender coordinate system)
                # BES: Y-up, Blender: Z-up
                if i == 0:
                    value = pos[0]  # X stays X
                elif i == 1:
                    value = pos[2]  # BES Z -> Blender Y
                else:
                    value = pos[1]  # BES Y -> Blender Z

                # Scale factor (BES units to Blender units)
                value = value * 0.01  # Centimeters to meters

                keyframe = fcurve.keyframe_points.insert(frame, value)
                keyframe.interpolation = 'LINEAR'

    def _import_rotation_track(self, pose_bone: bpy.types.PoseBone,
                               rotations: List[tuple], action: bpy.types.Action):
        """Import rotation keyframes.

        Args:
            pose_bone: Target pose bone
            rotations: List of (w, x, y, z) quaternions
            action: Blender action
        """
        # Set rotation mode to quaternion
        pose_bone.rotation_mode = 'QUATERNION'

        data_path = f'pose.bones["{pose_bone.name}"].rotation_quaternion'

        # Create F-curves for W, X, Y, Z
        for i in range(4):
            fcurve = action.fcurves.new(data_path=data_path, index=i)

            for frame, rot in enumerate(rotations):
                # Convert quaternion (BES to Blender coordinate system)
                # BES: Y-up, Blender: Z-up
                if i == 0:
                    value = rot[0]  # W stays W
                elif i == 1:
                    value = rot[1]  # X stays X
                elif i == 2:
                    value = rot[3]  # BES Z -> Blender Y
                else:
                    value = rot[2]  # BES Y -> Blender Z

                keyframe = fcurve.keyframe_points.insert(frame, value)
                keyframe.interpolation = 'LINEAR'

    def import_events(self, sto_anim: STOAnimation):
        """Import animation events as markers.

        Args:
            sto_anim: Parsed STO animation events
        """
        action = self.armature.animation_data.action
        if action is None:
            return

        # Clear existing markers (Blender 4.x compatible)
        while len(action.pose_markers) > 0:
            action.pose_markers.remove(action.pose_markers[0])

        # Add markers for each event
        for event in sto_anim.events:
            # Calculate frame from time
            frame = int(round(event.time * self.stg_anim.fps))

            # Create pose marker
            marker = action.pose_markers.new(event.name)
            marker.frame = frame


def register():
    """Register operator."""
    pass


def unregister():
    """Unregister operator."""
    pass
