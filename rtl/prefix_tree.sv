module prefix_tree #(
    parameter N = 32,
    parameter PIPE = 1  // 1 = pipeline output, 0 = combinational
) (
    input  logic          clk,
    input  logic          rst,
    input  logic [N-1:0]  g,
    input  logic [N-1:0]  p,
    input  logic          in_valid,
    output logic [N-1:0]  c,
    output logic          out_valid
);
    localparam STAGES = $clog2(N);

endmodule
