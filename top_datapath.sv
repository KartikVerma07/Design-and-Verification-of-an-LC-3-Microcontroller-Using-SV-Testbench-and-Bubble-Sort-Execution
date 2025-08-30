//------------------------------------------------------------------------------
// Module : top_datapath
// Logic  : Clocked + Combinational
// Summary: LC-3 datapath top. Integrates the global bus, memory control,
//          processing unit (regfile + ALU), PC, MAR mux, NZP, adder muxes,
//          IR, and control logic FSM.
//------------------------------------------------------------------------------
module top_datapath (
  input  logic 		 clk,
  input  logic 		 reset,
  output logic [15:0] pc_value,     // PC for monitor/trace
  output logic [15:0] ir_value,     // IR for monitor/trace
  output logic        ld_ir_obs,    // pulse when IR loads
  output logic        ready_bit_obs,// memory ready (sample-only)
  output logic [15:0] cpu_bus_obs   // (handy for debug/trace)
);
  //=============================
  // Global interconnect
  //=============================
  logic [15:0] cpu_bus;
  logic [15:0] adder_out;
  logic [15:0] pc_out;
  logic [15:0] sr1_out;
  logic [15:0] marmux_out;
  logic [15:0] mdr_out;
  logic [15:0] proc_out;
  logic [15:0] ir;
  logic [2:0]  nzp_out;
  logic        ready_bit;

  //=============================
  // Control signals (from control_logic)
  //=============================
  // Loads
  logic ld_mar, ld_mdr, ld_ir, ld_reg, ld_cc, ld_pc;
  // (unused but wired for completeness)
  logic ld_priv, ld_savedssp, ld_savedusp, ld_vector, ld_priority, ld_acv;

  // Bus gates (one-hot by microcode policy)
  logic gate_pc, gate_mdr, gate_alu, gate_marmux;
  // (unused but wired)
  logic gate_vector, gate_pc_minus1, gate_srp, gate_sp;

  // Mux controls
  logic [1:0] pcmux, drmux, sr1mux, addr2_sel, spmux, vectormux;
  logic       addr1_sel, marmux_sel, tablemux, psrmux;

  // ALU control
  logic [1:0] aluk;

  // Memory control
  logic mio_en, r_w;

  // Privilege control (unused)
  logic set_priv;

  //=============================
  // CPU Bus gating
  //=============================
  // Priority is arbitrary but control microcode should ensure one-hot gating.
  always_comb begin
    cpu_bus = 16'hFFFF;         // default = -1
    if (gate_marmux) cpu_bus = marmux_out;
    else if (gate_pc)   cpu_bus = pc_out;
    else if (gate_alu)  cpu_bus = proc_out;
    else if (gate_mdr)  cpu_bus = mdr_out;
  end

  //=============================
  // Processing Unit (Regfile + ALU)
  //=============================
  processing_unit u_proc (
    .clk       (clk),
    .reset     (reset),
    .ld_reg    (ld_reg),
    .aluk      (aluk),
    .ir_11_9   (ir[11:9]),
    .ir_8_6    (ir[8:6]),
    .ir_2_0    (ir[2:0]),
    .sr1mux    (sr1mux),
    .drmux     (drmux),
    .ir_5      (ir[5]),
    .ir_4_0    (ir[4:0]),
    .from_bus  (cpu_bus),
    .sr1_out   (sr1_out),          // tap for adder mux
    .to_bus    (proc_out)          // ALU → bus (gated)
  );

  //=============================
  // Memory subsystem
  //=============================
  memory_control u_memctl (
    .clk     (clk),
    .ld_mdr  (ld_mdr),
    .ld_mar  (ld_mar),
    .rw      (r_w),
    .mio_en  (mio_en),
    .from_bus(cpu_bus),
    .bus_out (mdr_out),
    .ready   (ready_bit)
  );

  //=============================
  // Program Counter
  //=============================
  pc u_pc (
    .clk    (clk),
    .reset  (reset),
    .ld_pc  (ld_pc),
    .pcmux  (pcmux),
    .from_bus(cpu_bus),
    .addr   (adder_out),
    .pc     (pc_out)
  );

  //=============================
  // NZP condition codes
  //=============================
  nzp u_nzp (
    .clk   (clk),
    .ld_cc (ld_cc),
    .bus   (cpu_bus),
    .cc    (nzp_out)
  );

  //=============================
  // Address adder muxes
  //=============================
  adder_muxs u_adder (
    .addr1_sel (addr1_sel),     // 0: PC, 1: SR1
    .addr2_sel (addr2_sel),     // 00:0, 01:off6, 10:pcoff9, 11:pcoff11
    .ir_10_0   (ir[10:0]),
    .pc        (pc_out),
    .sr1_out   (sr1_out),
    .adder_muxs(adder_out)
  );

  //=============================
  // MAR mux
  //=============================
  mar_mux u_marmux (
    .marmux_sel (marmux_sel),   // 0: trap vector ZEXT, 1: datapath address
    .ir_7_0     (ir[7:0]),
    .address    (adder_out),
    .mar_mux_out(marmux_out)
  );

    //=============================
  // IR
  //=============================
  IR_reg u_ir (
    .clk    (clk),
    .reset  (reset),
    .ld_ir  (ld_ir),
    .bus_in (cpu_bus),
    .ir     (ir)
  );


  //=============================
  // Control Logic (kept as-is; maps to new signal names)
  //=============================
control_logic u_ctrl (
  // Inputs
  .clk        (clk),
  .ir         (ir),
  .ready_bit  (ready_bit),
  .nzp        (nzp_out),   // <- if your wire is named nzp_out; otherwise use nzp
  .reset      (reset),

  // Loads
  .ld_mar     (ld_mar),
  .ld_mdr     (ld_mdr),
  .ld_ir      (ld_ir),
  .ld_reg     (ld_reg),
  .ld_cc      (ld_cc),
  .ld_pc      (ld_pc),

  // Bus gates
  .gate_pc    (gate_pc),
  .gate_mdr   (gate_mdr),
  .gate_alu   (gate_alu),
  .gate_marmux(gate_marmux),

  // Mux controls
  .pcmux      (pcmux),
  .drmux      (drmux),
  .sr1mux     (sr1mux),
  .addr1mux   (addr1_sel),
  .addr2mux   (addr2_sel),
  .marmux     (marmux_sel),

  // ALU control
  .aluk       (aluk),

  // Memory control
  .mio_en     (mio_en),
  .r_w        (r_w)
);

assign pc_value      = pc_out;
assign ir_value      = ir;
assign ld_ir_obs     = ld_ir;
assign ready_bit_obs = ready_bit;
assign cpu_bus_obs   = cpu_bus;

endmodule
