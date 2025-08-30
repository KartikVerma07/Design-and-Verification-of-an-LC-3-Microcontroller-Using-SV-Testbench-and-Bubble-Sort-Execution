

interface virtual_interface (input logic clk);
  // TB -> DUT drive
  logic reset;

  // DUT -> TB observations
  logic [15:0] pc_obs;     // from top_datapath.pc_value
  logic [15:0] ir_obs;     // from top_datapath.ir_value
  logic        ld_ir;      // from top_datapath.ld_ir_obs (IR load pulse)
  logic        ready_bit;  // from top_datapath.ready_bit_obs
  logic [15:0] cpu_bus;    // optional (from top_datapath.cpu_bus_obs)

  logic        mem_we;        // write enable to memory
  logic        mem_re;        // read  enable to memory
  logic [15:0] mem_addr;      // MAR (effective addr)
  logic [15:0] mem_wdata;     // MDR (data written)
  logic [15:0] mem_rdata;     // data read from memory
  logic        mem_ready;     // ready from memory

  // Driver clocking block (TB drives ONLY reset)
  clocking drv_cb @(posedge clk);
    output reset;
  endclocking

  // Monitor clocking block (sample all observed signals)
  clocking mon_cb @(posedge clk);
    input reset, ready_bit, ld_ir, pc_obs, ir_obs, cpu_bus;
    input mem_we, mem_re, mem_addr, mem_wdata, mem_rdata, mem_ready;
  endclocking

  // Utility
  task automatic apply_reset(int cycles = 2);
    drv_cb.reset <= 1'b1;
    repeat (cycles) @(drv_cb);
    drv_cb.reset <= 1'b0;
  endtask
endinterface
