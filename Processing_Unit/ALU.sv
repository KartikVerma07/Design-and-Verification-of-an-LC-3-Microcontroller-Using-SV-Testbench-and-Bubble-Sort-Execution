//------------------------------------------------------------------------------
// Module: ALU
// Logic : Combinational (no clock)
// Description: Performs arithmetic and logical operations on two operands.
//              The result is driven to the bus for register writeback, and
//              downstream logic determines the condition codes (N/Z/P).
//              Operands are sourced from the register file or an immediate
//              field as selected by the instruction register (IR).
//------------------------------------------------------------------------------

module ALU (
  // From Control Store:
  input  logic [1:0]  ALUK,

  // Operands
  input  logic [15:0] SR2MUX_Out,      // SR2 Mux's Output
  input  logic [15:0] RegFile_Out,  // Register File's Output

  // Output
  output logic [15:0] ToBus         // Output (goes to bus)
);

  // Prefer localparam (or move to a package later)
  localparam logic [1:0] ADD    = 2'b00;
  localparam logic [1:0] AND_   = 2'b01; // AND is a keyword in some contexts; keep unique name
  localparam logic [1:0] NOT_   = 2'b10;
  localparam logic [1:0] PASS_A = 2'b11;

  always_comb begin
    // default to avoid accidental latches & help X-prop in sim
    ToBus = '0;

    unique case (ALUK)
      ADD:    ToBus = SR2MUX_Out + RegFile_Out; // 16-bit two’s complement add (no sat/overflow)
      AND_:   ToBus = SR2MUX_Out & RegFile_Out;
      NOT_:   ToBus = ~RegFile_Out;
      PASS_A: ToBus =  RegFile_Out;
      default: /* keep default as '0; unique will flag unexpected values */
                ;
    endcase
  end

endmodule
