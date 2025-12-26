#!/usr/bin/env python3
"""
BES Round-Trip Test Tool

Tests BES file reading and writing by:
1. Reading an original BES file
2. Writing it back out
3. Comparing the two files byte-by-byte

Usage:
    python bes_roundtrip.py <input.bes> [output.bes]
    python bes_roundtrip.py --dump <input.bes>
"""

import sys
import os
import struct
import importlib.util
from typing import List, Tuple

# Get paths
tools_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(tools_dir)
vietcong_bes_dir = os.path.join(project_dir, 'vietcong_bes')


def load_module_direct(name, filepath):
    """Load a module directly from file path."""
    spec = importlib.util.spec_from_file_location(name, filepath)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


# Load dependencies in order (bypassing __init__.py which requires bpy)
binary_utils = load_module_direct(
    'vietcong_bes.utils.binary_utils',
    os.path.join(vietcong_bes_dir, 'utils', 'binary_utils.py')
)
sys.modules['vietcong_bes'] = type(sys)('vietcong_bes')
sys.modules['vietcong_bes.utils'] = type(sys)('vietcong_bes.utils')
sys.modules['vietcong_bes.utils'].binary_utils = binary_utils

math_utils = load_module_direct(
    'vietcong_bes.utils.math_utils',
    os.path.join(vietcong_bes_dir, 'utils', 'math_utils.py')
)
sys.modules['vietcong_bes.utils'].math_utils = math_utils

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
sys.modules['vietcong_bes.core'].bes_reader = bes_reader

bes_writer = load_module_direct(
    'vietcong_bes.core.bes_writer',
    os.path.join(vietcong_bes_dir, 'core', 'bes_writer.py')
)
sys.modules['vietcong_bes.core'].bes_writer = bes_writer

# Import what we need
read_bes_file = bes_reader.read_bes_file
write_bes_file = bes_writer.write_bes_file
ChunkType = constants.ChunkType


def roundtrip_test(input_path: str, output_path: str) -> bool:
    """Read BES, write it back, compare bytes.

    Returns True if files match exactly.
    """
    print(f"Reading: {input_path}")
    try:
        bes_file = read_bes_file(input_path)
    except Exception as e:
        print(f"ERROR reading file: {e}")
        import traceback
        traceback.print_exc()
        return False

    print(f"  - Materials: {len(bes_file.materials)}")
    print(f"  - Root node: {bes_file.root_node.name if bes_file.root_node else 'None'}")
    if bes_file.root_node:
        print(f"  - Children: {len(bes_file.root_node.children)}")
        count_meshes(bes_file.root_node)

    print(f"\nWriting: {output_path}")
    try:
        write_bes_file(output_path, bes_file)
    except Exception as e:
        print(f"ERROR writing file: {e}")
        import traceback
        traceback.print_exc()
        return False

    # Compare bytes
    with open(input_path, 'rb') as f:
        original = f.read()
    with open(output_path, 'rb') as f:
        exported = f.read()

    print(f"\nComparison:")
    print(f"  Original: {len(original):,} bytes")
    print(f"  Exported: {len(exported):,} bytes")

    if original == exported:
        print("\n[OK] PERFECT MATCH!")
        return True
    else:
        print(f"\n[FAIL] Files differ")
        find_differences(original, exported)
        return False


def count_meshes(node, depth=0):
    """Count and print mesh info recursively."""
    indent = "  " * (depth + 1)
    if node.meshes:
        print(f"{indent}- {node.name}: {len(node.meshes)} mesh(es)")
    for child in node.children:
        count_meshes(child, depth + 1)


def find_differences(original: bytes, exported: bytes):
    """Find and display differences between two byte arrays."""
    # Find first difference
    first_diff = None
    for i in range(min(len(original), len(exported))):
        if original[i] != exported[i]:
            first_diff = i
            break

    if first_diff is not None:
        print(f"\nFirst difference at offset 0x{first_diff:X} ({first_diff}):")

        # Show context around the difference
        start = max(0, first_diff - 16)
        end = min(len(original), first_diff + 32)

        print(f"\n  Original bytes (0x{start:X} - 0x{end:X}):")
        hex_dump(original[start:end], start)

        end = min(len(exported), first_diff + 32)
        print(f"\n  Exported bytes (0x{start:X} - 0x{end:X}):")
        hex_dump(exported[start:end], start)

        # Try to identify what chunk we're in
        identify_chunk_at_offset(original, first_diff)

    elif len(original) != len(exported):
        print(f"\nFiles have same content but different lengths:")
        print(f"  Original ends at: 0x{len(original):X}")
        print(f"  Exported ends at: 0x{len(exported):X}")


def hex_dump(data: bytes, base_offset: int = 0):
    """Print hex dump of data."""
    for i in range(0, len(data), 16):
        offset = base_offset + i
        hex_part = ' '.join(f'{b:02x}' for b in data[i:i+16])
        ascii_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in data[i:i+16])
        print(f"    {offset:08X}  {hex_part:<48}  {ascii_part}")


