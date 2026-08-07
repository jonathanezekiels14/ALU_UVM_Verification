`include "alu_defines.svh"
interface alu_interface (input logic CLK);

	// define logic signals
	logic RST, CE, MODE, CIN;
	logic [`DW-1:0] OPA, OPB;
	logic [`CW-1:0] CMD;
	logic [1:0] INP_VALID;
	logic [(2*`DW)-1:0] RES;
	logic COUT, OFLOW, G, L, E, ERR;

	// driver clocking block
	clocking inp_drv_cb @(posedge CLK);
		default input #1step output #1ns;
		output CE, MODE, CIN, OPA, OPB, CMD, INP_VALID;
	endclocking

	// input monitor clocking block
	clocking inp_mon_cb @(posedge CLK);
		default input #1step;
		input OPA, OPB, RST, CE, MODE, CIN, CMD, INP_VALID;
	endclocking

	// output monitor clocking block
	clocking out_mon_cb @(posedge CLK);
		default input #1step;
		input OPA, OPB, RST, CE, MODE, CIN, CMD, INP_VALID, RES, COUT, OFLOW, G, L, E, ERR;
	endclocking

	// define modports
	modport INP_DRV (clocking inp_drv_cb, input RST);
	modport INP_MON (clocking inp_mon_cb);
	modport OUT_MON (clocking out_mon_cb);

endinterface
