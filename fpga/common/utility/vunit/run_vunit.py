from pathlib import Path
from vunit import VUnit

VU = VUnit.from_argv()
lib = VU.add_library("utility")
lib.add_source_files("../source/*.vhd")
lib.add_source_files("*.vhd")
VU.main()
