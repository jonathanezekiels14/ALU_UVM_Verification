class alu_error_case_sequence extends alu_base_sequence;
	`uvm_object_utils(alu_error_case_sequence)

	function new(string name = "alu_error_case_sequence");
		super.new(name);
	endfunction

	virtual task body();
		alu_transaction tx;

		// true timeout error trigger
		repeat (17) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);
			if (!tx.randomize() with {
				CE == 1'b1;
				MODE == 1'b0;
				CMD == 4'b0000;
				INP_VALID == 2'b01;
			}) `uvm_error("SEQ", "Timeout Trigger randomization failed")
			finish_item(tx);
		end

		// explicit rotation error trigger
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b0;
			CMD == 4'b1100;
			INP_VALID == 2'b11;
			OPB > 8'h0F;
		}) `uvm_error("SEQ", "Rotation Error randomization failed")
		finish_item(tx);

		// out of bounds command check
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b0;
			CMD == 4'b1111;
			INP_VALID == 2'b11;
		}) `uvm_error("SEQ", "Invalid CMD randomization failed")
		finish_item(tx);
	endtask
endclass
