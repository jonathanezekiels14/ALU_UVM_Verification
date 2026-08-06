class alu_error_case_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_error_case_sequence)

  function new(string name = "alu_error_case_sequence");
    super.new(name);
  endfunction

  virtual task body();
    alu_transaction tx;

    // ---------------------------------------------------------
    // 1. True Timeout Error Trigger (Starving the 2nd operand)
    // ---------------------------------------------------------
    // Hold OPA valid (2'b01) for 17 consecutive cycles to trip the 16-cycle watchdog.
    // The RTL and Monitors will capture the latest OPA value and eventually timeout.
    repeat (17) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        CE == 1'b1; 
        MODE == 1'b0; 
        CMD == 4'b0000; 
        INP_VALID == 2'b01; // Send OPA, starve OPB
      }) `uvm_error("SEQ", "Timeout Trigger randomization failed")
      finish_item(tx);
    end

    // ---------------------------------------------------------
    // 2. Explicit Rotation Error (OPB[7:4] != 0)
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1;
      MODE == 1'b0;       // Logical Mode
      CMD == 4'b1100;     // ROL_A_B command
      INP_VALID == 2'b11;
      OPB > 8'h0F;        // Forces upper 4 bits (OPB[7:4]) to be non-zero
    }) `uvm_error("SEQ", "Rotation Error randomization failed")
    finish_item(tx);

    // ---------------------------------------------------------
    // 3. Out-of-bounds Command check
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1;
      MODE == 1'b0;
      CMD == 4'b1111;     // CMD 15 (Undefined logical command)
      INP_VALID == 2'b11;
    }) `uvm_error("SEQ", "Invalid CMD randomization failed")
    finish_item(tx);

  endtask
endclass
