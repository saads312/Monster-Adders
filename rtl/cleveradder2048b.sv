module cleveradder2048b #(
    parameter W = 2048,
    parameter M = 64,
    parameter PIPE = 1
) (
    input  logic          clk,
    input  logic          rst,
    input  logic [W-1:0]  a,
    input  logic [W-1:0]  b,
    input  logic          c_in,
    input  logic          in_valid,
    output logic [W-1:0]  sum,
    output logic          c_out,
    output logic          out_valid
);

    localparam N = W / M;  // number of chunks

endmodule
