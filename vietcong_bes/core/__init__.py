# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Core module for BES format handling.

Contains constants, data types, and binary I/O utilities.
"""

from .constants import *
from .bes_types import *
from .bes_reader import BESReader
from .bes_writer import BESWriter
from .chunk_parser import ChunkParser


def register():
    """Register core module."""
    pass


def unregister():
    """Unregister core module."""
    pass
