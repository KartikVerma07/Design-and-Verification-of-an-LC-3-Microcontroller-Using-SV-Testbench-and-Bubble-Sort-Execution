module mem_tap(virtual_interface V);
  // Log writes
  always @(posedge V.clk) if (V.mem_we)
    $display("[MEM-WR] t=%0t addr=%h data=%h", $time, V.mem_addr, V.mem_wdata);

  // Log reads (when ready pulses during read)
  always @(posedge V.clk) if (V.mem_re && V.mem_ready)
    $display("[MEM-RD] t=%0t addr=%h data=%h", $time, V.mem_addr, V.mem_rdata);

  // Catch “same addr twice in a row” (classic collapse bug)
  logic [15:0] last_wr_addr; bit have_last;
  always @(posedge V.clk) if (V.mem_we) begin
    if (have_last && (V.mem_addr == last_wr_addr))
      $error("[ASSERT] consecutive writes to same addr=%h", V.mem_addr);
    last_wr_addr <= V.mem_addr; have_last <= 1;
  end
endmodule
