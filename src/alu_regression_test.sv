class alu_regression_test extends alu_base_test;
  `uvm_component_utils(alu_regression_test)

  function new(string name = "alu_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_sanity_sequence      sanity_seq;
    alu_corner_case_sequence corner_seq;
    alu_error_case_sequence  error_seq;
    alu_rand_sequence        rand_seq;
phase.phase_done.set_drain_time(this, 100ns);
    phase.raise_objection(this);

    `uvm_info("REG_TEST", "==================================================", UVM_LOW)
    `uvm_info("REG_TEST", "       STARTING COMPREHENSIVE ALU REGRESSION      ", UVM_LOW)
    `uvm_info("REG_TEST", "==================================================", UVM_LOW)

    // 1. Sanity
	
    `uvm_info("REG_TEST", "Sanity Test", UVM_LOW)
    sanity_seq = alu_sanity_sequence::type_id::create("sanity_seq");
    sanity_seq.start(env.in_agent.seqr);

    `uvm_info("REG_TEST", "Corner Test", UVM_LOW)
    // 2. Corner Case
    corner_seq = alu_corner_case_sequence::type_id::create("corner_seq");
    corner_seq.start(env.in_agent.seqr);

    `uvm_info("REG_TEST", "Error Test", UVM_LOW)
    // 3. Error Case
    error_seq = alu_error_case_sequence::type_id::create("error_seq");
    error_seq.start(env.in_agent.seqr);

    `uvm_info("REG_TEST", "Rand Test", UVM_LOW)
    // 4. Constrained Random (Pulls +NUM_TX if provided, otherwise uses 1000 default)
    rand_seq = alu_rand_sequence::type_id::create("rand_seq");
    rand_seq.start(env.in_agent.seqr);

    `uvm_info("REG_TEST", "==================================================", UVM_LOW)
    `uvm_info("REG_TEST", "    ALU REGRESSION SUITE COMPLETED SUCCESSFULLY   ", UVM_LOW)
    `uvm_info("REG_TEST", "==================================================", UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass
