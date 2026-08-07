`include "alu_defines.svh"
`include "alu_interface.sv"
`include "alu_assertions.sv"
`include "alu_pkg.sv"

module tb_top;
	import uvm_pkg::*;
	import alu_pkg::*;

	// clock signal
	logic CLK;

	// clock generation
	initial begin
		CLK = 1'b0;
		forever #5 CLK = ~CLK;
	end

	// interface instantiation
	alu_interface vif (CLK);

	// dut instantiation
	ALU_DESIGN #(.DW(`DW), .CW(`CW)) dut (
		.CLK(vif.CLK),
		.RST(vif.RST),
		.CE(vif.CE),
		.INP_VALID(vif.INP_VALID),
		.MODE(vif.MODE),
		.CMD(vif.CMD),
		.CIN(vif.CIN),
		.OPA(vif.OPA),
		.OPB(vif.OPB),
		.RES(vif.RES),
		.ERR(vif.ERR),
		.COUT(vif.COUT),
		.OFLOW(vif.OFLOW),
		.G(vif.G),
		.L(vif.L),
		.E(vif.E)
	);

	// initial reset and signal initialization driver
	initial begin
		vif.CE = 1'b0;
		vif.INP_VALID = 2'b00;
		vif.MODE = 1'b0;
		vif.CMD = '0;
		vif.CIN = 1'b0;
		vif.OPA = '0;
		vif.OPB = '0;

		vif.RST = 1'b1;
		repeat(2) @(posedge CLK);
		vif.RST = 1'b0;
		`uvm_info("TB_TOP", "Initial Reset Released.", UVM_LOW)
	end

	// uvm startup block
	initial begin
		uvm_config_db#(virtual alu_interface)::set(null, "*", "vif", vif);
		run_test();
	end

	// safety timeout guard
	initial begin
		#5000000;
		`uvm_fatal("TB_TOP", "Simulation timeout reached! Deadlock detected.")
		$finish;
	end

	// bind assertions to the dut instance (fixed scope reference to avoid compilation errors)
	bind dut alu_assertions alu_sva (
		.CLK(CLK),
		.RST(RST),
		.CE(CE),
		.INP_VALID(INP_VALID),
		.MODE(MODE),
		.CMD(CMD),
		.CIN(CIN),
		.OPA(OPA),
		.OPB(OPB),
		.RES(RES),
		.ERR(ERR),
		.COUT(COUT),
		.OFLOW(OFLOW),
		.G(G),
		.L(L),
		.E(E)
	);

endmodule
