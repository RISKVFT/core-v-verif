//
// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technologies
// Copyright 2020 Silicon Labs, Inc.
// 
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     https://solderpad.org/licenses/
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 


`ifndef __UVMT_CV32_TB_SV__
`define __UVMT_CV32_TB_SV__


/**
 * Module encapsulating the CV32 DUT wrapper, and associated SV interfaces.
 * Also provide UVM environment entry and exit points.
 */
`default_nettype none
module uvmt_cv32_tb;

   import uvm_pkg::*;
   import uvmt_cv32_pkg::*;
   import uvme_cv32_pkg::*;


   // Capture regs for test status from Virtual Peripheral in dut_wrap.mem_i
   bit        tp;
   bit        tf;
   bit        evalid;
   bit [31:0] evalue;

   // Agent interfaces
   uvma_clknrst_if              clknrst_if(); // clock and resets from the clknrst agent
   uvma_clknrst_if              clknrst_if_iss();
   uvma_debug_if                debug_if();
   uvma_interrupt_if            interrupt_if(); // Interrupts

   // DUT Wrapper Interfaces
   uvmt_cv32_vp_status_if       vp_status_if();       // Status information generated by the Virtual Peripherals in the DUT WRAPPER memory.
   uvmt_cv32_core_cntrl_if      core_cntrl_if();      // Static and quasi-static core control inputs.
   uvmt_cv32_core_status_if     core_status_if();     // Core status outputs.   

   // Step and compare interface
   uvmt_cv32_step_compare_if step_compare_if();
   uvmt_cv32_isa_covg_if     isa_covg_if();

   // Debug assertion and coverage interface
   uvmt_cv32_debug_cov_assert_if debug_cov_assert_if();
   
  /**
   * DUT WRAPPER instance:
   * This is an update of the riscv_wrapper.sv from PULP-Platform RI5CY project with
   * a few mods to bring unused ports from the CORE to this level using SV interfaces.
   */
   uvmt_cv32_dut_wrap  #(
`ifdef NO_PULP
                         .PULP_XPULP        (0),
                         .PULP_CLUSTER      (0),
                         .PULP_ZFINX        (0),
