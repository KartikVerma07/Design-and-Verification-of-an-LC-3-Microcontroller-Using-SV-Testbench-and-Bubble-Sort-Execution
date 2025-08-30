package lc3_txn_pkg;

  // Full program+data transaction
  class program_txn;
    rand bit [15:0] start_pc   = 16'h3000;
    rand bit [15:0] code[];          // LC-3 firmware words (bubble sort)
    rand bit [15:0] data_base  = 16'h4000;
    rand bit [15:0] array[];         // test array
    rand bit [15:0] length_addr= 16'h3FFE;
    rand bit [15:0] done_addr  = 16'h3FFF;

    function void display();
      $display("[prog] PC=%h code_len=%0d base=%h N=%0d len@%h done@%h",
               start_pc, code.size(), data_base, array.size(),
               length_addr, done_addr);
    endfunction
  endclass

  // Optional richer monitor transactions (not required to run)
  class fetch_txn;
    bit [15:0] pc, ir;
    function new(bit [15:0] pc=0, bit [15:0] ir=0); 
		this.pc=pc; 
		this.ir=ir; 
	 endfunction
  endclass

  class reg_write_txn;
    bit [2:0]  dr; bit [15:0] data, pc_at_write;
    function new(bit [2:0] dr=0, bit [15:0] data=0, bit [15:0] pc=0);
      this.dr=dr; 
		this.data=data; 
		this.pc_at_write=pc;
    endfunction
  endclass

endpackage