module rca #(
    parameter int W = 2048,
    parameter int PIPE = 1  // 1 = pipelined (default), 0 = combinational
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         in_valid,
    input  logic [W-1:0] a,
    input  logic [W-1:0] b,
    input  logic         c_in,
    output logic         out_valid,
    output logic [W-1:0] sum,
    output logic         c_out
);

endmodule
