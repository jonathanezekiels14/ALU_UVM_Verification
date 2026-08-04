# =====================================================================
# Makefile for ALU UVM Verification Environment (ModelSim / Questa)
# =====================================================================

# Default configurable parameters (can be overridden from terminal)
TOP          ?= tb_top
TEST         ?= alu_regression_test
NUM_TX       ?= 10
VERBOSITY    ?= UVM_HIGH
SIM_NAME     ?= $(TEST)_run
UCDB_NAME    ?= $(TEST)_cov
WLF_NAME     ?= $(TEST).wlf
VCD_NAME     ?= $(TEST).vcd
COV_DIR      ?= covReport
MERGED_UCDB  ?= merged_coverage.ucdb

# Simulation flags with WLF logging and full coverage capture
VSIM_BATCH_FLAGS = -vopt work.$(TOP) \
                   -voptargs=+acc=npr \
                   -assertdebug \
                   -l $(SIM_NAME).log \
                   -coverage \
                   -c \
                   -wlf $(WLF_NAME) \
                   -do "log -r /*; coverage save -onexit -assert -directive -cvg -codeAll $(UCDB_NAME).ucdb; run -all; exit" \
                   +UVM_TESTNAME=$(TEST) \
                   +UVM_VERBOSITY=$(VERBOSITY) \
                   +NUM_TX=$(NUM_TX)

.PHONY: all lib comp sim gui vcd gtkwave merge cov clean

all: clean lib comp sim cov

# 1. Create the ModelSim working library
lib:
	vlib work

# 2. Compile design and testbench (+cover=sbceft applied ONLY to RTL)
comp: lib
	vlog -sv alu_defines.svh
	vlog -sv alu_interface.sv
	vlog -sv alu_assertions.sv
	vlog -sv +cover=sbceft alu.sv
	vlog -sv +incdir+. alu_pkg.sv
	vlog -sv tb_top.sv

# 3. Batch simulation (Generates log, UCDB, and WLF waveform file)
sim: comp
	vsim $(VSIM_BATCH_FLAGS)

# 4. Interactive GUI mode with waveform viewing
gui: comp
	vsim -vopt work.$(TOP) -voptargs=+acc=npr -assertdebug -coverage \
	     -wlf $(WLF_NAME) \
	     -do "add wave -r /*; run -all" \
	     +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +NUM_TX=$(NUM_TX) &

# 5. Convert WLF to GTKWave-compatible VCD format
vcd:
	vsim -c -do "wlf2vcd $(WLF_NAME) -o $(VCD_NAME); exit"
	@echo "Converted $(WLF_NAME) to GTKWave format: $(VCD_NAME)"

# 6. Convert and open waveform directly in GTKWave
gtkwave: vcd
	gtkwave $(VCD_NAME) &

# 7. Merge all test UCDB files into one cumulative database
merge:
	vcover merge $(MERGED_UCDB) *.ucdb
	@echo "Successfully merged all .ucdb files into $(MERGED_UCDB)"

# 8. Generate HTML Coverage Report from Merged Database
cov: merge
	vcover report -html $(MERGED_UCDB) -htmldir $(COV_DIR) -details -code bcesft -cvg -assert -directive
	@echo "Cumulative coverage report generated in directory: $(COV_DIR)/"

# 9. Clean up compilation artifacts, logs, waveforms, and coverage databases
clean:
	@rm -rf work transcript *.log *.wlf *.vcd *.ucdb $(COV_DIR)
	@echo "Workspace cleaned successfully!"
# Run simulation at max speed without compiling or saving coverage
fast: comp
	vsim -vopt work.$(TOP) -voptargs=+acc=npr -assertdebug -l $(SIM_NAME).log -c -do "run -all; exit" +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +NUM_TX=$(NUM_TX)
