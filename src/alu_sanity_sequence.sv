class alu_sanity_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_sanity_sequence)

  function new(string name = "alu_sanity_sequence");
    super.new(name);
  endfunction

  virtual task body();
    alu_transaction tx;

    // 1. Reset / Sanity check transaction
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    assert(tx.randomize() with {
      MODE == 1;
      CMD == 0; // ADD
      INP_VALID == 2'b11;
      OPA == 10;
      OPB == 20;
    });
    finish_item(tx);

    // 2. Arithmetic Mode & Command Switching Sanity
	repeat (5) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      assert(tx.randomize() with {
        MODE == 0;
        CMD inside {[0:12]};
        INP_VALID == 2'b11;
      });
      finish_item(tx);
    end

    // 3. Logical Mode Sanity
    repeat (5) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      assert(tx.randomize() with {
        MODE == 1;
        CMD inside {[0:10]};
        INP_VALID == 2'b11;
      });
      finish_item(tx);
    end

  endtask
endclass
