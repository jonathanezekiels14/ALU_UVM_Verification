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
		super.do_copy(rhs);
		this.OPA = obj.OPA;
		this.OPB = obj.OPB;
		this.INP_VALID = obj.INP_VALID;
		this.CMD = obj.CMD;
		this.MODE = obj.MODE;
		this.CIN = obj.CIN;
		this.CE= obj.CE;
		this.RES = obj.RES;
		this.ERR = obj.ERR;
		this.COUT = obj.COUT;
		this.OFLOW = obj.OFLOW;
		this.G = obj.G;
		this.L = obj.L;
		this.E = obj.E;
	endfunction

	virtual function bit do_compare(uvm_object rhs,uvm_comparer comparer);
		alu_transaction obj;
		if(!$cast(obj,rhs))
		begin
			`uvm_fatal("do_compare","Cast for Comparing object failed");
			return 0;
		end
		return 
		super.do_compare(rhs,comparer) &&
		RES == obj.RES &&
		ERR == obj.ERR &&
		OFLOW == obj.OFLOW &&
		COUT == obj.COUT &&
		G == obj.G &&
		L == obj.L &&
			E == obj.E;
	endfunction	
endclass


