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
    if (!tx.randomize() with {
      CE == 1'b1;         // FIX: Guarantee execution
      MODE == 1'b1;       // Arithmetic Mode
      CMD == 4'b0000;     // ADD
      INP_VALID == 2'b11;
      OPA == 10;
      OPB == 20;
    }) `uvm_error("SEQ", "Transaction 1 randomization failed!")
    finish_item(tx);

    // 2. Arithmetic Mode Sanity
    repeat (5) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        CE == 1'b1;         // FIX: Guarantee execution
        MODE == 1'b1;       // FIX: Swapped to 1 to match Arithmetic Mode
        CMD inside {[0:10]}; // Valid commands for Arithmetic are 0-10
        INP_VALID == 2'b11;
      }) `uvm_error("SEQ", "Arithmetic transaction randomization failed!")
      finish_item(tx);
    end

    // 3. Logical Mode Sanity
    repeat (5) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        CE == 1'b1;         // FIX: Guarantee execution
        MODE == 1'b0;       // FIX: Swapped to 0 to match Logical Mode
        CMD inside {[0:13]}; // FIX: Extended to 13 to include ROR_A_B
        INP_VALID == 2'b11;
      }) `uvm_error("SEQ", "Logical transaction randomization failed!")
      finish_item(tx);
    end

  endtask
endclass
