TOP   := subleq
BOARD := basys3
LIB   := lib/memory.sv

# Compile prog/prog.hsq -> prog/prog.hex before any build/sim.
PREBUILD := $(MAKE) -s -C subleq