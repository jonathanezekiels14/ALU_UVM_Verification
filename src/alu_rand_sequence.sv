class alu_rand_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_rand_sequence)

  rand int num_transactions;

  // 1. Bound the random generation so it doesn't freeze the simulator or skip the loop
  constraint c_num_tx {
    num_transactions inside {[1:20000]};
  }

  function new(string name = "alu_rand_sequence");
    super.new(name);
    
    // 2. Fetch the plusarg immediately upon creation
    if ($value$plusargs("NUM_TX=%0d", num_transactions)) begin
      `uvm_info("ALU_SEQ", $sformatf("Command-line override detected: NUM_TX set to %0d", num_transactions), UVM_LOW)
      // Lock the variable so seq.randomize() doesn't overwrite the command-line argument
      num_transactions.rand_mode(0); 
    end else begin
      num_transactions = 1000; // Default fallback
    end
  endfunction

  virtual task body();
    alu_transaction tx;

    repeat (num_transactions) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      
      // 3. Fix the scope error and use standard UVM if-check for randomization
      if (!tx.randomize() with {
          INP_VALID == 2'b11; // Ensure both operands are captured for clean pipeline flow
      }) begin
          `uvm_error("SEQ", "Transaction randomization failed!")
      end
      
      finish_item(tx);
    end
  endtask
endclass
