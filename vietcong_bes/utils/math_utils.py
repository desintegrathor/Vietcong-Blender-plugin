# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Math Utilities

Coordinate system conversion between BES (DirectX) and Blender.

BES/DirectX: Left-handed, Y-up, Z-forward
  X = right
  Y = up
  Z = forward (into screen)

Blender: Right-handed, Z-up, Y-forward
  X = right
  Y = forward (into screen)
  Z = up
"""

import math
from typing import Tuple, List


def bes_to_blender_coords(pos: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert BES position to Blender coordinates.

    Args:
        pos: (X, Y, Z) in BES coordinate system

    Returns:
        (X, Y, Z) in Blender coordinate system
    """
    # BES: X-right, Y-up, Z-forward
    # Blender: X-right, Y-forward, Z-up
    return (pos[0], pos[2], pos[1])


def blender_to_bes_coords(pos: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert Blender position to BES coordinates.

    Args:
        pos: (X, Y, Z) in Blender coordinate system

    Returns:
        (X, Y, Z) in BES coordinate system
    """
    # Blender: X-right, Y-forward, Z-up
    # BES: X-right, Y-up, Z-forward
    return (pos[0], pos[2], pos[1])


def bes_to_blender_normal(normal: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert BES normal vector to Blender.

    Args:
        normal: Normal vector in BES coordinate system

    Returns:
        Normal vector in Blender coordinate system
    """
    return bes_to_blender_coords(normal)


def blender_to_bes_normal(normal: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert Blender normal vector to BES.

    Args:
        normal: Normal vector in Blender coordinate system

    Returns:
        Normal vector in BES coordinate system
    """
    return blender_to_bes_coords(normal)


def bes_to_blender_uv(uv: Tuple[float, float]) -> Tuple[float, float]:
    """Convert BES UV coordinates to Blender.

    BES uses DirectX UV convention where V=0 is at top.
    Blender uses V=0 at bottom.

    Args:
        uv: (U, V) in BES format

    Returns:
        (U, V) in Blender format
    """
    return (uv[0], 1.0 - uv[1])


def blender_to_bes_uv(uv: Tuple[float, float]) -> Tuple[float, float]:
    """Convert Blender UV coordinates to BES.

    Args:
        uv: (U, V) in Blender format

    Returns:
        (U, V) in BES format
    """
    return (uv[0], 1.0 - uv[1])


def bes_to_blender_rotation(rot: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert BES rotation (radians) to Blender Euler angles.

    BES (DirectX): Left-handed, Y-up
    Blender: Right-handed, Z-up

    Args:
        rot: (X, Y, Z) rotation in radians (BES format)

    Returns:
        (X, Y, Z) Euler angles in radians (Blender format)
    """
    # Swap Y and Z, negate Y (forward axis) for handedness
    return (rot[0], -rot[2], rot[1])


def blender_to_bes_rotation(rot: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert Blender Euler angles to BES rotation.

    Blender: Right-handed, Z-up
    BES (DirectX): Left-handed, Y-up

    Args:
        rot: (X, Y, Z) Euler angles in radians (Blender format)

    Returns:
        (X, Y, Z) rotation in radians (BES format)
    """
    # Swap Y and Z, negate Y (forward axis) for handedness
    return (rot[0], rot[2], -rot[1])


def bes_to_blender_scale(scale: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert BES scale to Blender scale.

    Args:
        scale: (X, Y, Z) scale in BES format

    Returns:
        (X, Y, Z) scale in Blender format
    """
    return (scale[0], scale[2], scale[1])


def blender_to_bes_scale(scale: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Convert Blender scale to BES scale.

    Args:
        scale: (X, Y, Z) scale in Blender format

    Returns:
        (X, Y, Z) scale in BES format
    """
    return (scale[0], scale[2], scale[1])


def bes_matrix_to_blender(matrix: List[List[float]]) -> List[List[float]]:
    """Convert BES 4x4 matrix to Blender matrix.

    NOTE: BES matrices may contain calculation errors.
    Prefer using decomposed translation/rotation/scale when available.

    Args:
        matrix: 4x4 transformation matrix in BES format (row-major)

    Returns:
        4x4 transformation matrix in Blender format
    """
    # Swap Y and Z rows and columns
    # Original indices: 0=X, 1=Y, 2=Z, 3=W
    # Swapped indices:  0=X, 1=Z, 2=Y, 3=W
    result = [[0.0] * 4 for _ in range(4)]

    swap = [0, 2, 1, 3]

    for i in range(4):
        for j in range(4):
            result[swap[i]][swap[j]] = matrix[i][j]

    return result


def blender_matrix_to_bes(matrix: List[List[float]]) -> List[List[float]]:
    """Convert Blender 4x4 matrix to BES matrix.

    Args:
        matrix: 4x4 transformation matrix in Blender format

    Returns:
        4x4 transformation matrix in BES format (row-major)
    """
    return bes_matrix_to_blender(matrix)  # Same transformation


def degrees_to_radians(degrees: float) -> float:
    """Convert degrees to radians."""
    return degrees * (math.pi / 180.0)


def radians_to_degrees(radians: float) -> float:
    """Convert radians to degrees."""
    return radians * (180.0 / math.pi)


def calculate_bounding_sphere_radius(vertices: List[Tuple[float, float, float]]) -> float:
    """Calculate bounding sphere radius from vertex positions.

    Args:
        vertices: List of (X, Y, Z) vertex positions

    Returns:
        Radius of bounding sphere centered at origin
    """
    if not vertices:
        return 0.0

    max_dist_sq = 0.0
    for v in vertices:
        dist_sq = v[0] * v[0] + v[1] * v[1] + v[2] * v[2]
        if dist_sq > max_dist_sq:
            max_dist_sq = dist_sq

    return math.sqrt(max_dist_sq)


def calculate_center_of_mass(vertices: List[Tuple[float, float, float]]) -> Tuple[float, float, float]:
    """Calculate center of mass from vertex positions.

    Args:
        vertices: List of (X, Y, Z) vertex positions

    Returns:
        (X, Y, Z) center of mass
    """
    if not vertices:
        return (0.0, 0.0, 0.0)

    sum_x = sum_y = sum_z = 0.0
    for v in vertices:
        sum_x += v[0]
        sum_y += v[1]
        sum_z += v[2]

    n = len(vertices)
    return (sum_x / n, sum_y / n, sum_z / n)


def normalize_vector(v: Tuple[float, float, float]) -> Tuple[float, float, float]:
    """Normalize a 3D vector.

    Args:
        v: (X, Y, Z) vector

    Returns:
        Normalized (X, Y, Z) vector
    """
    length = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    if length < 1e-10:
        return (0.0, 0.0, 0.0)
    return (v[0] / length, v[1] / length, v[2] / length)
