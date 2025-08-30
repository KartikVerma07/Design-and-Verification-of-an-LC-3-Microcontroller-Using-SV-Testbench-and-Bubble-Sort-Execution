//------------------------------------------------------------------------------
// Module : memory_control
// Summary: Controls unified instruction/data memory using MAR/MDR registers.
//          • MDR <= (mio_en ? mem_rdata : bus) on ld_mdr
//          • MAR <= bus on ld_mar
//          • write_en = mio_en &  rw, read_en = mio_en & ~rw
//          • bus_out is the MDR (top-level gating drives the CPU bus).
//------------------------------------------------------------------------------

module memory_control (
  input  logic        clk,

  // Control
  input  logic        ld_mdr,
  input  logic        ld_mar,
  input  logic        rw,        // 1=write, 0=read
  input  logic        mio_en,    // memory operation enable

  // Datapath
  input  logic [15:0] from_bus,       // CPU bus into MC

  // Outputs
  output logic [15:0] bus_out,   // MDR -> CPU bus (externally gated)
  output logic        ready      // memory op completed
);

  // MDR/MAR registers
  logic [15:0] mdr_q, mar_q;
  assign bus_out = mdr_q;

  // Memory read data
  logic [15:0] mem_rdata;

  // Feed MDR mux: memory vs bus
  logic [15:0] mdr_d;
  assign mdr_d = (mio_en) ? mem_rdata : from_bus;

  // Address/control
  logic write_en;
  logic read_en; 
  assign write_en = (mio_en &  rw);
  assign read_en  = (mio_en & ~rw);

  // Register updates
  always_ff @(posedge clk) begin
    if (ld_mdr) mdr_q <= mdr_d;
    if (ld_mar) mar_q <= from_bus;
  end

  // never assert read and write together
//`ifndef SYNTHESIS
//  assert property (@(posedge clk) !(read_en && write_en))
//    else $error("memory_control: read_en and write_en high together");
//`endif

  // Memory instance (matches our SV 'memory' module)
  memory #(
    .INIT_FILE("../your_directory/your_deafult_memory.mem"),  //if not deafult values will be 0
    .ADDR_W   (16),
    .DEPTH    (65535),
    .DW       (16)
  ) u_mem (
    .clk        (clk),
    .write_en   (write_en),
    .read_en    (read_en),
    .write_addr (mar_q),
    .read_addr  (mar_q),
    .write_data (mdr_q),
    .ready      (ready),
    .read_data  (mem_rdata)
  );

endmodule
