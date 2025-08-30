//------------------------------------------------------------------------------
// Module : mar_mux
// Logic  : Combinational
// Summary: Selects the address to load into MAR:
//          • 0 → zero-extended trap vector {8'h00, IR[7:0]}
//          • 1 → address from datapath (e.g., PC/base + offset)
//------------------------------------------------------------------------------

module mar_mux (
  input  logic        marmux_sel,   // 0: trap vector ZEXT, 1: datapath address
  input  logic [7:0]  ir_7_0,
  input  logic [15:0] address,      // from the adder
  output logic [15:0] mar_mux_out
);

  // Combinational select
  assign mar_mux_out = (marmux_sel) ? address : {8'h00, ir_7_0};

endmodule