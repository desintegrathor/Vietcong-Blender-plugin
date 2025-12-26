# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Utility functions for BES plugin.
"""

from .binary_utils import BinaryReader, BinaryWriter, ChunkBuilder
from .math_utils import (
    bes_to_blender_coords,
    blender_to_bes_coords,
    bes_to_blender_uv,
    blender_to_bes_uv,
    bes_to_blender_rotation,
    blender_to_bes_rotation,
    bes_to_blender_scale,
    blender_to_bes_scale,
    bes_matrix_to_blender,
    blender_matrix_to_bes,
    calculate_bounding_sphere_radius,
    calculate_center_of_mass,
    normalize_vector,
)


def register():
    """Register utilities module."""
    pass


def unregister():
    """Unregister utilities module."""
    pass
