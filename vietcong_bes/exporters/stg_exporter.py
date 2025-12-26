# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
STG Animation Exporter

Exports Blender animations to Vietcong STG format.
"""

import bpy
import os
from typing import Optional, Dict, List, Tuple

from ..core.stg_parser import STGAnimation, STGBoneTrack
from ..core.stg_writer import write_stg_file
from ..core.sto_parser import STOAnimation, STOEvent
from ..core.sto_writer import write_sto_file


def export_stg(context, filepath: str, armature: bpy.types.Object = None, **options) -> set:
    """Export animation from Blender to STG file.

    Args:
        context: Blender context
        filepath: Output STG file path
        armature: Source armature object (optional, auto-detect if None)
        **options: Export options

    Returns:
        {'FINISHED'} on success, {'CANCELLED'} on failure
    """
    try:
        # Find source armature
        if armature is None:
            armature = find_armature(context)

        if armature is None:
            print("STG Export Error: No armature found")
            return {'CANCELLED'}

        if armature.animation_data is None or armature.animation_data.action is None:
            print("STG Export Error: Armature has no animation")
            return {'CANCELLED'}

        # Create exporter instance
        exporter = STGExporter(context, armature, options)
        stg_anim = exporter.export_animation()

        # Write STG file
        write_stg_file(filepath, stg_anim)

        # Export STO events if there are pose markers
        action = armature.animation_data.action
        if len(action.pose_markers) > 0:
            sto_anim = exporter.export_events()
            sto_path = filepath.replace('.STG', '.STO').replace('.stg', '.sto')
            write_sto_file(sto_path, sto_anim)

        return {'FINISHED'}

    except Exception as e:
        print(f"STG Export Error: {e}")
        import traceback
        traceback.print_exc()
        return {'CANCELLED'}


def find_armature(context) -> Optional[bpy.types.Object]:
    """Find armature in scene."""
    for obj in context.selected_objects:
        if obj.type == 'ARMATURE':
            return obj

    if context.active_object and context.active_object.type == 'ARMATURE':
        return context.active_object

    for obj in context.scene.objects:
        if obj.type == 'ARMATURE':
            return obj

    return None


class STGExporter:
    """Blender to STG animation exporter."""

    # Reverse mapping from bone name to STG index
    BONE_NAME_TO_INDEX = {
        'pelvis': 0, 'Hips': 0, 'Root': 0, 'Bip01': 0,
        'L_thigh': 1, 'LeftHip': 1,
        'L_calf': 2, 'LeftKnee': 2,
        'L_foot': 3, 'LeftAnkle': 3, 'LFoot': 3,
        'L_toe0': 4, 'LToe': 4,
        'L_toe0Nub': 5, 'LToeNub': 5,
        'R_thigh': 6, 'RightHip': 6,
        'R_calf': 7, 'RightKnee': 7,
        'R_foot': 8, 'RightAnkle': 8, 'RFoot': 8,
        'R_toe0': 9, 'RToe': 9,
        'R_toe0Nub': 10, 'RToeNub': 10,
        'spine': 11, 'Chest': 11,
        'spine1': 12, 'Chest2': 12,
        'neck': 13, 'Neck': 13,
        'head': 14, 'Head': 14,
        'headNub': 15, 'HeadTop': 15,
        'L_clavicle': 16, 'LeftCollar': 16,
        'L_upper_arm': 17, 'LeftShoulder': 17,
        'L_forearm': 18, 'LeftElbow': 18,
        'L_hand': 19, 'LeftWrist': 19,
        'L_finger0': 20, 'LeftFingers': 20,
        'L_finger0Nub': 21, 'LeftFingersNub': 21,
        'R_clavicle': 22, 'RightCollar': 22,
        'R_upper_arm': 23, 'RightShoulder': 23,
        'R_forearm': 24, 'RightElbow': 24,
        'R_hand': 25, 'RightWrist': 25,
        'R_finger0': 26, 'RightFingers': 26,
        'R_finger0Nub': 27, 'RightFingersNub': 27,
    }

    def __init__(self, context, armature: bpy.types.Object, options: dict):
        """Initialize exporter.

        Args:
            context: Blender context
            armature: Source armature
            options: Export options
        """
        self.context = context
        self.armature = armature
        self.options = options
        self.action = armature.animation_data.action

    def export_animation(self) -> STGAnimation:
        """Export animation data from armature."""
        action = self.action

        # Calculate frame range
        frame_start = int(self.context.scene.frame_start)
        frame_end = int(self.context.scene.frame_end)
        frame_count = frame_end - frame_start + 1

        # Calculate duration and FPS
        fps = self.context.scene.render.fps / self.context.scene.render.fps_base
        duration = (frame_count - 1) / fps if fps > 0 else 0.0

        anim = STGAnimation(
            filename=os.path.basename(action.name),
            version=1,
            duration=duration,
            frame_count=frame_count,
            fps=fps
        )

        # Collect bone tracks from F-curves
        bone_tracks: Dict[int, STGBoneTrack] = {}

        # Group F-curves by bone
        bone_fcurves: Dict[str, Dict[str, List]] = {}

        for fcurve in action.fcurves:
            # Parse data path like 'pose.bones["pelvis"].location'
            if not fcurve.data_path.startswith('pose.bones["'):
                continue

            try:
                # Extract bone name
                start = fcurve.data_path.index('["') + 2
                end = fcurve.data_path.index('"]')
                bone_name = fcurve.data_path[start:end]

                # Determine property type
                if '.location' in fcurve.data_path:
                    prop_type = 'location'
                elif '.rotation_quaternion' in fcurve.data_path:
                    prop_type = 'rotation_quaternion'
                else:
                    continue

                if bone_name not in bone_fcurves:
                    bone_fcurves[bone_name] = {'location': [], 'rotation_quaternion': []}

                bone_fcurves[bone_name][prop_type].append(fcurve)

            except (ValueError, IndexError):
                continue

        # Process each bone
        for bone_name, curves in bone_fcurves.items():
            bone_index = self._get_bone_index(bone_name)
            if bone_index is None:
                continue

            if bone_index not in bone_tracks:
                bone_tracks[bone_index] = STGBoneTrack(bone_index=bone_index)

            track = bone_tracks[bone_index]

            # Extract position keyframes
            loc_curves = curves.get('location', [])
            if len(loc_curves) >= 3:
                track.has_position = True
                for frame in range(frame_start, frame_end + 1):
                    # Evaluate F-curves at frame
                    x = self._evaluate_fcurve(loc_curves, 0, frame)
                    y = self._evaluate_fcurve(loc_curves, 1, frame)
                    z = self._evaluate_fcurve(loc_curves, 2, frame)

                    # Convert from Blender to BES coordinates (Z-up to Y-up)
                    # Blender: X right, Y forward, Z up
                    # BES: X right, Y up, Z forward
                    bx = x * 100.0  # Meters to centimeters
                    by = z * 100.0  # Blender Z -> BES Y
                    bz = y * 100.0  # Blender Y -> BES Z

                    track.positions.append((bx, by, bz))

            # Extract rotation keyframes
            rot_curves = curves.get('rotation_quaternion', [])
            if len(rot_curves) >= 4:
                track.has_rotation = True
                for frame in range(frame_start, frame_end + 1):
                    # Evaluate F-curves at frame (W, X, Y, Z order)
                    w = self._evaluate_fcurve(rot_curves, 0, frame)
                    x = self._evaluate_fcurve(rot_curves, 1, frame)
                    y = self._evaluate_fcurve(rot_curves, 2, frame)
                    z = self._evaluate_fcurve(rot_curves, 3, frame)

                    # Convert from Blender to BES coordinates
                    # Swap Y and Z components
                    bw = w
                    bx = x
                    by = z  # Blender Z -> BES Y
                    bz = y  # Blender Y -> BES Z

                    track.rotations.append((bw, bx, by, bz))

        anim.bone_tracks = list(bone_tracks.values())
        return anim

    def export_events(self) -> STOAnimation:
        """Export pose markers as STO events."""
        action = self.action
        fps = self.context.scene.render.fps / self.context.scene.render.fps_base

        sto = STOAnimation(
            filename=os.path.basename(action.name),
            version=1
        )

        for marker in action.pose_markers:
            time = marker.frame / fps if fps > 0 else 0.0
            sto.events.append(STOEvent(
                name=marker.name,
                time=time,
                data=(0, 0, 0, 0)
            ))

        return sto

    def _get_bone_index(self, bone_name: str) -> Optional[int]:
        """Get STG bone index for bone name."""
        # Direct lookup
        if bone_name in self.BONE_NAME_TO_INDEX:
            return self.BONE_NAME_TO_INDEX[bone_name]

        # Case-insensitive lookup
        name_lower = bone_name.lower()
        for name, idx in self.BONE_NAME_TO_INDEX.items():
            if name.lower() == name_lower:
                return idx

        # Partial match
        for name, idx in self.BONE_NAME_TO_INDEX.items():
            if name.lower() in name_lower or name_lower in name.lower():
                return idx

        return None

    def _evaluate_fcurve(self, curves: List, index: int, frame: float) -> float:
        """Evaluate F-curve at frame."""
        for curve in curves:
            if curve.array_index == index:
                return curve.evaluate(frame)
        return 0.0


def register():
    """Register exporter."""
    pass


def unregister():
    """Unregister exporter."""
    pass
