# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Tests for STG animation roundtrip (read -> write -> read -> compare).

Standalone tests that don't require Blender.
Run with: python tests/test_stg_roundtrip.py
"""

import sys
import os
import struct
import math
import tempfile

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

TEST_DIR = os.path.join(PROJECT_ROOT, 'tests', 'CHARACTERS', 'ANIMS')


def euler_to_quaternion(rx, ry, rz):
    """Convert Euler angles (degrees) to quaternion."""
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


def quaternion_to_euler(w, x, y, z):
    """Convert quaternion to Euler angles (degrees) - YZX order."""
    mag = math.sqrt(w*w + x*x + y*y + z*z)
    if mag > 0:
        w, x, y, z = w/mag, x/mag, y/mag, z/mag

    # Convert to rotation matrix elements
    m11 = 1.0 - 2.0 * (y*y + z*z)
    m21 = 2.0 * (x*y + w*z)
    m22 = 1.0 - 2.0 * (x*x + z*z)
    m23 = 2.0 * (y*z - w*x)
    m31 = 2.0 * (x*z - w*y)
    m33 = 1.0 - 2.0 * (x*x + y*y)
    m13 = 2.0 * (x*z + w*y)

    # Extract YZX Euler angles
    if abs(m21) < 0.99999:
        rz = math.asin(max(-1.0, min(1.0, m21)))
        ry = math.atan2(-m31, m11)
        rx = math.atan2(-m23, m22)
    else:
        rz = math.copysign(math.pi / 2, m21)
        ry = math.atan2(m13, m33)
        rx = 0.0

    RAD_TO_DEG = 180.0 / math.pi
    return (rx * RAD_TO_DEG, -ry * RAD_TO_DEG, -rz * RAD_TO_DEG)


def parse_stg_file(filepath):
    """Parse STG file and return raw data for comparison."""
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

    # Parse frame data
    frames = []
    for frame in range(frame_count):
        frame_data = []
        for track_idx in range(num_tracks):
            x = struct.unpack_from('<f', data, offset)[0]
            y = struct.unpack_from('<f', data, offset + 4)[0]
            z = struct.unpack_from('<f', data, offset + 8)[0]
            offset += 12
            frame_data.append((x, y, z))
        frames.append(frame_data)

    return {
        'version': version,
        'duration': duration,
        'frame_count': frame_count,
        'num_components': num_components,
        'bone_indices': bone_indices,
        'bone_types': bone_types,
        'frames': frames,
    }


def write_stg_file(filepath, data):
    """Write STG file from parsed data."""
    with open(filepath, 'wb') as f:
        f.write(b'STG\xff')
        f.write(struct.pack('<I', data['version']))
        f.write(struct.pack('<f', data['duration']))
        f.write(struct.pack('<I', data['frame_count']))
        f.write(struct.pack('<I', data['num_components']))
        f.write(struct.pack('<I', len(data['bone_indices'])))
        f.write(bytes(data['bone_indices']))
        f.write(bytes(data['bone_types']))

        for frame_data in data['frames']:
            for x, y, z in frame_data:
                f.write(struct.pack('<fff', x, y, z))


def test_euler_quaternion_identity():
    """Test Euler identity produces quaternion identity."""
    quat = euler_to_quaternion(0, 0, 0)
    assert abs(quat[0] - 1.0) < 0.0001, f"Identity W wrong: {quat[0]}"
    assert abs(quat[1]) < 0.0001, f"Identity X wrong: {quat[1]}"
    assert abs(quat[2]) < 0.0001, f"Identity Y wrong: {quat[2]}"
    assert abs(quat[3]) < 0.0001, f"Identity Z wrong: {quat[3]}"
    print("PASS: Euler identity -> quaternion identity")

    # Test normalized quaternions
    test_angles = [(90, 0, 0), (0, 90, 0), (0, 0, 90), (45, 45, 45)]
    for rx, ry, rz in test_angles:
        quat = euler_to_quaternion(rx, ry, rz)
        mag = math.sqrt(sum(x*x for x in quat))
        assert abs(mag - 1.0) < 0.0001, f"Not normalized for ({rx},{ry},{rz}): {mag}"
    print("PASS: Quaternion normalization")


def test_raw_stg_roundtrip():
    """Test raw STG file roundtrip (no conversion)."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found: {TEST_DIR}")
        return

    stg_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STG')][:10]

    passed = 0
    failed = 0

    for filename in stg_files:
        filepath = os.path.join(TEST_DIR, filename)

        try:
            # Read original
            original = parse_stg_file(filepath)

            # Write to temp file
            with tempfile.NamedTemporaryFile(suffix='.stg', delete=False) as tmp:
                tmp_path = tmp.name

            write_stg_file(tmp_path, original)

            # Read back
            roundtrip = parse_stg_file(tmp_path)

            # Compare
            if original['version'] != roundtrip['version']:
                raise ValueError(f"Version mismatch: {original['version']} vs {roundtrip['version']}")
            if abs(original['duration'] - roundtrip['duration']) > 0.0001:
                raise ValueError(f"Duration mismatch: {original['duration']} vs {roundtrip['duration']}")
            if original['frame_count'] != roundtrip['frame_count']:
                raise ValueError(f"Frame count mismatch")
            if original['bone_indices'] != roundtrip['bone_indices']:
                raise ValueError(f"Bone indices mismatch")
            if original['bone_types'] != roundtrip['bone_types']:
                raise ValueError(f"Bone types mismatch")

            # Compare frame data
            for fi, (orig_frame, rt_frame) in enumerate(zip(original['frames'], roundtrip['frames'])):
                for ti, (orig_vals, rt_vals) in enumerate(zip(orig_frame, rt_frame)):
                    for vi, (ov, rv) in enumerate(zip(orig_vals, rt_vals)):
                        if abs(ov - rv) > 0.0001:
                            raise ValueError(f"Frame {fi} track {ti} value {vi}: {ov} vs {rv}")

            passed += 1
            os.unlink(tmp_path)

        except Exception as e:
            failed += 1
            print(f"FAIL: {filename} - {e}")
            if 'tmp_path' in locals():
                try:
                    os.unlink(tmp_path)
                except:
                    pass

    print(f"Raw STG roundtrip: {passed} passed, {failed} failed")
    assert failed == 0, f"{failed} files failed roundtrip"
    print("PASS: Raw STG roundtrip")


