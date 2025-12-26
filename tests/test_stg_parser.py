# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Tests for STG animation parser.

Standalone tests that don't require Blender.
Run with: python tests/test_stg_parser.py
"""

import sys
import os
import struct
import math

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_DIR = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')


def euler_to_quaternion(rx, ry, rz):
    """Convert Euler angles (degrees) to quaternion. Matches engine."""
    DEG_TO_HALF_RAD = math.pi / 360.0
    half_x = rx * DEG_TO_HALF_RAD
    half_y = -ry * DEG_TO_HALF_RAD
    half_z = -rz * DEG_TO_HALF_RAD

    cy, sy = math.cos(half_y), math.sin(half_y)
    cx, sx = math.cos(half_x), math.sin(half_x)
    cz, sz = math.cos(half_z), math.sin(half_z)

    def quat_mul(a, b):
        return (
            a[0]*b[0] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3],
            a[1]*b[0] + a[0]*b[1] + a[3]*b[2] - a[2]*b[3],
            a[2]*b[0] + a[0]*b[2] + a[1]*b[3] - a[3]*b[1],
            a[3]*b[0] + a[0]*b[3] + a[2]*b[1] - a[1]*b[2]
        )

    qy = (cy, sy, 0.0, 0.0)
    qx = (cx, 0.0, sx, 0.0)
    qz = (cz, 0.0, 0.0, sz)

    temp = quat_mul(qz, qy)
    return quat_mul(temp, qx)


def parse_stg_file(filepath):
    """Parse STG file and return animation data."""
    with open(filepath, 'rb') as f:
        data = f.read()

    if data[:4] != b'STG\xff':
        raise ValueError(f"Invalid magic: {data[:4]}")

    version = struct.unpack_from('<I', data, 4)[0]
    duration = struct.unpack_from('<f', data, 8)[0]
    frame_count = struct.unpack_from('<I', data, 12)[0]
    num_components = struct.unpack_from('<I', data, 16)[0]
    bone_indices_size = struct.unpack_from('<I', data, 20)[0]

    offset = 24
    bone_indices = list(data[offset:offset + bone_indices_size])
    offset += bone_indices_size

    bone_types = list(data[offset:offset + num_components])
    offset += num_components

    num_tracks = num_components // 3

    # Parse tracks
    tracks = []
    bone_idx_ptr = 0
    for track_idx in range(num_tracks):
        t0 = bone_types[track_idx * 3]
        if t0 in (0, 1, 2):
            bone_idx = 0
            track_type = 'position'
        else:
            bone_idx = bone_indices[bone_idx_ptr] if bone_idx_ptr < len(bone_indices) else 0
            bone_idx_ptr += 1
            track_type = 'rotation'
        tracks.append({'bone_index': bone_idx, 'type': track_type, 'data': []})

    # Parse frame data
    for frame in range(frame_count):
        for track_idx in range(num_tracks):
            x = struct.unpack_from('<f', data, offset)[0]
            y = struct.unpack_from('<f', data, offset + 4)[0]
            z = struct.unpack_from('<f', data, offset + 8)[0]
            offset += 12

            if tracks[track_idx]['type'] == 'position':
                tracks[track_idx]['data'].append((x, y, z))
            else:
                tracks[track_idx]['data'].append(euler_to_quaternion(x, y, z))

    return {
        'version': version,
        'duration': duration,
        'frame_count': frame_count,
        'fps': (frame_count - 1) / duration if duration > 0 and frame_count > 1 else 30.0,
        'tracks': tracks,
    }


def test_euler_to_quaternion():
    """Test Euler to quaternion conversion."""
    # Test identity
    q = euler_to_quaternion(0, 0, 0)
    assert abs(q[0] - 1.0) < 0.0001, f"Identity W wrong: {q[0]}"
    assert abs(q[1]) < 0.0001, f"Identity X wrong: {q[1]}"
    assert abs(q[2]) < 0.0001, f"Identity Y wrong: {q[2]}"
    assert abs(q[3]) < 0.0001, f"Identity Z wrong: {q[3]}"
    print("PASS: Euler identity -> quaternion identity")

    # Test 90 degree rotations produce valid quaternions (magnitude = 1)
    for rx, ry, rz in [(90, 0, 0), (0, 90, 0), (0, 0, 90), (45, 45, 45)]:
        q = euler_to_quaternion(rx, ry, rz)
        mag = math.sqrt(sum(x*x for x in q))
        assert abs(mag - 1.0) < 0.0001, f"Quaternion not normalized for ({rx},{ry},{rz}): mag={mag}"
    print("PASS: Quaternion normalization")


def test_file_size_validation():
    """Test all STG files have correct size based on header."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found: {TEST_DIR}")
        return

    stg_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STG')]

    passed = 0
    failed = 0

    for filename in stg_files:
        filepath = os.path.join(TEST_DIR, filename)

        with open(filepath, 'rb') as f:
            data = f.read()

        if data[:4] != b'STG\xff':
            continue

        frame_count = struct.unpack_from('<I', data, 12)[0]
        num_components = struct.unpack_from('<I', data, 16)[0]
        bone_indices_size = struct.unpack_from('<I', data, 20)[0]

        num_tracks = num_components // 3
        expected_size = 24 + bone_indices_size + num_components + (num_tracks * 3 * 4 * frame_count)

        if len(data) == expected_size:
            passed += 1
        else:
            failed += 1
            print(f"FAIL: {filename} - expected {expected_size}, got {len(data)}")

    print(f"File size validation: {passed} passed, {failed} failed")
    assert failed == 0, f"{failed} files failed size validation"


