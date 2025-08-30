//------------------------------------------------------------------------------
// Module : processing_unit
// Summary: LC-3 processing slice that selects SR1/DR registers, forms the SR2
//          operand (register or sign-extended imm5), instantiates the register
//          file and ALU, and drives the bus output.
//------------------------------------------------------------------------------

module processing_unit (
  input  logic         clk,
  input  logic         reset,

  // Register file control
  input  logic         ld_reg,        // load enable for DR

  // ALU control
  input  logic [1:0]   aluk,          // ALU operation select

  // IR fields / mux selects
  input  logic [2:0]   ir_11_9,       // DR field
  input  logic [2:0]   ir_8_6,        // SR1 field
  input  logic [2:0]   ir_2_0,        // SR2 field
  input  logic [1:0]   sr1mux,        // SR1 source select
  input  logic [1:0]   drmux,         // DR destination select
  input  logic         ir_5,          // imm5 vs SR2 select
  input  logic [4:0]   ir_4_0,        // imm5 value

  // Datapath bus
  input  logic [15:0]  from_bus,      // writeback data to registers

  // Outputs
  output logic [15:0]  sr1_out,       // taps SR1 for external adder module
  output logic [15:0]  to_bus         // ALU result to global bus
);

  //--------------------------------------------------------------------------
  // Muxes
  //--------------------------------------------------------------------------

  // SR1 mux (which register feeds SR1 port of regfile)
  logic [2:0] sr1mux_out;
  always_comb begin
    unique case (sr1mux)
      2'b00: sr1mux_out = ir_11_9;  // DR field
      2'b01: sr1mux_out = ir_8_6;   // SR1 field
      2'b10: sr1mux_out = 3'b110;   // R6
      default: sr1mux_out = 3'b000; // R0
    endcase
  end

  // SR2 mux (register SR2 vs sign-extended imm5)
  logic [15:0] sr2mux_out;
  logic [15:0] sr2_out;         // SR2 data from regfile
  logic [15:0] imm5_sext;       // sign-extended imm5
  assign imm5_sext = {{11{ir_4_0[4]}}, ir_4_0};

  always_comb begin
    sr2mux_out = (ir_5) ? imm5_sext : sr2_out;
  end

  // DR mux (which register is the destination)
  logic [2:0] drmux_out;
  always_comb begin
    unique case (drmux)
      2'b00: drmux_out = ir_11_9; // DR field
      2'b01: drmux_out = 3'b111;  // R7 (link)
      2'b10: drmux_out = 3'b110;  // R6 (stack/frame)
      default: drmux_out = 3'b000;
    endcase
  end

  //--------------------------------------------------------------------------
  // Submodules
  //--------------------------------------------------------------------------

  logic [15:0] sr1_w; // internal SR1 wire to feed ALU and external tap
  assign sr1_out = sr1_w;

  // Updated register_file (SV, async read / sync write, no i_/o_ prefixes)
  Reg_File #(.INIT_FILE(""))
  u_regfile (
    .clk      (clk),
    .reset    (reset),
    .ld_reg   (ld_reg),
    .dr_addr  (drmux_out),
    .sr1_addr (sr1mux_out),
    .sr2_addr (ir_2_0),
    .from_bus (from_bus),
    .sr1_Out  (sr1_w),
    .sr2_Out  (sr2_out)
  );

  // ALU
  ALU u_alu (
    .ALUK        (aluk),
    .SR2MUX_Out  (sr2mux_out),
    .RegFile_Out (sr1_w),
    .ToBus       (to_bus)
  );

endmodule