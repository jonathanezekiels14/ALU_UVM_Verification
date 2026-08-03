class alu_error_case_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_error_case_sequence)

  function new(string name = "alu_error_case_sequence");
    super.new(name);
  endfunction

  virtual task body();
    alu_transaction tx;

    // 1. Missing second input valid (INP_VALID = 2'b01)
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    assert(tx.randomize() with {
      MODE == 0; CMD == 0; INP_VALID == 2'b01;
    });
    finish_item(tx);

    start_item(tx);
    assert(tx.randomize() with {
	    MODE == 0; CMD ==0; INP_VALID == 2'b10;
    });
    finish_item(tx);
    // 2. Out-of-bounds Command check
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    assert(tx.randomize() with {
      MODE == 0; CMD == 15; INP_VALID == 2'b11;
    });
    finish_item(tx);
  endtask
endclass
