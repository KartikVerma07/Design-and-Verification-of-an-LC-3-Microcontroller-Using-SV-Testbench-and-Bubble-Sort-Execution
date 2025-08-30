//------------------------------------------------------------------------------
// Testbench : processing_unit_tb
// Summary   : Verifies register writes, ALU pass-through, register-register
//             ADD, and ADD with imm5 using the processing_unit in isolation.
//             All stimulus uses clock edges (no real-time delays in stimulus).
//------------------------------------------------------------------------------

`timescale 1ns/1ps
timeunit 1ns; timeprecision 1ps;

module processing_unit_TB;

  // Clock & reset
  logic clk = 1'b0;
  logic reset = 1'b0;

  // processing_unit controls
  logic        ld_reg;
  logic [1:0]  aluk;
  logic [1:0]  sr1mux_sel;   // 00: IR[11:9], 01: IR[8:6], 10: R6
  logic [1:0]  drmux_sel;    // 00: IR[11:9], 01: R7, 10: R6

  // “IR” fields (sliced at DUT ports)
  logic [15:0] ir;

  // Bus wiring: either external drive (bus_ext) or loopback (to_bus) for writeback
  logic        gate_alu_to_bus;   // when 1, feed ALU result back into bus
  logic [15:0] bus_ext;           // external bus drive (for plain reg writes)
  logic [15:0] bus_in;            // goes into DUT
  logic [15:0] to_bus;            // DUT ALU output

  //observe SR1 output if you want (not required)
  logic [15:0] sr1_tap;

  // 12 MHz clock (only used for clock gen, stimulus uses edge events)
  localparam time HALF = 41.667ns;
  always #(HALF) clk = ~clk;

  // Edge helpers (no #HALF in stimulus)
  task automatic step_pos (int n = 1); repeat (n) @(posedge clk); endtask
  task automatic step_neg (int n = 1); repeat (n) @(negedge clk); endtask

  // Compose a convenient IR value
  function automatic [15:0] mk_ir
  (
    input logic [2:0] dr,
    input logic [2:0] sr1,
    input logic       use_imm5,
    input logic [4:0] imm5,
    input logic [2:0] sr2
  );
    logic [15:0] v; v = '0;
    v[11:9] = dr;
    v[8:6]  = sr1;
    v[5]    = use_imm5;
    if (use_imm5) v[4:0] = imm5; else v[2:0] = sr2;
    return v;
  endfunction

  // DUT bus mux: external drive OR ALU loopback (simulates top-level bus gating)
  assign bus_in = gate_alu_to_bus ? to_bus : bus_ext;

  // DUT
  processing_unit dut (
    .clk        (clk),
    .reset      (reset),
    .ld_reg     (ld_reg),
    .aluk       (aluk),
    .ir_11_9    (ir[11:9]),
    .ir_8_6     (ir[8:6]),
    .ir_2_0     (ir[2:0]),
    .sr1mux     (sr1mux_sel),
    .drmux      (drmux_sel),
    .ir_5       (ir[5]),
    .ir_4_0     (ir[4:0]),
    .from_bus   (bus_in),
    .sr1_out    (sr1_tap),
    .to_bus     (to_bus)
  );

  // --- Small self-check helpers ------------------------------------------------
  task automatic wr_reg_via_bus(input logic [2:0] dr, input logic [15:0] val);
    // plain write: use external bus source, DR from IR[11:9]
    drmux_sel = 2'b00;                // DR = IR[11:9]
    ir        = mk_ir(dr, 3'b000, 1'b0, 5'h0, 3'b000);
    gate_alu_to_bus = 1'b0;           // don't loop back for plain write
    bus_ext   = val;
    ld_reg    = 1'b1;
    step_pos();                       // capture at this posedge
    ld_reg    = 1'b0;
    bus_ext   = '0;
  endtask

  task automatic check_reg_pass_a(input logic [2:0] sr1, input logic [15:0] exp);
    // Drive ALU PASS_A of SR1 onto bus and compare
    sr1mux_sel = 2'b01;               // SR1 = IR[8:6]
    ir         = mk_ir(3'b000, sr1, 1'b0, 5'h0, 3'b000);
    aluk       = 2'b11;               // PASS_A
    gate_alu_to_bus = 1'b1;           // observe ALU result on bus
    step_pos();
    assert (to_bus === exp)
      else $fatal(1, "PASS_A mismatch: SR1=R%0d exp=%h got=%h", sr1, exp, to_bus);
    gate_alu_to_bus = 1'b0;
  endtask

  task automatic add_rr_writeback
  (
    input logic [2:0] dr,  // dest
    input logic [2:0] s1,  // SR1
    input logic [2:0] s2   // SR2
  );
    // ALU = R[s1] + R[s2], write back to DR through bus loopback
    sr1mux_sel = 2'b01;               // SR1 = IR[8:6]
    drmux_sel  = 2'b00;               // DR = IR[11:9]
    ir         = mk_ir(dr, s1, 1'b0, 5'h0, s2); // IR[5]=0 -> use SR2
    aluk       = 2'b00;               // ADD
    gate_alu_to_bus = 1'b1;           // ALU result onto bus
    ld_reg     = 1'b1;                // write back via bus
    step_pos();
    ld_reg     = 1'b0;
    gate_alu_to_bus = 1'b0;
  endtask

  task automatic add_ri_writeback
  (
    input logic [2:0] dr,
    input logic [2:0] s1,
    input logic signed [4:0] imm5
  );
    // ALU = R[s1] + imm5, write back to DR
    sr1mux_sel = 2'b01;               // SR1 = IR[8:6]
    drmux_sel  = 2'b00;               // DR = IR[11:9]
    ir         = mk_ir(dr, s1, 1'b1, imm5[4:0], 3'b000); // IR[5]=1 -> imm5
    aluk       = 2'b00;               // ADD
    gate_alu_to_bus = 1'b1;
    ld_reg     = 1'b1;
    step_pos();
    ld_reg     = 1'b0;
    gate_alu_to_bus = 1'b0;
  endtask
  // -----------------------------------------------------------------------------

  // Stimulus
  initial begin
    // defaults
    ld_reg         = 1'b0;
    aluk           = 2'b00;
    sr1mux_sel     = 2'b00;
    drmux_sel      = 2'b00;
    gate_alu_to_bus= 1'b0;
    bus_ext        = '0;
    ir             = '0;

    // reset for 2 cycles
    reset = 1'b1; step_pos(2); reset = 1'b0;

    // ---------------------------------------------------------------------------
    // 1) Basic writes: R7=0x000F, R4=0x00F0
    // ---------------------------------------------------------------------------
    wr_reg_via_bus(3'd7, 16'h000F);
    wr_reg_via_bus(3'd4, 16'h00F0);

    // Readbacks via PASS_A
    check_reg_pass_a(3'd7, 16'h000F);
    check_reg_pass_a(3'd4, 16'h00F0);

    // ---------------------------------------------------------------------------
    // 2) R1=3, R2=4; R3 = R1 + R2; verify R3=7
    // ---------------------------------------------------------------------------
    wr_reg_via_bus(3'd1, 16'h0003);
    wr_reg_via_bus(3'd2, 16'h0004);
    add_rr_writeback(3'd3, 3'd1, 3'd2);
    check_reg_pass_a(3'd3, 16'h0007);

    // ---------------------------------------------------------------------------
    // 3) Chained adds using register-register
    //    R4 = R1 + R3 (=3+7=10), R7 = R4 + R3 (=10+7=17)
    // ---------------------------------------------------------------------------
    add_rr_writeback(3'd4, 3'd1, 3'd3);
    check_reg_pass_a(3'd4, 16'h000A);
    add_rr_writeback(3'd7, 3'd4, 3'd3);
    check_reg_pass_a(3'd7, 16'h0011);

    // ---------------------------------------------------------------------------
    // 4) ADD imm5: R0 = R2 + 8 (=4+8=12), R1 = R1 + 8 (=3+8=11)
    // ---------------------------------------------------------------------------
    add_ri_writeback(3'd0, 3'd2, 5'sd8);
    check_reg_pass_a(3'd0, 16'h000C);

    add_ri_writeback(3'd1, 3'd1, 5'sd8);
    check_reg_pass_a(3'd1, 16'h000B);

    // Done
    $display("[TB] Finished!");
    $finish;
  end

endmodule
