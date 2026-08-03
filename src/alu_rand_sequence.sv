class alu_rand_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_rand_sequence)

  rand int num_transactions;

  function new(string name = "alu_rand_sequence");
    super.new(name);
    num_transactions = 1000; // Default fallback if plusarg is absent
  endfunction

  virtual task pre_start();
    super.pre_start();
    if ($value$plusargs("NUM_TX=%0d", num_transactions)) begin
      `uvm_info("ALU_SEQ", $sformatf("Command-line override detected: NUM_TX set to %0d", num_transactions), UVM_LOW)
    end else begin
      `uvm_info("ALU_SEQ", $sformatf("No +NUM_TX plusarg found. Using default: %0d", num_transactions), UVM_LOW)
    end
  endtask

  virtual task body();
    alu_transaction tx;

    repeat (num_transactions) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      assert(tx.randomize() with {
	      INP_VALID < 4;
      }) else `uvm_error("SEQ", "Transaction randomization failed!");
      finish_item(tx);
    end
  endtask
endclass
