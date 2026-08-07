class alu_transaction extends uvm_sequence_item;

	// declare random variables
	rand bit [`DW-1:0] OPA;
	rand bit [`DW-1:0] OPB;
	rand bit [1:0] INP_VALID;
	rand bit [`CW-1:0] CMD;
	rand bit MODE;
	rand bit CIN;
	rand bit CE;
	rand bit RST;

	// declare output and flag variables
	logic [(2*`DW)-1:0] RES;
	logic ERR;
	logic COUT;
	logic OFLOW;
	logic G;
	logic L;
	logic E;
	logic timeout_occurred;

	// register with factory
	`uvm_object_utils_begin(alu_transaction)
		`uvm_field_int(CE, UVM_DEFAULT)
		`uvm_field_int(INP_VALID, UVM_DEFAULT | UVM_BIN)
		`uvm_field_int(MODE, UVM_DEFAULT)
		`uvm_field_int(CMD, UVM_DEFAULT | UVM_DEC)
		`uvm_field_int(CIN, UVM_DEFAULT)
		`uvm_field_int(OPA, UVM_DEFAULT | UVM_DEC)
		`uvm_field_int(OPB, UVM_DEFAULT | UVM_DEC)
		`uvm_field_int(RES, UVM_DEFAULT | UVM_DEC)
		`uvm_field_int(ERR, UVM_DEFAULT)
		`uvm_field_int(COUT, UVM_DEFAULT)
		`uvm_field_int(OFLOW, UVM_DEFAULT)
		`uvm_field_int(G, UVM_DEFAULT)
		`uvm_field_int(L, UVM_DEFAULT)
		`uvm_field_int(E, UVM_DEFAULT)
		`uvm_field_int(RST, UVM_DEFAULT)
		`uvm_field_int(timeout_occurred, UVM_DEFAULT)
	`uvm_object_utils_end

	// constrain clock enable
	constraint set_ce {
		soft CE == 1;
	}

	// constrain command boundaries
	constraint set_cmd {
		(MODE == 0) -> soft CMD <= 13;
		(MODE == 1) -> soft CMD <= 10;
		solve MODE before CMD;
	}

	// constrain carry in
	constraint set_cin {
		soft CIN dist { 0 := 5, 1 := 5 };
	}

	// constructor
	function new(string name = "alu_transaction");
		super.new(name);
		CE = 1'b1;
		INP_VALID = 2'b11;
		timeout_occurred = 1'b0;
		RST = 1'b0;
	endfunction

endclass
