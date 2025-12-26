"""Simple BES reader test without Blender - direct file import."""

import sys
import os
import importlib.util

# Add project to path
project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_module(name, filepath):
    """Load a module directly from file path."""
    spec = importlib.util.spec_from_file_location(name, filepath)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

# Create fake parent packages
sys.modules['vietcong_bes'] = type(sys)('vietcong_bes')
sys.modules['vietcong_bes.core'] = type(sys)('vietcong_bes.core')
sys.modules['vietcong_bes.utils'] = type(sys)('vietcong_bes.utils')

# Load modules in dependency order
base_path = os.path.join(project_dir, 'vietcong_bes')

# Utils
binary_utils = load_module('vietcong_bes.utils.binary_utils', os.path.join(base_path, 'utils', 'binary_utils.py'))

# Core
constants = load_module('vietcong_bes.core.constants', os.path.join(base_path, 'core', 'constants.py'))
bes_types = load_module('vietcong_bes.core.bes_types', os.path.join(base_path, 'core', 'bes_types.py'))
chunk_parser = load_module('vietcong_bes.core.chunk_parser', os.path.join(base_path, 'core', 'chunk_parser.py'))
bes_reader = load_module('vietcong_bes.core.bes_reader', os.path.join(base_path, 'core', 'bes_reader.py'))

def main():
    test_file = sys.argv[1] if len(sys.argv) > 1 else os.path.join(project_dir, 'tests', 'CUP_BANGS.BES')

    print(f"Reading: {test_file}")

    try:
        bes = bes_reader.read_bes_file(test_file)
        print(f"Version: {bes.header.version}")
        print(f"Root node: {bes.root_node.name if bes.root_node else None}")

        def count_nodes(node, depth=0):
            if not node:
                return
            prefix = "  " * depth
            mesh_count = len(node.meshes) if node.meshes else 0
            child_count = len(node.children) if node.children else 0
            bone_count = len(node.bone_parts) if hasattr(node, 'bone_parts') and node.bone_parts else 0
            print(f"{prefix}{node.name}: meshes={mesh_count}, children={child_count}, bone_parts={bone_count}")

            # Show bone parts if present
            if hasattr(node, 'bone_parts') and node.bone_parts:
                for bp in node.bone_parts:
                    bp_meshes = len(bp.meshes) if bp.meshes else 0
                    bp_verts = sum(len(m.vertices) for m in bp.meshes) if bp.meshes else 0
                    print(f"{prefix}  [BONE] {bp.name}: meshes={bp_meshes}, vertices={bp_verts}")

            if node.children:
                for child in node.children:
                    count_nodes(child, depth + 1)

        count_nodes(bes.root_node)
        print("\nRead successfully!")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
