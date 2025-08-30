`include "../lc3_mem_path.svh"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "lc3_checker.sv"
import lc3_txn_pkg::*;

class lc3_env;
  // Channels
  mailbox #(program_txn)  mb_prog_drv  = new();
  mailbox #(program_txn)  mb_prog_copy = new();
  mailbox #(fetch_txn)    mb_fetch     = new();
  mailbox #(reg_write_txn) mb_wr       = new();

  // Components
  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  sb;
  lc3_checker chk;

  virtual virtual_interface vif;

  function new(virtual virtual_interface vif);
    this.vif = vif;
    gen = new(mb_prog_drv, mb_prog_copy);
    drv = new(mb_prog_drv, vif);
    mon = new(vif, mb_fetch, mb_wr);
    sb  = new(mb_fetch, mb_wr);
    chk = new();
  endfunction

  // Wait for DONE flag in memory
  task automatic wait_done(bit [15:0] done_addr, int unsigned max_cycles=1_000_000);
    for (int cyc=0;cyc<max_cycles;cyc++) begin
      @(posedge vif.clk);
      if (`LC3_MEM(done_addr) == 16'h0001) return;
    end
    $fatal(1, "[ENV] TIMEOUT waiting for DONE");
  endtask

  task run(int N = 16);
    program_txn p;
    fork
      drv.run();
      mon.run();
      sb.run();
    join_none

    // Create 1 test and send to driver; keep a copy via mb_prog_copy
    gen.run_once(N);

    // Grab a local copy for DONE/compare
    mb_prog_copy.get(p);

    // Give a couple cycles for driver reset
    repeat (4) @(posedge vif.clk);

    // Run until firmware reports DONE
    wait_done(p.done_addr, 2_000_000);

    // Dump unsorted array (from generator)
    chk.print_array("UNSORTED Array: ", p.array);

    // Check final array
    chk.compare_array(p.data_base, p.array.size());
  endtask
endclass
