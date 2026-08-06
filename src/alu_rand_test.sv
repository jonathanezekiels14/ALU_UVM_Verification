class alu_rand_test extends alu_base_test;
  `uvm_component_utils(alu_rand_test)

  function new(string name = "alu_rand_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_rand_sequence seq;
phase.get_objection().set_drain_time(this, 100ns);
    phase.raise_objection(this);
    `uvm_info("ALU_TEST", "Starting ALU Random Test...", UVM_LOW)
    
    seq = alu_rand_sequence::type_id::create("seq");
    seq.start(env.in_agent.seqr);
    
    `uvm_info("ALU_TEST", "ALU Random Test Completed.", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
