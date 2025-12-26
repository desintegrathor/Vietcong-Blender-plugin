# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
STO Animation Events Writer

Writes Vietcong STO animation event files.
"""

import struct
from .sto_parser import STOAnimation, STOEvent


class STOWriter:
    """Writer for STO animation event files."""

    def __init__(self, anim: STOAnimation):
        """Initialize writer.

        Args:
            anim: Animation events data to write
        """
        self.anim = anim

    def write(self, filepath: str):
        """Write animation events to STO file.

        Args:
            filepath: Output file path
        """
        with open(filepath, 'wb') as f:
            self._write_to_file(f)

    def _write_to_file(self, f):
        """Write animation events to file object."""
        # Write header
        f.write(struct.pack('<I', self.anim.version))
        f.write(struct.pack('<I', len(self.anim.events)))

        # Write events
        for event in self.anim.events:
            # Name (20 bytes, null-padded)
            name_bytes = event.name.encode('ascii', errors='replace')[:19]
            name_bytes = name_bytes.ljust(20, b'\x00')
            f.write(name_bytes)

            # Time (float)
            f.write(struct.pack('<f', event.time))

            # Data (4 uint32)
            f.write(struct.pack('<4I', *event.data))


def write_sto_file(filepath: str, anim: STOAnimation):
    """Write an STO animation event file.

    Args:
        filepath: Output file path
        anim: Animation events data to write
    """
    writer = STOWriter(anim)
    writer.write(filepath)
