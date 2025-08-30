//------------------------------------------------------------------------------
// Module : ir_reg
// Summary: Instruction Register. Captures the 16-bit instruction from the CPU
//          bus when ld_ir is asserted. Asynchronous reset clears to 0.
//------------------------------------------------------------------------------

module IR_reg (
  input  logic        clk,
  input  logic        reset,
  input  logic        ld_ir,
  input  logic [15:0] bus_in,
  output logic [15:0] ir
);
  always_ff @(posedge clk or posedge reset) begin
    if (reset)   ir <= '0;
    else if (ld_ir) ir <= bus_in;
  end
endmodule