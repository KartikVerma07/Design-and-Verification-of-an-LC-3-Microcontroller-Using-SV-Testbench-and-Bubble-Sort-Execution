import lc3_txn_pkg::*;

class generator;
  mailbox #(program_txn) out_drv_mb;   // to driver
  mailbox #(program_txn) out_copy_mb;  // env copy (for DONE/compare)
  
  string fw_path;

  function new(mailbox #(program_txn) m_drv,
               mailbox #(program_txn) m_copy);
    string pa;

    out_drv_mb  = m_drv;
    out_copy_mb = m_copy;

    fw_path     = "E:/MastersVT/LC3/Assembly_Program_BubbleSort/output.hex";
    if ($value$plusargs("FW=%s", pa)) fw_path = pa;
  endfunction
  

    // Read one 16-bit hex word per line into a queue
  local function void build_firmware(ref bit [15:0] code[$]);
    int fd; 
    string line; 
    int unsigned w; 
    int rc; 
    int count = 0;

    fd = $fopen(fw_path, "r");
    if (fd == 0)
      $fatal(1, $sformatf("[GEN] Cannot open firmware hex: %s", fw_path));

    while ($fgets(line, fd)) begin
      // ignore blank / comment-ish lines
      if (line.len() == 0) continue;
      rc = $sscanf(line, "%h", w);
      if (rc == 1) begin
        code.push_back(w[15:0]);
        count++;
      end
    end
    $fclose(fd);

    if (count == 0)
      $fatal(1, $sformatf("[GEN] No words read from %s", fw_path));

    $display("[GEN] Loaded %0d words from %s", count, fw_path);
  endfunction

  // Produce one test (N random elements)
  task run_once(int N = 16);
    program_txn p;
    bit [15:0] fw[$];

    p = new(); 
    p.start_pc    = 16'h3000;   //program will start at x3000
    p.data_base   = 16'h4000;   //array base at x4000
    p.length_addr = 16'h3FFE;   //length stored at x3FFE
    p.done_addr   = 16'h3FFF;   //DONE flag at x3FFF

    // Firmware
    build_firmware(fw);
    p.code = new[fw.size()]; 
    foreach (fw[i]) p.code[i] = fw[i];

    // Random array
    p.array = new[N];
    foreach (p.array[i]) p.array[i] = $urandom_range(0, 16'hFF00);

    p.display();
    out_drv_mb.put(p);
    out_copy_mb.put(p); // env keeps a copy for checking
  endtask
  
endclass
