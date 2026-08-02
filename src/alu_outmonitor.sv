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
		forever begin
        		@(vif.out_mon_cb);

        		// Handle reset condition
        		if (vif.out_mon_cb.RST == 1'b1) begin
            			continue;
        		end

        		// Sample output only when Clock Enable (CE) is active
        		if (vif.out_mon_cb.CE == 1'b1) begin
            			alu_transaction tx = alu_transaction::type_id::create("tx");

            			// --- POPULATE INPUTS ---
            			tx.OPA     = vif.out_mon_cb.OPA;
            			tx.OPB     = vif.out_mon_cb.OPB;
            			tx.CMD     = vif.out_mon_cb.CMD;
            			tx.MODE    = vif.out_mon_cb.MODE;
            			tx.CIN     = vif.out_mon_cb.CIN;
            			tx.CE      = vif.out_mon_cb.CE;

            			// --- POPULATE OUTPUTS ---
            			tx.RES     = vif.out_mon_cb.RES;
            			tx.COUT    = vif.out_mon_cb.COUT;
            			tx.OFLOW   = vif.out_mon_cb.OFLOW;
            			tx.ERR     = vif.out_mon_cb.ERR;
            			tx.G       = vif.out_mon_cb.G;
            			tx.L       = vif.out_mon_cb.L;
            			tx.E       = vif.out_mon_cb.E;

           			out_monitor_port.write(tx);
			end
    		end
	endtask	
endclass
