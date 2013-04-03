

///////////////////////////////////////////////////////////////////////////////
// This file will hold module definitions of the reservation station table.  //
// The main module utilizes multiple individual reservation station modules. //
///////////////////////////////////////////////////////////////////////////////

`define SD #1

// defined paramters //
`define NUM_RSES 8
`define RS_EMPTY        3'b000
`define RS_WAITING_A    3'b001
`define RS_WAITING_B    3'b010
`define RS_WAITING_BOTH 3'b011
`define RS_READY        3'b100
`define RSTAG_NULL      8'hFF           


// individual reservation station entry module //
module reservation_station_entry(clock,reset,fill,                               // signals in

                           // input busses //
                           dest_reg_in,
						   dest_tag_in,
                           rega_value_in,
                           regb_value_in,
                           waiting_taga_in,
                           waiting_tagb_in,                

                           // generic signals to just be passed on //
                           opa_select_in,
                           opb_select_in,
                           alu_func_in,
                           rd_mem_in,
                           wr_mem_in,
                           cond_branch_in,
                           uncond_branch_in,

                           // cdbs in //
                           cdb1_tag_in,cdb1_value_in,                
                           cdb2_tag_in,cdb2_value_in,

                           // outputs //
                           status_out,                                           // signals out
						   dest_tag_out,
                           dest_reg_out,
                           rega_value_out,
                           regb_value_out, 

                           // outputs for signals to simply be passed through
                           opa_select_out,
                           opb_select_out,
                           alu_func_out,
                           rd_mem_out,
                           wr_mem_out,
                           cond_branch_out,
                           uncond_branch_out

                           );

   // inputs //
   input wire clock;
   input wire reset;
   input wire fill;
   input wire [4:0]  dest_reg_in;
   input wire [7:0]  dest_tag_in;
   input wire [63:0] rega_value_in;
   input wire [63:0] regb_value_in;
   input wire [7:0]  waiting_taga_in;
   input wire [7:0]  waiting_tagb_in;

   input wire [7:0]  cdb1_tag_in;
   input wire [7:0]  cdb2_tag_in;
   input wire [63:0] cdb1_value_in;
   input wire [63:0] cdb2_value_in;

   input wire [1:0] opa_select_in;
   input wire [1:0] opb_select_in;
   input wire [4:0] alu_func_in;
   input wire       rd_mem_in;
   input wire       wr_mem_in;
   input wire       cond_branch_in;
   input wire       uncond_branch_in;


   // outputs //
   output reg  [2:0]  status_out;
   output reg  [4:0]  dest_reg_out;
   output reg  [7:0]  dest_tag_out;
   output reg  [63:0] rega_value_out;
   output reg  [63:0] regb_value_out;

   output reg  [1:0]  opa_select_out;
   output reg  [1:0]  opb_select_out;
   output reg  [4:0]  alu_func_out;
   output reg         rd_mem_out;
   output reg         wr_mem_out;
   output reg         cond_branch_out;
   output reg         uncond_branch_out;


   // internal registers and wires //
   reg  [2:0]  n_status;
   reg  [4:0]  n_dest_reg;
   reg  [7:0]  n_dest_tag;
   reg  [7:0]    waiting_taga;
   reg  [7:0]  n_waiting_taga;
   reg  [7:0]    waiting_tagb;
   reg  [7:0]  n_waiting_tagb; 
   reg  [63:0] n_rega_value;
   reg  [63:0] n_regb_value;

   reg [1:0]  n_opa_select_out;
   reg [1:0]  n_opb_select_out;
   reg [4:0]  n_alu_func_out;
   reg        n_rd_mem_out;
   reg        n_wr_mem_out;
   reg        n_cond_branch_out;
   reg        n_uncond_branch_out;

   wire taga_in_nonnull;     
   wire tagb_in_nonnull;
   wire taga_cur_nonnull;
   wire tagb_cur_nonnull;
   wire taga_in_match_cdb1_in;
   wire taga_in_match_cdb2_in;
   wire tagb_in_match_cdb1_in;
   wire tagb_in_match_cdb2_in;
   wire taga_cur_match_cdb1_cur;
   wire taga_cur_match_cdb2_cur;
   wire tagb_cur_match_cdb1_cur;
   wire tagb_cur_match_cdb2_cur;

   // combinational assignments //
   assign taga_in_nonnull        = (waiting_taga_in!=`RSTAG_NULL);
   assign tagb_in_nonnull        = (waiting_tagb_in!=`RSTAG_NULL);
   assign taga_cur_nonnull       = (waiting_taga!=`RSTAG_NULL);
   assign tagb_cur_nonnull       = (waiting_tagb!=`RSTAG_NULL);
   assign taga_in_match_cdb1_in  = (waiting_taga_in==cdb1_tag_in);
   assign taga_in_match_cdb2_in  = (waiting_taga_in==cdb2_tag_in);
   assign tagb_in_match_cdb1_in  = (waiting_tagb_in==cdb1_tag_in);
   assign tagb_in_match_cdb2_in  = (waiting_tagb_in==cdb2_tag_in); 
   assign taga_cur_match_cdb1_in = (waiting_taga==cdb1_tag_in);
   assign taga_cur_match_cdb2_in = (waiting_taga==cdb2_tag_in);
   assign tagb_cur_match_cdb1_in = (waiting_tagb==cdb1_tag_in);
   assign tagb_cur_match_cdb2_in = (waiting_tagb==cdb2_tag_in);


   // combinational logic to set next states //
   always@*
   begin

      if (fill)
      begin

         // stuff based on logic //
         n_waiting_taga = (taga_in_match_cdb1_in && taga_in_nonnull) ? `RSTAG_NULL  :
                         ((taga_in_match_cdb2_in && taga_in_nonnull) ? `RSTAG_NULL : waiting_taga_in);
         n_waiting_tagb = (tagb_in_match_cdb1_in && tagb_in_nonnull) ? `RSTAG_NULL  :
                         ((tagb_in_match_cdb2_in && tagb_in_nonnull) ? `RSTAG_NULL :  waiting_tagb_in);
         n_rega_value   = (taga_in_match_cdb1_in && taga_in_nonnull) ? cdb1_value_in :
                         ((taga_in_match_cdb2_in && taga_in_nonnull) ? cdb2_value_in : rega_value_in);
         n_regb_value   = (tagb_in_match_cdb1_in && tagb_in_nonnull) ? cdb1_value_in :
                         ((tagb_in_match_cdb2_in && tagb_in_nonnull) ? cdb2_value_in : regb_value_in);
         case ({ (n_waiting_taga!=`RSTAG_NULL), (n_waiting_tagb!=`RSTAG_NULL) })
            2'b00: n_status = `RS_READY;
            2'b01: n_status = `RS_WAITING_B;
            2'b10: n_status = `RS_WAITING_A;
            2'b11: n_status = `RS_WAITING_BOTH;
         endcase
         
         // pass-throughs //
         n_dest_reg          = dest_reg_in;
		 n_dest_tag          = dest_tag_in;
         n_opa_select_out    = opa_select_in; 
         n_opb_select_out    = opb_select_in; 
         n_alu_func_out      = alu_func_in;
         n_rd_mem_out        = rd_mem_in;
         n_wr_mem_out        = wr_mem_in;
         n_cond_branch_out   = cond_branch_in;
         n_uncond_branch_out = uncond_branch_in;

      end
      else
      begin

         // stuff based on logic //
         n_waiting_taga = (taga_cur_match_cdb1_in && taga_cur_nonnull) ? `RSTAG_NULL : 
                         ((taga_cur_match_cdb2_in && taga_cur_nonnull) ? `RSTAG_NULL : waiting_taga);
         n_waiting_tagb = (tagb_cur_match_cdb1_in && tagb_cur_nonnull) ? `RSTAG_NULL : 
                         ((tagb_cur_match_cdb2_in && tagb_cur_nonnull) ? `RSTAG_NULL : waiting_tagb);
         n_rega_value   = (taga_cur_match_cdb1_in && taga_cur_nonnull) ? cdb1_value_in :
                         ((taga_cur_match_cdb2_in && taga_cur_nonnull) ? cdb2_value_in : rega_value_out);
         n_regb_value   = (tagb_cur_match_cdb1_in && tagb_cur_nonnull) ? cdb1_value_in : 
                         ((tagb_cur_match_cdb2_in && tagb_cur_nonnull) ? cdb2_value_in : regb_value_out);
         case ({ (n_waiting_taga!=`RSTAG_NULL), (n_waiting_tagb!=`RSTAG_NULL) })
            2'b00: n_status = `RS_READY;
            2'b01: n_status = `RS_WAITING_B;
            2'b10: n_status = `RS_WAITING_A;
            2'b11: n_status = `RS_WAITING_BOTH;
         endcase

         // pass-throughs //
         n_dest_reg          = dest_reg_out;
		 n_dest_tag          = dest_tag_out;
         n_opa_select_out    = opa_select_out;
         n_opb_select_out    = opb_select_out;
         n_alu_func_out      = alu_func_out;
         n_rd_mem_out        = rd_mem_out;
         n_wr_mem_out        = wr_mem_out;
         n_cond_branch_out   = cond_branch_out;
         n_uncond_branch_out = uncond_branch_out;

      end
   end

   // clock synchronous events //
   always@(posedge clock)
   begin
      if (reset)
      begin
         status_out        <= `SD `RS_EMPTY;
         dest_reg_out      <= `SD 5'd0;
		 dest_tag_out      <= `SD `RSTAG_NULL;
         waiting_taga      <= `SD `RSTAG_NULL;
         waiting_tagb      <= `SD `RSTAG_NULL;
         rega_value_out    <= `SD 64'd0;
         regb_value_out    <= `SD 64'd0;
         opa_select_out    <= `SD 2'b00;
         opb_select_out    <= `SD 2'b00;
         alu_func_out      <= `SD 5'd0;
         rd_mem_out        <= `SD 1'b0;
         wr_mem_out        <= `SD 1'b0;
         cond_branch_out   <= `SD 1'b0;
         uncond_branch_out <= `SD 1'b0;
      end
      else
      begin
         status_out        <= `SD n_status;
         dest_reg_out      <= `SD n_dest_reg;
		 dest_tag_out      <= `SD n_dest_tag;
         waiting_taga      <= `SD n_waiting_taga;
         waiting_tagb      <= `SD n_waiting_tagb;
         rega_value_out    <= `SD n_rega_value;
         regb_value_out    <= `SD n_regb_value;
         opa_select_out    <= `SD n_opa_select_out;
         opb_select_out    <= `SD n_opb_select_out;
         alu_func_out      <= `SD n_alu_func_out;
         rd_mem_out        <= `SD n_rd_mem_out;
         wr_mem_out        <= `SD n_wr_mem_out;
         cond_branch_out   <= `SD n_cond_branch_out;
         uncond_branch_out <= `SD n_uncond_branch_out;
      end
   end

