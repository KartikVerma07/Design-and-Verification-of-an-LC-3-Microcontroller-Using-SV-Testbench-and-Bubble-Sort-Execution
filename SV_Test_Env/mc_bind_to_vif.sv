// mc_bind_to_vif.sv
// Binds onto 'memory_control' to expose internal signals into your virtual_interface.
`include "virtual_interface.sv"

`ifndef MC_BIND_TO_VIF_SV
`define MC_BIND_TO_VIF_SV

// Create a bound module in the scope of each memory_control instance.
module mc_bind_to_vif (
  virtual_interface V,
  input  logic        write_en,
  input  logic        read_en,
  input  logic [15:0] mar_q,
  input  logic [15:0] mdr_q,
  input  logic [15:0] mem_rdata,
  input  logic        ready
);
  // We are inside the scope of *this* memory_control instance,
  // so we can reference its internal nets directly by name.

  // Drive interface from internal signals
  assign V.mem_we     = write_en;   // internal logic
  assign V.mem_re     = read_en;    // internal logic
  assign V.mem_addr   = mar_q;      // MAR register
  assign V.mem_wdata  = mdr_q;      // MDR register (to memory)
  assign V.mem_rdata  = mem_rdata;  // from memory
  assign V.mem_ready  = ready;      // memory ready

  // Optional observability for control sequencing
//   assign V.ld_mdr_obs = ld_mdr;
//   assign V.ld_mar_obs = ld_mar;
//   assign V.mio_en_obs = mio_en;
//   assign V.rw_obs     = rw;

endmodule

`endif
