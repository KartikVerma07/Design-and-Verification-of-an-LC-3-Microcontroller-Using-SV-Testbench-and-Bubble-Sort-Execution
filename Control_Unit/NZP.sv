//------------------------------------------------------------------------------
// Module : nzp
// Logic  : Clocked register (CC) + combinational next-state logic
// Summary: Tracks LC-3 condition codes (N/Z/P) based on the 16-bit bus value.
//          On ld_cc, captures {N,Z,P} where N = sign bit, Z = (bus == 0),
//          P = (~sign) & (bus != 0).
//------------------------------------------------------------------------------

module nzp (
  input  logic        clk,
  input  logic        ld_cc,     // load enable for condition codes
  input  logic [15:0] bus,       // datapath result
  output logic [2:0]  cc         // {N,Z,P} to control
);

  // Combinational next-state for CC
  logic [2:0] cc_next;
  logic       is_zero;

  assign is_zero = (bus == '0);
  // cc_next = {N,Z,P}
  assign cc_next = { bus[15], is_zero, (~bus[15] & ~is_zero) };

  // Registered update
  always_ff @(posedge clk) begin
    if (ld_cc) cc <= cc_next;   // hold value when ld_cc == 0
  end

endmodule
