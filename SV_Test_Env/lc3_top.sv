import lc3_txn_pkg::*;

`include "virtual_interface.sv"  // your interface type (defines virtual_interface)
`include "lc3_env.sv"

module lc3_top;

  // ---------------------------
  // Clock
  // ---------------------------
  logic clk = 1'b0;
  localparam time HALF = 41.667ns;   // ~12 MHz
  always #(HALF) clk = ~clk;

  // ---------------------------
  // TB <-> DUT interface
  // ---------------------------
  virtual_interface vif(clk);
  initial vif.reset = 1'b0;          // env/driver will toggle via apply_reset()

  // ---------------------------
  // DUT
  // (Make sure top_datapath has these observe outputs: pc_value, ir_value,
  //  ld_ir_obs, ready_bit_obs. If you haven’t added them yet, see prior note.)
  // ---------------------------
  top_datapath dut (
	  .clk           (clk),
	  .reset         (vif.reset),
	  .pc_value      (vif.pc_obs),
	  .ir_value      (vif.ir_obs),
	  .ld_ir_obs     (vif.ld_ir),
	  .ready_bit_obs (vif.ready_bit),
	  .cpu_bus_obs   ()
  );
  // (Optionally, if we want to export cpu_bus_obs)
  // assign vif.cpu_bus   = dut.cpu_bus_obs;

  // bind adapter so vif gets MAR/MDR signals
  bind memory_control mc_bind_to_vif mc2vif(
    .V        (lc3_top.vif),        // interface instance from TB
    .write_en (write_en),   // these names are the *internal* signals of memory_control
    .read_en  (read_en),
    .mar_q    (mar_q),
    .mdr_q    (mdr_q),
    .mem_rdata(mem_rdata),
    .ready    (ready)
);

  // memory tap to log all memory accesses
  mem_tap u_mem_tap(.V(vif));

  // ---------------------------
  // Environment
  // ---------------------------
  lc3_env env;
  initial begin
    env = new(vif);
    $display("[TB] LC-3 bubble sort test starting");
    env.run(16);   // N = 16 elements
    $display("[TB] Done");
    $finish;
  end

endmodule