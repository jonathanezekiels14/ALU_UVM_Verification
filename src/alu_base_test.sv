class alu_base_test extends uvm_test;
        `uvm_component_utils(alu_base_test)

        alu_env     env;
        alu_config  cfg;
        virtual alu_interface vif;

        function new(string name = "alu_base_test", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                env = alu_env::type_id::create("env", this);
                cfg = alu_config::type_id::create("cfg");

                if (!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", cfg.vif))
                        `uvm_fatal("ALU_TEST", "Virtual interface failed to get from config DB");

                uvm_config_db#(alu_config)::set(this, "*", "alu_config", cfg);
        endfunction

        task run_phase(uvm_phase phase);
                phase.raise_objection(this);
                #1us;
                phase.drop_objection(this);
        endtask

        function void report_phase(uvm_phase phase);
                super.report_phase(phase);
                `uvm_info("TEST_REPORT", "Test execution completed successfully.", UVM_LOW);
        endfunction

endclass
