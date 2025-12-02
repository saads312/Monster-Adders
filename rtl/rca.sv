module rca #(
    parameter W = 2048,
    parameter PIPE = 1  
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          in_valid,
    input  logic [W-1:0]  a,
    input  logic [W-1:0]  b,
    input  logic          c_in,
    output logic          out_valid,
    output logic [W-1:0]  sum,
    output logic          c_out
);

    generate
        if (PIPE) begin : gen_pipelined

            logic [W-1:0] a_r, b_r;
            logic         c_in_r;

            always_ff @(posedge clk) begin
                a_r    <= a;
                b_r    <= b;
                c_in_r <= c_in;
            end

            logic [W:0] sum_wide;
            wire  [W:0] cext = {{W{1'b0}}, c_in_r};
            assign sum_wide = {1'b0, a_r} + {1'b0, b_r} + cext;

            always_ff @(posedge clk) begin
                sum   <= sum_wide[W-1:0];
                c_out <= sum_wide[W];
            end

            logic in_valid_d1;
            always_ff @(posedge clk) begin
                if (rst) begin
                    in_valid_d1 <= 1'b0;
                    out_valid   <= 1'b0;
                end else begin
                    in_valid_d1 <= in_valid;    
                    out_valid   <= in_valid_d1; 
                end
            end

        end else begin : gen_comb
            logic [W:0] sum_wide_c;

            always_comb begin
                sum_wide_c = {1'b0, a} + {1'b0, b} + {{W{1'b0}}, c_in};
                sum        = sum_wide_c[W-1:0];
                c_out      = sum_wide_c[W];
            end

            always_comb begin
                out_valid = in_valid;
            end

        end
    endgenerate

endmodule
