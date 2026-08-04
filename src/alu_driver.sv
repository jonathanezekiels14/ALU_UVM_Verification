class alu_driver extends uvm_driver #(alu_transaction);
        `uvm_component_utils(alu_driver)

        virtual alu_interface.INP_DRV vif;
        alu_config cfg;

        function new(string name = "alu_driver", uvm_component parent);
                super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
                super.build_phase(phase);
                
                // Get configuration from database
                if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
                        `uvm_fatal("alu_driver", "Driver Failed to find config file");
        endfunction

        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);
                
                // Connect virtual interface
                this.vif = cfg.vif;
        endfunction

        task run_phase(uvm_phase phase);
                // Initialize pins
                reset_pins();

                forever begin
                        // Wait for reset to drop
                        wait(vif.RST == 0);

                        fork
                                // Process transaction
                                begin
                                        seq_item_port.get_next_item(req);
                                        drive(req);
                                        seq_item_port.item_done();
                                end
                                
                                // Monitor for reset
                                begin
                                        wait(vif.RST == 1'b1);
                                end
                        join_any

                        disable fork;

                        // Handle reset condition
                        if(vif.RST == 1) begin
                                `uvm_warning("DRV_RST", "RST asserted mid operation, aborting transaction");
                                reset_pins();
                        end
                end
        endtask

        task reset_pins();
                // Clear interface signals
                vif.inp_drv_cb.OPA <= 0;
                vif.inp_drv_cb.OPB <= 0;
                vif.inp_drv_cb.INP_VALID <= 0;
                vif.inp_drv_cb.CMD <= 0;
                vif.inp_drv_cb.MODE <= 0;
                vif.inp_drv_cb.CIN <= 0;
                vif.inp_drv_cb.CE <= 0;
        endtask

	task drive(alu_transaction drv_trans);
    		// Wait for clock edge
    		@(vif.inp_drv_cb);
    
    		// Drive transaction to interface
    		vif.inp_drv_cb.OPA       <= drv_trans.OPA;
    		vif.inp_drv_cb.OPB       <= drv_trans.OPB;
    		vif.inp_drv_cb.INP_VALID <= drv_trans.INP_VALID;
    		vif.inp_drv_cb.CMD       <= drv_trans.CMD;
    		vif.inp_drv_cb.MODE      <= drv_trans.MODE;
    		vif.inp_drv_cb.CIN       <= drv_trans.CIN;
    		vif.inp_drv_cb.CE        <= drv_trans.CE;

    		// Log driven values
    		`uvm_info("ALU_DRIVER", $sformatf("Driven Transaction -> OPA: 'h%0h | OPB: 'h%0h | INP_VALID: 'b%0b | CMD: %0d | MODE: %0b | CIN: %0b | CE: %0b", drv_trans.OPA, 
                                     drv_trans.OPB, 
                                     drv_trans.INP_VALID, 
                                     drv_trans.CMD, 
                                     drv_trans.MODE, 
                                     drv_trans.CIN, 
                                     drv_trans.CE), UVM_LOW)
		endtask	
endclass
