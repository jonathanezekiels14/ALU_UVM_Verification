# =====================================================================
# Makefile for ALU UVM Verification Environment (ModelSim / Questa)
# =====================================================================

# Default configurable parameters (can be overridden from terminal)
TEST   ?= alu_rand_test
NUM_TX ?= 10000

# Simulation flags for batch mode (auto-exits when simulation finishes)
VSIM_BATCH_FLAGS = -c -do "run -all; exit"

.PHONY: all lib comp sim gui clean

all: clean lib comp sim

# 1. Create the ModelSim working library
lib:
	vlib work

# 2. Compile everything in strict dependency order
comp: lib
	vlog -sv alu_defines.svh
	vlog -sv alu_interface.sv
	vlog -sv alu_assertions.sv
	vlog -sv alu.sv             # <-- Replace with your actual RTL file name(s)
	vlog -sv +incdir+. alu_pkg.sv
	vlog -sv tb_top.sv

# 3. Run simulation in Batch Mode (Terminal output only)
sim: comp
	vsim work.tb_top $(VSIM_BATCH_FLAGS) +UVM_TESTNAME=$(TEST) +NUM_TX=$(NUM_TX)

# 4. Run simulation in Graphical User Interface (GUI) Mode
gui: comp
	vsim work.tb_top +UVM_TESTNAME=$(TEST) +NUM_TX=$(NUM_TX) &

# 5. Clean up compilation artifacts and logs
clean:
	@rm -rf work transcript *.log *.wlf
	@echo "Workspace cleaned successfully!"
