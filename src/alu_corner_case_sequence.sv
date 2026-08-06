class alu_corner_case_sequence extends alu_base_sequence;
  `uvm_object_utils(alu_corner_case_sequence)

  function new(string name = "alu_corner_case_sequence");
    super.new(name);
  endfunction

  virtual task body();
    alu_transaction tx;

    // ---------------------------------------------------------
    // 1. COUT Trigger (ADD with max values)
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1;         // Guarantee execution
      MODE == 1'b1;       // Arithmetic Mode
      CMD == 4'b0000;     // ADD
      INP_VALID == 2'b11;
      OPA == 8'hFF;       // Max 8-bit value
      OPB == 8'h01;       // 255 + 1 triggers COUT
    }) `uvm_error("SEQ", "COUT Trigger randomization failed!")
    finish_item(tx);

    // ---------------------------------------------------------
    // 2. Overflow Trigger (SUB: 0 - 1)
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1;
      MODE == 1'b1;       // Arithmetic Mode
      CMD == 4'b0001;     // SUB
      INP_VALID == 2'b11;
      OPA == 8'h00;
      OPB == 8'h01;       // 0 - 1 triggers OFLOW
    }) `uvm_error("SEQ", "Overflow Trigger randomization failed!")
    finish_item(tx);

    // ---------------------------------------------------------
    // 3. Multiplication Boundary Case
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1;
      MODE == 1'b1;       // Arithmetic Mode
      CMD == 4'b1001;     // MUL_INC
      INP_VALID == 2'b11;
      OPA == 8'hFF;       // Max 8-bit value
      OPB == 8'hFF;       // (255+1) * (255+1) overflows 16-bit RES to 0
    }) `uvm_error("SEQ", "Multiplication Boundary randomization failed!")
    finish_item(tx);
    
    // ---------------------------------------------------------
    // 4. Timeout Boundary Hit: OPA first, OPB at exactly cycle 16
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1; MODE == 1'b1; CMD == 4'b0000; INP_VALID == 2'b01; // OPA only
    }) `uvm_error("SEQ", "Boundary Stage 1 failed")
    finish_item(tx);

    // Hold OPA for 15 cycles to push the wait_counter to exactly 15 
    repeat (15) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        CE == 1'b1; INP_VALID == 2'b01; // FIX: Hold OPA instead of flushing with 2'b00
      }) `uvm_error("SEQ", "Boundary Idle failed")
      finish_item(tx);
    end

    // Provide OPB on the exact 16th cycle boundary
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1; MODE == 1'b1; CMD == 4'b0000; INP_VALID == 2'b10; // OPB only
    }) `uvm_error("SEQ", "Boundary Stage 2 failed")
    finish_item(tx);

    // ---------------------------------------------------------
    // 5. Timeout Boundary Hit: OPB first, OPA at exactly cycle 16
    // ---------------------------------------------------------
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1; MODE == 1'b0; CMD == 4'b0000; INP_VALID == 2'b10; // OPB only
    }) `uvm_error("SEQ", "Boundary Stage 3 failed")
    finish_item(tx);

    // Hold OPB for 15 cycles
    repeat (15) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        CE == 1'b1; INP_VALID == 2'b10; // FIX: Hold OPB instead of flushing with 2'b00
      }) `uvm_error("SEQ", "Boundary Idle failed")
      finish_item(tx);
    end

    // Provide OPA on the exact 16th cycle boundary
    tx = alu_transaction::type_id::create("tx");
    start_item(tx);
    if (!tx.randomize() with {
      CE == 1'b1; MODE == 1'b0; CMD == 4'b0000; INP_VALID == 2'b01; // OPA only
    }) `uvm_error("SEQ", "Boundary Stage 4 failed")
    finish_item(tx);

    // ---------------------------------------------------------
    // 6. ROR_A_B Bit-Sweep Expression Coverage
    // ---------------------------------------------------------
    for (int i = 4; i <= 7; i++) begin
      tx = alu_transaction::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        CE == 1'b1;
        MODE == 1'b0;
        CMD == 4'b1101;     // ROR_A_B
        INP_VALID == 2'b11;
        OPB == (1 << i);    // Walks a '1' through bits 4, 5, 6, and 7
      }) `uvm_error("SEQ", "ROR Bit-Sweep failed")
      finish_item(tx);
    end
  endtask
endclass
