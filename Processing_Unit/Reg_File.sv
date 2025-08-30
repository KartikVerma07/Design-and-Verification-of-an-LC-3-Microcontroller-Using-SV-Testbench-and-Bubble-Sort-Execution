//------------------------------------------------------------------------------
// Module : Reg_File
// Summary: 8×16 LC-3 register file (R0–R7) with asynchronous reads and
//          edge-triggered writeback.
//
// Behavior:
//   • Reads (sr1, sr2) are combinational: sr* = mem[sr*_addr].
//   • Write occurs on posedge clk when ld_reg == 1'b1: mem[dr_addr] <= bus.
//   • Active-high asynchronous reset clears all registers to '0.
//   • Read/Write same register in one cycle returns the OLD value on the re
//------------------------------------------------------------------------------

module Reg_File #(
  parameter string INIT_FILE = ""   // Optional hex file to pre-load registers
) (
  input  logic         clk,
  input  logic         reset,       // Active-high reset
  // Control
  input  logic         ld_reg,
  // Register addresses
  input  logic [2:0]   dr_addr,     // Destination register
  input  logic [2:0]   sr1_addr,    // Source register 1
  input  logic [2:0]   sr2_addr,    // Source register 2
  // Datapath bus
  input  logic [15:0]  from_bus,
  // Read outputs (asynchronous reads)
  output logic [15:0]  sr1_Out,
  output logic [15:0]  sr2_Out
);

  // Sizes
  localparam int ADDR_W = 3;
  localparam int NUMBER_OF_ELEMENTS = 8;
  localparam int ELEMENT_SIZE = 16;

  // 8 x 16 register file
  logic [ELEMENT_SIZE-1:0] mem [NUMBER_OF_ELEMENTS];

  // Asynchronous read ports
  always_comb begin
    sr1_Out = mem[sr1_addr];
    sr2_Out = mem[sr2_addr];
  end

  // Synchronous write port with async reset
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < NUMBER_OF_ELEMENTS; i++) mem[i] <= '0;
    end else if (ld_reg) begin
      mem[dr_addr] <= from_bus;
    end
  end

endmodule
