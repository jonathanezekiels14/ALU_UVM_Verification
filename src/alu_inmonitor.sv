class alu_inpmon extends uvm_monitor;
	`uvm_component_utils(alu_inpmon)
	uvm_analysis_port#(trans) inp_monitor_port;

	virtual alu_interface.INP_MON vif;
	alu_config cfg;
	alu_transaction inmon_trans;

	function new(string name="alu_inpmon",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(alu_config)::get(this,"","alu_config",cfg))
			`uvm_fatal(get_type_name(),"Input_Monitor Getting Failed")
		inp_monitor_port=new("inp_monitor_port",this);
	endfunction
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		vif=cfg.vif;
	endfunction
	
	task run_phase(uvm_phase phase);
		inmon_trans=alu_transaction::type_id::create("inmon_trans");
		forever begin
			collect_input();
			`uvm_info("INPUT_MONITOR",$sformatf("Input MONITOR\n%s",inmon_trans.sprint()),UVM_NONE)
	end
		    
 endtask

 virtual task collect_input();
	begin
		//repeat(7)
        	//@(vif.inp_mon_cb);
		inmon_trans.CE        =   vif.inp_mon_cb.CE; 
		inmon_trans.INP_VALID =   vif.inp_mon_cb.INP_VALID;
	    	inmon_trans.OPA        =   vif.inp_mon_cb.OA;
		inmon_trans.OPB        =   vif.inp_mon_cb.OB;
		inmon_trans.MODE      =   vif.inp_mon_cb.MODE;
		inmon_trans.CMD       =   vif.inp_mon_cb.CMD;
		
		if((inmon_trans.MODE==1) && ((inmon_trans.cmd==4'b0010) || (inmon_trans.CMD==4'b0011)))
		begin
			inmon_trans.CIN       =   vif.inp_mon_cb.CIN;
		end
		
		inp_monitor_port.write(inmon_trans);
	    end
 endtask

endclass

