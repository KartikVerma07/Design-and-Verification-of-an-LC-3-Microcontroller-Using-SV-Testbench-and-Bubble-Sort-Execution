//------------------------------------------------------------------------------
// Module : adder_muxs
// Summary: Forms address operands for MAR/PC by selecting between PC or SR1
//          (Addr1 mux) and between {0, off6, pcoff9, pcoff11} (Addr2 mux),
//          then adds them combinationally.
//------------------------------------------------------------------------------

module adder_muxs (
  // From Control Store
  input  logic        addr1_sel,       // 0: PC, 1: SR1
  input  logic [1:0]  addr2_sel,       // 00: 0, 01: off6, 10: pcoff9, 11: pcoff11

  // From datapath
  input  logic [10:0] ir_10_0,
  input  logic [15:0] pc,
  input  logic [15:0] sr1_out,

  // Output
  output logic [15:0] adder_muxs
);

  // Sign-extended immediates from IR
  logic [15:0] imm6_sext;    // IR[5:0]
  logic [15:0] off9_sext;    // IR[8:0]
  logic [15:0] off11_sext;   // IR[10:0]

  // Correct, width-safe sign extensions
  assign imm6_sext  = {{10{ir_10_0[5]}},  ir_10_0[5:0]};    // 6  -> 16
  assign off9_sext  = {{7{ ir_10_0[8]}},  ir_10_0[8:0]};    // 9  -> 16
  assign off11_sext = {{5{ ir_10_0[10]}}, ir_10_0[10:0]};   // 11 -> 16

  // Addr1 mux: PC vs SR1
  logic [15:0] addr1_mux_out;
  assign addr1_mux_out = (addr1_sel) ? sr1_out : pc;

  // Addr2 mux: 0, off6, pcoff9, pcoff11
  localparam logic [1:0] ADDR2_ZERO    = 2'b00;
  localparam logic [1:0] ADDR2_OFF6    = 2'b01;
  localparam logic [1:0] ADDR2_PCOFF9  = 2'b10;
  localparam logic [1:0] ADDR2_PCOFF11 = 2'b11;

  logic [15:0] addr2_mux_out;
  always_comb begin
    unique case (addr2_sel)
      ADDR2_ZERO   : addr2_mux_out = '0;
      ADDR2_OFF6   : addr2_mux_out = imm6_sext;
      ADDR2_PCOFF9 : addr2_mux_out = off9_sext;
      ADDR2_PCOFF11: addr2_mux_out = off11_sext;
      default      : addr2_mux_out = 'x;
    endcase
  end

  // The adder
  assign adder_muxs = addr1_mux_out + addr2_mux_out;

endmodule
