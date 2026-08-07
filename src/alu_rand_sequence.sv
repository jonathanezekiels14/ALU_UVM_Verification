class alu_rand_sequence extends alu_base_sequence;
	`uvm_object_utils(alu_rand_sequence)

	rand int num_transactions;

	// constraint for number of transactions
	constraint c_num_tx {
		num_transactions inside {[1:20000]};
	}

	// constructor
	function new(string name = "alu_rand_sequence");
		super.new(name);

		// fetch plusarg or fallback to default
		if ($value$plusargs("NUM_TX=%0d", num_transactions)) begin
			`uvm_info("ALU_SEQ", $sformatf("Command-line override detected: NUM_TX set to %0d", num_transactions), UVM_LOW)
			num_transactions.rand_mode(0);
		end else begin
			num_transactions = 1000;
		end
	endfunction

	// body task
	virtual task body();
		alu_transaction tx;

		// loop for random transactions
		repeat (num_transactions) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);

			// randomize transaction with valid inputs
			if (!tx.randomize() with {
				INP_VALID == 2'b11;
			}) begin
				`uvm_error("SEQ", "Transaction randomization failed!")
			end

			finish_item(tx);
		end
	endtask
endclass
