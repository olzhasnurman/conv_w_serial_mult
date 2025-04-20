/* Copyright (c) 2025 Nazarbayev University. All rights reserved. */

// -------------------------------------------
// This is a simple 4-bit counter module.
// -------------------------------------------
module counter 
(
    input logic i_clk,
    input logic i_arstn,
    input logic i_valid,

    output logic [3:0] o_count
);

    always_ff @(posedge i_clk, negedge i_arstn) begin
        if (~ i_arstn) 
            o_count <= '0;
        else if (o_count == 4'd12)
            o_count <= '0;
        else if (i_valid)
            o_count <= o_count + 4'b1;
    end
    
endmodule