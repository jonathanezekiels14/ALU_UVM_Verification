class alu_corner_test extends alu_base_test;
  `uvm_component_utils(alu_corner_test)

  function new(string name = "alu_corner_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_corner_case_sequence seq;
    phase.raise_objection(this);
    seq = alu_corner_case_sequence::type_id::create("seq");
    seq.start(env.in_agent.seqr);
    phase.drop_objection(this);
  endtask
endclass
