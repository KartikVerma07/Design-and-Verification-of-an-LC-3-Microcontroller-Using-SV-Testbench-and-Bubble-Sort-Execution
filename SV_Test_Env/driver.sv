`include "../lc3_mem_path.svh"
import lc3_txn_pkg::*;

class driver;
  mailbox #(program_txn) in_mb;
  virtual virtual_interface vif;

  function new(mailbox #(program_txn) in_mb, virtual virtual_interface vif);
    this.in_mb = in_mb; this.vif = vif;
  endfunction

  // RAM pokes (using centralized macro LC3_MEM)
  task automatic load_code(input bit [15:0] base_pc, input bit [15:0] code[]);
    for (int i=0;i<code.size();i++) `LC3_MEM(base_pc + i) = code[i];
  endtask

  task automatic load_data(input bit [15:0] base, input bit [15:0] arr[]);
    for (int i=0;i<arr.size();i++) `LC3_MEM(base + i) = arr[i];
  endtask

  task automatic write_len(input bit [15:0] addr, input int unsigned N);
    `LC3_MEM(addr) = N[15:0];
  endtask

  task automatic clear_done(input bit [15:0] addr);
    `LC3_MEM(addr) = 16'h0000;
  endtask

  task run();
    program_txn p;
    forever begin
      in_mb.get(p);
      $display("[DRV] Loading program/data …");
      load_code(p.start_pc, p.code);
      load_data(p.data_base, p.array);
      write_len(p.length_addr, p.array.size());
      clear_done(p.done_addr);
      $display("[DRV] Load complete.");
      // Reset & release (driver does it here for simplicity)
      vif.apply_reset(3);
    end
  endtask
endclass
