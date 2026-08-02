// Declare analysis implementation ports for separate input and output monitors
`uvm_analysis_imp_decl(_inp)
`uvm_analysis_imp_decl(_out)

class alu_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(alu_scoreboard)

        // Analysis implementation ports
        uvm_analysis_imp_inp #(alu_transaction, alu_scoreboard) inp_imp;
        uvm_analysis_imp_out #(alu_transaction, alu_scoreboard) out_imp;

        // Queue to store expected transactions predicted by the reference model
        alu_transaction exp_queue[$];

        // Statistics counters
        int match_count = 0;
        int mismatch_count = 0;

        function new(string name = "alu_scoreboard", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                inp_imp = new("inp_imp", this);
                out_imp = new("out_imp", this);
        endfunction

        // Receives input transaction, predicts expected output using reference model, and pushes to queue
        virtual function void write_inp(alu_transaction req);
                alu_transaction exp_tx;
                $cast(exp_tx, req.clone()); // Create an independent copy for the reference model

                predict_output(exp_tx);
                exp_queue.push_back(exp_tx);
        endfunction

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
                                case (tx.CMD)
                                        4'b0000: begin // ADD
                                                {tx.COUT, tx.RES} = {1'b0, tx.OPA} + {1'b0, tx.OPB};
                                        end
                                        4'b0001: begin // SUB
                                                {tx.OFLOW, tx.RES} = {1'b0, tx.OPA} - {1'b0, tx.OPB};
                                        end
                                        4'b0010: begin // ADD_CIN
                                                {tx.COUT, tx.RES} = {1'b0, tx.OPA} + {1'b0, tx.OPB} + {8'b0, tx.CIN};
                                        end
                                        4'b0011: begin // SUB_CIN
                                                {tx.OFLOW, tx.RES} = {1'b0, tx.OPA} - {1'b0, tx.OPB} - {8'b0, tx.CIN};
                                        end
                                        4'b0100: begin // INC_A
                                                tx.RES = tx.OPA + 1'b1;
                                        end
                                        4'b0101: begin // DEC_A
                                                tx.RES = tx.OPA - 1'b1;
                                        end
                                        4'b0110: begin // INC_B
                                                tx.RES = tx.OPB + 1'b1;
                                        end
                                        4'b0111: begin // DEC_B
                                                tx.RES = tx.OPB - 1'b1;
                                        end
                                        4'b1000: begin // CMP
                                                if (tx.OPA > tx.OPB)      tx.G = 1'b1;
                                                else if (tx.OPA < tx.OPB) tx.L = 1'b1;
                                                else                      tx.E = 1'b1;
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
                                case (tx.CMD)
                                        4'b0000: tx.RES = { {`DW{1'b0}}, tx.OPA & tx.OPB };        // AND
                                        4'b0001: tx.RES = { {`DW{1'b0}}, ~(tx.OPA & tx.OPB) };      // NAND
                                        4'b0010: tx.RES = { {`DW{1'b0}}, tx.OPA | tx.OPB };        // OR
                                        4'b0011: tx.RES = { {`DW{1'b0}}, ~(tx.OPA | tx.OPB) };      // NOR
                                        4'b0100: tx.RES = { {`DW{1'b0}}, tx.OPA ^ tx.OPB };        // XOR
                                        4'b0101: tx.RES = { {`DW{1'b0}}, ~(tx.OPA ^ tx.OPB) };      // XNOR
                                        4'b0110: tx.RES = { {`DW{1'b0}}, ~tx.OPA };                 // NOT_A
                                        4'b0111: tx.RES = { {`DW{1'b0}}, ~tx.OPB };                 // NOT_B
                                        4'b1000: tx.RES = { {`DW{1'b0}}, tx.OPA >> 1 };             // SHR1_A
                                        4'b1001: tx.RES = { {`DW{1'b0}}, tx.OPA << 1 };             // SHL1_A
                                        4'b1010: tx.RES = { {`DW{1'b0}}, tx.OPB >> 1 };             // SHR1_B
                                        4'b1011: tx.RES = { {`DW{1'b0}}, tx.OPB << 1 };             // SHL1_B
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

        // Receives actual transaction from output monitor and compares against expected prediction queue
        virtual function void write_out(alu_transaction act_tx);
                alu_transaction exp_tx;

                if (exp_queue.size() > 0) begin
                        exp_tx = exp_queue.pop_front();

                        // Compare critical fields (RES, Flags, ERR)
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
                end else begin
                        `uvm_error("SCBD_UNEXPECTED", "Received output monitor transaction but expected queue is empty")
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
