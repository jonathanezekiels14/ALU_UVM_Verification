class alu_transaction extends uvm_sequence_item;
	`uvm_oject_utils(alu_transaction)

	rand bit [`DW-1:0] OPA,OPB;
	rand bit [1:0] INP_VALID;
	rand bit [`CW-1:0] CMD;
	rand bit MODE,CIN,CE;
	logic [(2*`DW)-1:0] RES;
	logic ERR,COUT,OFLOW,G,L,E;

	constraint set_ce { soft
		CE == dist { 1:= 9};
	}

	constraint set_cmd { soft 
		(MODE == 0) -> CMD < 13;
		(MODE == 1) -> CMD < 11;
		solve MODE before CMD;
	}

	constraint set_cin { soft
		CIN == dist { 0 := 5, 1:= 5};
	}

	function new(string name = "alu_transaction");
		super.new(name);
	endfunction

	virtual function void do_copy(uvm_object rhs);
		alu_transaction obj;
		if (!$cast(obj,rhs)) begin
			`uvm_fatal("do_copy","Casting of do_copy object failed");
		end
	endfunction
endclass


