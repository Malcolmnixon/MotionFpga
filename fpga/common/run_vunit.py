from pathlib import Path
from vunit import VUnit

VU = VUnit.from_argv()
lib = VU.add_library("common")
lib.add_source_files("utility/source/*.vhd")
lib.add_source_files("devices/source/*.vhd")
lib.add_source_files("communications/source/*.vhd")
lib.add_source_files("utility/vunit/*.vhd")
lib.add_source_files("devices/vunit/*.vhd")
lib.add_source_files("communications/vunit/*.vhd")
VU.main()
