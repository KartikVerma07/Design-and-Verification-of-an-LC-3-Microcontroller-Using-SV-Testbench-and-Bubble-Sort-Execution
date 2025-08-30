//------------------------------------------------------------------------------
// Testbench : Reg_File_TB (edge-driven stimulus)
// Summary   : Drives the LC-3 8×16 register file. Uses only clock edges for
//             timing (no direct #HALF delays in stimulus).
//------------------------------------------------------------------------------

`timescale 1ns/1ps
timeunit 1ns;  timeprecision 1ps;

module Reg_File_TB;

  // DUT connections
  logic        clk   = 1'b0;
  logic        reset = 1'b0;

  logic        ld_reg;
  logic [2:0]  dr_addr, sr1_addr, sr2_addr;
  logic [15:0] bus;
  logic [15:0] sr1, sr2;

  // 12 MHz clock: T/2 = 41.667 ns (only used for clock gen)
  localparam time HALF = 41.667ns;

  // Clock generation
  always #(HALF) clk = ~clk;

  // ---------- Edge helpers ----------
  task automatic step_pos (int n = 1); repeat (n) @(posedge clk); endtask
  task automatic step_neg (int n = 1); repeat (n) @(negedge clk); endtask
  // (use step_pos/step_neg instead of #delays)

  // DUT
  Reg_File DUT (
    .clk     (clk),
    .reset   (reset),
    .ld_reg  (ld_reg),
    .dr_addr (dr_addr),
    .sr1_addr(sr1_addr),
    .sr2_addr(sr2_addr),
    .from_bus(bus),
    .sr1_Out (sr1),
    .sr2_Out (sr2)
  );

  // Stimulus (edge-driven)
  initial begin
    // Defaults
    ld_reg   = 1'b0;
    dr_addr  = '0;
    sr1_addr = '0;
    sr2_addr = '0;
    bus      = '0;

    // Apply async reset for 2 posedges
    reset = 1'b1; step_pos(2); reset = 1'b0;

    // Test 1: write 0x000F to R1
    bus     = 16'h000F; ld_reg = 1'b1; dr_addr = 3'b001;
    step_pos();                 // capture on this edge
    ld_reg  = 1'b0; bus = '0; dr_addr = '0;

    // Test 2: write 0x00F0 to R4
    step_neg();                 // align like the original negedge start
    bus     = 16'h00F0; ld_reg = 1'b1; dr_addr = 3'b100;
    step_pos();
    ld_reg  = 1'b0; bus = '0; dr_addr = '0;

    // Test 3: readbacks on SR1 (async read; wait to next posedge to observe)
    sr1_addr = 3'b001; step_pos(); sr1_addr = '0;   // R1 -> SR1
    step_neg();                                     // half-cycle spacing
    sr1_addr = 3'b100; step_pos(); sr1_addr = '0;   // R4 -> SR1

    // Test 4: readbacks on SR2
    step_neg();
    sr2_addr = 3'b001; step_pos(); sr2_addr = '0;   // R1 -> SR2
    step_neg();
    sr2_addr = 3'b100; step_pos(); sr2_addr = '0;   // R4 -> SR2

    // Test 5: simultaneous SR1/SR2 reads (R1 and R4)
    step_neg();
    sr1_addr = 3'b001; sr2_addr = 3'b100;
    step_pos();
    sr1_addr = '0;     sr2_addr = '0;

    // Test 6: read & write same reg (R7): read shows OLD, write lands on edge
    step_pos(2);
    bus     = 16'h1111; ld_reg = 1'b1; dr_addr = 3'b111;
    step_pos();          ld_reg = 1'b0; bus = '0; dr_addr = '0;

    step_pos(6);
    bus      = 16'hF000; ld_reg = 1'b1; dr_addr = 3'b111;
    sr1_addr = 3'b111;   sr2_addr = 3'b111;   // reading while writing
    step_pos();          ld_reg = 1'b0; bus = '0; dr_addr = '0;
    step_pos(2);         sr1_addr = '0; sr2_addr = '0;

    // Wrap up after a few more cycles
    step_pos(20);
    $display("Finished!");
    $finish;
  end

endmodule
