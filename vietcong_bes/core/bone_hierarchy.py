# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
ISKE Bone Hierarchy Reconstruction

Reconstructs parent-child bone relationships from ISKE bone names.
Based on standard humanoid skeleton structure used in Vietcong.

Bone names discovered from IDA analysis of logs.dll (sub_1008F8D0).
"""

from typing import Optional, List, Dict

# Parent mapping: bone_name -> parent_name (None for root)
ISKE_BONE_PARENTS = {
    # Root
    'Hips': None,

    # Left leg chain
    'LeftHip': 'Hips',
    'LeftKnee': 'LeftHip',
    'LeftAnkle': 'LeftKnee',
    'LFoot': 'LeftAnkle',
    'LToe': 'LFoot',

    # Right leg chain
    'RightHip': 'Hips',
    'RightKnee': 'RightHip',
    'RightAnkle': 'RightKnee',
    'RFoot': 'RightAnkle',
    'RToe': 'RFoot',

    # Spine
    'Chest': 'Hips',

    # Left arm chain
    'LeftCollar': 'Chest',
    'LeftShoulder': 'LeftCollar',
    'LeftElbow': 'LeftShoulder',
    'LeftWrist': 'LeftElbow',
    'LeftFingers': 'LeftWrist',

    # Right arm chain
    'RightCollar': 'Chest',
    'RightShoulder': 'RightCollar',
    'RightElbow': 'RightShoulder',
    'RightWrist': 'RightElbow',
    'RightFingers': 'RightWrist',

    # Head chain
    'Neck': 'Chest',
    'Head': 'Neck',
    'HeadTop': 'Head',

    # Weapon attachment
    'Weapon': 'RightWrist',
}


def get_bone_parent(bone_name: str) -> Optional[str]:
    """Get parent bone name for ISKE bone.

    Args:
        bone_name: Name of the bone

    Returns:
        Parent bone name, or None if root or unknown
    """
    return ISKE_BONE_PARENTS.get(bone_name)


def build_bone_hierarchy(bone_names: List[str]) -> Dict[Optional[str], List[str]]:
    """Build hierarchy dict from list of bone names.

    Args:
        bone_names: List of bone names found in file

    Returns:
        Dict mapping parent -> [children]
        Key None contains root bones
    """
    hierarchy: Dict[Optional[str], List[str]] = {}
    for name in bone_names:
        parent = get_bone_parent(name)
        if parent not in hierarchy:
            hierarchy[parent] = []
        hierarchy[parent].append(name)
    return hierarchy


def get_root_bones(bone_names: List[str]) -> List[str]:
    """Get bones that have no parent (roots).

    Args:
        bone_names: List of bone names

    Returns:
        List of root bone names
    """
    roots = []
    for name in bone_names:
        if get_bone_parent(name) is None:
            roots.append(name)
    return roots


def get_bone_chain(bone_name: str) -> List[str]:
    """Get full bone chain from root to this bone.

    Args:
        bone_name: Name of the target bone

    Returns:
        List of bone names from root to target (inclusive)
    """
    chain = []
    current = bone_name
    while current is not None:
        chain.append(current)
        current = get_bone_parent(current)
    chain.reverse()
    return chain


def is_known_bone(bone_name: str) -> bool:
    """Check if bone name is in the known ISKE hierarchy.

    Args:
        bone_name: Name to check

    Returns:
        True if bone name is recognized
    """
    return bone_name in ISKE_BONE_PARENTS
