//------------------------------------------------------------------------------
// Module : pc
// Logic  : Clocked (PC register) + combinational (PCMUX)
// Summary: Holds the next-instruction address. PCMUX selects between PC+1,
//          a branch/target address, or a bus value to load into PC when enabled.
//------------------------------------------------------------------------------

module pc (
  input  logic        clk,
  input  logic        reset,          // active-high async reset
  // Control
  input  logic        ld_pc,          // load enable for PC
  input  logic [1:0]  pcmux,          // select next PC source
  // Datapath
  input  logic [15:0] from_bus,       // value from global bus
  input  logic [15:0] addr,           // address from adder/mux block
  // Output
  output logic [15:0] pc              // feeds BUS and Addr1 mux
);

  // PC register
  logic [15:0] pc_q;
  assign pc = pc_q;

  // Next-PC candidates
  logic [15:0] pc_plus1;
  logic [15:0] pc_mux_out;

  assign pc_plus1 = pc_q + 16'd1;

  // PCMUX selects: PC+1, BUS, or ADDER
  localparam logic [1:0]
    PC1     = 2'b00,
    BUS_SEL = 2'b01,
    ADDER   = 2'b10;

  always_comb begin
    unique case (pcmux)
      PC1    : pc_mux_out = pc_plus1;
      BUS_SEL: pc_mux_out = from_bus;
      ADDER  : pc_mux_out = addr;
      default: pc_mux_out = '0;
    endcase
  end

  // Async reset, edge-triggered update
  always_ff @(posedge clk or posedge reset) begin
    if (reset)       pc_q <= 16'h3000;   // reset vector
    else if (ld_pc)  pc_q <= pc_mux_out;
  end

endmodule
