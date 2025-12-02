module naiveadder2048b
#(
    parameter W = 2048, // DO NOT CHANGE!
    parameter M = 128
) (
    input  logic          clk,
    input  logic          rst,
    input  logic 	  in_valid,
    input  logic [W-1:0]  a,
    input  logic [W-1:0]  b,
    input logic           c_in,
    output logic 	  out_valid,
    output logic [W-1:0]  sum,
    output logic          c_out
);

csa_pipe #( .W(W), .M(M)) csa_pipe_inst (
	.clk(clk),
	.rst(rst),
	.in_valid(in_valid),
	.a(a),
	.b(b),
	.c_in(c_in),
	.sum(sum),
	.c_out(c_out),
	.out_valid(out_valid)
);

endmodule

