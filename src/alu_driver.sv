class alu_driver extends uvm_driver #(alu_transaction);
    `uvm_component_utils(alu_driver)
    virtual alu_interface.INP_DRV vif;
    alu_config cfg;

    function new(string name = "alu_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
            `uvm_fatal("alu_driver", "Driver Failed to find config file");
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        this.vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        reset_pins();

        forever begin
            wait(vif.RST == 0);
            // REMOVED THE REDUNDANT @(vif.inp_drv_cb) HERE!

            seq_item_port.get_next_item(req);

            fork
                begin drive(req); end
                begin wait(vif.RST == 1'b1); end
            join_any

            disable fork;

            if(vif.RST == 1'b1) begin
                reset_pins();
            end
            
            seq_item_port.item_done();
        end
    endtask

    task reset_pins();
        vif.inp_drv_cb.OPA       <= 0;
        vif.inp_drv_cb.OPB       <= 0;
        vif.inp_drv_cb.INP_VALID <= 0;
        vif.inp_drv_cb.CMD       <= 0;
        vif.inp_drv_cb.MODE      <= 0;
        vif.inp_drv_cb.CIN       <= 0;
        vif.inp_drv_cb.CE        <= 0;
    endtask

    task drive(alu_transaction drv_trans);
        @(vif.inp_drv_cb); // Wait for exact clock edge
        
        vif.inp_drv_cb.OPA       <= drv_trans.OPA;
        vif.inp_drv_cb.OPB       <= drv_trans.OPB;
        vif.inp_drv_cb.INP_VALID <= drv_trans.INP_VALID;
        vif.inp_drv_cb.CMD       <= drv_trans.CMD;
        vif.inp_drv_cb.MODE      <= drv_trans.MODE;
        vif.inp_drv_cb.CIN       <= drv_trans.CIN;
        vif.inp_drv_cb.CE        <= drv_trans.CE;
        
        // NO ARTIFICIAL 2'b00 FLUSH HERE. The sequence controls the bus!
    endtask
endclass
