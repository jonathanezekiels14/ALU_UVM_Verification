class alu_base_sequence extends uvm_sequence#(alu_transaction);
  `uvm_object_utils(alu_base_sequence)

  function new(string name = "alu_base_sequence");
    super.new(name);
  endfunction
endclass
