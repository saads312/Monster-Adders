module cleveradder2048b #(
    parameter W    = 2048,
    parameter M    = 64,
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

    localparam int NUM_CHUNKS = W / M;
    localparam int PREFIX_SIZE = NUM_CHUNKS;

    logic [M-1:0] sum_g [NUM_CHUNKS-1:0];
    logic [NUM_CHUNKS-1:0] g;           
    logic [NUM_CHUNKS-1:0] p;          
    logic [NUM_CHUNKS-1:0] valid_row1_g;

    genvar i;
    generate
        for (i = 0; i < NUM_CHUNKS; i++) begin : gen_gp_chunks
            logic c_in_chunk;
            assign c_in_chunk = (i == 0) ? c_in : 1'b0;

            rca #( .W(M), .PIPE(PIPE) ) rca_g (
                .clk(clk), .rst(rst), .in_valid(in_valid),
                .a(a[i*M +: M]), .b(b[i*M +: M]), .c_in(c_in_chunk),
                .sum(sum_g[i]), .c_out(g[i]), .out_valid(valid_row1_g[i])
            );

            rca #( .W(M), .PIPE(PIPE) ) rca_p (
                .clk(clk), .rst(rst), .in_valid(in_valid),
                .a(a[i*M +: M]), .b(b[i*M +: M]), .c_in(1'b1),
                .sum(), .c_out(p[i]), .out_valid()
            );
        end
    endgenerate


    logic [PREFIX_SIZE-1:0] c_prefix;
    logic valid_row2;

    prefix_tree #(
        .N(PREFIX_SIZE),
        .PIPE(PIPE)
    ) prefix_inst (
        .clk(clk), .rst(rst),
        .g(g), .p(p), .in_valid(valid_row1_g[0]),
        .c(c_prefix), .out_valid(valid_row2)
    );

    localparam int TREE_LATENCY = (PIPE == 1) ? $clog2(PREFIX_SIZE) : 0;

    logic [M-1:0] sum_g_delayed [NUM_CHUNKS-1:0];

    generate
        if (PIPE == 1 && TREE_LATENCY > 0) begin : gen_delay_pipeline
            logic [M-1:0] sum_g_pipe [NUM_CHUNKS-1:0][TREE_LATENCY-1:0];
            for (i = 0; i < NUM_CHUNKS; i++) begin : delay_chunks
                always_ff @(posedge clk) begin
                    sum_g_pipe[i][0] <= sum_g[i];
                    for (int d = 1; d < TREE_LATENCY; d++) begin
                        sum_g_pipe[i][d] <= sum_g_pipe[i][d-1];
                    end
                end
                assign sum_g_delayed[i] = sum_g_pipe[i][TREE_LATENCY-1];
            end
        end else begin : gen_no_delay
            for (i = 0; i < NUM_CHUNKS; i++) assign sum_g_delayed[i] = sum_g[i];
        end
    endgenerate


    logic [M-1:0] sum_final [NUM_CHUNKS-1:0];
    logic [NUM_CHUNKS-1:0] valid_row3;
    logic [NUM_CHUNKS-1:0] cout_row3_unused;

    generate
        for (i = 0; i < NUM_CHUNKS; i++) begin : gen_final_add
            logic carry_in;
            if (i == 0) assign carry_in = 1'b0;
            else        assign carry_in = c_prefix[i-1];

            rca #( .W(M), .PIPE(PIPE) ) rca_final (
                .clk(clk), .rst(rst), .in_valid(valid_row2),
                .a(sum_g_delayed[i]), .b({M{1'b0}}), .c_in(carry_in),
                .sum(sum_final[i]), .c_out(cout_row3_unused[i]), .out_valid(valid_row3[i])
            );
        end
    endgenerate

    logic c_out_raw;
    assign c_out_raw = c_prefix[NUM_CHUNKS-1];

    logic [15:0] carry_fifo;
    logic [3:0] wr_ptr, rd_ptr;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (valid_row2) begin
                carry_fifo[wr_ptr] <= c_out_raw;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (valid_row3[0]) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    always_comb begin
        for (int j = 0; j < NUM_CHUNKS; j++) begin
            sum[j*M +: M] = sum_final[j];
        end
    end

    assign c_out = carry_fifo[rd_ptr];
    assign out_valid = valid_row3[0];

endmodule
