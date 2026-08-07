class alu_sanity_test extends alu_base_test;
	`uvm_component_utils(alu_sanity_test)

	// constructor
	function new(string name = "alu_sanity_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// run phase
	virtual task run_phase(uvm_phase phase);
		alu_sanity_sequence seq;
		
		// set drain time to allow last transaction to complete
		phase.phase_done.set_drain_time(this, 100ns);
		
		// start sequence execution
		phase.raise_objection(this);
		seq = alu_sanity_sequence::type_id::create("seq");
		seq.start(env.in_agent.seqr);
		phase.drop_objection(this);
	endtask
endclass
