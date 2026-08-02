class alu_corner_case_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_corner_case_sequence)

  function new(string name = "alu_corner_case_sequence");
    super.new(name);
  endfunction

  virtual task body();
    alu_transaction tx;

    // 1. COUT Trigger (ADD with max values)
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    assert(tx.randomize() with {
      MODE == 0; CMD == 0; INP_VALID == 2'b11; OPA == 32'hFFFFFFFF; OPB == 32'h00000001;
    });
    finish_item(tx);

    // 2. Overflow Trigger (SUB: 0 - 1)
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    assert(tx.randomize() with {
      MODE == 0; CMD == 1; INP_VALID == 2'b11; OPA == 32'h00000000; OPB == 32'h00000001;
    });
    finish_item(tx);

    // 3. Multiplication Boundary Case
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    assert(tx.randomize() with {
      MODE == 0; CMD == 9; INP_VALID == 2'b11; OPA == 32'hFFFFFFFF; OPB == 32'hFFFFFFFF;
    });
    finish_item(tx);
  endtask
endclass
