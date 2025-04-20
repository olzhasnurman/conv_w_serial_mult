/* Copyright (c) 2025 Nazarbayev University. All rights reserved. */

// ----------------------------------------------
// This is a top level serial multiplier module.
// ----------------------------------------------

module serial_mul
#(
    parameter DATA_WIDTH = 8    
)
(
    // Input interface.
    input  logic       i_clk,
    input  logic       i_arstn,
    input  logic       i_valid,
    input  logic       i_a,
    input  logic       i_b,

    // Output interface.
    output logic [1:0] o_product
);
    //--------------------------------
    // Local parameters.
    //--------------------------------
    localparam N_OF_I2B = 1 + (DATA_WIDTH - 4)/2; // 3 for DATA_WIDTH = 8.
    localparam N_OF_2FA = N_OF_I2B;               // 3.
    

    //--------------------------------
    // Internal nets.
    //--------------------------------
    logic [1:0] s_i2b_sum [N_OF_I2B - 1:0];
    logic [1:0] s_t2b_sum;

    logic s_a [N_OF_I2B - 1:0];
    logic s_b [N_OF_I2B - 1:0];

    // Unused.
    logic unused_s_b_i2b_out;
    

    logic [N_OF_2FA - 1:0] s_carry_in;
    logic [N_OF_2FA - 1:0] s_carry_out;

    logic [1:0] s_adder_sum_0;
    logic [1:0] s_adder_sum_1;
    logic [1:0] s_adder_sum_2;


    //------------------------------------
    // Lower-level module instantiations.
    //------------------------------------
    
    // I2B module.
    i2b I2B0 (
        .i_clk   ( i_clk              ),
        .i_arstn ( i_arstn            ),
        .i_valid ( i_valid            ),
        .i_a     ( i_a                ),
        .i_b     ( s_b[0]             ),
        .o_sum   ( s_i2b_sum[0]       ),
        .o_a     ( s_a[0]             ),
        .o_b     ( unused_s_b_i2b_out )
    );

    // Intermediate I2B modules.
    genvar i;

    generate
        for (i = 0; i < N_OF_I2B - 1; i++) begin : i2b_multipier
            i2b I2B_MODULE (
                .i_clk   ( i_clk            ),
                .i_arstn ( i_arstn          ),
                .i_valid ( i_valid          ),
                .i_a     ( s_a[i]           ),
                .i_b     ( s_b[i + 1]       ),
                .o_sum   ( s_i2b_sum[i + 1] ),
                .o_a     ( s_a[i + 1]       ),
                .o_b     ( s_b[i]           )
            );
        end
    endgenerate

    // T2B module.
    t2b T2B0 (
        .i_clk   ( i_clk             ),
        .i_arstn ( i_arstn           ),
        .i_valid ( i_valid           ),
        .i_a     ( s_a[N_OF_I2B - 1] ),
        .i_b     ( i_b               ),
        .o_sum   ( s_t2b_sum         ),
        .o_b     ( s_b[N_OF_I2B - 1] )
    );

    //-----------------------------------
    // 2-bit Full adder tree.
    //-----------------------------------

    // -------- LEVEL 0 --------
    full_adder FA0_0 (
        .i_input1 ( s_i2b_sum[0]   ),
        .i_input2 ( s_i2b_sum[1]   ),
        .i_cin    ( s_carry_in[0]  ),
        .o_sum    ( s_adder_sum_0  ),
        .o_cout   ( s_carry_out[0] )
    );

    full_adder FA0_3 (
        .i_input1 ( s_i2b_sum[2]   ),
        .i_input2 ( s_t2b_sum      ),
        .i_cin    ( s_carry_in[1]  ),
        .o_sum    ( s_adder_sum_1  ),
        .o_cout   ( s_carry_out[1] )
    );

    // -------- LEVEL 1 --------
    full_adder FA1_0 (
        .i_input1 ( s_adder_sum_0  ),
        .i_input2 ( s_adder_sum_1  ),
        .i_cin    ( s_carry_in[2]  ),
        .o_sum    ( s_adder_sum_2  ),
        .o_cout   ( s_carry_out[2] )
    );

    // DFF.
    always_ff @( posedge i_clk, negedge i_arstn ) begin
        if ( ~ i_arstn ) 
            s_carry_in <= '0;
        else if (i_valid) 
            s_carry_in <= s_carry_out;
    end

    //--------------------------------
    // Output logic.
    //--------------------------------
    assign o_product = s_adder_sum_2;
    

endmodule