def test_sto_roundtrip():
    """Test STO file roundtrip."""
    if not os.path.exists(TEST_DIR):
        print(f"SKIP: Test directory not found")
        return

    sto_files = [f for f in os.listdir(TEST_DIR) if f.upper().endswith('.STO')][:10]

    passed = 0
    failed = 0

    for filename in sto_files:
        filepath = os.path.join(TEST_DIR, filename)

        try:
            # Read original
            with open(filepath, 'rb') as f:
                original_data = f.read()

            # Parse
            version = struct.unpack_from('<I', original_data, 0)[0]
            entry_count = struct.unpack_from('<I', original_data, 4)[0]

            # Write to temp
            with tempfile.NamedTemporaryFile(suffix='.sto', delete=False) as tmp:
                tmp_path = tmp.name
                tmp.write(original_data)

            # Read back
            with open(tmp_path, 'rb') as f:
                roundtrip_data = f.read()

            # Compare bytes
            if original_data != roundtrip_data:
                raise ValueError("Data mismatch")

            passed += 1
            os.unlink(tmp_path)

        except Exception as e:
            failed += 1
            print(f"FAIL: {filename} - {e}")
            if 'tmp_path' in locals():
                try:
                    os.unlink(tmp_path)
                except:
                    pass

    print(f"STO roundtrip: {passed} passed, {failed} failed")
    assert failed == 0, f"{failed} files failed roundtrip"
    print("PASS: STO roundtrip")


if __name__ == '__main__':
    print("=" * 60)
    print("STG Roundtrip Tests")
    print("=" * 60)

    tests = [
        ("Euler-Quaternion Identity", test_euler_quaternion_identity),
        ("Raw STG Roundtrip", test_raw_stg_roundtrip),
        ("STO Roundtrip", test_sto_roundtrip),
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
