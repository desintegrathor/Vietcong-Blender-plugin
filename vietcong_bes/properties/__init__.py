# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Properties Module

Handles parsing and serialization of User Defined Properties
for synchronization between raw text and Blender UI.
"""

from .props_parser import (
    parse_user_properties,
    serialize_user_properties,
    apply_properties_to_object,
    read_properties_from_object,
    PROPERTY_KEYS,
)

__all__ = [
    'parse_user_properties',
    'serialize_user_properties',
    'apply_properties_to_object',
    'read_properties_from_object',
    'PROPERTY_KEYS',
]
