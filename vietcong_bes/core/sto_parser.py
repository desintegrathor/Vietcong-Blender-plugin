# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
STO Animation Events Parser

Parses Vietcong STO animation event files.

STO Format Structure:
- Header (8 bytes):
  - Version/flags: uint32 (usually 1)
  - Entry count: uint32

- Event entries (40 bytes each):
  - Name: 20 bytes (null-terminated ASCII string)
  - Time: float (event time in seconds)
  - Data: 16 bytes (4 uint32 values - event-specific parameters)

Common event names (Czech):
- PravaNoha/LevaNoha: Right/left foot (footstep sounds)
- Susteni: Rustling/shuffling sound
- dopad/doskok: Impact/landing
- odraz: Push-off
- noha: Foot
- ruka/RUKA: Hand
- KOLENO: Knee
"""

import struct
from dataclasses import dataclass, field
from typing import List, Tuple, Optional
from ..utils.binary_utils import BinaryReader


@dataclass
class STOEvent:
    """Animation event."""
    name: str
    time: float  # Event time in seconds
    data: Tuple[int, int, int, int] = (0, 0, 0, 0)  # Event parameters


@dataclass
class STOAnimation:
    """Parsed STO animation events."""
    filename: str = ''
    version: int = 0
    events: List[STOEvent] = field(default_factory=list)


class STOParser:
    """Parser for STO animation event files."""

    def __init__(self, filepath: str):
        self.filepath = filepath
        self._reader: Optional[BinaryReader] = None

    def parse(self) -> STOAnimation:
        """Parse STO file and return animation events."""
        self._reader = BinaryReader(self.filepath)

        try:
            anim = STOAnimation(filename=self.filepath)

            # Read header
            anim.version = self._reader.read_uint32()
            entry_count = self._reader.read_uint32()

            # Read events
            for _ in range(entry_count):
                # Read name (20 bytes, null-terminated)
                name_bytes = self._reader.read(20)
                name = name_bytes.split(b'\x00')[0].decode('ascii', errors='replace')

                # Read time (float)
                time = self._reader.read_float()

                # Read data (4 uint32)
                d0 = self._reader.read_uint32()
                d1 = self._reader.read_uint32()
                d2 = self._reader.read_uint32()
                d3 = self._reader.read_uint32()

                anim.events.append(STOEvent(
                    name=name,
                    time=time,
                    data=(d0, d1, d2, d3)
                ))

            return anim

        finally:
            self._reader.close()


def read_sto_file(filepath: str) -> STOAnimation:
    """Read and parse an STO animation event file.

    Args:
        filepath: Path to STO file

    Returns:
        Parsed STOAnimation object
    """
    parser = STOParser(filepath)
    return parser.parse()
