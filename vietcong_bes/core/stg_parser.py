# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
STG Animation Parser

Parses Vietcong STG animation files (Ptero-Engine-II Animation data).

STG Format Structure (verified from IDA analysis of logs.dll):
- Header (24 bytes):
  - Magic: "STG\xFF" (4 bytes)
  - Version: uint32 (0 or 1)
  - Animation length: float (seconds)
  - Frame count: uint32 (actual count)
  - Num components: uint32 (number of type bytes = triplets * 3)
  - Bone indices size: uint32 (number of bone index bytes)

- Bone indices: uint8[bone_indices_size] - which skeleton bones are animated
- Bone types: uint8[num_components] - component types (0,1,2=position, 3,4,5=rotation)
  - Processed in triplets of 3 bytes
  - Each triplet = one animation track

- Frame data:
  - For each frame, for each type triplet:
    - Position (types 0,1,2): 3 floats (X, Y, Z)
    - Rotation (types 3,4,5): 3 floats (degrees) - Euler angles

Data size formula: bone_indices_size + num_components * (4 * frame_count + 1)

Rotation order: Y * Z * X (based on IDA analysis)
Euler angles are converted to quaternions in-engine.
"""

import struct
import math
from dataclasses import dataclass, field
from typing import List, Tuple, Optional
from ..utils.binary_utils import BinaryReader


@dataclass
class STGBoneTrack:
    """Animation track for a single bone."""
    bone_index: int
    has_position: bool = False
    has_rotation: bool = False
    positions: List[Tuple[float, float, float]] = field(default_factory=list)
    rotations: List[Tuple[float, float, float, float]] = field(default_factory=list)  # Quaternions


@dataclass
class STGAnimation:
    """Parsed STG animation data."""
    filename: str = ''
    version: int = 1
    duration: float = 0.0  # In seconds
    frame_count: int = 0
    fps: float = 30.0  # Assumed FPS
    bone_tracks: List[STGBoneTrack] = field(default_factory=list)

    # Raw data for roundtrip
    raw_bone_indices: bytes = b''
    raw_bone_types: bytes = b''


def euler_to_quaternion(rx: float, ry: float, rz: float) -> Tuple[float, float, float, float]:
    """Convert Euler angles (degrees) to quaternion.

    Matches the engine's conversion:
    - Rotation order: Y * Z * X
    - Y and Z angles are negated
    - Uses half-angles for quaternion

    Args:
        rx: Rotation around X axis (degrees)
        ry: Rotation around Y axis (degrees)
        rz: Rotation around Z axis (degrees)

    Returns:
        Quaternion as (w, x, y, z)
    """
    # Convert to radians and apply half-angle
    # Engine uses 0.0087266462 = pi/360 = deg_to_rad / 2
    DEG_TO_HALF_RAD = math.pi / 360.0

    # Engine negates Y and Z
    half_x = rx * DEG_TO_HALF_RAD
    half_y = -ry * DEG_TO_HALF_RAD
    half_z = -rz * DEG_TO_HALF_RAD

    # Create axis quaternions
    # qy = (cos(half_y), sin(half_y), 0, 0)
    cy, sy = math.cos(half_y), math.sin(half_y)
    qy = (cy, sy, 0.0, 0.0)

    # qx = (cos(half_x), 0, sin(half_x), 0)
    cx, sx = math.cos(half_x), math.sin(half_x)
    qx = (cx, 0.0, sx, 0.0)

    # qz = (cos(half_z), 0, 0, sin(half_z))
    cz, sz = math.cos(half_z), math.sin(half_z)
    qz = (cz, 0.0, 0.0, sz)

    # Multiply: result = qz * qy
    def quat_mul(a, b):
        w = a[0]*b[0] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3]
        x = a[1]*b[0] + a[0]*b[1] + a[3]*b[2] - a[2]*b[3]
        y = a[2]*b[0] + a[0]*b[2] + a[1]*b[3] - a[3]*b[1]
        z = a[3]*b[0] + a[0]*b[3] + a[2]*b[1] - a[1]*b[2]
        return (w, x, y, z)

    # Order: Y * Z * X (from engine analysis)
    temp = quat_mul(qz, qy)
    result = quat_mul(temp, qx)

    # Clean up near-zero values (engine does this)
    def clean(v):
        if abs(v) < 0.0001:
            return 0.0
        return v

    return (clean(result[0]), clean(result[1]), clean(result[2]), clean(result[3]))


class STGParser:
    """Parser for STG animation files."""

    MAGIC_NEW = b'STG\xFF'  # 0xFF475453 little-endian
    MAGIC_OLD = b'STGI'     # 0x49475453 little-endian

    def __init__(self, filepath: str):
        self.filepath = filepath
        self._reader: Optional[BinaryReader] = None

    def parse(self) -> STGAnimation:
        """Parse STG file and return animation data."""
        self._reader = BinaryReader(self.filepath)

        try:
            anim = STGAnimation(filename=self.filepath)

            # Read and check magic
            magic = self._reader.read(4)

            if magic == self.MAGIC_OLD:
                return self._parse_old_format(anim)
            elif magic == self.MAGIC_NEW:
                return self._parse_new_format(anim)
            else:
                raise ValueError(f"Unknown STG magic: {magic.hex()}")

        finally:
            self._reader.close()

    def _parse_new_format(self, anim: STGAnimation) -> STGAnimation:
        """Parse new STG format (STG\xFF magic)."""
        # Version
        anim.version = self._reader.read_uint32()
        if anim.version > 1:
            raise ValueError(f"Unsupported STG version: {anim.version}")

        # Header structure (verified from IDA analysis):
        # 0x08: animation_length (float) - duration in seconds
        # 0x0C: frame_count (uint32) - actual frame count
        # 0x10: num_components (uint32) - number of type bytes (triplets * 3)
        # 0x14: bone_indices_size (uint32) - number of bone index bytes

        anim.duration = self._reader.read_float()
        anim.frame_count = self._reader.read_uint32()  # Actual count (not minus 1!)
        num_components = self._reader.read_uint32()
        bone_indices_size = self._reader.read_uint32()

        # Calculate FPS from duration and frame count
        if anim.duration > 0 and anim.frame_count > 1:
            anim.fps = (anim.frame_count - 1) / anim.duration

        # Read bone indices
        anim.raw_bone_indices = self._reader.read(bone_indices_size)
        bone_indices = list(anim.raw_bone_indices)

        # Read ALL type bytes (num_components of them)
        anim.raw_bone_types = self._reader.read(num_components)
        bone_types = list(anim.raw_bone_types)

        # Calculate number of animation tracks (triplets)
        num_tracks = num_components // 3

        # Create bone tracks
        # Track mapping: first track with position goes to bone 0,
        # then rotation tracks map to bone_indices in order
        bone_track_map = {}  # bone_index -> STGBoneTrack
        track_to_bone = []  # track_index -> bone_index

        bone_idx_ptr = 0
        for track_idx in range(num_tracks):
            type_offset = track_idx * 3
            t0 = bone_types[type_offset]

            if t0 in (0, 1, 2):
                # Position track - always for bone 0 (root)
                bone_idx = 0
            else:
                # Rotation track - get bone from bone_indices
                if bone_idx_ptr < len(bone_indices):
                    bone_idx = bone_indices[bone_idx_ptr]
                    bone_idx_ptr += 1
                else:
                    bone_idx = 0  # Fallback

            track_to_bone.append(bone_idx)

            if bone_idx not in bone_track_map:
                bone_track_map[bone_idx] = STGBoneTrack(bone_index=bone_idx)

            track = bone_track_map[bone_idx]
            if t0 in (0, 1, 2):
                track.has_position = True
            elif t0 in (3, 4, 5):
                track.has_rotation = True

        # Read frame data
        for frame in range(anim.frame_count):
            for track_idx in range(num_tracks):
                type_offset = track_idx * 3
                t0 = bone_types[type_offset]
                bone_idx = track_to_bone[track_idx]
                track = bone_track_map[bone_idx]

                if t0 in (0, 1, 2):
                    # Position data (3 floats)
                    x = self._reader.read_float()
                    y = self._reader.read_float()
                    z = self._reader.read_float()
                    track.positions.append((x, y, z))
                elif t0 in (3, 4, 5):
                    # Rotation data (3 floats - euler degrees)
                    rx = self._reader.read_float()
                    ry = self._reader.read_float()
                    rz = self._reader.read_float()
                    # Convert to quaternion
                    quat = euler_to_quaternion(rx, ry, rz)
                    track.rotations.append(quat)

        anim.bone_tracks = list(bone_track_map.values())
        return anim

    def _parse_old_format(self, anim: STGAnimation) -> STGAnimation:
        """Parse old STG format (STGI magic)."""
        # Old format has different structure
        # For now, just read basic info
        anim.version = 0

        # TODO: Implement old format parsing if needed
        # Based on IDA: calls sub_101078D0

        raise NotImplementedError("Old STG format (STGI) not yet implemented")


def read_stg_file(filepath: str) -> STGAnimation:
    """Read and parse an STG animation file.

    Args:
        filepath: Path to STG file

    Returns:
        Parsed STGAnimation object
    """
    parser = STGParser(filepath)
    return parser.parse()
