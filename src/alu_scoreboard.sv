class alu_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(alu_scoreboard)

	// analysis exports
	uvm_analysis_export #(alu_transaction) inp_export;
	uvm_analysis_export #(alu_transaction) out_export;

	// tlm analysis fifos
	uvm_tlm_analysis_fifo #(alu_transaction) inp_fifo;
	uvm_tlm_analysis_fifo #(alu_transaction) out_fifo;

	// statistics counters
	int match_count = 0;
	int mismatch_count = 0;

	// constructor
	function new(string name = "alu_scoreboard", uvm_component parent);
		super.new(name, parent);
	endfunction

	// build phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		inp_export = new("inp_export", this);
		out_export = new("out_export", this);
		inp_fifo = new("inp_fifo", this);
		out_fifo = new("out_fifo", this);
	endfunction

	// connect phase
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		inp_export.connect(inp_fifo.analysis_export);
		out_export.connect(out_fifo.analysis_export);
	endfunction

	// run phase
	task run_phase(uvm_phase phase);
		alu_transaction req_tx, exp_tx, act_tx;

		forever begin
			// get transactions
			inp_fifo.get(req_tx);
			$cast(exp_tx, req_tx.clone());
			predict_output(exp_tx);
			out_fifo.get(act_tx);

			// compare expected vs actual
			compare_tx(exp_tx, act_tx);
		end
	endtask

	// reference model
	virtual function void predict_output(alu_transaction tx);
		logic [8:0] temp_sum;

		// handle reset
		if (tx.RST == 1'b1) begin
			tx.RES = 0;
			tx.COUT = 0;
			tx.OFLOW = 0;
			tx.G = 0;
			tx.E = 0;
			tx.L = 0;
			tx.ERR = 0;
			return;
		end

		// initialize defaults
		tx.RES = 0;
		tx.ERR = 0;
		tx.COUT = 0;
		tx.OFLOW = 0;
		tx.G = 0;
		tx.E = 0;
		tx.L = 0;

		// handle timeout
		if (tx.timeout_occurred) begin
			tx.ERR = 1'b1;
			tx.RES = 0;
			return;
		end

		// execute operation
		if (tx.CE == 1'b1) begin
			if (tx.MODE == 1'b1) begin
				// arithmetic operations
				case (tx.CMD)
					4'b0000: begin
						temp_sum = tx.OPA + tx.OPB;
						tx.COUT = temp_sum[8];
						tx.RES = temp_sum;
					end
					4'b0001: begin
						tx.OFLOW = (tx.OPA < tx.OPB) ? 1'b1 : 1'b0;
						tx.RES = tx.OPA - tx.OPB;
					end
					4'b0010: begin
						temp_sum = tx.OPA + tx.OPB + tx.CIN;
						tx.COUT = temp_sum[8];
						tx.RES = temp_sum;
					end
					4'b0011: begin
						tx.OFLOW = (tx.OPA < (tx.OPB + tx.CIN)) ? 1'b1 : 1'b0;
						tx.RES = tx.OPA - tx.OPB - tx.CIN;
					end
					4'b0100: begin
						temp_sum = tx.OPA + 1'b1;
						tx.COUT = temp_sum[8];
						tx.RES = temp_sum;
					end
					4'b0101: begin
						tx.RES = tx.OPA - 1'b1;
					end
					4'b0110: begin
						temp_sum = tx.OPB + 1'b1;
						tx.COUT = temp_sum[8];
						tx.RES = temp_sum;
					end
					4'b0111: begin
						tx.RES = tx.OPB - 1'b1;
					end
					4'b1000: begin
						if (tx.OPA > tx.OPB) tx.G = 1'b1;
						else if (tx.OPA < tx.OPB) tx.L = 1'b1;
						else tx.E = 1'b1;
					end
					4'b1001: begin
						tx.RES = (tx.OPA + 1'b1) * (tx.OPB + 1'b1);
					end
					4'b1010: begin
						tx.RES = (tx.OPA << 1) * tx.OPB;
					end
					default: begin
						tx.RES = 0;
					end
				endcase
			end else begin
				// logical operations
				case (tx.CMD)
					4'b0000: tx.RES = { {`DW{1'b0}}, tx.OPA & tx.OPB };
					4'b0001: tx.RES = { {`DW{1'b0}}, ~(tx.OPA & tx.OPB) };
					4'b0010: tx.RES = { {`DW{1'b0}}, tx.OPA | tx.OPB };
					4'b0011: tx.RES = { {`DW{1'b0}}, ~(tx.OPA | tx.OPB) };
					4'b0100: tx.RES = { {`DW{1'b0}}, tx.OPA ^ tx.OPB };
					4'b0101: tx.RES = { {`DW{1'b0}}, ~(tx.OPA ^ tx.OPB) };
					4'b0110: tx.RES = { {`DW{1'b0}}, ~tx.OPA };
					4'b0111: tx.RES = { {`DW{1'b0}}, ~tx.OPB };
					4'b1000: tx.RES = { {`DW{1'b0}}, tx.OPA >> 1 };
					4'b1001: tx.RES = { {`DW{1'b0}}, tx.OPA << 1 };
					4'b1010: tx.RES = { {`DW{1'b0}}, tx.OPB >> 1 };
					4'b1011: tx.RES = { {`DW{1'b0}}, tx.OPB << 1 };
					4'b1100: begin
						if (tx.OPB[7:4] != 4'b0000) begin
							tx.ERR = 1'b1;
						end else begin
							logic [2:0] rot_amt;
							rot_amt = tx.OPB[2:0];
							tx.RES = { {`DW{1'b0}}, (tx.OPA << rot_amt) | (tx.OPA >> (`DW - rot_amt)) };
						end
					end
					4'b1101: begin
						if (tx.OPB[7:4] != 4'b0000) begin
							tx.ERR = 1'b1;
						end else begin
							logic [2:0] rot_amt;
							rot_amt = tx.OPB[2:0];
							tx.RES = { {`DW{1'b0}}, (tx.OPA >> rot_amt) | (tx.OPA << (`DW - rot_amt)) };
						end
					end
					default: tx.RES = 0;
				endcase
			end
		end
	endfunction

	// comparison logic
	virtual function void compare_tx(alu_transaction exp_tx, alu_transaction act_tx);
		if ((act_tx.RES === exp_tx.RES) &&
			(act_tx.COUT === exp_tx.COUT) &&
			(act_tx.OFLOW === exp_tx.OFLOW) &&
			(act_tx.G === exp_tx.G) &&
			(act_tx.E === exp_tx.E) &&
			(act_tx.L === exp_tx.L) &&
			(act_tx.ERR === exp_tx.ERR)) begin
			match_count++;
			`uvm_info("SCBD_MATCH", $sformatf("PASS! Match Count: %0d", match_count), UVM_HIGH)
		end else begin
			mismatch_count++;
			`uvm_error("SCBD_MISMATCH", $sformatf("MISMATCH #%0d!\nExpected:\n%s\nActual:\n%s", mismatch_count, exp_tx.sprint(), act_tx.sprint()))
		end
	endfunction

	// report phase
	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		`uvm_info("SCBD_REPORT", "----------------------------------------", UVM_LOW)
		`uvm_info("SCBD_REPORT", "ALU SCOREBOARD REPORT Summary:", UVM_LOW)
		`uvm_info("SCBD_REPORT", $sformatf("Total Matches: %0d", match_count), UVM_LOW)
		`uvm_info("SCBD_REPORT", $sformatf("Total Mismatches: %0d", mismatch_count), UVM_LOW)
		`uvm_info("SCBD_REPORT", "----------------------------------------", UVM_LOW)
	endfunction

endclass
