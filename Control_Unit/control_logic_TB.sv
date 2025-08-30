//------------------------------------------------------------------------------
// Testbench : control_logic_TB (edge-driven, no file I/O assumptions)
// Summary   : Smoke-tests the control path. Applies reset, simulates a memory
//             ready pulse, then drives IR opcodes (ADD, BR) and prints control
//             signals each posedge for inspection.
//------------------------------------------------------------------------------

`timescale 1ns/1ps
timeunit 1ns; timeprecision 1ps;

module control_logic_TB;

  // Clock
  logic clk = 1'b0;
  localparam time HALF = 41.667ns;   // ~12 MHz
  always #(HALF) clk = ~clk;

  // Inputs to DUT
  logic        reset;
  logic [15:0] ir;
  logic        ready_bit;
  logic [2:0]  nzp;

  // Outputs from DUT
  logic        ld_mar, ld_mdr, ld_ir, ld_reg, ld_cc, ld_pc;
  logic        gate_pc, gate_mdr, gate_alu, gate_marmux;
  logic [1:0]  pcmux, drmux, sr1mux, addr2mux;
  logic        addr1mux, marmux;
  logic [1:0]  aluk;
  logic        mio_en, r_w;

  // Edge helper
  task automatic step_pos(int n = 1); repeat (n) @(posedge clk); endtask

  // DUT
  control_logic dut (
    .clk       (clk),
    .ir        (ir),
    .ready_bit (ready_bit),
    .nzp       (nzp),
    .reset     (reset),

    .ld_mar    (ld_mar),
    .ld_mdr    (ld_mdr),
    .ld_ir     (ld_ir),
    .ld_reg    (ld_reg),
    .ld_cc     (ld_cc),
    .ld_pc     (ld_pc),

    .gate_pc   (gate_pc),
    .gate_mdr  (gate_mdr),
    .gate_alu  (gate_alu),
    .gate_marmux(gate_marmux),

    .pcmux     (pcmux),
    .drmux     (drmux),
    .sr1mux    (sr1mux),
    .addr1mux  (addr1mux),
    .addr2mux  (addr2mux),
    .marmux    (marmux),

    .aluk      (aluk),
    .mio_en    (mio_en),
    .r_w       (r_w)
  );

  // Simple cycle-by-cycle trace
  always @(posedge clk) begin
     $display("[%0t] IR=%h | L=%02h G=%1h | MUX(pc,dr,s1,a1,a2)=%0d,%0d,%0d,%0b,%0d | ALU=%0d | MEM=%0b/%0b",
           $time, ir,
           {ld_ir,ld_pc,ld_mar,ld_mdr,ld_reg,ld_cc},         // L: {IR,PC,MAR,MDR,REG,CC}
           {gate_pc,gate_mdr,gate_alu,gate_marmux},          // G: {PC,MDR,ALU,MARMUX}
           pcmux, drmux, sr1mux, addr1mux, addr2mux,
           aluk, mio_en, r_w);
  end

  // Stimulus (edge-driven)
  initial begin
    // Defaults
    reset = 1'b0;
    ir = 16'h0000;
    ready_bit = 1'b0;
    nzp = 3'b000;

    // Reset for 2 cycles
    reset = 1'b1; step_pos(2); reset = 1'b0;

    // Idle a few cycles
    step_pos(2);

    // Simulate memory ready pulse (for R condition advancement)
    ready_bit = 1'b1; step_pos(1); ready_bit = 1'b0;

    // Feed an ADD instruction (opcode 0001 in IR[15:12])
    // Exact fields below aren’t critical for this smoke test—opcode is what IRD uses.
    ir = 16'b0001_000_000_000_010;  // ADD R0 <- R0 + R2
    step_pos(5);

    // Another memory ready pulse
    ready_bit = 1'b1; step_pos(1); ready_bit = 1'b0;

    // Try a BR (opcode 0000) with NZP set so BEN would evaluate true when latched
    ir  = 16'b0000_111_000000000; // BRnzp (all three set)
    nzp = 3'b100;                 // e.g., N=1
    step_pos(2);

    // Let it run a few more cycles
    step_pos(10);

    $display("[TB] Finished.");
    $finish;
  end

endmodule
