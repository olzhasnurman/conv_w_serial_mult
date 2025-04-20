/* Copyright (c) 2025 Nazarbayev University. All rights reserved. */

// -------------------------------------------
// This is a simple 2-bit Full Adder module.
// -------------------------------------------

module full_adder 
#(
    parameter DATA_WIDTH = 2
) 
(
    // Input interface.
    input  logic [DATA_WIDTH - 1:0] i_input1,
    input  logic [DATA_WIDTH - 1:0] i_input2,
    input  logic                    i_cin,

    // Output interface.
    output logic [DATA_WIDTH - 1:0] o_sum,
    output logic                    o_cout
);
    // Adder logic.
    assign {o_cout, o_sum} = i_input1 + i_input2 + {1'b0, i_cin};
    
endmodule