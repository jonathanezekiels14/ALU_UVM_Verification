class alu_input_agent extends uvm_agent;
        `uvm_component_utils(alu_input_agent)

        alu_driver     drv;
        alu_sequencer  seqr;
        alu_inpmon     inp_mon;
        alu_config     cfg;

        uvm_analysis_port#(alu_transaction) agent_inp_port;

        function new(string name = "alu_input_agent", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                
                if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
                        `uvm_fatal("ALU_IN_AGENT", "Failed to get alu_config from database");

                inp_mon = alu_inpmon::type_id::create("inp_mon", this);
                drv     = alu_driver::type_id::create("drv", this);
                seqr    = alu_sequencer::type_id::create("seqr", this);

                agent_inp_port = new("agent_inp_port", this);
        endfunction

        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                
                // Connect driver to sequencer
                drv.seq_item_port.connect(seqr.seq_item_export);
                
                // Forward input monitor port to agent level
                inp_mon.inp_monitor_port.connect(agent_inp_port);
        endfunction

endclass
