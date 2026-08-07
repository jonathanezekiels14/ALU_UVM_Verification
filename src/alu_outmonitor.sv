class alu_outmon extends uvm_monitor;
	`uvm_component_utils(alu_outmon)

	// declare analysis port and virtual interface
	uvm_analysis_port#(alu_transaction) out_monitor_port;
	virtual alu_interface.OUT_MON vif;
	alu_config cfg;

	// constructor
	function new(string name="alu_outmon", uvm_component parent);
		super.new(name, parent);
	endfunction

	// build phase
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(alu_config)::get(this, "", "alu_config", cfg))
			`uvm_fatal(get_type_name(), "Output_Monitor Config Getting Failed");
		out_monitor_port = new("out_monitor_port", this);
	endfunction

	// connect phase
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		vif = cfg.vif;
	endfunction

	// run phase
	task run_phase(uvm_phase phase);
		logic has_oprd1 = 0;
		logic has_oprd2 = 0;
		int timeout_counter = 0;
		logic [3:0] current_cmd;
		logic current_mode;

		forever begin
			@(vif.out_mon_cb);

			// handle reset
			if (vif.out_mon_cb.RST == 1'b1) begin
				has_oprd1 = 0;
				has_oprd2 = 0;
				timeout_counter = 0;
				continue;
			end

			if (vif.out_mon_cb.CE == 1'b1) begin
				// track two stage input state
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
					default: begin
						// clear operands on flush
						has_oprd1 = 0;
						has_oprd2 = 0;
						timeout_counter = 0;
					end
				endcase

				// check timeout condition
				if (has_oprd1 ^ has_oprd2) begin
					timeout_counter++;
					if (timeout_counter >= 16) begin
						// broadcast timeout transaction
						spawn_capture_thread(current_mode, current_cmd, 1);
						has_oprd1 = 0;
						has_oprd2 = 0;
						timeout_counter = 0;
					end
				end

				// check completion condition
				if (has_oprd1 && has_oprd2) begin
					// broadcast complete transaction
					spawn_capture_thread(current_mode, current_cmd, 0);
					has_oprd1 = 0;
					has_oprd2 = 0;
					timeout_counter = 0;
				end
			end
		end
	endtask

	// background thread to wait for dut execution latency
	task automatic spawn_capture_thread(logic mode, logic [3:0] cmd, logic is_timeout);
		fork
			begin
				int latency_cycles;

				// calculate latency
				if (is_timeout) begin
					latency_cycles = 2;
				end else if (mode == 1'b1 && (cmd == 4'b1001 || cmd == 4'b1010)) begin
					latency_cycles = 4;
				end else begin
					latency_cycles = 2;
				end

				// wait for required active ce cycles
				repeat (latency_cycles) begin
					do @(vif.out_mon_cb);
					while (vif.out_mon_cb.CE != 1'b1);
				end

				// capture outputs and write to port
				begin
					alu_transaction tx = alu_transaction::type_id::create("tx");
					tx.RES = vif.out_mon_cb.RES;
					tx.COUT = vif.out_mon_cb.COUT;
					tx.OFLOW = vif.out_mon_cb.OFLOW;
					tx.ERR = vif.out_mon_cb.ERR;
					tx.G = vif.out_mon_cb.G;
					tx.L = vif.out_mon_cb.L;
					tx.E = vif.out_mon_cb.E;
					tx.timeout_occurred = is_timeout;
					out_monitor_port.write(tx);
				end
			end
		join_none
	endtask
endclass
