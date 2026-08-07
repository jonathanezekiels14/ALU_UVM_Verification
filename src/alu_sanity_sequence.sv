class alu_sanity_sequence extends alu_base_sequence;
	`uvm_object_utils(alu_sanity_sequence)

	// constructor
	function new(string name = "alu_sanity_sequence");
		super.new(name);
	endfunction

	// body task
	virtual task body();
		alu_transaction tx;

		// basic add transaction
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b1;
			CMD == 4'b0000;
			INP_VALID == 2'b11;
			OPA == 10;
			OPB == 20;
		}) `uvm_error("SEQ", "Transaction 1 randomization failed!")
		finish_item(tx);


		// arithmetic mode loop
		repeat (5) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);
			if (!tx.randomize() with {
				CE == 1'b1;
				MODE == 1'b1;
				CMD inside {[0:10]};
				INP_VALID == 2'b11;
			}) `uvm_error("SEQ", "Arithmetic transaction randomization failed!")
			finish_item(tx);
		end

		// logical mode loop
		repeat (5) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);
			if (!tx.randomize() with {
				CE == 1'b1;
				MODE == 1'b0;
				CMD inside {[0:13]};
				INP_VALID == 2'b11;
			}) `uvm_error("SEQ", "Logical transaction randomization failed!")
			finish_item(tx);
		end
	endtask
endclass
