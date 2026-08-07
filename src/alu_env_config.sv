class alu_config extends uvm_object;
	`uvm_object_utils(alu_config)

	// virtual interface handle
	virtual alu_interface vif;

	// active or passive agent control
	uvm_active_passive_enum is_active = UVM_ACTIVE;

	// constructor
	function new(string name = "alu_config");
		super.new(name);
	endfunction
endclass
