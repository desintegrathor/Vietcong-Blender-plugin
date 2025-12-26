#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Roundtrip test script for BES files.

Tests the read->write->read cycle without Blender.
Compares original and roundtrip BESFile structures.
"""

import sys
import os
import tempfile
import importlib.util
from typing import Tuple, List, Optional

# Get paths
test_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(test_dir)
vietcong_bes_dir = os.path.join(project_dir, 'vietcong_bes')


def load_module_direct(name, filepath):
    """Load a module directly from file path."""
    spec = importlib.util.spec_from_file_location(name, filepath)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


# Load dependencies in order (bypass Blender-dependent __init__.py)
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
sys.modules['vietcong_bes.core'].bes_reader = bes_reader

bes_writer = load_module_direct(
    'vietcong_bes.core.bes_writer',
    os.path.join(vietcong_bes_dir, 'core', 'bes_writer.py')
)
sys.modules['vietcong_bes.core'].bes_writer = bes_writer

bes_compare = load_module_direct(
    'vietcong_bes.core.bes_compare',
    os.path.join(vietcong_bes_dir, 'core', 'bes_compare.py')
)
sys.modules['vietcong_bes.core'].bes_compare = bes_compare

# Import what we need
read_bes_file = bes_reader.read_bes_file
write_bes_file = bes_writer.write_bes_file
compare_bes_files = bes_compare.compare_bes_files


def find_bes_files(directory: str) -> List[str]:
    """Find all BES files in directory and subdirectories."""
    bes_files = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.lower().endswith('.bes'):
                bes_files.append(os.path.join(root, f))
    return sorted(bes_files)


def roundtrip_single_file(filepath: str, verbose: bool = False) -> Tuple[bool, List[str], Optional[Exception]]:
    """Test roundtrip for a single BES file.

    Args:
        filepath: Path to BES file
        verbose: Print detailed information

    Returns:
        Tuple of (success, differences, exception)
    """
    try:
        # Read original file
        original = read_bes_file(filepath)

        # Write to temp file
        with tempfile.NamedTemporaryFile(suffix='.bes', delete=False) as tmp:
            tmp_path = tmp.name

        try:
            write_bes_file(tmp_path, original)

            # Read roundtrip file
            roundtrip = read_bes_file(tmp_path)

            # Compare structures
            result = compare_bes_files(original, roundtrip)

            if verbose and not result.equal:
                print(f"  Differences found:")
                for diff in result.differences[:10]:
                    print(f"    - {diff}")
                if len(result.differences) > 10:
                    print(f"    ... and {len(result.differences) - 10} more")

            return result.equal, result.differences, None

        finally:
            # Clean up temp file
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    except Exception as e:
        import traceback
        if verbose:
            print(f"  Exception: {e}")
            traceback.print_exc()
        return False, [], e


def main():
    """Main test function."""
    import argparse

    parser = argparse.ArgumentParser(description='BES Roundtrip Tests')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('-f', '--file', help='Test single file')
    parser.add_argument('--stop-on-fail', action='store_true', help='Stop on first failure')
    args = parser.parse_args()

    print("=" * 70)
    print("BES Roundtrip Tests")
    print("=" * 70)

    # Find files to test
    if args.file:
        if os.path.isabs(args.file):
            bes_files = [args.file]
        else:
            bes_files = [os.path.join(test_dir, args.file)]
    else:
        bes_files = find_bes_files(test_dir)

    if not bes_files:
        print("No BES files found!")
        return 1

    print(f"Found {len(bes_files)} BES file(s) to test\n")

    # Run tests
    passed = 0
    failed = 0
    errors = 0
    results = []

    for filepath in bes_files:
        rel_path = os.path.relpath(filepath, test_dir)
        print(f"Testing: {rel_path}", end=" ... ")

        success, diffs, exception = roundtrip_single_file(filepath, verbose=args.verbose)

        if exception:
            print(f"ERROR: {type(exception).__name__}: {exception}")
            errors += 1
            results.append((rel_path, 'ERROR', str(exception)))
        elif success:
            print("PASS")
            passed += 1
            results.append((rel_path, 'PASS', None))
        else:
            print(f"FAIL ({len(diffs)} differences)")
            failed += 1
            results.append((rel_path, 'FAIL', diffs))

        if args.stop_on_fail and (not success or exception):
            print("\nStopping on first failure")
            break

    # Print summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Errors: {errors}")
    print(f"Total:  {len(results)}")

    if failed > 0 or errors > 0:
        print("\nFailed files:")
        for rel_path, status, info in results:
            if status != 'PASS':
                print(f"  [{status}] {rel_path}")
                if status == 'FAIL' and info:
                    for diff in info[:3]:
                        print(f"         {diff}")
                    if len(info) > 3:
                        print(f"         ... and {len(info) - 3} more")

    return 0 if (failed == 0 and errors == 0) else 1


if __name__ == '__main__':
    sys.exit(main())
