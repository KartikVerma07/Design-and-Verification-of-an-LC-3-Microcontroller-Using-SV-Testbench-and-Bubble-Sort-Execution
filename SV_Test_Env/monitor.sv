import lc3_txn_pkg::*;

class monitor;
  virtual virtual_interface vif;
  mailbox #(fetch_txn)     fetch_mb;
  mailbox #(reg_write_txn) wr_mb;

  function new(virtual virtual_interface vif,
               mailbox #(fetch_txn) fmb = null,
               mailbox #(reg_write_txn) wmb = null);
    this.vif = vif; 
	 this.fetch_mb = fmb; 
	 this.wr_mb = wmb;
  endfunction

  task run();
    forever begin
      @(vif.mon_cb);
      // If I wire pc_obs/ir_obs at top, this logs and can push txns
      if (fetch_mb != null && vif.mon_cb.ld_ir) begin
        fetch_txn f = new(vif.mon_cb.pc_obs, vif.mon_cb.ir_obs);
        fetch_mb.put(f);
        $display("[MON] PC=%h IR=%h RDY=%0b", vif.mon_cb.pc_obs, vif.mon_cb.ir_obs, vif.mon_cb.ready_bit);
      end
    end
  endtask
endclass
