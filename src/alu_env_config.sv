class alu_config extends uvm_object;
  `uvm_object_utils(alu_config)

  // Virtual Interface handle
  virtual alu_interface vif;
  function new(string name = "alu_config");
    super.new(name);
  endfunction
endclass