def identify_chunk_at_offset(data: bytes, offset: int):
    """Try to identify what chunk contains the given offset."""
    # Skip header (16 bytes) and preview (12288 bytes)
    chunk_start = 16 + 12288

    print(f"\nSearching for chunk containing offset 0x{offset:X}...")

    chunks = []
    pos = chunk_start
    while pos + 8 <= len(data):
        chunk_type = struct.unpack('<I', data[pos:pos+4])[0]
        chunk_size = struct.unpack('<I', data[pos+4:pos+8])[0]

        if chunk_size < 8 or chunk_size > len(data) - pos:
            break

        chunks.append((pos, chunk_type, chunk_size))

        if pos <= offset < pos + chunk_size:
            try:
                type_name = ChunkType(chunk_type).name
            except ValueError:
                type_name = f"UNKNOWN"
            print(f"  Offset is inside chunk at 0x{pos:X}:")
            print(f"    Type: 0x{chunk_type:04X} ({type_name})")
            print(f"    Size: {chunk_size} bytes")
            print(f"    Relative offset: 0x{offset - pos:X} ({offset - pos} bytes into chunk)")
            return

        pos += chunk_size

    print(f"  Could not identify containing chunk")


def dump_chunks(path: str, max_depth: int = 10):
    """Dump chunk structure of BES file."""
    print(f"Dumping chunks from: {path}")

    with open(path, 'rb') as f:
        data = f.read()

    # Header
    print(f"\nHeader (16 bytes):")
    print(f"  Magic: {data[0:4]}")
    print(f"  Version: {data[4:8]}")

    # Skip preview
    chunk_start = 16 + 12288
    print(f"\nChunks start at offset 0x{chunk_start:X}")

    def parse_chunks(pos: int, end: int, depth: int) -> int:
        """Parse chunks recursively, return position after parsing."""
        while pos + 8 <= end and depth < max_depth:
            chunk_type = struct.unpack('<I', data[pos:pos+4])[0]
            chunk_size = struct.unpack('<I', data[pos+4:pos+8])[0]

            if chunk_size < 8 or pos + chunk_size > end:
                break

            indent = "  " * depth
            try:
                type_name = ChunkType(chunk_type).name
            except ValueError:
                type_name = f"UNKNOWN_0x{chunk_type:04X}"

            print(f"{indent}[0x{pos:08X}] {type_name} (size={chunk_size})")

            # For container chunks, parse children
            if chunk_type in [ChunkType.OBJECT, ChunkType.MODEL]:
                # Read child data first
                if chunk_type == ChunkType.OBJECT:
                    # OBJECT: hash(4) + name_len(4) + name + child_count(4)
                    if pos + 8 < end:
                        name_len = struct.unpack('<I', data[pos+12:pos+16])[0]
                        name = data[pos+16:pos+16+name_len].decode('utf-8', errors='replace').rstrip('\x00')
                        child_count = struct.unpack('<I', data[pos+16+name_len:pos+20+name_len])[0]
                        print(f"{indent}  name=\"{name}\" children={child_count}")
                        # Parse nested chunks after OBJECT header
                        child_start = pos + 20 + name_len
                        parse_chunks(child_start, pos + chunk_size, depth + 1)
                elif chunk_type == ChunkType.MODEL:
                    # MODEL contains MESH chunks
                    parse_chunks(pos + 8, pos + chunk_size, depth + 1)

            pos += chunk_size
        return pos

    parse_chunks(chunk_start, len(data), 0)


def compare_chunk_structure(path1: str, path2: str):
    """Compare chunk structure of two BES files."""
    print(f"Comparing chunk structures:")
    print(f"  File 1: {path1}")
    print(f"  File 2: {path2}")

    def get_chunks(path: str) -> List[Tuple[int, int, int]]:
        """Get list of (offset, type, size) for all top-level chunks."""
        with open(path, 'rb') as f:
            data = f.read()

        chunks = []
        pos = 16 + 12288  # Skip header and preview

        while pos + 8 <= len(data):
            chunk_type = struct.unpack('<I', data[pos:pos+4])[0]
            chunk_size = struct.unpack('<I', data[pos+4:pos+8])[0]

            if chunk_size < 8 or pos + chunk_size > len(data):
                break

            chunks.append((pos, chunk_type, chunk_size))
            pos += chunk_size

        return chunks

    chunks1 = get_chunks(path1)
    chunks2 = get_chunks(path2)

    print(f"\n  File 1: {len(chunks1)} chunks")
    print(f"  File 2: {len(chunks2)} chunks")

    # Compare chunk types
    types1 = [c[1] for c in chunks1]
    types2 = [c[1] for c in chunks2]

    if types1 == types2:
        print("\n  Chunk types: MATCH")
    else:
        print("\n  Chunk types: DIFFER")
        for i, (t1, t2) in enumerate(zip(types1, types2)):
            if t1 != t2:
                try:
                    n1 = ChunkType(t1).name
                except ValueError:
                    n1 = f"0x{t1:04X}"
                try:
                    n2 = ChunkType(t2).name
                except ValueError:
                    n2 = f"0x{t2:04X}"
                print(f"    Chunk {i}: {n1} vs {n2}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    if sys.argv[1] == '--dump':
        if len(sys.argv) < 3:
            print("Usage: python bes_roundtrip.py --dump <input.bes>")
            sys.exit(1)
        dump_chunks(sys.argv[2])
    elif sys.argv[1] == '--compare':
        if len(sys.argv) < 4:
            print("Usage: python bes_roundtrip.py --compare <file1.bes> <file2.bes>")
            sys.exit(1)
        compare_chunk_structure(sys.argv[2], sys.argv[3])
    else:
        input_path = sys.argv[1]
        output_path = sys.argv[2] if len(sys.argv) > 2 else input_path.replace('.bes', '_roundtrip.bes')

        success = roundtrip_test(input_path, output_path)
        sys.exit(0 if success else 1)
