//------------------------------------------------------------------------------
// Module : control_logic
// Logic  : Clocked + Combinational
// Summary: Wraps microsequencer + control store and exposes decoded control
//          signals for the LC-3 datapath.
//------------------------------------------------------------------------------

module control_logic (
  input  logic        clk,
  // From datapath
  input  logic [15:0] ir,
  input  logic        ready_bit,
  input  logic [2:0]  nzp,
  input  logic        reset,

  // Load registers (datapath + regfile)
  output logic        ld_mar,
  output logic        ld_mdr,
  output logic        ld_ir,
  output logic        ld_reg,
  output logic        ld_cc,
  output logic        ld_pc,
//   output logic        ld_priv,        // UNUSED
//   output logic        ld_savedssp,    // UNUSED
//   output logic        ld_savedusp,    // UNUSED
//   output logic        ld_vector,      // UNUSED
//   output logic        ld_priority,    // UNUSED
//   output logic        ld_acv,         // UNUSED

  // CPU bus gates
  output logic        gate_pc,
  output logic        gate_mdr,
  output logic        gate_alu,
  output logic        gate_marmux,
//   output logic        gate_vector,    // UNUSED
//   output logic        gate_pc_minus1, // UNUSED
//   output logic        gate_srp,       // UNUSED
//   output logic        gate_sp,        // UNUSED

  // Mux controls
  output logic [1:0]  pcmux,
  output logic [1:0]  drmux,
  output logic [1:0]  sr1mux,
  output logic        addr1mux,
  output logic [1:0]  addr2mux,
//   output logic [1:0]  spmux,          // UNUSED
  output logic        marmux,
//   output logic        tablemux,       // UNUSED
//   output logic [1:0]  vectormux,      // UNUSED
//   output logic        psrmux,         // UNUSED

  // ALU control 
  output logic [1:0]  aluk,

  // Memory control
  output logic        mio_en,
  output logic        r_w

  // Privilege control
//   output logic        set_priv        // UNUSED
);

  // ---------------------------------------------------------------------------
  // Microsequencer + Control Store
  // ---------------------------------------------------------------------------
  logic [51:0] cur_state;
  logic [5:0]  next_addr;

  // Microsequencer control fields (decoded from cur_state)
  logic        ird;
  logic [2:0]  cond;
  logic [5:0]  j_field;
  logic        ld_ben;  // internal

  microsequencer u_microseq (
    .clk              (clk),
    .reset            (reset),
    // From control store
    .j_field          (j_field),
    .cond_bits        (cond),
    .ird              (ird),
    .ld_ben           (ld_ben),
    // From datapath
    .r_bit            (ready_bit),
    .ir_15_9          (ir[15:9]),
    .nzp              (nzp),
    // .ACV              (),   // UNUSED
    // .PSR_15           (),   // UNUSED
    // .INT              (),   // UNUSED
    .next_addr			 (next_addr)
  );

  control_store u_cstore (
    .clk       (clk),
    .read_en   (1'b1),   // always read microinstruction
    .read_addr (next_addr),
    .read_data (cur_state)
  );

  // ---------------------------------------------------------------------------
  // Decode current microinstruction into control signals
  // Bit map (MSB..LSB):
  // [51]=IRD, [50:48]=COND, [47:42]=J,
  // [41]=LD_MAR, [40]=LD_MDR, [39]=LD_IR, [38]=LD_BEN, [37]=LD_REG, [36]=LD_CC,
  // [35]=LD_PC, [34]=LD_Priv, [33]=LD_SavedSSP, [32]=LD_SavedUSP, [31]=LD_Vector,
  // [30]=LD_Priority, [29]=LD_ACV,
  // [28]=GatePC, [27]=GateMDR, [26]=GateALU, [25]=GateMarMux, [24]=GateVector,
  // [23]=GatePC-1, [22]=GateSRP, [21]=GateSP,
  // [20:19]=PCMUX, [18:17]=DRMUX, [16:15]=SR1MUX, [14]=ADDR1MUX, [13:12]=ADDR2MUX,
  // [11:10]=SPMUX, [9]=MARMUX, [8]=TableMUX, [7:6]=VectorMUX, [5]=PSRMUX,
  // [4:3]=ALUK, [2]=MIO_EN, [1]=R_W, [0]=Set_Priv
  // ---------------------------------------------------------------------------

  // Sequencer inputs
  assign ird     = cur_state[51];
  assign cond    = cur_state[50:48];
  assign j_field = cur_state[47:42];

  // Loads
  assign ld_mar       = cur_state[41];
  assign ld_mdr       = cur_state[40];
  assign ld_ir        = cur_state[39];
  assign ld_ben       = cur_state[38];           // internal only
  assign ld_reg       = cur_state[37];
  assign ld_cc        = cur_state[36];
  assign ld_pc        = cur_state[35];
//   assign ld_priv      = cur_state[34];           // UNUSED
//   assign ld_savedssp  = cur_state[33];           // UNUSED
//   assign ld_savedusp  = cur_state[32];           // UNUSED
//   assign ld_vector    = cur_state[31];           // UNUSED
//   assign ld_priority  = cur_state[30];           // UNUSED
//   assign ld_acv       = cur_state[29];           // UNUSED

  // Bus gates
  assign gate_pc         = cur_state[28];
  assign gate_mdr        = cur_state[27];
  assign gate_alu        = cur_state[26];
  assign gate_marmux     = cur_state[25];
//   assign gate_vector     = cur_state[24];        // UNUSED
//   assign gate_pc_minus1  = cur_state[23];        // UNUSED
//   assign gate_srp        = cur_state[22];        // UNUSED
//   assign gate_sp         = cur_state[21];        // UNUSED

  // Mux controls
  assign pcmux     = cur_state[20:19];
  assign drmux     = cur_state[18:17];
  assign sr1mux    = cur_state[16:15];
  assign addr1mux  = cur_state[14];
  assign addr2mux  = cur_state[13:12];
//   assign spmux     = cur_state[11:10];           // UNUSED
  assign marmux    = cur_state[9];
//   assign tablemux  = cur_state[8];               // UNUSED
//   assign vectormux = cur_state[7:6];             // UNUSED
//   assign psrmux    = cur_state[5];               // UNUSED

  // ALU & memory
  assign aluk      = cur_state[4:3];
  assign mio_en    = cur_state[2];
  assign r_w       = cur_state[1];

  // Privilege
 // assign set_priv  = cur_state[0];               // UNUSED

endmodule