def test_all_files_parse():
    """Test all STG files can be parsed without errors."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found: {TEST_DIR}")
        return

    stg_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STG')]

    passed = 0
    failed = 0
    errors = []

    for filename in stg_files:
        filepath = os.path.join(TEST_DIR, filename)
        try:
            anim = parse_stg_file(filepath)
            # Validate structure
            assert anim['frame_count'] > 0
            assert len(anim['tracks']) > 0
            for track in anim['tracks']:
                assert len(track['data']) == anim['frame_count']
            passed += 1
        except Exception as e:
            failed += 1
            errors.append((filename, str(e)))

    print(f"Parse all files: {passed} passed, {failed} failed out of {len(stg_files)}")

    if errors:
        for name, err in errors[:5]:
            print(f"  ERROR: {name}: {err}")

    assert failed == 0, f"{failed} files failed to parse"


def test_sample_animation_data():
    """Test sample animation has reasonable values."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found")
        return

    stg_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STG')]
    if not stg_files:
        print("SKIP: No STG files found")
        return

    filepath = os.path.join(TEST_DIR, stg_files[0])
    anim = parse_stg_file(filepath)

    print(f"Sample: {stg_files[0]}")
    print(f"  Version: {anim['version']}")
    print(f"  Duration: {anim['duration']:.2f}s")
    print(f"  Frames: {anim['frame_count']}")
    print(f"  FPS: {anim['fps']:.2f}")
    print(f"  Tracks: {len(anim['tracks'])}")

    # Check first track (should be position for bone 0)
    pos_track = None
    rot_track = None
    for t in anim['tracks']:
        if t['type'] == 'position' and pos_track is None:
            pos_track = t
        if t['type'] == 'rotation' and rot_track is None:
            rot_track = t

    if pos_track:
        pos = pos_track['data'][0]
        print(f"  First position: ({pos[0]:.2f}, {pos[1]:.2f}, {pos[2]:.2f})")

    if rot_track:
        rot = rot_track['data'][0]
        print(f"  First rotation (quat): ({rot[0]:.4f}, {rot[1]:.4f}, {rot[2]:.4f}, {rot[3]:.4f})")

    print("PASS: Sample animation data")


def test_bone_indices():
    """Analyze bone indices used in animations."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found")
        return

    stg_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STG')][:50]

    all_bone_indices = set()
    for filename in stg_files:
        filepath = os.path.join(TEST_DIR, filename)
        with open(filepath, 'rb') as f:
            data = f.read()

        bone_indices_size = struct.unpack_from('<I', data, 20)[0]
        bone_indices = list(data[24:24 + bone_indices_size])
        all_bone_indices.update(bone_indices)

    print(f"Bone indices used: {sorted(all_bone_indices)}")
    print(f"Total unique bones: {len(all_bone_indices)}")

    # Expected bones (0-27 range)
    assert max(all_bone_indices) < 30, "Bone index out of expected range"
    print("PASS: Bone indices in valid range")


if __name__ == '__main__':
    print("=" * 60)
    print("STG Parser Tests")
    print("=" * 60)

    tests = [
        ("Euler to Quaternion", test_euler_to_quaternion),
        ("File Size Validation", test_file_size_validation),
        ("All Files Parse", test_all_files_parse),
        ("Sample Animation Data", test_sample_animation_data),
        ("Bone Indices", test_bone_indices),
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
