#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Test script for BES file parsing.
Run this script directly to test BES parsing without Blender.
"""

import sys
import os
import importlib.util

# Get paths
test_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(test_dir)
vietcong_bes_dir = os.path.join(project_dir, 'vietcong_bes')

# Manually load modules to bypass the main __init__.py which requires bpy

def load_module_direct(name, filepath):
    """Load a module directly from file path."""
    spec = importlib.util.spec_from_file_location(name, filepath)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

# Load dependencies in order
binary_utils = load_module_direct(
    'vietcong_bes.utils.binary_utils',
    os.path.join(vietcong_bes_dir, 'utils', 'binary_utils.py')
)
sys.modules['vietcong_bes'] = type(sys)('vietcong_bes')
sys.modules['vietcong_bes.utils'] = type(sys)('vietcong_bes.utils')
sys.modules['vietcong_bes.utils'].binary_utils = binary_utils

constants = load_module_direct(
    'vietcong_bes.core.constants',
    os.path.join(vietcong_bes_dir, 'core', 'constants.py')
)
sys.modules['vietcong_bes.core'] = type(sys)('vietcong_bes.core')
sys.modules['vietcong_bes.core'].constants = constants

bes_types = load_module_direct(
    'vietcong_bes.core.bes_types',
    os.path.join(vietcong_bes_dir, 'core', 'bes_types.py')
)
sys.modules['vietcong_bes.core'].bes_types = bes_types

chunk_parser = load_module_direct(
    'vietcong_bes.core.chunk_parser',
    os.path.join(vietcong_bes_dir, 'core', 'chunk_parser.py')
)
sys.modules['vietcong_bes.core'].chunk_parser = chunk_parser

bes_reader = load_module_direct(
    'vietcong_bes.core.bes_reader',
    os.path.join(vietcong_bes_dir, 'core', 'bes_reader.py')
)

# Import what we need
read_bes_file = bes_reader.read_bes_file
BESPteroMat = bes_types.BESPteroMat
BESStandardMaterial = bes_types.BESStandardMaterial


def print_node_tree(node, indent=0):
    """Print node hierarchy."""
    prefix = "  " * indent
    name = node.get_visible_name()
    mesh_count = len(node.meshes)
    child_count = len(node.children)

    print(f"{prefix}- {name!r} (name_hash={node.name_hash})")
    if mesh_count > 0:
        print(f"{prefix}  Meshes: {mesh_count}")
        for mesh in node.meshes:
            vert_count = len(mesh.vertices)
            face_count = len(mesh.faces)
            print(f"{prefix}    - Material {mesh.material_index}: {vert_count} verts, {face_count} faces")

    if node.transform:
        t = node.transform
        print(f"{prefix}  Transform: pos={t.translation}, rot={t.rotation}, scale={t.scale}")

    if node.properties:
        print(f"{prefix}  Properties: {node.properties.properties}")

    for child in node.children:
        print_node_tree(child, indent + 1)


def test_bes_file(filepath):
    """Test parsing a single BES file."""
    print(f"\n{'='*60}")
    print(f"Testing: {os.path.basename(filepath)}")
    print(f"{'='*60}")

    try:
        bes_file = read_bes_file(filepath)

        # Header info
        print(f"\nHeader:")
        print(f"  Version: {bes_file.header.version}")
        print(f"  Exporter: {bes_file.header.exporter}")

        # Preview
        if bes_file.preview:
            print(f"\nPreview: {len(bes_file.preview.pixels)} bytes")

        # Info block
        if bes_file.info:
            print(f"\nInfo block:")
            print(f"  Author: {bes_file.info.author}")
            print(f"  Comment: {bes_file.info.comment}")
            print(f"  Total faces: {bes_file.info.total_faces}")

        # Materials
        print(f"\nMaterials: {len(bes_file.materials)}")
        for i, mat in enumerate(bes_file.materials):
            mat_type = "PteroMat" if isinstance(mat, BESPteroMat) else "Standard"
            print(f"  [{i}] {mat.name} ({mat_type})")
            if isinstance(mat, BESPteroMat):
                print(f"      Transparency: 0x{mat.transparency_type:04X}")
                print(f"      Collision: {mat.collision_material}")
                print(f"      Two-sided: {mat.two_sided}")
            if mat.textures:
                for slot, tex in mat.textures.items():
                    print(f"      Texture [{slot}]: {tex.filename}")

        # Scene hierarchy
        print(f"\nScene hierarchy:")
        if bes_file.root_node:
            print_node_tree(bes_file.root_node)
        else:
            print("  (no root node)")

        print(f"\nSUCCESS: File parsed correctly!")
        return True

    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main test function."""
    test_dir = os.path.dirname(os.path.abspath(__file__))

    # Find all BES files in test directory
    bes_files = [f for f in os.listdir(test_dir) if f.lower().endswith('.bes')]

    if not bes_files:
        print("No BES files found in tests/ directory")
        return 1

    print(f"Found {len(bes_files)} BES file(s) to test")

    success_count = 0
    for filename in sorted(bes_files):
        filepath = os.path.join(test_dir, filename)
        if test_bes_file(filepath):
            success_count += 1

    print(f"\n{'='*60}")
    print(f"Results: {success_count}/{len(bes_files)} files parsed successfully")
    print(f"{'='*60}")

    return 0 if success_count == len(bes_files) else 1


if __name__ == '__main__':
    sys.exit(main())
