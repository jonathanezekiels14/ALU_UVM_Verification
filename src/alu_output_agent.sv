class alu_output_agent extends uvm_agent;
        `uvm_component_utils(alu_output_agent)

        alu_outmonitor out_mon;
        alu_config     cfg;

        uvm_analysis_port#(alu_transaction) agent_out_port;

        function new(string name = "alu_output_agent", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                
                if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
                        `uvm_fatal("ALU_OUT_AGENT", "Failed to get alu_config from database");

                out_mon = alu_outmonitor::type_id::create("out_mon", this);
                agent_out_port = new("agent_out_port", this);
        endfunction

        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                
                // Forward output monitor port to agent level
                out_mon.out_monitor_port.connect(agent_out_port);
        endfunction

endclass
