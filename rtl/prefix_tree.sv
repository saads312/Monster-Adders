module prefix_tree #(
    parameter N    = 32,
    parameter PIPE = 1  // 1 = pipelined, 0 = combinational
) (
    input  logic          clk,
    input  logic          rst,
    input  logic [N-1:0]  g,
    input  logic [N-1:0]  p,
    input  logic          in_valid,
    output logic [N-1:0]  c,
    output logic          out_valid
);
    localparam int LEVELS = $clog2(N);

    generate
        if (PIPE) begin : gen_pipelined
            logic [N-1:0] g_stage [0:LEVELS];
            logic [N-1:0] p_stage [0:LEVELS];
            logic [LEVELS:0] valid_stage;

            assign g_stage[0]   = g;
            assign p_stage[0]   = p;
            assign valid_stage[0] = in_valid;

            genvar lv;
            for (lv = 0; lv < LEVELS; lv++) begin : level_gen
                localparam int STRIDE = 1 << lv;
                logic [N-1:0] g_next, p_next;

                always_comb begin
                    for (int idx = 0; idx < N; idx++) begin
                        if (idx < STRIDE) begin
                            g_next[idx] = g_stage[lv][idx];
                            p_next[idx] = p_stage[lv][idx];
                        end else begin
                            g_next[idx] = g_stage[lv][idx] | (p_stage[lv][idx] & g_stage[lv][idx-STRIDE]);
                            p_next[idx] = p_stage[lv][idx] & p_stage[lv][idx-STRIDE];
                        end
                    end
                end

                always_ff @(posedge clk) begin
                    g_stage[lv+1] <= g_next;
                    p_stage[lv+1] <= p_next;

                    if (rst) valid_stage[lv+1] <= 1'b0;
                    else     valid_stage[lv+1] <= valid_stage[lv];
                end
            end

            assign c = g_stage[LEVELS];
            assign out_valid = valid_stage[LEVELS];

        end else begin : gen_combinational
            logic [N-1:0] g_comb [LEVELS+1];
            logic [N-1:0] p_comb [LEVELS+1];

            assign g_comb[0] = g;
            assign p_comb[0] = p;

            genvar lv, i;
            for (lv = 0; lv < LEVELS; lv++) begin : level_comb
                localparam int STRIDE = 1 << lv;
                for (i = 0; i < N; i++) begin : idx_comb
                    if (i < STRIDE) begin
                        assign g_comb[lv+1][i] = g_comb[lv][i];
                        assign p_comb[lv+1][i] = p_comb[lv][i];
                    end else begin
                        assign g_comb[lv+1][i] = g_comb[lv][i] | (p_comb[lv][i] & g_comb[lv][i-STRIDE]);
                        assign p_comb[lv+1][i] = p_comb[lv][i] & p_comb[lv][i-STRIDE];
                    end
                end
            end

            assign c = g_comb[LEVELS];
            assign out_valid = in_valid;
        end
    endgenerate
endmodule
