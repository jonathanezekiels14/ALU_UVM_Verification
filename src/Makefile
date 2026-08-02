# =====================================================================
# Makefile for ALU UVM Verification Environment (ModelSim / Questa)
# =====================================================================

# Default configurable parameters (can be overridden from terminal)
TOP        ?= tb_top
TEST       ?= alu_regression_test
NUM_TX     ?= 10000
SIM_NAME   ?= sim_run
UCDB_NAME  ?= coverage_results

# Advanced simulation flags for batch mode with coverage, assertions, and logging
VSIM_BATCH_FLAGS = -vopt work.$(TOP) \
                   -voptargs= "+acc=npr +cover=sbc"  \
                   -assertdebug \
                   -l $(SIM_NAME).log \
                   -coverage \
                   -c \
                   -do "coverage save -onexit -assert -directive -cvg -codeAll $(UCDB_NAME).ucdb; run -all; exit" \
                   +UVM_TESTNAME=$(TEST) \
                   +NUM_TX=$(NUM_TX)

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
	vlog -sv alu.sv
	vlog -sv +incdir+. alu_pkg.sv
	vlog -sv tb_top.sv

# 3. Run simulation in Batch Mode (with coverage & assertion debugging)
sim: comp
	vsim $(VSIM_BATCH_FLAGS)

# 4. Run simulation in Graphical User Interface (GUI) Mode
gui: comp
	vsim -vopt work.$(TOP) -voptargs=+acc=npr -assertdebug -coverage +UVM_TESTNAME=$(TEST) +NUM_TX=$(NUM_TX) &

# 5. Clean up compilation artifacts, logs, and coverage databases
clean:
	@rm -rf work transcript *.log *.wlf *.ucdb
	@echo "Workspace cleaned successfully!"
