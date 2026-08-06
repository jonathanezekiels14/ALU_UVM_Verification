class alu_outmon extends uvm_monitor;
    `uvm_component_utils(alu_outmon)

    uvm_analysis_port#(alu_transaction) out_monitor_port;
    virtual alu_interface.OUT_MON vif;
    alu_config cfg;

    function new(string name="alu_outmon", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
            `uvm_fatal(get_type_name(), "Output_Monitor Config Getting Failed");
        out_monitor_port = new("out_monitor_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        logic has_oprd1 = 0;
        logic has_oprd2 = 0;
        int timeout_counter = 0;
        logic [3:0] current_cmd;
        logic current_mode;

        forever begin
            @(vif.out_mon_cb);

            if (vif.out_mon_cb.RST == 1'b1) begin
                has_oprd1 = 0;
                has_oprd2 = 0;
                timeout_counter = 0;
                continue;
            end

            if (vif.out_mon_cb.CE == 1'b1) begin
                // 1. Track two-stage input state and flush
                case (vif.out_mon_cb.INP_VALID)
                    2'b01: begin 
                        has_oprd1 = 1; 
                        current_cmd = vif.out_mon_cb.CMD;
                        current_mode = vif.out_mon_cb.MODE;
                    end
                    2'b10: begin 
                        has_oprd2 = 1; 
                        current_cmd = vif.out_mon_cb.CMD;
                        current_mode = vif.out_mon_cb.MODE;
                    end
                    2'b11: begin 
                        has_oprd1 = 1; 
                        has_oprd2 = 1; 
                        current_cmd = vif.out_mon_cb.CMD;
                        current_mode = vif.out_mon_cb.MODE;
                        timeout_counter = 0; 
                    end
                    default: begin // 2'b00 explicitly clears captured operands
                        has_oprd1 = 0; 
                        has_oprd2 = 0; 
                        timeout_counter = 0; 
                    end
                endcase

                // 2. Check for Timeout Condition
                if (has_oprd1 ^ has_oprd2) begin
                    timeout_counter++;
                    if (timeout_counter >= 16) begin
                        // Timeout hit! Spawn thread to capture the ERR flag
                        spawn_capture_thread(current_mode, current_cmd, 1);
                        has_oprd1 = 0; has_oprd2 = 0; timeout_counter = 0;
                    end
                end

                // 3. Check for Complete Operation
                if (has_oprd1 && has_oprd2) begin
                    // Both operands hit! Spawn thread to capture the math result
                    spawn_capture_thread(current_mode, current_cmd, 0);
                    has_oprd1 = 0; has_oprd2 = 0; timeout_counter = 0;
                end
            end
        end
    endtask

    // Background thread to wait for DUT execution latency 
    // FIX: MUST be 'automatic' so concurrent threads don't overwrite each other
    task automatic spawn_capture_thread(logic mode, logic [3:0] cmd, logic is_timeout);
        fork
            begin
                int latency_cycles;

                if (is_timeout) begin
                    latency_cycles = 2; // 1 cycle for ERR flag to assert + 1 sampling offset
                end else if (mode == 1'b1 && (cmd == 4'b1001 || cmd == 4'b1010)) begin
                    latency_cycles = 4; // 3-cycle operation + 1 clocking block offset
                end else begin
                    latency_cycles = 2; // 1-cycle operation + 1 clocking block offset
                end

                // Wait for the required number of ACTIVE CE cycles
                repeat (latency_cycles) begin
                    do @(vif.out_mon_cb);
                    while (vif.out_mon_cb.CE != 1'b1);
                end

                // Capture Outputs
                begin
                    alu_transaction tx = alu_transaction::type_id::create("tx");
                    tx.RES   = vif.out_mon_cb.RES;
                    tx.COUT  = vif.out_mon_cb.COUT;
                    tx.OFLOW = vif.out_mon_cb.OFLOW;
                    tx.ERR   = vif.out_mon_cb.ERR;
                    tx.G     = vif.out_mon_cb.G;
                    tx.L     = vif.out_mon_cb.L;
                    tx.E     = vif.out_mon_cb.E;
                    tx.timeout_occurred = is_timeout;

                    out_monitor_port.write(tx);
                end
            end
        join_none
    endtask
endclass
