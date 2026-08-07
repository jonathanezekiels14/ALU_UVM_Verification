class alu_regression_test extends alu_base_test;
	`uvm_component_utils(alu_regression_test)

	// constructor
	function new(string name = "alu_regression_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// end of elaboration phase
	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		`uvm_info("REG_TEST", "Printing Testbench Topology:", UVM_LOW)
		uvm_top.print_topology();
	endfunction

	// run phase
	virtual task run_phase(uvm_phase phase);
		alu_sanity_sequence sanity_seq;
		alu_corner_case_sequence corner_seq;
		alu_error_case_sequence error_seq;
		alu_rand_sequence rand_seq;

		// set drain time and raise objection
		phase.phase_done.set_drain_time(this, 100ns);
		phase.raise_objection(this);

		`uvm_info("REG_TEST", "==================================================", UVM_LOW)
		`uvm_info("REG_TEST", "STARTING COMPREHENSIVE ALU REGRESSION", UVM_LOW)
		`uvm_info("REG_TEST", "==================================================", UVM_LOW)

		// execute sanity test
		`uvm_info("REG_TEST", "Sanity Test", UVM_LOW)
		sanity_seq = alu_sanity_sequence::type_id::create("sanity_seq");
		sanity_seq.start(env.in_agent.seqr);

		// execute corner case test
		`uvm_info("REG_TEST", "Corner Test", UVM_LOW)
		corner_seq = alu_corner_case_sequence::type_id::create("corner_seq");
		corner_seq.start(env.in_agent.seqr);

		// execute error case test
		`uvm_info("REG_TEST", "Error Test", UVM_LOW)
		error_seq = alu_error_case_sequence::type_id::create("error_seq");
		error_seq.start(env.in_agent.seqr);

		// execute constrained random test
		`uvm_info("REG_TEST", "Rand Test", UVM_LOW)
		rand_seq = alu_rand_sequence::type_id::create("rand_seq");
		rand_seq.start(env.in_agent.seqr);

		`uvm_info("REG_TEST", "==================================================", UVM_LOW)
		`uvm_info("REG_TEST", "ALU REGRESSION SUITE COMPLETED SUCCESSFULLY", UVM_LOW)
		`uvm_info("REG_TEST", "==================================================", UVM_LOW)

		phase.drop_objection(this);
	endtask
endclass
