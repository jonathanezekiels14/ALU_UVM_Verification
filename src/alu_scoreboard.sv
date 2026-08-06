class alu_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(alu_scoreboard)

        // Replace analysis imps with analysis exports
        uvm_analysis_export #(alu_transaction) inp_export;
        uvm_analysis_export #(alu_transaction) out_export;

        // TLM Analysis FIFOs to buffer transactions
        uvm_tlm_analysis_fifo #(alu_transaction) inp_fifo;
        uvm_tlm_analysis_fifo #(alu_transaction) out_fifo;

        // Statistics counters
        int match_count = 0;
        int mismatch_count = 0;

        function new(string name = "alu_scoreboard", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                // Instantiate exports and FIFOs
                inp_export = new("inp_export", this);
                out_export = new("out_export", this);
                inp_fifo   = new("inp_fifo", this);
                out_fifo   = new("out_fifo", this);
        endfunction

        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                // Connect exports directly to the FIFOs
                inp_export.connect(inp_fifo.analysis_export);
                out_export.connect(out_fifo.analysis_export);
        endfunction

        // The run_phase consumes time and natively handles the 1-cycle delay
        task run_phase(uvm_phase phase);
                alu_transaction req_tx, exp_tx, act_tx;

                forever begin
                        // 1. Get input transaction (blocks until input monitor sends one)
                        inp_fifo.get(req_tx);

                        // 2. Clone and run reference model to predict expected output
                        $cast(exp_tx, req_tx.clone());
                        predict_output(exp_tx);

                        // 3. Get actual transaction (blocks until output monitor sends one)
                        // This blocking call natively handles the 1 clock cycle delay
                        out_fifo.get(act_tx);

                        // 4. Compare expected vs actual
                        compare_tx(exp_tx, act_tx);
                end
        endtask

        // Reference Model Logic matching the ALU Specification
        virtual function void predict_output(alu_transaction tx);
                // 1. Reset Behavior
                if (tx.RST == 1'b1) begin
                        tx.RES = 'b0;
                        tx.COUT = 1'b0;
                        tx.OFLOW = 1'b0;
                        tx.G = 1'b0;
                        tx.E = 1'b0;
                        tx.L = 1'b0;
                        tx.ERR = 1'b0;
                        return;
                end

                // Default outputs/flags initialization
                tx.RES = 'b0;    // FIX: Must clear RES to prevent garbage matching on CMP
                tx.ERR = 1'b0;
                tx.COUT = 1'b0;
                tx.OFLOW = 1'b0;
                tx.G = 1'b0;
                tx.E = 1'b0;
                tx.L = 1'b0;

                // 2. Timeout Error Condition
                if (tx.timeout_occurred) begin
                        tx.ERR = 1'b1;
                        tx.RES = 'b0;
                        return;
                end

                // 3. Execution Stage (when Clock Enable is high)
                if (tx.CE == 1'b1) begin
                        if (tx.MODE == 1'b1) begin
                                // --- ARITHMETIC OPERATIONS (MODE = 1) ---
                                logic [8:0] temp_sum; // 9-bit temp variable for carry extraction

                                case (tx.CMD)
                                        4'b0000: begin // ADD
                                                temp_sum = tx.OPA + tx.OPB;
                                                tx.COUT = temp_sum[8];
                                                tx.RES = temp_sum;
                                        end
                                        4'b0001: begin // SUB
                                                tx.OFLOW = (tx.OPA < tx.OPB) ? 1'b1 : 1'b0;
                                                tx.RES = tx.OPA - tx.OPB;
                                        end
                                        4'b0010: begin // ADD_CIN
                                                temp_sum = tx.OPA + tx.OPB + tx.CIN;
                                                tx.COUT = temp_sum[8];
                                                tx.RES = temp_sum;
                                        end
                                        4'b0011: begin // SUB_CIN
                                                tx.OFLOW = (tx.OPA < (tx.OPB + tx.CIN)) ? 1'b1 : 1'b0;
                                                tx.RES = tx.OPA - tx.OPB - tx.CIN;
                                        end
                                        4'b0100: begin // INC_A
                                                temp_sum = tx.OPA + 1'b1;
                                                tx.COUT = temp_sum[8];
                                                tx.RES = temp_sum;
                                        end
                                        4'b0101: begin // DEC_A
                                                tx.RES = tx.OPA - 1'b1;
                                        end
                                        4'b0110: begin // INC_B
                                                temp_sum = tx.OPB + 1'b1;
                                                tx.COUT = temp_sum[8];
                                                tx.RES = temp_sum;
                                        end
                                        4'b0111: begin // DEC_B
                                                tx.RES = tx.OPB - 1'b1;
                                        end
                                        4'b1000: begin // CMP
                                                if (tx.OPA > tx.OPB)      tx.G = 1'b1;
                                                else if (tx.OPA < tx.OPB) tx.L = 1'b1;
                                                else                      tx.E = 1'b1;
                                                // RES remains 0 as set by default initialization
                                        end
                                        4'b1001: begin // MUL_INC
                                                tx.RES = (tx.OPA + 1'b1) * (tx.OPB + 1'b1);
                                        end
                                        4'b1010: begin // MUL_SHL
                                                tx.RES = (tx.OPA << 1) * tx.OPB;
                                        end
                                        default: begin
                                                tx.RES = 'b0;
                                        end
                                endcase
                        end
                        else begin
                                // --- LOGICAL OPERATIONS (MODE = 0) ---
                                // (Your logical operations are perfectly fine as written)
                                case (tx.CMD)
                                        4'b0000: tx.RES = { {`DW{1'b0}}, tx.OPA & tx.OPB };        // AND
                                        4'b0001: tx.RES = { {`DW{1'b0}}, ~(tx.OPA & tx.OPB) };     // NAND
                                        4'b0010: tx.RES = { {`DW{1'b0}}, tx.OPA | tx.OPB };        // OR
                                        4'b0011: tx.RES = { {`DW{1'b0}}, ~(tx.OPA | tx.OPB) };     // NOR
                                        4'b0100: tx.RES = { {`DW{1'b0}}, tx.OPA ^ tx.OPB };        // XOR
                                        4'b0101: tx.RES = { {`DW{1'b0}}, ~(tx.OPA ^ tx.OPB) };     // XNOR
                                        4'b0110: tx.RES = { {`DW{1'b0}}, ~tx.OPA };                // NOT_A
                                        4'b0111: tx.RES = { {`DW{1'b0}}, ~tx.OPB };                // NOT_B
                                        4'b1000: tx.RES = { {`DW{1'b0}}, tx.OPA >> 1 };            // SHR1_A
                                        4'b1001: tx.RES = { {`DW{1'b0}}, tx.OPA << 1 };            // SHL1_A
                                        4'b1010: tx.RES = { {`DW{1'b0}}, tx.OPB >> 1 };            // SHR1_B
                                        4'b1011: tx.RES = { {`DW{1'b0}}, tx.OPB << 1 };            // SHL1_B
                                        4'b1100: begin // ROL_A_B
                                                if (tx.OPB[7:4] != 4'b0000) begin
                                                        tx.ERR = 1'b1;
                                                end else begin
                                                        logic [2:0] rot_amt;
                                                        rot_amt = tx.OPB[2:0];
                                                        tx.RES = { {`DW{1'b0}}, (tx.OPA << rot_amt) | (tx.OPA >> (`DW - rot_amt)) };
                                                end
                                        end
                                        4'b1101: begin // ROR_A_B
                                                if (tx.OPB[7:4] != 4'b0000) begin
                                                        tx.ERR = 1'b1;
                                                end else begin
                                                        logic [2:0] rot_amt;
                                                        rot_amt = tx.OPB[2:0];
                                                        tx.RES = { {`DW{1'b0}}, (tx.OPA >> rot_amt) | (tx.OPA << (`DW - rot_amt)) };
                                                end
                                        end
                                        default: tx.RES = 'b0;
                                endcase
                        end
                end
        endfunction
        // Cleanly extracted comparison logic
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
                        `uvm_error("SCBD_MISMATCH", $sformatf("MISMATCH #%0d!\nExpected:\n%s\nActual:\n%s",
                                           mismatch_count, exp_tx.sprint(), act_tx.sprint()))
                end
        endfunction

        function void report_phase(uvm_phase phase);
                super.report_phase(phase);
                `uvm_info("SCBD_REPORT", "----------------------------------------", UVM_LOW)
                `uvm_info("SCBD_REPORT", "ALU SCOREBOARD REPORT Summary:", UVM_LOW)
                `uvm_info("SCBD_REPORT", $sformatf("Total Matches   : %0d", match_count), UVM_LOW)
                `uvm_info("SCBD_REPORT", $sformatf("Total Mismatches: %0d", mismatch_count), UVM_LOW)
                `uvm_info("SCBD_REPORT", "----------------------------------------", UVM_LOW)
        endfunction

endclass
