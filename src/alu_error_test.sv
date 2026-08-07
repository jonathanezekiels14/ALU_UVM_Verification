class alu_error_test extends alu_base_test;
	`uvm_component_utils(alu_error_test)

	// constructor
	function new(string name = "alu_error_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// run phase
	virtual task run_phase(uvm_phase phase);
		alu_error_case_sequence seq;

		// set drain time and execute sequence
		phase.phase_done.set_drain_time(this, 100ns);
		phase.raise_objection(this);
		seq = alu_error_case_sequence::type_id::create("seq");
		seq.start(env.in_agent.seqr);
		phase.drop_objection(this);
	endtask
endclass
