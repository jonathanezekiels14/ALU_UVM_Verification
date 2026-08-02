class alu_driver extends uvm_driver #(alu_transaction);
	`uvm_component_utils(alu_driver)

	virtual alu_interface.INP_DRV vif;
	alu_config cfg;

	function new(string name = "alu_driver",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(alu_config)::get(this,"","alu_config",cfg))
			`uvm_fatal("alu_driver","Driver Failed to find config file");
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		this.vif = cfg.vif;
	endfunction

	task run_phase(uvm_phase phase);
		reset_pins();

		forever begin
			wait(vif.RST == 0);
			
			fork
				begin
					seq_item_port.get_next_item(req);
					drive(req);
					seq_item_port.item_done();
				end

				begin
					wait(vif.rst_n == 1'b1);
				end

			join_any

			disable fork;

			if(vif.RST == 1) begin
				`uvm_warning("DRV_RST","RST asserted mid operation, aborting transaction");
				reset_pins();
			end
		end
	endtask

	task reset_pins();
		vif.OPA <= 0;
		vif.OPB <= 0;
		vif.INP_VALID <= 0;
		vif.CMD <= 0;
		vif.MODE <= 0;
		vif.CIN <= 0;
		vif.CE <= 0;
	endtask

	task drive(alu_transaction drv_trans);
		vif.OPA <= drv_trans.OPA;
		vif.OPB <= drv_trans.OPB;
		vif.INP_VALID <= drv_trans.INP_VALID;
		vif.CMD <= drv_trans.CMD;
		vif.MODE <= drv_trans.MODE;
		vif.CIN <= drv_trans.CIN;
		vif.CE <= drv_trans.CE;
	endtask

endclass
