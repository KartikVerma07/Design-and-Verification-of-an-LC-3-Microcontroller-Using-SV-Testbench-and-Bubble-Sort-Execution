`include "../lc3_mem_path.svh"
import lc3_txn_pkg::*;

class scoreboard;
  mailbox #(fetch_txn)     fetch_mb;
  mailbox #(reg_write_txn) wr_mb;

  function new(mailbox #(fetch_txn) fmb = null,
               mailbox #(reg_write_txn) wmb = null);
    this.fetch_mb = fmb; 
	 this.wr_mb = wmb;
  endfunction

  task run();
    fork
      // -------- FETCH LOOP: flow check + opcode sanity --------
      if (fetch_mb != null) forever begin
        fetch_txn f;
        automatic bit [15:0] ir_mem; 
        automatic logic [3:0] op;
        
        fetch_mb.get(f);

        // Flow check: IR read from memory at PC must equal observed IR
        ir_mem = `LC3_MEM(f.pc- 16'h0001);
        if ((^f.ir != 1'bX) && (ir_mem != f.ir))
          $fatal(1, "[SB] Flow mismatch: PC=%h memIR=%h monIR=%h", f.pc, ir_mem, f.ir);

        // Opcode sanity: only ops my design implements
         op = f.ir[15:12];
        if (!(op inside {4'h0,4'h1,4'h2,4'h5,4'h6,4'h7,4'h9,4'hE,4'hF}))
          $fatal(1, "[SB] Illegal opcode 0x%0h @PC(fetch)=%h (IR=%h)", op, f.pc- 16'h0001, f.ir);

        $display("[SB] (FETCH)->pc=%h ir=%h", f.pc- 16'h0001, f.ir);
      end

      // -------- REG-WRITE LOOP: sanity --------
      if (wr_mb != null) forever begin
        reg_write_txn w; 
        wr_mb.get(w);

        if (w.dr > 3'd7)
          $fatal(1, "[SB] Bad DR=%0d @PC=%h", w.dr, w.pc_at_write);

        if (^w.data === 1'bX)
          $fatal(1, "[SB] X data on write R%0d<=%h @PC=%h", w.dr, w.data, w.pc_at_write);

        $display("[SB] WR   R%0d<=%h @PC=%h", w.dr, w.data, w.pc_at_write);
      end
    join_none
  endtask
endclass