endmodule





// needed outputs from decode stage: //
//
// wire [63:0] id_rega_out;
// wire [63:0] id_regb_out;
// wire  [1:0] id_opa_select_out;
// wire  [1:0] id_opb_select_out;
// wire  [4:0] id_dest_reg_idx_out;
// wire  [4:0] id_alu_func_out;
// wire        id_rd_mem_out;
// wire        id_wr_mem_out;
// wire        id_cond_branch_out;
// wire        id_uncond_branch_out;
// wire        id_halt_out;
// wire        id_illegal_out;
// wire        id_valid_inst_out;
//
// FROM SCOTT:  //
//
// opa_select
// opb_select
// alu_func
// dest_reg
// cond_branch
// uncond_branch
// valid_inst
//


// the actual reservation station module //
module reservation_station(clock,reset,               // signals in

                           // signals and busses in for inst 1 (from id1) //
                           inst1_rega_value_in,
                           inst1_regb_value_in,
                           inst1_rega_tag_in,
                           inst1_regb_tag_in,
                           inst1_dest_reg_in,
                           inst1_dest_tag_in,
                           inst1_opa_select_in,
                           inst1_opb_select_in,
                           inst1_alu_func_in,
                           inst1_rd_mem_in,
                           inst1_wr_mem_in,
                           inst1_cond_branch_in,
                           inst1_uncond_branch_in,
                           inst1_valid,

                           // signals and busses in for inst 2 (from id2) //
                           inst2_rega_value_in,
                           inst2_regb_value_in,
                           inst2_rega_tag_in,
                           inst2_regb_tag_in,
                           inst2_dest_reg_in,
                           inst2_dest_tag_in,
                           inst2_opa_select_in,
                           inst2_opb_select_in,
                           inst2_alu_func_in,
                           inst2_rd_mem_in,
                           inst2_wr_mem_in,
                           inst2_cond_branch_in,
                           inst2_uncond_branch_in,
                           inst2_valid,

                           // cdb inputs //
                           cdb1_tag_in,
                           cdb2_tag_in,
                           cdb1_value_in,
                           cdb2_value_in,

                           // signals and busses out for inst1 to the ex stage
                           inst1_rega_value_out,inst1_regb_value_out,
                           inst1_opa_select_out,inst1_opb_select_out,
                           inst1_alu_func_out,
                           inst1_rd_mem_out,inst1_wr_mem_out,
                           inst1_cond_branch_out,inst1_uncond_branch_out,
                           inst1_valid_out,
                           inst1_dest_reg_out,
                           inst1_dest_tag_out,

                           // signals and busses out for inst2 to the ex stage
                           inst2_rega_value_out,inst2_regb_value_out,
                           inst2_opa_select_out,inst2_opb_select_out,
                           inst2_alu_func_out,
                           inst2_rd_mem_out,inst2_wr_mem_out,
                           inst2_cond_branch_out,inst2_uncond_branch_out,
                           inst2_valid_out,
                           inst2_dest_reg_out,
                           inst2_dest_tag_out,

                           // signal outputs //
                           dispatch
                         
                           // outputs for debugging //
                               );


   // inputs //
   input wire clock;
   input wire reset;

   input wire [63:0] inst1_rega_value_in,inst1_regb_value_in;
   input wire [63:0] inst2_rega_value_in,inst2_regb_value_in;
   input wire [7:0]  inst1_rega_tag_in,inst1_regb_tag_in;
   input wire [7:0]  inst2_rega_tag_in,inst2_regb_tag_in;
   input wire [4:0]  inst1_dest_reg_in;
   input wire [4:0]  inst2_dest_reg_in;
   input wire [7:0]  inst1_dest_tag_in;
   input wire [7:0]  inst2_dest_tag_in;
   input wire [1:0]  inst1_opa_select_in,inst1_opb_select_in;
   input wire [1:0]  inst2_opa_select_in,inst2_opb_select_in;
   input wire [4:0]  inst1_alu_func_in;
   input wire [4:0]  inst2_alu_func_in;
   input wire        inst1_rd_mem_in,inst1_wr_mem_in;
   input wire        inst2_rd_mem_in,inst2_wr_mem_in;
   input wire        inst1_cond_branch_in,inst1_uncond_branch_in;
   input wire        inst2_cond_branch_in,inst2_uncond_branch_in;
   input wire        inst1_valid;
   input wire        inst2_valid;

   input wire [7:0]  cdb1_tag_in;
   input wire [7:0]  cdb2_tag_in;
   input wire [63:0] cdb1_value_in;
   input wire [63:0] cdb2_value_in;


   // outputs //
   output wire dispatch; 

   output wor [63:0] inst1_rega_value_out,inst1_regb_value_out;
   output wor [1:0]  inst1_opa_select_out,inst1_opb_select_out;
   output wor [4:0]  inst1_alu_func_out;
   output wor        inst1_rd_mem_out,inst1_wr_mem_out;
   output wor        inst1_cond_branch_out,inst1_uncond_branch_out;
   output wor        inst1_valid_out;
   output wor [4:0]  inst1_dest_reg_out;
   output wor [7:0]  inst1_dest_tag_out;

   output wor [63:0] inst2_rega_value_out,inst2_regb_value_out;
   output wor [1:0]  inst2_opa_select_out,inst2_opb_select_out;
   output wor [4:0]  inst2_alu_func_out;
   output wor        inst2_rd_mem_out,inst2_wr_mem_out;
   output wor        inst2_cond_branch_out,inst2_uncond_branch_out;
   output wor        inst2_valid_out;
   output wor [4:0]  inst2_dest_reg_out;
   output wor [7:0]  inst2_dest_tag_out;

   
   // internal wires for interfacing the rs entries //
   wire [(`NUM_RSES-1):0] fills;
   wire [(`NUM_RSES-1):0] resets;

   wire [4:0]             dest_regs_in     [(`NUM_RSES-1):0];
   wire [7:0]             dest_tags_in     [(`NUM_RSES-1):0];
   wire [63:0]            rega_values_in   [(`NUM_RSES-1):0];
   wire [63:0]            regb_values_in   [(`NUM_RSES-1):0];
   wire [7:0]             waiting_tagas_in [(`NUM_RSES-1):0];
   wire [7:0]             waiting_tagbs_in [(`NUM_RSES-1):0];                

   wire [1:0]             opa_selects_in   [(`NUM_RSES-1):0];
   wire [1:0]             opb_selects_in   [(`NUM_RSES-1):0];
   wire [4:0]             alu_funcs_in     [(`NUM_RSES-1):0];
   wire [(`NUM_RSES-1):0] rd_mems_in;
   wire [(`NUM_RSES-1):0] wr_mems_in;
   wire [(`NUM_RSES-1):0] cond_branches_in;
   wire [(`NUM_RSES-1):0] uncond_branches_in;
 
   wire [2:0]             statuses_out     [(`NUM_RSES-1):0];
   wire [4:0]             dest_regs_out    [(`NUM_RSES-1):0];
   wire [7:0]             dest_tags_out    [(`NUM_RSES-1):0];
   wire [63:0]            rega_values_out  [(`NUM_RSES-1):0];
   wire [63:0]            regb_values_out  [(`NUM_RSES-1):0];
   
   wire [1:0]             opa_selects_out  [(`NUM_RSES-1):0];
   wire [1:0]             opb_selects_out  [(`NUM_RSES-1):0];
   wire [4:0]             alu_funcs_out    [(`NUM_RSES-1):0];
   wire [(`NUM_RSES-1):0] rd_mems_out ;
   wire [(`NUM_RSES-1):0] wr_mems_out;
   wire [(`NUM_RSES-1):0] cond_branches_out;
   wire [(`NUM_RSES-1):0] uncond_branches_out;

   
   // other internal wires //   
   wire [2:0] statuses       [(`NUM_RSES-1):0];
   wire [7:0] waiting_tags1  [(`NUM_RSES-1):0];
   wire [7:0] waiting_tags2  [(`NUM_RSES-1):0]; 

   reg  [7:0]   ages         [(`NUM_RSES-1):0];
   wire [7:0] n_ages         [(`NUM_RSES-1):0];

   wand [(`NUM_RSES-1):0] issue_first_states;   // indicates whether or not this rs entry should issue next
   wand [(`NUM_RSES-1):0] issue_second_states;  // indicates whether or not this rs entry should issue next
   wire [(`NUM_RSES-1):0] ready_states;         // indicates whether or not this rs entry is currently ready to issue
   wire [(`NUM_RSES-1):0] comp_table [(`NUM_RSES-1):0];    // table of rs entry age comparisons 

   
   // combinational logic for assigning next rs age values //
   generate
      for (genvar i=0; i<`NUM_RSES; i=i+1)
      begin : ASSIGNNRSAGES
         assign n_ages[i] = (dispatch && inst1_valid && inst2_valid) ? ages[i]+8'd2 : ( (dispatch && inst1_valid && inst2_valid) ? ages[i]+8'd1 : ages[i] );
      end
   endgenerate
   
   
   // combinational logic for assigning outputs, including dispatch state (whether or not table is full) //
   genvar i;
   generate
      for (genvar i=0; i<`NUM_RSES; i=i+1)
	  begin : ASSIGNOUTPUTS

		 assign dispatch = (rs_statuses[i]==`RS_EMPTY);
		
		 assign inst1_rega_value_out    = (issue_first_states[i] ? rega_values_out[i] : 64'd0);
		 assign inst1_regb_value_out    = (issue_first_states[i] ? regb_values_out[i] : 64'd0);
	     assign inst1_opa_select_out    = (issue_first_states[i] ? opa_selects_out[i] : 2'd0);
		 assign inst1_opb_select_out    = (issue_first_states[i] ? opb_selects_out[i] : 2'd0);
		 assign inst1_alu_func_out      = (issue_first_states[i] ? alu_funcs_out[i] : 5'd0);
		 assign inst1_rd_mem_out        = (issue_first_states[i] ? rd_mems_out[i] : 1'd0);
		 assign inst1_wr_mem_out        = (issue_first_states[i] ? wr_mems_out[i] : 1'd0);
		 assign inst1_cond_branch_out   = (issue_first_states[i] ? cond_branches_out[i] : 1'd0);
		 assign inst1_uncond_branch_out = (issue_first_states[i] ? uncond_branches_out[i] : 1'd0);
		 assign inst1_valid_out         = (issue_first_states[i]);
		 assign inst1_dest_reg_out      = (issue_first_states[i] ? dest_regs_out[i] : 5'd0);
		 assign inst1_dest_tag_out      = (issue_first_states[i] ? dest_tags_out[i] : 8'd0);
		
		 assign inst2_rega_value_out    = (issue_second_states[i] ? rega_values_out[i] : 64'd0);
		 assign inst2_regb_value_out    = (issue_second_states[i] ? regb_values_out[i] : 64'd0);
	     assign inst2_opa_select_out    = (issue_second_states[i] ? opa_selects_out[i] : 2'd0);
		 assign inst2_opb_select_out    = (issue_second_states[i] ? opb_selects_out[i] : 2'd0);
		 assign inst2_alu_func_out      = (issue_second_states[i] ? alu_funcs_out[i] : 5'd0);
		 assign inst2_rd_mem_out        = (issue_second_states[i] ? rd_mems_out[i] : 1'd0);
		 assign inst2_wr_mem_out        = (issue_second_states[i] ? wr_mems_out[i] : 1'd0);
		 assign inst2_cond_branch_out   = (issue_second_states[i] ? cond_branches_out[i] : 1'd0);
		 assign inst2_uncond_branch_out = (issue_second_states[i] ? uncond_branches_out[i] : 1'd0);
		 assign inst2_valid_out         = (issue_second_states[i]);
		 assign inst2_dest_reg_out      = (issue_second_states[i] ? dest_regs_out[i] : 5'd0);
		 assign inst2_dest_tag_out      = (issue_second_states[i] ? dest_tags_out[i] : 8'd0);		
		 
	  end
   endgenerate   

   
   // combinational logic to assign rs entry inputs //
   // **************** TODO!!! ******************** //
   generate
      for (genvar i=0; i<`NUM_RSES; i=i+1)
	  begin : ASSIGNRSINPUTS
   	     assign resets[i] = (reset || issue_first_states[i] || issue_second_states[i]);
		 assign fills[i]  = ();
         assign dest_regs_in[i] = inst1_dest_reg_in;
   wire [7:0]             dest_tags_in     [(`NUM_RSES-1):0];
   wire [63:0]            rega_values_in   [(`NUM_RSES-1):0];
   wire [63:0]            regb_values_in   [(`NUM_RSES-1):0];
   wire [7:0]             waiting_tagas_in [(`NUM_RSES-1):0];
   wire [7:0]             waiting_tagbs_in [(`NUM_RSES-1):0];         

   wire [1:0]             opa_selects_in   [(`NUM_RSES-1):0];
   wire [1:0]             opb_selects_in   [(`NUM_RSES-1):0];
   wire [4:0]             alu_funcs_in     [(`NUM_RSES-1):0];
   wire [(`NUM_RSES-1):0] rd_mems_in;
   wire [(`NUM_RSES-1):0] wr_mems_in;
   wire [(`NUM_RSES-1):0] cond_branches_in;
   wire [(`NUM_RSES-1):0] uncond_branches_in;
	  end
   endgenerate
   

   // combinational logic for assigning issue_first_states, //
   // issue_second_states, ready_states, and comp_table     // 
   generate
      for (genvar i=0; i<`NUM_RSES; i=i+1)
      begin : ASSIGNSTATESOUTERLOOP

         assign ready_states[i]        = (statuses[i]==`RS_READY);
         assign issue_first_states[i]  = ready_states[i];
         assign issue_second_states[i] = ready_states[i];
         assign issue_second_states[i] = ~issue_first_states[i];

         for (genvar j=0; j<`NUM_RSES; j=j+1)
         begin : ASSIGNSTATESINNERLOOP
            assign issue_first_states[i]  = (~ready_states[j] || comp_table[j][i]);   // exclusion cases for rs entry j
            assign issue_second_states[i] = (~ready_states[j] || comp_table[j][i] || issue_first_states[j]);   // exclusion cases for rs entry j
            assign comp_table[i][j]       = (ages[i]<ages[j]);   // is rs entry i newer than rs entry j?  
         end
   
      end
   endgenerate


   // internal modules (reservation station entries) //
   generate 
      for (genvar i=0; i<`NUM_RSES; i=i+1)
      begin : RSEMODULELOOP
	  
         reservation_station_entry entries(.clock(clock), .reset(resets[i]), .fill(fills[i])

                           // input busses //
                           .dest_reg_in(dest_regs_in[i]),
						   .dest_tag_in(dest_tags_in[i]),
                           .rega_value_in(rega_values_in[i]),
                           .regb_value_in(regb_values_in[i]),
                           .waiting_taga_in(waiting_tagas_in[i]),
                           .waiting_tagb_in(waiting_tagbs_in[i]),                

                           // generic signals to just be passed on //
                           .opa_select_in(opa_selects_in[i]),
                           .opb_select_in(opb_selects_in[i]),
                           .alu_func_in(alu_funcs_in[i]),
                           .rd_mem_in(rd_mems_in[i]),
                           .wr_mem_in(wr_mems_in[i]),
                           .cond_branch_in(cond_branches_in[i]),
                           .uncond_branch_in(uncond_branches_in[i]),

                           // cdbs in //
                           .cdb1_tag_in(cdb1_tag_in), .cdb1_value_in(cdb1_value_in),                
                           .cdb2_tag_in(cdb2_tag_in), .cdb2_value_in(cdb2_value_in),

                           // outputs //
                           .status_out(statuses_out[i]),                                           // signals out
                           .dest_reg_out(dest_regs_out[i]),
						   .dest_tag_out(dest_tags_out[i]),
                           .rega_value_out(rega_values_out[i]),
                           .regb_value_out(regb_values_out[i]),

                           // outputs for signals to simply be passed through
                           .opa_select_out(opa_selects_out[i]),
                           .opb_select_out(opb_selects_out[i]),
                           .alu_func_out(alu_funcs_out[i]),
                           .rd_mem_out(rd_mems_out[i]),
                           .wr_mem_out(wr_mems_out[i]),
                           .cond_branch_out(cond_branches_out[i]),
                           .uncond_branch_out(uncond_branches_out[i])
						   
						   );
      end

   endgenerate


   // clock synchronous assignment for the few bits of state in the module //
   genvar i;
   generate
      for (genvar i=0; i<`NUM_RSES; i=i+1)
	  begin
	    always@(posedge clock)
   	    begin
		  if (reset)
			 ages[i]    <= `SD 8'd0;
 		  else
	 		 ages[i]    <= `SD n_ages[i];
	    end
      end
   endgenerate

endmodule


