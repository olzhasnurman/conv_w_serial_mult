/* Copyright (c) 2025 Nazarbayev University. All rights reserved. */

// ---------------------------------------------------------------------------------------------
// This is a top conv module that the serial multipier module.
// ---------------------------------------------------------------------------------------------

module conv_top
#(
    parameter DATA_WIDTH  = 8,
    parameter KERNEL_SIZE = 25
)
(
    // Input interface.
    input  logic                     i_clk,
    input  logic                     i_arstn,
	input  logic                     i_arstn_perf,
	input  logic                     i_enable_count2,
    input  logic                     i_ready,
    input  logic                     i_valid,
    input  logic [KERNEL_SIZE - 1:0] i_bit_X,
    input  logic [KERNEL_SIZE - 1:0] i_bit_K,

    output logic [              1:0] o_conv,
    output logic                     o_ready,
    output logic                     o_valid,
	output logic [             31:0] o_perf_cycle_count,
	output logic [             31:0] o_perf_cycle_count2
);

    //--------------------------------
    // Internal nets.
    //--------------------------------
    logic [3:0] s_count;

    logic s_valid_data_in;
    logic s_valid_data_out;
	 
	logic [KERNEL_SIZE - 1:0] s_bit_X_delayed;
	logic [KERNEL_SIZE - 1:0] s_bit_K_delayed;

    logic [1:0] s_product [KERNEL_SIZE - 1:0];

    localparam N_OF_2FA = KERNEL_SIZE - 1;

    logic [N_OF_2FA - 1:0] s_carry_in;
    logic [N_OF_2FA - 1:0] s_carry_out;
	 
    //-----------------------------------
    // Delayed inputs.
    //-----------------------------------
    always_ff @(posedge i_clk, negedge i_arstn) begin
        if (~ i_arstn) begin
            s_bit_X_delayed <= '0;
            s_bit_K_delayed <= '0;
        end
        else if (s_valid_data_in) begin
            s_bit_X_delayed <= i_bit_X;
            s_bit_K_delayed <= i_bit_K;
        end
    end


    //-----------------------------------
    // Lower-level module instantiations.
    //-----------------------------------
    
    // Serial multiplier module instances.
    genvar i;
    generate
        for (i = 0; i < KERNEL_SIZE; i++) begin : serial_multipier
            serial_mul #(
                .DATA_WIDTH ( DATA_WIDTH )
            ) S_MUL0 (
                .i_clk     ( i_clk              ),
                .i_arstn   ( i_arstn            ),
                .i_valid   ( s_valid_data_in    ),
                .i_a       ( s_bit_X_delayed[i] ),
                .i_b       ( s_bit_K_delayed[i] ),
                .o_product ( s_product[i]       )
            );
        end
    endgenerate
	 

    // Counter module.
    counter COUNT0 (
        .i_clk   ( i_clk           ),
        .i_arstn ( i_arstn         ),
        .i_valid ( s_valid_data_in ),
        .o_count ( s_count         )
    );
	 
	assign s_valid_data_out = (s_count >= 4'd5) & (s_count <= 4'd12);
	
	// Performance cycle counter.
	always_ff @(posedge i_clk, negedge i_arstn_perf) begin
	    if (~ i_arstn_perf)
		    o_perf_cycle_count <= 32'b0;
		else if (s_valid_data_in)
		    o_perf_cycle_count <= o_perf_cycle_count + 32'b1;
	end
	 
	// Performance cycle counter2.
	always_ff @(posedge i_clk, negedge i_arstn_perf) begin
	     if (~ i_arstn_perf)
		    o_perf_cycle_count2 <= 32'b0;
		else if (i_enable_count2)
		    o_perf_cycle_count2 <= o_perf_cycle_count2 + 32'b1;
	end



    //-----------------------------------
    // 2-bit Full Adder tree.
    //-----------------------------------
    logic [1:0] s_sum_0;
    logic [1:0] s_sum_1;
    logic [1:0] s_sum_2;
    logic [1:0] s_sum_3;
    logic [1:0] s_sum_4;
    logic [1:0] s_sum_5;
    logic [1:0] s_sum_6;
    logic [1:0] s_sum_7;
    logic [1:0] s_sum_8;
    logic [1:0] s_sum_9;
    logic [1:0] s_sum_10;
    logic [1:0] s_sum_11;
    logic [1:0] s_sum_12;
    logic [1:0] s_sum_13;
    logic [1:0] s_sum_14;
    logic [1:0] s_sum_15;
    logic [1:0] s_sum_16;
    logic [1:0] s_sum_17;
    logic [1:0] s_sum_18;
    logic [1:0] s_sum_19;
    logic [1:0] s_sum_20;
    logic [1:0] s_sum_21;
    logic [1:0] s_sum_22;
    logic [1:0] s_sum_23;

    // -------- LEVEL 0: pair s_product[] --------
    full_adder FA0_0 (
        .i_input1 ( s_product[0]    ),
        .i_input2 ( s_product[1]    ),
        .i_cin    ( s_carry_in[0]   ),
        .o_sum    ( s_sum_0         ),
        .o_cout   ( s_carry_out[0]  )
    );
    
    full_adder FA0_1 (
        .i_input1 ( s_product[2]    ),
        .i_input2 ( s_product[3]    ),
        .i_cin    ( s_carry_in[1]   ),
        .o_sum    ( s_sum_1         ),
        .o_cout   ( s_carry_out[1]  )
    );
    
    full_adder FA0_2 (
        .i_input1 ( s_product[4]    ),
        .i_input2 ( s_product[5]    ),
        .i_cin    ( s_carry_in[2]   ),
        .o_sum    ( s_sum_2         ),
        .o_cout   ( s_carry_out[2]  )
    );
    
    full_adder FA0_3 (
        .i_input1 ( s_product[6]    ),
        .i_input2 ( s_product[7]    ),
        .i_cin    ( s_carry_in[3]   ),
        .o_sum    ( s_sum_3         ),
        .o_cout   ( s_carry_out[3]  )
    );
    
    full_adder FA0_4 (
        .i_input1 ( s_product[8]    ),
        .i_input2 ( s_product[9]    ),
        .i_cin    ( s_carry_in[4]   ),
        .o_sum    ( s_sum_4         ),
        .o_cout   ( s_carry_out[4]  )
    );
    
    full_adder FA0_5 (
        .i_input1 ( s_product[10]   ),
        .i_input2 ( s_product[11]   ),
        .i_cin    ( s_carry_in[5]   ),
        .o_sum    ( s_sum_5         ),
        .o_cout   ( s_carry_out[5]  )
    );
    
    full_adder FA0_6 (
        .i_input1 ( s_product[12]   ),
        .i_input2 ( s_product[13]   ),
        .i_cin    ( s_carry_in[6]   ),
        .o_sum    ( s_sum_6         ),
        .o_cout   ( s_carry_out[6]  )
    );
    
    full_adder FA0_7 (
        .i_input1 ( s_product[14]   ),
        .i_input2 ( s_product[15]   ),
        .i_cin    ( s_carry_in[7]   ),
        .o_sum    ( s_sum_7         ),
        .o_cout   ( s_carry_out[7]  )
    );
    
    full_adder FA0_8 (
        .i_input1 ( s_product[16]   ),
        .i_input2 ( s_product[17]   ),
        .i_cin    ( s_carry_in[8]   ),
        .o_sum    ( s_sum_8         ),
        .o_cout   ( s_carry_out[8]  )
    );
    
    full_adder FA0_9 (
        .i_input1 ( s_product[18]   ),
        .i_input2 ( s_product[19]   ),
        .i_cin    ( s_carry_in[9]   ),
        .o_sum    ( s_sum_9         ),
        .o_cout   ( s_carry_out[9]  )
    );
    
    full_adder FA0_10 (
        .i_input1 ( s_product[20]   ),
        .i_input2 ( s_product[21]   ),
        .i_cin    ( s_carry_in[10]  ),
        .o_sum    ( s_sum_10        ),
        .o_cout   ( s_carry_out[10] )
    );
    
    full_adder FA0_11 (
        .i_input1 ( s_product[22]   ),
        .i_input2 ( s_product[23]   ),
        .i_cin    ( s_carry_in[11]  ),
        .o_sum    ( s_sum_11        ),
        .o_cout   ( s_carry_out[11] )
    );
    
    // Unpaired last product input.
    logic [1:0] s_last;
    assign s_last = s_product[24]; // will be summed later.
    
    // -------- LEVEL 1 --------
    full_adder FA1_0 (
        .i_input1 ( s_sum_0         ),
        .i_input2 ( s_sum_1         ),
        .i_cin    ( s_carry_in[12]  ),
        .o_sum    ( s_sum_12        ),
        .o_cout   ( s_carry_out[12] )
    );
    
    full_adder FA1_1 (
        .i_input1 ( s_sum_2         ),
        .i_input2 ( s_sum_3         ),
        .i_cin    ( s_carry_in[13]  ),
        .o_sum    ( s_sum_13        ),
        .o_cout   ( s_carry_out[13] )
    );
    
    full_adder FA1_2 (
        .i_input1 ( s_sum_4         ),
        .i_input2 ( s_sum_5         ),
        .i_cin    ( s_carry_in[14]  ),
        .o_sum    ( s_sum_14        ),
        .o_cout   ( s_carry_out[14] )
    );
    
    full_adder FA1_3 (
        .i_input1 ( s_sum_6         ),
        .i_input2 ( s_sum_7         ),
        .i_cin    ( s_carry_in[15]  ),
        .o_sum    ( s_sum_15        ),
        .o_cout   ( s_carry_out[15] )
    );
    
    full_adder FA1_4 (
        .i_input1 ( s_sum_8         ),
        .i_input2 ( s_sum_9         ),
        .i_cin    ( s_carry_in[16]  ),
        .o_sum    ( s_sum_16        ),
        .o_cout   ( s_carry_out[16] )
    );
    
    full_adder FA1_5 (
        .i_input1 ( s_sum_10        ),
        .i_input2 ( s_sum_11        ),
        .i_cin    ( s_carry_in[17]  ),
        .o_sum    ( s_sum_17        ),
        .o_cout   ( s_carry_out[17] )
    );
    
    // -------- LEVEL 2 --------
    full_adder FA2_0 (
        .i_input1 ( s_sum_12        ),
        .i_input2 ( s_sum_13        ),
        .i_cin    ( s_carry_in[18]  ),
        .o_sum    ( s_sum_18        ),
        .o_cout   ( s_carry_out[18] )
    );
    
    full_adder FA2_1 (
        .i_input1 ( s_sum_14        ),
        .i_input2 ( s_sum_15        ),
        .i_cin    ( s_carry_in[19]  ),
        .o_sum    ( s_sum_19        ),
        .o_cout   ( s_carry_out[19] )
    );
    
    full_adder FA2_2 (
        .i_input1 ( s_sum_16        ),
        .i_input2 ( s_sum_17        ),
        .i_cin    ( s_carry_in[20]  ),
        .o_sum    ( s_sum_20        ),
        .o_cout   ( s_carry_out[20] )
    );
    
    // -------- LEVEL 3 --------
    full_adder FA3_0 (
        .i_input1 ( s_sum_18        ),
        .i_input2 ( s_sum_19        ),
        .i_cin    ( s_carry_in[21]  ),
        .o_sum    ( s_sum_21        ),
        .o_cout   ( s_carry_out[21] )
    );
    
    full_adder FA3_1 (
        .i_input1 ( s_sum_20        ),
        .i_input2 ( s_last          ), // s_product[24].
        .i_cin    ( s_carry_in[22]  ),
        .o_sum    ( s_sum_22        ),
        .o_cout   ( s_carry_out[22] )
    );
    
    // -------- LEVEL 4 (Final Adder) --------
    full_adder FA4_0 (
        .i_input1 ( s_sum_21        ),
        .i_input2 ( s_sum_22        ),
        .i_cin    ( s_carry_in[23]  ),
        .o_sum    ( s_sum_23        ), // final result.
        .o_cout   ( s_carry_out[23] )
    );

    assign o_conv = s_sum_23;
	 
	 
    // DFF.
    always_ff @( posedge i_clk, negedge i_arstn ) begin
        if ( ~ i_arstn ) 
            s_carry_in <= '0;
        else if (s_valid_data_in) 
            s_carry_in <= s_carry_out;
    end
	 
    //-----------------------------------
    // Main FSM.
    //-----------------------------------

    // FSM: State definitions.
    typedef enum logic [2:0] {
        IDLE      = 3'd0,
        READ      = 3'd1,
        WAIT_RES  = 3'd2,
        READ_DONE = 3'd3,
        WRITE     = 3'd4,
        WRITE_DONE = 3'd5
    } state_t;

    state_t PS;
    state_t NS;


    // FSM: NS synchronization.
    always_ff @(posedge i_clk, negedge i_arstn) begin
        if (~ i_arstn)
            PS <= IDLE;
        else
            PS <= NS;
    end


    // FSM: NS logic.
    always_comb begin
        // Default value.
        NS = PS;

        case (PS)
            IDLE: 
				if (i_valid) 
				    NS = READ;
            READ:   NS = WAIT_RES;
            WAIT_RES: 
				if (s_valid_data_out)
				    NS = WRITE;
                else
					NS = READ_DONE;
            READ_DONE: 
				if (~ i_valid)
				     NS = IDLE;
            WRITE:
				if (~ i_ready)
				    NS = WRITE_DONE;
            WRITE_DONE: 
				if (i_ready)
				    NS = IDLE;
            default: 
				    NS = PS;
        endcase
    end


    // FSM: Output logic.
    always_comb begin
        // Default values.
        s_valid_data_in = 1'b0;
        o_ready         = 1'b0;
        o_valid         = 1'b0;

        case (PS)
            IDLE : o_ready         = 1'b1;
            READ : s_valid_data_in = 1'b1; 
            WRITE: o_valid         = 1'b1;
            default: begin
                s_valid_data_in = 1'b0;
                o_ready         = 1'b0;
                o_valid         = 1'b0;
            end
        endcase
    end
endmodule
