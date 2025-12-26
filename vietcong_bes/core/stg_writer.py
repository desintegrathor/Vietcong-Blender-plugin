# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
STG Animation Writer

Writes Vietcong STG animation files (Ptero-Engine-II Animation data).
"""

import struct
import math
from typing import List, Tuple
from .stg_parser import STGAnimation, STGBoneTrack


def quaternion_to_euler(w: float, x: float, y: float, z: float) -> Tuple[float, float, float]:
    """Convert quaternion to Euler angles (degrees).

    Reverses the engine's euler_to_quaternion conversion:
    - Rotation order: Y * Z * X (intrinsic) = X * Z * Y (extrinsic)
    - Y and Z angles were negated during conversion

    Args:
        w, x, y, z: Quaternion components

    Returns:
        Tuple of (rx, ry, rz) in degrees
    """
    # Normalize quaternion
    mag = math.sqrt(w*w + x*x + y*y + z*z)
    if mag > 0:
        w, x, y, z = w/mag, x/mag, y/mag, z/mag

    # Convert quaternion to rotation matrix elements
    # For YZX order extraction
    m11 = 1.0 - 2.0 * (y*y + z*z)
    m12 = 2.0 * (x*y - w*z)
    m13 = 2.0 * (x*z + w*y)
    m21 = 2.0 * (x*y + w*z)
    m22 = 1.0 - 2.0 * (x*x + z*z)
    m23 = 2.0 * (y*z - w*x)
    m31 = 2.0 * (x*z - w*y)
    m32 = 2.0 * (y*z + w*x)
    m33 = 1.0 - 2.0 * (x*x + y*y)

    # Extract YZX Euler angles
    # Based on: R = Ry * Rz * Rx
    if abs(m21) < 0.99999:
        rz = math.asin(max(-1.0, min(1.0, m21)))
        ry = math.atan2(-m31, m11)
        rx = math.atan2(-m23, m22)
    else:
        # Gimbal lock
        rz = math.copysign(math.pi / 2, m21)
        ry = math.atan2(m13, m33)
        rx = 0.0

    # Convert to degrees
    RAD_TO_DEG = 180.0 / math.pi

    # Undo the negation that was applied during import
    rx_deg = rx * RAD_TO_DEG
    ry_deg = -ry * RAD_TO_DEG  # Was negated
    rz_deg = -rz * RAD_TO_DEG  # Was negated

    return (rx_deg, ry_deg, rz_deg)


class STGWriter:
    """Writer for STG animation files."""

    MAGIC = b'STG\xFF'

    def __init__(self, anim: STGAnimation):
        """Initialize writer.

        Args:
            anim: Animation data to write
        """
        self.anim = anim

    def write(self, filepath: str):
        """Write animation to STG file.

        Args:
            filepath: Output file path
        """
        with open(filepath, 'wb') as f:
            self._write_to_file(f)

    def _write_to_file(self, f):
        """Write animation data to file object."""
        # Prepare track data
        position_tracks = []
        rotation_tracks = []

        for track in self.anim.bone_tracks:
            if track.has_position and track.positions:
                position_tracks.append(track)
            if track.has_rotation and track.rotations:
                rotation_tracks.append(track)

        # Build bone_indices (only for rotation tracks, position is always bone 0)
        bone_indices = bytes([t.bone_index for t in rotation_tracks])

        # Build bone_types (triplets)
        # Position tracks: 0, 1, 2
        # Rotation tracks: 3, 4, 5
        bone_types = bytearray()
        for _ in position_tracks:
            bone_types.extend([0, 1, 2])
        for _ in rotation_tracks:
            bone_types.extend([3, 4, 5])

        num_tracks = len(position_tracks) + len(rotation_tracks)
        num_components = num_tracks * 3

        # Write header
        f.write(self.MAGIC)
        f.write(struct.pack('<I', self.anim.version))
        f.write(struct.pack('<f', self.anim.duration))
        f.write(struct.pack('<I', self.anim.frame_count))
        f.write(struct.pack('<I', num_components))
        f.write(struct.pack('<I', len(bone_indices)))

        # Write bone indices
        f.write(bone_indices)

        # Write bone types
        f.write(bytes(bone_types))

        # Write frame data
        for frame_idx in range(self.anim.frame_count):
            # Position tracks first
            for track in position_tracks:
                if frame_idx < len(track.positions):
                    pos = track.positions[frame_idx]
                else:
                    pos = (0.0, 0.0, 0.0)
                f.write(struct.pack('<fff', pos[0], pos[1], pos[2]))

            # Rotation tracks
            for track in rotation_tracks:
                if frame_idx < len(track.rotations):
                    quat = track.rotations[frame_idx]
                    # Convert quaternion back to Euler angles
                    euler = quaternion_to_euler(quat[0], quat[1], quat[2], quat[3])
                else:
                    euler = (0.0, 0.0, 0.0)
                f.write(struct.pack('<fff', euler[0], euler[1], euler[2]))


def write_stg_file(filepath: str, anim: STGAnimation):
    """Write an STG animation file.

    Args:
        filepath: Output file path
        anim: Animation data to write
    """
    writer = STGWriter(anim)
    writer.write(filepath)
