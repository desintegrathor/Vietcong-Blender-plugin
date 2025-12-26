#!/usr/bin/env python3
"""Quick roundtrip test - prints results for all BES files fast."""

import sys
import os
import tempfile

# Setup paths
test_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(test_dir)
sys.path.insert(0, project_dir)

# Import directly (avoiding the slow module loading)
vietcong_bes_dir = os.path.join(project_dir, 'vietcong_bes')
import importlib.util

def load_mod(name, filepath):
    spec = importlib.util.spec_from_file_location(name, filepath)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

# Load modules once
sys.modules['vietcong_bes'] = type(sys)('vietcong_bes')
sys.modules['vietcong_bes.utils'] = type(sys)('vietcong_bes.utils')
sys.modules['vietcong_bes.core'] = type(sys)('vietcong_bes.core')

binary_utils = load_mod('vietcong_bes.utils.binary_utils',
                         os.path.join(vietcong_bes_dir, 'utils', 'binary_utils.py'))
sys.modules['vietcong_bes.utils'].binary_utils = binary_utils

constants = load_mod('vietcong_bes.core.constants',
                     os.path.join(vietcong_bes_dir, 'core', 'constants.py'))
sys.modules['vietcong_bes.core'].constants = constants

bes_types = load_mod('vietcong_bes.core.bes_types',
                     os.path.join(vietcong_bes_dir, 'core', 'bes_types.py'))
sys.modules['vietcong_bes.core'].bes_types = bes_types

chunk_parser = load_mod('vietcong_bes.core.chunk_parser',
                        os.path.join(vietcong_bes_dir, 'core', 'chunk_parser.py'))
sys.modules['vietcong_bes.core'].chunk_parser = chunk_parser

bes_reader = load_mod('vietcong_bes.core.bes_reader',
                      os.path.join(vietcong_bes_dir, 'core', 'bes_reader.py'))
bes_writer = load_mod('vietcong_bes.core.bes_writer',
                      os.path.join(vietcong_bes_dir, 'core', 'bes_writer.py'))
bes_compare = load_mod('vietcong_bes.core.bes_compare',
                       os.path.join(vietcong_bes_dir, 'core', 'bes_compare.py'))

read_bes_file = bes_reader.read_bes_file
write_bes_file = bes_writer.write_bes_file
compare_bes_files = bes_compare.compare_bes_files

# Flush output to see results immediately
import functools
print = functools.partial(print, flush=True)

def find_bes_files(directory):
    """Find all BES files in directory and subdirectories."""
    bes_files = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.lower().endswith('.bes'):
                bes_files.append(os.path.join(root, f))
    return sorted(bes_files)

def test_file(filepath):
    """Test roundtrip for single file."""
    try:
        original = read_bes_file(filepath)

        # Write to temp file
        fd, tmp_path = tempfile.mkstemp(suffix='.bes')
        os.close(fd)

        try:
            write_bes_file(tmp_path, original)
            roundtrip = read_bes_file(tmp_path)
            result = compare_bes_files(original, roundtrip)
            return result.equal, result.differences, None
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    except Exception as e:
        return False, [], e

def main():
    print("=" * 60)
    print("BES Quick Roundtrip Test")
    print("=" * 60)

    bes_files = find_bes_files(test_dir)
    print(f"Found {len(bes_files)} files\n")

    passed = 0
    failed = 0
    errors = 0
    failed_files = []

    for filepath in bes_files:
        rel_path = os.path.relpath(filepath, test_dir)
        success, diffs, exc = test_file(filepath)

        if exc:
            print(f"ERROR: {rel_path} - {exc}")
            errors += 1
            failed_files.append((rel_path, 'ERROR', str(exc)))
        elif success:
            print(f"PASS:  {rel_path}")
            passed += 1
        else:
            print(f"FAIL:  {rel_path} ({len(diffs)} diffs)")
            failed += 1
            failed_files.append((rel_path, 'FAIL', diffs[:5]))

    print("\n" + "=" * 60)
    print(f"SUMMARY: {passed} passed, {failed} failed, {errors} errors")
    print("=" * 60)

    if failed_files:
        print("\nFailed/Error files:")
        for rel_path, status, info in failed_files:
            print(f"  [{status}] {rel_path}")
            if status == 'FAIL':
                for d in info:
                    print(f"         {d}")

    return 0 if (failed == 0 and errors == 0) else 1

if __name__ == '__main__':
    sys.exit(main())
