//------------------------------------------------------------------------------
// control_store: 64×52 microinstruction ROM/RAM with synchronous read
//------------------------------------------------------------------------------

`ifndef CONTROL_STORE_INIT
  // Default microcode file (adjust relative path to your sim working dir)
  `define CONTROL_STORE_INIT "E:/MastersVT/LC3/Control_Signals/output.txt"
`endif

module control_store #(
  parameter bit         INIT_EN = 1,
  parameter int unsigned ADDR_W = 6,   // 64 states
  parameter int unsigned DEPTH  = 64,
  parameter int unsigned MIW    = 52
) (
  input  logic                 clk,
  input  logic                 read_en,
  input  logic [ADDR_W-1:0]    read_addr,
  output logic [MIW-1:0]       read_data
);

  // Storage
  logic [MIW-1:0] mem [0:DEPTH-1];

  // Synchronous read
  always_ff @(posedge clk) begin
    if (read_en) read_data <= mem[read_addr];
  end

`ifndef SYNTHESIS
  // Initialize from file in simulation (and some Quartus flows for ROM inference)
  initial if (INIT_EN) $readmemb(`CONTROL_STORE_INIT, mem);
`endif

`ifndef SYNTHESIS
  initial if ((1 << ADDR_W) < DEPTH)
    $warning("control_store: DEPTH=%0d exceeds addressable range with ADDR_W=%0d",
             DEPTH, ADDR_W);
`endif

endmodule
