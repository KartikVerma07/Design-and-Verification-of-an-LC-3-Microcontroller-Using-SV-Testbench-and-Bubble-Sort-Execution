//------------------------------------------------------------------------------
// Module : microsequencer
// Logic  : Combinational + Clocked
// Summary: Produces next microinstruction address for the control store.
//------------------------------------------------------------------------------

module microsequencer (
  input  logic        clk,
  input  logic        reset,

  // From Control Store
  input  logic [5:0]  j_field,
  input  logic [2:0]  cond_bits,
  input  logic        ird,
  input  logic        ld_ben,

  // From memory interface
  input  logic        r_bit,

  // From datapath
  input  logic [6:0]  ir_15_9,   // {IR[15],...,IR[9]} => [6]=IR15 ... [0]=IR9
  input  logic [2:0]  nzp,       // {N,Z,P} -> [2]=N,[1]=Z,[0]=P
//   input  logic        acv,       // UNUSED
//   input  logic        psr_15,    // UNUSED

  // From interrupt logic
//   input  logic        intr,      // UNUSED

  // To control store
  output logic [5:0]  next_addr
);

  // ---------------------------------------------------------------------------
  // BEN computation: BEN = (IR[11]&N) | (IR[10]&Z) | (IR[9]&P)
  // ir_15_9[2]=IR[11], [1]=IR[10], [0]=IR[9]
  // ---------------------------------------------------------------------------
  logic ben_now, ben_q;
  assign ben_now = (ir_15_9[0] & nzp[0]) |  // IR[9] & P
                   (ir_15_9[1] & nzp[1]) |  // IR[10] & Z
                   (ir_15_9[2] & nzp[2]);   // IR[11] & N

  // BEN register (loaded only when ld_ben=1)
  always_ff @(posedge clk or posedge reset) begin
    if (reset)       ben_q <= 1'b0;
    else if (ld_ben) ben_q <= ben_now;
  end

  // ---------------------------------------------------------------------------
  // Condition encodings (match original design)
  // ---------------------------------------------------------------------------
  localparam logic [2:0]
    COND_R     = 3'b001,
    COND_BEN   = 3'b010,
    COND_IR11  = 3'b011;
    // COND_PSR15 = 3'b100, // UNUSED path
    // COND_INT   = 3'b101, // UNUSED path
    // COND_ACV   = 3'b110; // UNUSED path

  // ---------------------------------------------------------------------------
  // Next address logic (classic LC-3 style)
  //   reset     -> state 0x12 (6'h12)
  //   ird==1    -> {00, IR[15:12]}
  //   cond_bits -> OR-in selected condition into j_field
  //   default   -> j_field
  // ---------------------------------------------------------------------------
  always_comb begin
    if (reset) begin
      next_addr = 6'h12;                                  // FIX: 6-bit reset vector
    end else if (ird) begin
      next_addr = {2'b00, ir_15_9[6:3]};                  // opcode dispatch
    end else begin
      unique case (cond_bits)
        COND_BEN  : next_addr = ({3'b000, ben_q, 2'b00}       | j_field);  // +4 if BEN=1, ben_q depends on NZP
        COND_R    : next_addr = ({4'b0000, r_bit, 1'b0}       | j_field);  // +2 if R=1
        COND_IR11 : next_addr = ({5'b00000, ir_15_9[2]}       | j_field);  // +1 if IR[11]=1 
        // COND_PSR15: next_addr = ({2'b00, psr_15, 3'b000}    | j_field); // UNUSED
        // COND_INT  : next_addr = ({1'b0, intr, 4'b0000}      | j_field); // UNUSED
        // COND_ACV  : next_addr = ({acv, 5'b00000}            | j_field); // UNUSED
        default   : next_addr = j_field;
      endcase
    end
  end

endmodule
