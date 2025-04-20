/* Copyright (c) 2025 Nazarbayev University. All rights reserved. */

// -------------------------------------------
// This is a Terminating 2-bit block (T2B).
// -------------------------------------------

module t2b
(
    // Input interface.
    input  logic        i_clk,
    input  logic        i_arstn,
    input  logic        i_valid,
    input  logic        i_a,
    input  logic        i_b,

    // Output interface.
    output logic [1:0] o_sum,
    output logic       o_b
);

    //--------------------------------
    // Internal nets.
    //--------------------------------
    logic s_a_ff1;
    logic s_b_ff1;

    logic s_A0;
    logic s_A1;
    logic s_B0;
    logic s_B1;

    logic s_carry_out;
    logic s_carry_in;

    //-----------------------------
    // Continious assignments.
    //-----------------------------
    assign s_A0 = s_a_ff1 & s_b_ff1;
    assign s_A1 = i_a     & s_b_ff1;
    assign s_B0 = 1'b0;
    assign s_B1 = s_a_ff1 & i_b;

    //------------------------------------
    // Lower-level module instantiations.
    //------------------------------------

    // DFF.
    always_ff @(posedge i_clk, negedge i_arstn) begin
        if (~ i_arstn) begin
            s_a_ff1    <= 1'b0;
            s_b_ff1    <= 1'b0;
            s_carry_in <= 1'b0;
        end
        else if (i_valid) begin
            s_a_ff1    <= i_a;
            s_b_ff1    <= i_b;
            s_carry_in <= s_carry_out;
        end
    end

    // 2FA.
    full_adder FA0 (
        .i_input1 ( {s_A1, s_A0} ),
        .i_input2 ( {s_B1, s_B0} ),
        .i_cin    ( s_carry_in   ),
        .o_sum    ( o_sum        ),
        .o_cout   ( s_carry_out  )
    );

    //------------------------
    // Output logic.
    //------------------------
    assign o_b = s_b_ff1;

endmodule