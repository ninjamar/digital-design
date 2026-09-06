TOP   := subleq
BOARD := basys3
LIB   := lib/memory.sv lib/busy_status.sv

# Compile prog/prog.hsq -> prog/prog.hex before any build/sim.
PREBUILD := $(MAKE) -s -C subleq