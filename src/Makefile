# =====================================================================
# Makefile for ALU UVM Verification Environment (ModelSim / Questa)
# =====================================================================

# Default configurable parameters (can be overridden from terminal)
TOP        ?= tb_top
TEST       ?= alu_regression_test
NUM_TX     ?= 10000
VERBOSITY  ?= UVM_MEDIUM
SIM_NAME   ?= sim_run
UCDB_NAME  ?= coverage_results
COV_DIR    ?= covReport

# Advanced simulation flags (Keep voptargs clean to preserve class covergroups)
VSIM_BATCH_FLAGS = -vopt work.$(TOP) \
                   -voptargs=+acc=npr \
                   -assertdebug \
                   -l $(SIM_NAME).log \
                   -coverage \
                   -c \
                   -do "coverage save -onexit -assert -directive -cvg -codeAll $(UCDB_NAME).ucdb; run -all; exit" \
                   +UVM_TESTNAME=$(TEST) \
                   +UVM_VERBOSITY=$(VERBOSITY) \
                   +NUM_TX=$(NUM_TX)

.PHONY: all lib comp sim gui cov clean

all: clean lib comp sim cov

# 1. Create the ModelSim working library
lib:
	vlib work

# 2. Compile everything (+cover=sbceft applied ONLY to RTL 'alu.sv')
comp: lib
	vlog -sv alu_defines.svh
	vlog -sv alu_interface.sv
	vlog -sv alu_assertions.sv
	vlog -sv +cover=sbceft alu.sv
	vlog -sv +incdir+. alu_pkg.sv
	vlog -sv tb_top.sv

# 3. Run simulation in Batch Mode
sim: comp
	vsim $(VSIM_BATCH_FLAGS)

# 4. Generate HTML Coverage Report (Detailed mode includes Code + Covergroups + Assertions)
cov:
	vcover report -html $(UCDB_NAME).ucdb -htmldir $(COV_DIR) -details
	@echo "Coverage report generated in directory: $(COV_DIR)/"

# 5. Run simulation in GUI Mode
gui: comp
	vsim -vopt work.$(TOP) -voptargs=+acc=npr -assertdebug -coverage +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +NUM_TX=$(NUM_TX) &

# 6. Clean up compilation artifacts, logs, and coverage databases
clean:
	@rm -rf work transcript *.log *.wlf *.ucdb $(COV_DIR)
	@echo "Workspace cleaned successfully!"
