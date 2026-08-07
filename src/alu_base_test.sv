class alu_base_test extends uvm_test;
	`uvm_component_utils(alu_base_test)

	// declare environment and config
	alu_env env;
	alu_config cfg;
	virtual alu_interface vif;

	// constructor
	function new(string name = "alu_base_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	// build phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = alu_env::type_id::create("env", this);
		cfg = alu_config::type_id::create("cfg");
		// get virtual interface
		if (!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", cfg.vif))
			`uvm_fatal("ALU_TEST", "Virtual interface failed to get from config DB");
		// set config in database
		uvm_config_db#(alu_config)::set(this, "*", "alu_config", cfg);
	endfunction

	// run phase
	task run_phase(uvm_phase phase);
		// set drain time to allow last transaction to complete
		phase.phase_done.set_drain_time(this, 100ns);
		phase.raise_objection(this);
		#1us;
		phase.drop_objection(this);
	endtask

	// report phase
	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		`uvm_info("TEST_REPORT", "Test execution completed successfully.", UVM_LOW);
	endfunction
endclass
