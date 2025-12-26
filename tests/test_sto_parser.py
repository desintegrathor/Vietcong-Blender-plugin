# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Tests for STO animation events parser.

Standalone tests that don't require Blender.
Run with: python tests/test_sto_parser.py
"""

import sys
import os
import struct

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_DIR = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')


def parse_sto_file(filepath):
    """Parse STO file and return animation events."""
    with open(filepath, 'rb') as f:
        data = f.read()

    if len(data) < 8:
        raise ValueError(f"File too small: {len(data)} bytes")

    version = struct.unpack_from('<I', data, 0)[0]
    entry_count = struct.unpack_from('<I', data, 4)[0]

    events = []
    offset = 8

    for _ in range(entry_count):
        name_bytes = data[offset:offset + 20]
        name = name_bytes.split(b'\x00')[0].decode('ascii', errors='replace')
        offset += 20

        time = struct.unpack_from('<f', data, offset)[0]
        offset += 4

        d0, d1, d2, d3 = struct.unpack_from('<4I', data, offset)
        offset += 16

        events.append({
            'name': name,
            'time': time,
            'data': (d0, d1, d2, d3),
        })

    return {
        'version': version,
        'events': events,
    }


def test_file_size_validation():
    """Test all STO files have correct size based on header."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found: {TEST_DIR}")
        return

    sto_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STO')]

    passed = 0
    failed = 0

    for filename in sto_files:
        filepath = os.path.join(TEST_DIR, filename)

        with open(filepath, 'rb') as f:
            data = f.read()

        if len(data) < 8:
            failed += 1
            continue

        entry_count = struct.unpack_from('<I', data, 4)[0]
        expected_size = 8 + entry_count * 40

        if len(data) == expected_size:
            passed += 1
        else:
            failed += 1
            print(f"FAIL: {filename} - expected {expected_size}, got {len(data)}")

    print(f"File size validation: {passed} passed, {failed} failed")
    assert failed == 0, f"{failed} files failed size validation"


def test_all_files_parse():
    """Test all STO files can be parsed without errors."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found: {TEST_DIR}")
        return

    sto_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STO')]

    passed = 0
    failed = 0
    errors = []

    for filename in sto_files:
        filepath = os.path.join(TEST_DIR, filename)
        try:
            anim = parse_sto_file(filepath)
            # Validate structure
            for event in anim['events']:
                assert isinstance(event['name'], str)
                assert isinstance(event['time'], float)
                assert len(event['data']) == 4
            passed += 1
        except Exception as e:
            failed += 1
            errors.append((filename, str(e)))

    print(f"Parse all files: {passed} passed, {failed} failed out of {len(sto_files)}")

    if errors:
        for name, err in errors[:5]:
            print(f"  ERROR: {name}: {err}")

    assert failed == 0, f"{failed} files failed to parse"


def test_event_names():
    """Collect and verify unique event names."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found")
        return

    sto_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STO')]

    event_names = set()

    for filename in sto_files:
        filepath = os.path.join(TEST_DIR, filename)
        try:
            anim = parse_sto_file(filepath)
            for event in anim['events']:
                event_names.add(event['name'])
        except:
            pass

    print(f"Unique event names ({len(event_names)}):")
    for name in sorted(event_names):
        print(f"  {name}")

    # Known events that should exist
    known = ['PravaNoha', 'LevaNoha']
    for k in known:
        if k in event_names:
            print(f"PASS: Known event '{k}' found")

    assert len(event_names) > 0, "No event names found"
    print("PASS: Event names collected")


def test_sample_events():
    """Test sample file with events."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found")
        return

    # Find file with events
    sto_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STO')]

    for filename in sto_files:
        filepath = os.path.join(TEST_DIR, filename)
        if os.path.getsize(filepath) <= 8:
            continue

        anim = parse_sto_file(filepath)
        if not anim['events']:
            continue

        print(f"Sample: {filename}")
        print(f"  Version: {anim['version']}")
        print(f"  Events: {len(anim['events'])}")

        for event in anim['events'][:3]:
            print(f"    {event['name']:15} @ {event['time']:.3f}s  data={event['data']}")

        print("PASS: Sample events")
        return

    print("SKIP: No STO files with events found")


if __name__ == '__main__':
    print("=" * 60)
    print("STO Parser Tests")
    print("=" * 60)

    tests = [
        ("File Size Validation", test_file_size_validation),
        ("All Files Parse", test_all_files_parse),
        ("Event Names", test_event_names),
        ("Sample Events", test_sample_events),
    ]

    passed = 0
    failed = 0

    for name, test_func in tests:
        print()
        try:
            test_func()
            passed += 1
        except AssertionError as e:
            print(f"FAIL: {name} - {e}")
            failed += 1
        except Exception as e:
            print(f"ERROR: {name} - {e}")
            failed += 1

    print()
    print("=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)

    sys.exit(0 if failed == 0 else 1)
