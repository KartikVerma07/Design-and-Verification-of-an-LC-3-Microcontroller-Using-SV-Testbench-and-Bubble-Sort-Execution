//------------------------------------------------------------------------------
// Testbench : microsequencer_TB (edge-driven, no checker)
// Summary   : Exercises reset vector, plain J, R(wait) split, IRD dispatch,
//             and BEN-controlled branch (with ld_ben). Prints observed next_addr.
//------------------------------------------------------------------------------

`timescale 1ns/1ps
timeunit 1ns; timeprecision 1ps;

module microsequencer_TB;

  // Clocking
  logic clk = 1'b0, reset = 1'b0;
  localparam time HALF = 41.667ns;   // 12 MHz clock (for generation only)
  always #(HALF) clk = ~clk;

  // Edge helper
  task automatic step_pos(int n=1); repeat(n) @(posedge clk); endtask

  // DUT inputs/outputs
  logic [5:0] j_field;
  logic [2:0] cond_bits;
  logic       ird;
  logic       ld_ben;
  logic       r_bit;
  logic [6:0] ir_15_9;   // [6:3]=IR[15:12] opcode, [2]=IR11,[1]=IR10,[0]=IR9
  logic [2:0] nzp;       // {N,Z,P}
  logic [5:0] next_addr;

  // DUT
  microsequencer dut (
    .clk       (clk),
    .reset     (reset),
    .j_field   (j_field),
    .cond_bits (cond_bits),
    .ird       (ird),
    .ld_ben    (ld_ben),
    .r_bit     (r_bit),
    .ir_15_9   (ir_15_9),
    .nzp       (nzp),
    .next_addr (next_addr)
  );

  // Drive sequence with simple prints
  initial begin
    // Defaults
    j_field   = '0; cond_bits = 3'b000; ird = 1'b0; ld_ben = 1'b0;
    r_bit     = 1'b0; ir_15_9 = '0; nzp = '0;

    // Reset vector
    reset = 1'b1; step_pos();
    $display("[SEQ] reset:           next=%0d (0x%0h)  expected 0x12", next_addr, next_addr);
    reset = 1'b0;

    // Plain J (COND=000): next = J (18)
    j_field   = 6'd18; cond_bits = 3'b000; ird = 1'b0;
    step_pos();
    $display("[SEQ] J only:          next=%0d (0x%0h)  expected 18", next_addr, next_addr);

    // Unused cond encoding (101): default to J (33)
    j_field   = 6'd33; cond_bits = 3'b101;
    step_pos();
    $display("[SEQ] COND=101 deflt:  next=%0d (0x%0h)  expected 33", next_addr, next_addr);

    // Unused cond encoding (110): default to J (28)
    j_field   = 6'd28; cond_bits = 3'b110;
    step_pos();
    $display("[SEQ] COND=110 deflt:  next=%0d (0x%0h)  expected 28", next_addr, next_addr);

    // R(wait) split (COND=001): +2 when r_bit=1
    j_field   = 6'd28; cond_bits = 3'b001; r_bit = 1'b0;
    step_pos();
    $display("[SEQ] R=0:             next=%0d (0x%0h)  expected 28", next_addr, next_addr);
    r_bit     = 1'b1;
    step_pos();
    $display("[SEQ] R=1:             next=%0d (0x%0h)  expected 30", next_addr, next_addr);

    // IRD dispatch: next = {2'b00, IR[15:12]} => for 0001 (ADD) expect 1
    ir_15_9   = 7'b0001000;  // IR[15:12]=0001
    ird       = 1'b1;
    step_pos();
    $display("[SEQ] IRD ADD:         next=%0d (0x%0h)  expected 1", next_addr, next_addr);
    ird       = 1'b0;

    // BEN path (COND=010): +4 when BEN=1 (needs ld_ben to latch)
    // Case A: BEN=0 -> stay at J (22)
    ir_15_9   = 7'b0000000;  // IR[11:9]=000
    nzp       = 3'b000;
    ld_ben    = 1'b1; step_pos(); ld_ben = 1'b0;   // latch BEN=0
    j_field   = 6'd22; cond_bits = 3'b010;
    step_pos();
    $display("[SEQ] BEN=0:           next=%0d (0x%0h)  expected 22", next_addr, next_addr);

    // Case B: BEN=1 -> J+4 (24)
    ir_15_9   = 7'b0001100;  // IR11=1
    nzp       = 3'b100;      // N=1
    ld_ben    = 1'b1; step_pos(); ld_ben = 1'b0;   // latch BEN=1
    j_field   = 6'd20; cond_bits = 3'b010;
    step_pos();
    $display("[SEQ] BEN=1:           next=%0d (0x%0h)  expected 24", next_addr, next_addr);

    $display("[TB] Sequence complete.");
    $finish;
  end

endmodule