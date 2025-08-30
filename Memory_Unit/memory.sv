//------------------------------------------------------------------------------
// Module : memory
// Summary: Parameterizable 1R/1W synchronous RAM (single clock) with optional
//          hex-file initialization. Read data is registered. READY pulses:
//            • same cycle for writes
//            • one cycle after reads
//------------------------------------------------------------------------------

module memory #(
  parameter string       INIT_FILE = "",     // optional $readmemh() source
  parameter int unsigned ADDR_W    = 9,      // address width
  parameter int unsigned DEPTH     = 512,    // number of elements
  parameter int unsigned DW        = 8       // data width (bits)
) (
  input  logic                 clk,

  // Enables
  input  logic                 write_en,
  input  logic                 read_en,

  // Addresses
  input  logic [ADDR_W-1:0]    write_addr,
  input  logic [ADDR_W-1:0]    read_addr,

  // Data
  input  logic [DW-1:0]        write_data,
  output logic                 ready,        // op completion pulse
  output logic [DW-1:0]        read_data     // registered read
);

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------
  logic [DW-1:0] mem [0:DEPTH-1];

  /*
  if (INIT_FILE != "") begin : gen_init
    initial $readmemh(INIT_FILE, mem);
  end */

  // ---------------------------------------------------------------------------
  // Read/Write + READY timing
  //   • WRITE: ready asserted in same cycle as write
  //   • READ : ready asserted the cycle after data is captured
  // ---------------------------------------------------------------------------
  logic rd_ready_d /* verilator keep */;

  always_ff @(posedge clk) begin
    // default
    ready       <= 1'b0;

    // write path
    if (write_en) begin
      mem[write_addr] <= write_data;
      ready           <= 1'b1;      // same-cycle pulse for writes
    end

    // read path (synchronous)
    if (read_en) begin
      read_data  <= mem[read_addr]; // registered read
      rd_ready_d <= 1'b1;           // arm next-cycle ready
    end

    // next-cycle ready for reads
    if (rd_ready_d) begin
      rd_ready_d <= 1'b0;
      ready      <= 1'b1;
    end
  end

  // Optional sanity checks (simulation-only)
`ifndef SYNTHESIS
  // Warn if address width likely mismatches depth (not fatal)
  initial begin
    if ((1<<ADDR_W) < DEPTH)
      $warning("memory: DEPTH (%0d) exceeds addressable range with ADDR_W=%0d", DEPTH, ADDR_W);
  end
`endif

endmodule
