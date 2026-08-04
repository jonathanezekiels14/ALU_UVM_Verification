class alu_inpmon extends uvm_monitor;
        `uvm_component_utils(alu_inpmon)

        uvm_analysis_port#(alu_transaction) inp_monitor_port;
        virtual alu_interface.INP_MON vif;
        alu_config cfg;

        function new(string name="alu_inpmon", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                if(!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
                        `uvm_fatal(get_type_name(), "Input_Monitor Getting Failed");
                inp_monitor_port = new("inp_monitor_port", this);
        endfunction

        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                vif = cfg.vif;
        endfunction

        task run_phase(uvm_phase phase);
                logic [`DW-1:0] oprd1;
                logic [`DW-1:0] oprd2;
                logic has_oprd1 = 0;
                logic has_oprd2 = 0;
                int timeout_counter = 0;
                logic [`CW-1:0] current_cmd;
                logic current_mode;
                logic current_cin;
                logic current_ce;

                forever begin
                        @(vif.inp_mon_cb);

                        if (vif.inp_mon_cb.RST == 1'b1) begin
                                has_oprd1 = 0;
                                has_oprd2 = 0;
                                timeout_counter = 0;
                                continue;
                        end

                        // Track INP_VALID encoding states
                        case (vif.inp_mon_cb.INP_VALID)
                                2'b01: begin
                                        oprd1 = vif.inp_mon_cb.OPA;
                                        current_cmd = vif.inp_mon_cb.CMD;
                                        current_mode = vif.inp_mon_cb.MODE;
                                        current_cin = vif.inp_mon_cb.CIN;
                                        current_ce = vif.inp_mon_cb.CE;
                                        has_oprd1 = 1;
                                        timeout_counter = 0;
                                end
                                2'b10: begin
                                        oprd2 = vif.inp_mon_cb.OPB;
                                        current_cmd = vif.inp_mon_cb.CMD;
                                        current_mode = vif.inp_mon_cb.MODE;
                                        current_cin = vif.inp_mon_cb.CIN;
                                        current_ce = vif.inp_mon_cb.CE;
                                        has_oprd2 = 1;
                                        timeout_counter = 0;
                                end
                                2'b11: begin
                                        oprd1 = vif.inp_mon_cb.OPA;
                                        oprd2 = vif.inp_mon_cb.OPB;
                                        current_cmd = vif.inp_mon_cb.CMD;
                                        current_mode = vif.inp_mon_cb.MODE;
                                        current_cin = vif.inp_mon_cb.CIN;
                                        current_ce = vif.inp_mon_cb.CE;
                                        has_oprd1 = 1;
                                        has_oprd2 = 1;
                                        timeout_counter = 0;
                                end
                                default: begin
                                        // Do nothing. Preserve has_oprd1/has_oprd2 states 
                                        // across idle or gap cycles while waiting for the next operand.
                                end
                        endcase

                        // 16-cycle timeout logic if waiting for the second operand
                        if ((has_oprd1 ^ has_oprd2)) begin
                                timeout_counter++;
                                if (timeout_counter >= 16) begin
                                        alu_transaction timeout_tx = alu_transaction::type_id::create("timeout_tx");
                                        timeout_tx.OPA = oprd1;
                                        timeout_tx.OPB = oprd2;
                                        timeout_tx.CMD = current_cmd;
                                        timeout_tx.MODE = current_mode;
                                        timeout_tx.CIN = current_cin;
                                        timeout_tx.CE = current_ce;
                                        timeout_tx.timeout_occurred = 1'b1;

                                        inp_monitor_port.write(timeout_tx);

                                        has_oprd1 = 0;
                                        has_oprd2 = 0;
                                        timeout_counter = 0;
                                end
                        end

                        // Complete transaction when both operands are available
                        if (has_oprd1 && has_oprd2) begin
                                alu_transaction complete_tx = alu_transaction::type_id::create("complete_tx");
                                complete_tx.OPA = oprd1;
                                complete_tx.OPB = oprd2;
                                complete_tx.CMD = current_cmd;
                                complete_tx.MODE = current_mode;
                                complete_tx.CIN = current_cin;
                                complete_tx.CE = current_ce;
                                complete_tx.timeout_occurred = 1'b0;
                                inp_monitor_port.write(complete_tx);

                                has_oprd1 = 0;
                                has_oprd2 = 0;
                                timeout_counter = 0;
                        end
                end
        endtask

endclass