`endif
                         .INSTR_ADDR_WIDTH  (32),
                         .INSTR_RDATA_WIDTH (32),
                         .RAM_ADDR_WIDTH    (22)
                        )
                        dut_wrap (.*);

  // Bind in OBI interfaces (montioring only supported currently)
  bind cv32e40p_wrapper
    uvma_obi_if obi_instr_if_i(.clk(clk_i),
                               .reset_n(rst_ni),
                               .req(instr_req_o),
                               .gnt(instr_gnt_i),
                               .addr(instr_addr_o),
                               .be('0),
                               .we('0),
                               .wdata('0),
                               .rdata(instr_rdata_i),
                               .rvalid(instr_rvalid_i),
                               .rready(1'b1)
                               );

  bind cv32e40p_wrapper
    uvma_obi_if obi_data_if_i(.clk(clk_i),
                              .reset_n(rst_ni),
                              .req(data_req_o),
                              .gnt(data_gnt_i),
                              .addr(data_addr_o),
                              .be(data_be_o),
                              .we(data_we_o),
                              .wdata(data_wdata_o),
                              .rdata(data_rdata_i),
                              .rvalid(data_rvalid_i),
                              .rready(1'b1)
                              );

  // Bind in verification modules to the design
  bind cv32e40p_core 
    uvmt_cv32e40p_interrupt_assert interrupt_assert_i(.mcause_n(cs_registers_i.mcause_n),
                                                      .mip(cs_registers_i.mip),
                                                      .mie_q(cs_registers_i.mie_q),
                                                      .mie_n(cs_registers_i.mie_n),
                                                      .mstatus_mie(cs_registers_i.mstatus_q.mie),
                                                      .mtvec_mode_q(cs_registers_i.mtvec_mode_q),
                                                      .if_stage_instr_rvalid_i(if_stage_i.instr_rvalid_i),
                                                      .if_stage_instr_rdata_i(if_stage_i.instr_rdata_i),
                                                      .id_stage_instr_valid_i(id_stage_i.instr_valid_i),
                                                      .id_stage_instr_rdata_i(id_stage_i.instr_rdata_i),
                                                      .branch_taken_ex(id_stage_i.branch_taken_ex),
                                                      .ctrl_fsm_cs(id_stage_i.controller_i.ctrl_fsm_cs),
                                                      .debug_mode_q(id_stage_i.controller_i.debug_mode_q),                                                      
                                                      .*);
    
    // Hook up interface to debug assertions and coverage                                          
    assign debug_cov_assert_if.clk_i = clknrst_if.clk;
    assign debug_cov_assert_if.rst_ni = clknrst_if.reset_n;
    assign debug_cov_assert_if.fetch_enable_i = dut_wrap.cv32e40p_wrapper_i.core_i.fetch_enable_i;
    assign debug_cov_assert_if.if_stage_instr_rvalid_i = dut_wrap.cv32e40p_wrapper_i.core_i.if_stage_i.instr_rvalid_i;
    assign debug_cov_assert_if.if_stage_instr_rdata_i = dut_wrap.cv32e40p_wrapper_i.core_i.if_stage_i.instr_rdata_i;
    assign debug_cov_assert_if.id_stage_instr_valid_i = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.instr_valid_i;
    assign debug_cov_assert_if.id_stage_instr_rdata_i = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.instr_rdata_i;
    assign debug_cov_assert_if.id_stage_is_compressed = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.is_compressed_i;
    assign debug_cov_assert_if.id_valid = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.id_valid_i;
    assign debug_cov_assert_if.is_decoding = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.is_decoding_o;
    assign debug_cov_assert_if.id_stage_pc = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.pc_id_i;
    assign debug_cov_assert_if.if_stage_pc = dut_wrap.cv32e40p_wrapper_i.core_i.if_stage_i.pc_if_o;
    assign debug_cov_assert_if.mie_q = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mstatus_q.mie;
    assign debug_cov_assert_if.ctrl_fsm_cs = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.ctrl_fsm_cs;
    assign debug_cov_assert_if.illegal_insn_i = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.illegal_insn_i;
    assign debug_cov_assert_if.illegal_insn_q = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.illegal_insn_q;
    assign debug_cov_assert_if.ecall_insn_i = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.ecall_insn_i;
    assign debug_cov_assert_if.debug_req_i = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.debug_req_i;
    assign debug_cov_assert_if.debug_mode_q = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.debug_mode_q;
    assign debug_cov_assert_if.dcsr_q = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.dcsr_q;
    assign debug_cov_assert_if.depc_q = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.depc_q;
    assign debug_cov_assert_if.depc_n = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.depc_n;
    assign debug_cov_assert_if.mcause_q = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mcause_q;
    assign debug_cov_assert_if.mtvec = {dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mtvec_q, 8'h00};
    assign debug_cov_assert_if.mepc_q = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mepc_q;
    assign debug_cov_assert_if.tdata1 = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.tmatch_control_rdata;
    assign debug_cov_assert_if.tdata2 = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.tmatch_value_rdata;
    assign debug_cov_assert_if.trigger_match_i = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.trigger_match_i;
    assign debug_cov_assert_if.mcountinhibit_q = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mcountinhibit_q;
    assign debug_cov_assert_if.mcycle = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mhpmcounter_q[0];
    assign debug_cov_assert_if.minstret = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mhpmcounter_q[2];
    assign debug_cov_assert_if.inst_ret = dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.inst_ret;
    assign debug_cov_assert_if.csr_access = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.csr_access;
    assign debug_cov_assert_if.csr_op = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.csr_op;
    assign debug_cov_assert_if.csr_addr = dut_wrap.cv32e40p_wrapper_i.core_i.csr_addr;
    assign debug_cov_assert_if.irq_ack_o = dut_wrap.cv32e40p_wrapper_i.core_i.irq_ack_o;
    assign debug_cov_assert_if.dm_halt_addr_i = dut_wrap.cv32e40p_wrapper_i.core_i.dm_halt_addr_i;
    assign debug_cov_assert_if.dm_exception_addr_i = dut_wrap.cv32e40p_wrapper_i.core_i.dm_exception_addr_i;
    assign debug_cov_assert_if.core_sleep_o = dut_wrap.cv32e40p_wrapper_i.core_i.core_sleep_o;
    assign debug_cov_assert_if.irq_i = dut_wrap.cv32e40p_wrapper_i.core_i.irq_i;

    // Instantiate debug assertions
    uvmt_cv32e40p_debug_assert u_debug_assert(.cov_assert_if(debug_cov_assert_if));

  /**
   * ISS WRAPPER instance:
   * TODO: finalize the parameters passed in.
   */
   `ifdef ISS
      uvmt_cv32_iss_wrap  #(
                            .ID (0)
                           )
                           iss_wrap ( .clk_period(clknrst_if.clk_period),
                                      .clknrst_if(clknrst_if_iss),
                                      .step_compare_if(step_compare_if),
                                      .isa_covg_if(isa_covg_if)
                             );
     /**
      * Step-and-Compare logic 
      */
      uvmt_cv32_step_compare step_compare (.clknrst_if(clknrst_if),
                                           .step_compare_if(step_compare_if) );

      always @(dut_wrap.cv32e40p_wrapper_i.tracer_i.retire) -> step_compare_if.riscv_retire;
      assign step_compare_if.insn_pc   = dut_wrap.cv32e40p_wrapper_i.tracer_i.insn_pc;
      assign step_compare_if.riscy_GPR = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.register_file_i.mem;
      assign clknrst_if_iss.reset_n = clknrst_if.reset_n;
    
      wire [31:0] irq_enabled;
      reg [31:0] irq_deferint;
      reg [31:0] irq_mip;
      reg core_sleep_o_d;

      always @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
        if (!clknrst_if.reset_n)
          core_sleep_o_d <= 1'b0;
        else
          core_sleep_o_d <= dut_wrap.cv32e40p_wrapper_i.core_sleep_o;
      end

      wire id_start = dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.id_valid_o &
                      dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.is_decoding_o;

      assign irq_enabled = dut_wrap.cv32e40p_wrapper_i.irq_i & dut_wrap.cv32e40p_wrapper_i.core_i.cs_registers_i.mie_n;

      /**
       * step_compare_if.deferint_prime is set to 0 (asserted) when the controller in ID commits to an interrupt
         derefint_prime is then reset to 1 when the ID stage commits to the next instruction (which should be the MTVEC entry address)
      */
      always @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
        if (!clknrst_if_iss.reset_n)
          step_compare_if.deferint_prime <= 1'b1;
        else if (dut_wrap.irq_ack)
          step_compare_if.deferint_prime <= 1'b0;
        else if (core_sleep_o_d && irq_enabled) 
          step_compare_if.deferint_prime <= 1'b0;
        else if (id_start && !step_compare_if.deferint_prime) 
          step_compare_if.deferint_prime <= 1'b1;
      end

      /**
       * When the ID stage commits, we set deferint to the ISS to signal to look at the interrrupts
       */
      always @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
        if (!clknrst_if_iss.reset_n)
          iss_wrap.b1.deferint <= 1'b1;
        else if (id_start && !step_compare_if.deferint_prime) 
          iss_wrap.b1.deferint <= 1'b0;
      end

      /**
       * deferint deassertion logic, on negedge of ovp_b1_Step from the ISS the deferint has been consumed 
       */
      always @(negedge step_compare_if.ovp_b1_Step) begin
        if (iss_wrap.b1.deferint == 0) begin
          iss_wrap.b1.deferint <= 1'b1;
          irq_deferint <= '0;
        end
      end

      /**
        * irq_deferint will capture the asserted interrupt to present to the ISS later
        * since the autoclear/ack interface can clear the IRQ long before the ISS sees it
        */
      always @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
        if (!clknrst_if.reset_n)
          irq_deferint <= '0;
        else if (dut_wrap.irq_ack)        
          irq_deferint <= (1 << dut_wrap.irq_id);
        else if (core_sleep_o_d && irq_enabled)
          irq_deferint <= irq_enabled;
      end
      
      always @*
        //iss_wrap.b1.irq_i = !iss_wrap.b1.deferint ? irq_deferint : irq_mip;
        iss_wrap.b1.irq_i = !iss_wrap.b1.deferint ? irq_deferint : dut_wrap.irq;

      /**
       * Interrupt assertion to iss_wrap, note this runs on the ISS clock (skewed from core clock)
       */
      always @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
        if (!clknrst_if.reset_n) begin
          irq_mip <= '0;
        end
        else begin
          for (int irq_idx=0; irq_idx<32; irq_idx++) begin
                        
            // Leave ISS side asserted as long as RTL interrupt line is asserted
            if (dut_wrap.cv32e40p_wrapper_i.irq_i[irq_idx]) 
              irq_mip[irq_idx] <= 1'b1;          
            // If deferint is low and ovp_b1_Step is asserted, then interrupt was consumed by model
            // Clear it now to avoid mip miscompare
            else if (step_compare_if.ovp_b1_Step && iss_wrap.b1.deferint == 0)
              irq_mip[irq_idx] <= 1'b0;
            // If RTL interrupt deasserts, but the core has not taken the interrupt, then clear ISS irq
            else if (iss_wrap.b1.deferint == 1)
              irq_mip[irq_idx] <= 1'b0;            
          end
        end
      end

      // Count number of issued and retired instructions
      // This makes synchronizing haltreq to RM easier
      logic [31:0] count_issue;
      logic [31:0] count_retire;
      always @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
        if (!clknrst_if.reset_n) begin
            count_issue <= 32'h0;
        end else begin
            if (dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.id_valid_o & dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.is_decoding_o &&
               !dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.illegal_insn_i) begin
                count_issue <= count_issue + 1;
            end
        end
      end

      always @(dut_wrap.cv32e40p_wrapper_i.tracer_i.retire or negedge clknrst_if.reset_n) begin
          if (!clknrst_if.reset_n) begin
              count_retire <= 32'h0;
          end else begin
              count_retire <= count_retire + 1;
          end
      end

      // A simple FSM for controlling haltreq into RM
      typedef enum logic [1:0] {INACTIVE, DBG_TAKEN, DRIVE_REQ} dbg_state_e;
      dbg_state_e debug_req_state;

      always @(posedge clknrst_if_iss.clk or negedge clknrst_if_iss.reset_n) begin
        if (!clknrst_if_iss.reset_n) begin
            iss_wrap.b1.haltreq <= 1'b0;
            debug_req_state <= INACTIVE;
        end else begin
            unique case(debug_req_state)
                INACTIVE: begin
                    iss_wrap.b1.haltreq <= 1'b0;

                    // Only drive haltreq if we have an external request
                    if (dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.ctrl_fsm_cs inside {cv32e40p_pkg::DBG_TAKEN_ID, cv32e40p_pkg::DBG_TAKEN_IF} &&
                        dut_wrap.cv32e40p_wrapper_i.core_i.id_stage_i.controller_i.debug_req_pending) begin

                        debug_req_state <= DBG_TAKEN;
                        // Already in sync, assert halreq right away
                        if (count_retire == count_issue) begin
                            iss_wrap.b1.haltreq <= 1'b1;
                        end
                    end
                end
                DBG_TAKEN: begin
                    // Assert haltreq when we are in sync
                    if (count_retire == count_issue) begin
                        iss_wrap.b1.haltreq <= 1'b1;
                        debug_req_state <= DRIVE_REQ;
                    end
                end
                DRIVE_REQ: begin
                    // Deassert haltreq when DM is observed
                    if(iss_wrap.b1.DM == 1'b1) begin
                        debug_req_state <= INACTIVE;
                    end
                end
                default: begin
                    debug_req_state <= INACTIVE;
                end
            endcase
        end
      end
    `endif

   /**
    * Test bench entry point.
    */
   initial begin : test_bench_entry_point

     // Specify time format for simulation (units_number, precision_number, suffix_string, minimum_field_width)
     $timeformat(-9, 3, " ns", 8);
      
     // Add interfaces handles to uvm_config_db
     uvm_config_db#(virtual uvma_debug_if               )::set(.cntxt(null), .inst_name("*.env.debug_agent"), .field_name("vif"), .value(debug_if));
     uvm_config_db#(virtual uvma_clknrst_if             )::set(.cntxt(null), .inst_name("*.env.clknrst_agent"), .field_name("vif"),        .value(clknrst_if));
     uvm_config_db#(virtual uvma_interrupt_if           )::set(.cntxt(null), .inst_name("*.env.interrupt_agent"), .field_name("vif"),      .value(interrupt_if));
     uvm_config_db#(virtual uvma_obi_if                 )::set(.cntxt(null), .inst_name("*.env.obi_instr_agent"), .field_name("vif"),      .value(dut_wrap.cv32e40p_wrapper_i.obi_instr_if_i));
     uvm_config_db#(virtual uvma_obi_if                 )::set(.cntxt(null), .inst_name("*.env.obi_data_agent"),  .field_name("vif"),      .value(dut_wrap.cv32e40p_wrapper_i.obi_data_if_i));
     uvm_config_db#(virtual uvmt_cv32_vp_status_if      )::set(.cntxt(null), .inst_name("*"), .field_name("vp_status_vif"),       .value(vp_status_if)      );
     uvm_config_db#(virtual uvmt_cv32_core_cntrl_if     )::set(.cntxt(null), .inst_name("*"), .field_name("core_cntrl_vif"),      .value(core_cntrl_if)     );
     uvm_config_db#(virtual uvmt_cv32_core_status_if    )::set(.cntxt(null), .inst_name("*"), .field_name("core_status_vif"),     .value(core_status_if)    );     
     uvm_config_db#(virtual uvmt_cv32_step_compare_if   )::set(.cntxt(null), .inst_name("*"), .field_name("step_compare_vif"),    .value(step_compare_if));
     uvm_config_db#(virtual uvmt_cv32_isa_covg_if       )::set(.cntxt(null), .inst_name("*"), .field_name("isa_covg_vif"),        .value(isa_covg_if));
     uvm_config_db#(virtual uvmt_cv32_debug_cov_assert_if)::set(.cntxt(null), .inst_name("*.env.debug_agent"), .field_name("vif_cov"),.value(debug_cov_assert_if));
      
     // Make the DUT Wrapper Virtual Peripheral's status outputs available to the base_test
     uvm_config_db#(bit      )::set(.cntxt(null), .inst_name("*"), .field_name("tp"),     .value(1'b0)        );
     uvm_config_db#(bit      )::set(.cntxt(null), .inst_name("*"), .field_name("tf"),     .value(1'b0)        );
     uvm_config_db#(bit      )::set(.cntxt(null), .inst_name("*"), .field_name("evalid"), .value(1'b0)        );
     uvm_config_db#(bit[31:0])::set(.cntxt(null), .inst_name("*"), .field_name("evalue"), .value(32'h00000000));
      
     // Run test
     uvm_top.enable_print_topology = 0; // ENV coders enable this as a debug aid
     uvm_top.finish_on_completion  = 1;
     uvm_top.run_test();
   end : test_bench_entry_point

   
   // Capture the test status and exit pulse flags
   // TODO: put this logic in the vp_status_if (makes it easier to pass to ENV)
   always @(posedge clknrst_if.clk) begin
     if (!clknrst_if.reset_n) begin
       tp     <= 1'b0;
       tf     <= 1'b0;
       evalid <= 1'b0;
       evalue <= 32'h00000000;
     end
     else begin
       if (vp_status_if.tests_passed) begin
         tp <= 1'b1;
         uvm_config_db#(bit)::set(.cntxt(null), .inst_name("*"), .field_name("tp"), .value(1'b1));
       end
       if (vp_status_if.tests_failed) begin
         tf <= 1'b1;
         uvm_config_db#(bit)::set(.cntxt(null), .inst_name("*"), .field_name("tf"), .value(1'b1));
       end
       if (vp_status_if.exit_valid) begin
         evalid <= 1'b1;
         uvm_config_db#(bit)::set(.cntxt(null), .inst_name("*"), .field_name("evalid"), .value(1'b1));
       end
       if (vp_status_if.exit_valid) begin
         evalue <= vp_status_if.exit_value;
         uvm_config_db#(bit[31:0])::set(.cntxt(null), .inst_name("*"), .field_name("evalue"), .value(vp_status_if.exit_value));
       end
     end
   end

   
   /**
    * End-of-test summary printout.
    */
   final begin: end_of_test
      string             summary_string;
      uvm_report_server  rs;
      int                err_count;
      int                warning_count;
      int                fatal_count;
      static bit         sim_finished = 0;
      
      static string  red   = "\033[31m\033[1m";
      static string  green = "\033[32m\033[1m";
      static string  reset = "\033[0m";
      
      rs            = uvm_top.get_report_server();
      err_count     = rs.get_severity_count(UVM_ERROR);
      warning_count = rs.get_severity_count(UVM_WARNING);
      fatal_count   = rs.get_severity_count(UVM_FATAL);
      
      void'(uvm_config_db#(bit)::get(null, "", "sim_finished", sim_finished));

      $display("\n%m: *** Test Summary ***\n");
      
      if (sim_finished && (err_count == 0) && (fatal_count == 0)) begin
         $display("    PPPPPPP    AAAAAA    SSSSSS    SSSSSS   EEEEEEEE  DDDDDDD     ");
         $display("    PP    PP  AA    AA  SS    SS  SS    SS  EE        DD    DD    ");
         $display("    PP    PP  AA    AA  SS        SS        EE        DD    DD    ");
         $display("    PPPPPPP   AAAAAAAA   SSSSSS    SSSSSS   EEEEE     DD    DD    ");
         $display("    PP        AA    AA        SS        SS  EE        DD    DD    ");
         $display("    PP        AA    AA  SS    SS  SS    SS  EE        DD    DD    ");
         $display("    PP        AA    AA   SSSSSS    SSSSSS   EEEEEEEE  DDDDDDD     ");
         $display("    ----------------------------------------------------------");
         if (warning_count == 0) begin
           $display("                        SIMULATION PASSED                     ");
         end
         else begin
           $display("                 SIMULATION PASSED with WARNINGS              ");
         end
         $display("    ----------------------------------------------------------");
      end
      else begin
         $display("    FFFFFFFF   AAAAAA   IIIIII  LL        EEEEEEEE  DDDDDDD       ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FFFFF     AAAAAAAA    II    LL        EEEEE     DD    DD      ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FF        AA    AA    II    LL        EE        DD    DD      ");
         $display("    FF        AA    AA  IIIIII  LLLLLLLL  EEEEEEEE  DDDDDDD       ");
         
         if (sim_finished == 0) begin
            $display("    --------------------------------------------------------");
            $display("                   SIMULATION FAILED - ABORTED              ");
            $display("    --------------------------------------------------------");
         end
         else begin
            $display("    --------------------------------------------------------");
            $display("                       SIMULATION FAILED                    ");
            $display("    --------------------------------------------------------");
         end
      end
   end
   
endmodule : uvmt_cv32_tb
`default_nettype wire

`endif // __UVMT_CV32_TB_SV__
