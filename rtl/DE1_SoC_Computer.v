

module DE1_SoC_Computer
(
        // Clock pin.
    input          CLOCK_50;

    // HPS Pins	
    // DDR3 SDRAM
    output [14: 0] HPS_DDR3_ADDR;
    output [ 2: 0] HPS_DDR3_BA;
    output         HPS_DDR3_CAS_N;
    output         HPS_DDR3_CKE;
    output         HPS_DDR3_CK_N;
    output         HPS_DDR3_CK_P;
    output         HPS_DDR3_CS_N;
    output [ 3: 0] HPS_DDR3_DM;
    inout  [31: 0] HPS_DDR3_DQ;
    inout  [ 3: 0] HPS_DDR3_DQS_N;
    inout  [ 3: 0] HPS_DDR3_DQS_P;
    output         HPS_DDR3_ODT;
    output         HPS_DDR3_RAS_N;
    output         HPS_DDR3_RESET_N;
    input          HPS_DDR3_RZQ;
    output         HPS_DDR3_WE_N;
);
    //-------------------------------------
    //  Internal nets.
    //-------------------------------------

    wire [31:0] lw_pio_write_0;
    wire [31:0] lw_pio_write_1;
    wire [31:0] lw_pio_read;
    wire [31:0] lw_pio_read_cycle;
    wire [31:0] lw_pio_read_cycle2;

    wire s_o_ready;
    wire s_o_valid;
    wire [1:0] s_o_conv;

    conv_top CT (
        .i_clk              ( CLOCK_50             ),
        .i_arstn            ( ~lw_pio_write_1[27]  ),
    	 .i_arstn_perf       ( ~lw_pio_write_1[28 ] ),
    	 .i_enable_count2    ( lw_pio_write_1[29]   ),
        .i_ready            ( lw_pio_write_1[26]   ),
        .i_valid            ( lw_pio_write_1[25]   ),
        .i_bit_X            ( lw_pio_write_0[24:0] ),
        .i_bit_K            ( lw_pio_write_1[24:0] ),
        .o_conv             ( s_o_conv             ),
        .o_ready            ( s_o_ready            ),
        .o_valid            ( s_o_valid            ),
    	 .o_perf_cycle_count ( lw_pio_read_cycle    ),
    	 .o_perf_cycle_count2( lw_pio_read_cycle2   )
    );

    assign lw_pio_read = {28'b0, s_o_ready, s_o_valid, s_o_conv};



    ARM_HPS The_System (
    	// Global signals
    	.system_pll_ref_clk_clk                        (CLOCK_50  ),
    	.system_pll_ref_reset_reset                    (1'b0      ),
    
    	// PIO ports
    	.lw_pio_read_external_connection_export        ( lw_pio_read        ),
    	.lw_pio_read_perf_0_external_connection_export ( lw_pio_read_cycle  ),
    	.lw_pio_read_perf_1_external_connection_export ( lw_pio_read_cycle2 ),
    	.lw_pio_write_0_external_connection_export     ( lw_pio_write_0     ),
    	.lw_pio_write_1_external_connection_export     ( lw_pio_write_1     ),
    
        // DDR3 SDRAM
    	.memory_mem_a                                  ( HPS_DDR3_ADDR      ),
    	.memory_mem_ba                                 ( HPS_DDR3_BA        ),
    	.memory_mem_ck                                 ( HPS_DDR3_CK_P      ),
    	.memory_mem_ck_n                               ( HPS_DDR3_CK_N      ),
    	.memory_mem_cke                                ( HPS_DDR3_CKE       ),
    	.memory_mem_cs_n                               ( HPS_DDR3_CS_N      ),
    	.memory_mem_ras_n                              ( HPS_DDR3_RAS_N     ),
    	.memory_mem_cas_n                              ( HPS_DDR3_CAS_N     ),
    	.memory_mem_we_n                               ( HPS_DDR3_WE_N      ),
    	.memory_mem_reset_n                            ( HPS_DDR3_RESET_N   ),
    	.memory_mem_dq                                 ( HPS_DDR3_DQ        ),
    	.memory_mem_dqs                                ( HPS_DDR3_DQS_P     ),
    	.memory_mem_dqs_n                              ( HPS_DDR3_DQS_N     ),
    	.memory_mem_odt                                ( HPS_DDR3_ODT       ),
    	.memory_mem_dm                                 ( HPS_DDR3_DM        ),
    	.memory_oct_rzqin                              ( HPS_DDR3_RZQ       )
    );
endmodule
