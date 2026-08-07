class alu_corner_case_sequence extends alu_base_sequence;
	`uvm_object_utils(alu_corner_case_sequence)

	function new(string name = "alu_corner_case_sequence");
		super.new(name);
	endfunction

	virtual task body();
		alu_transaction tx;

		// cout trigger test
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b1;
			CMD == 4'b0000;
			INP_VALID == 2'b11;
			OPA == 8'hFF;
			OPB == 8'h01;
		}) `uvm_error("SEQ", "COUT Trigger randomization failed!")
		finish_item(tx);

		// overflow trigger test
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b1;
			CMD == 4'b0001;
			INP_VALID == 2'b11;
			OPA == 8'h00;
			OPB == 8'h01;
		}) `uvm_error("SEQ", "Overflow Trigger randomization failed!")
		finish_item(tx);

		// multiplication boundary test
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b1;
			CMD == 4'b1001;
			INP_VALID == 2'b11;
			OPA == 8'hFF;
			OPB == 8'hFF;
		}) `uvm_error("SEQ", "Multiplication Boundary randomization failed!")
		finish_item(tx);

		// timeout boundary hit opa first
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b1;
			CMD == 4'b0000;
			INP_VALID == 2'b01;
		}) `uvm_error("SEQ", "Boundary Stage 1 failed")
		finish_item(tx);

		repeat (15) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);
			if (!tx.randomize() with {
				CE == 1'b1;
				INP_VALID == 2'b01;
			}) `uvm_error("SEQ", "Boundary Idle failed")
			finish_item(tx);
		end

		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b1;
			CMD == 4'b0000;
			INP_VALID == 2'b10;
		}) `uvm_error("SEQ", "Boundary Stage 2 failed")
		finish_item(tx);

		// timeout boundary hit opb first
		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b0;
			CMD == 4'b0000;
			INP_VALID == 2'b10;
		}) `uvm_error("SEQ", "Boundary Stage 3 failed")
		finish_item(tx);

		repeat (15) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);
			if (!tx.randomize() with {
				CE == 1'b1;
				INP_VALID == 2'b10;
			}) `uvm_error("SEQ", "Boundary Idle failed")
			finish_item(tx);
		end

		tx = alu_transaction::type_id::create("tx");
		start_item(tx);
		if (!tx.randomize() with {
			CE == 1'b1;
			MODE == 1'b0;
			CMD == 4'b0000;
			INP_VALID == 2'b01;
		}) `uvm_error("SEQ", "Boundary Stage 4 failed")
		finish_item(tx);

		// ror bit sweep coverage test
		for (int i = 4; i <= 7; i++) begin
			tx = alu_transaction::type_id::create("tx");
			start_item(tx);
			if (!tx.randomize() with {
				CE == 1'b1;
				MODE == 1'b0;
				CMD == 4'b1101;
				INP_VALID == 2'b11;
				OPB == (1 << i);
			}) `uvm_error("SEQ", "ROR Bit-Sweep failed")
			finish_item(tx);
		end
	endtask
endclass
