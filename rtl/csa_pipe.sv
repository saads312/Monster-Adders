/*
module csa_pipe #(
    parameter W = 128,
    parameter M = 1
) (
    input logic clk,
    input logic rst,
    input logic in_valid,
    input logic [W-1:0] a,
    input logic [W-1:0] b,
    input logic c_in,
    output logic out_valid,
    output logic [W-1:0] sum,
    output logic c_out
);

localparam int REMAINDER = W % M;
localparam int NUM_FULL_CHUNKS = W/M;
localparam int TOTAL_CHUNKS = NUM_FULL_CHUNKS + ((REMAINDER > 0) ? 1 : 0);
localparam int PIPELINE_STAGES = (REMAINDER != 0) ? (NUM_FULL_CHUNKS + 2) : (NUM_FULL_CHUNKS + 1);

logic valid_pipe [PIPELINE_STAGES-1:0];
logic [M-1:0] sum_r [NUM_FULL_CHUNKS:1][NUM_FULL_CHUNKS-1:0];
logic [M-1:0] a_r [NUM_FULL_CHUNKS-1:0][NUM_FULL_CHUNKS-1:0];
logic [M-1:0] b_r [NUM_FULL_CHUNKS-1:0][NUM_FULL_CHUNKS-1:0];
logic c_in_r, c_out_r;
logic [M-1:0] sum_r_cin0 [NUM_FULL_CHUNKS-1:1];
logic [M-1:0] sum_r_cin1 [NUM_FULL_CHUNKS-1:1];
logic c_out_r_cin0 [NUM_FULL_CHUNKS-1:1];
logic c_out_r_cin1 [NUM_FULL_CHUNKS-1:1];
logic c_out_r_after_mux [NUM_FULL_CHUNKS:1];

always_ff @(posedge clk) begin
	if (rst) begin
		for (int i = 0; i < PIPELINE_STAGES; i++) begin
			valid_pipe[i] <= 1'b0;
		end
		c_in_r <= 1'b0;
		c_out_r <= 1'b0;
	end else begin
		// Valid pipeline
		valid_pipe[0] <= in_valid;
		for (int i = 1; i < PIPELINE_STAGES; i++) begin
			valid_pipe[i] <= valid_pipe[i-1];
		end

		// Input capture
		c_in_r <= c_in;
		for (int i = 0; i < NUM_FULL_CHUNKS; i++) begin
			a_r[0][i] <= a[i*M +: M];
			b_r[0][i] <= b[i*M +: M];
		end
	end
end

always_ff @(posedge clk) begin
	{c_out_r_after_mux[1], sum_r[1][0]} <= a_r[0][0] + b_r[0][0] + {{(M-1){1'b0}}, c_in_r};
	for (int i = 2; i <= NUM_FULL_CHUNKS; i++) begin
		sum_r[i][0] <= sum_r[i-1][0];
	end

	for (int i = 1; i < NUM_FULL_CHUNKS; i++) begin
		for (int k = 1; k <= NUM_FULL_CHUNKS; k++) begin
			if (k < i) begin
				a_r[k][i] <= a_r[k-1][i];
				b_r[k][i] <= b_r[k-1][i];
			end else if (k == i) begin
				{c_out_r_cin0[k], sum_r_cin0[k]} <= a_r[k-1][i] + b_r[k-1][i];
				{c_out_r_cin1[k], sum_r_cin1[k]} <= a_r[k-1][i] + b_r[k-1][i] + {{(M-1){1'b0}}, 1'b1};
			end else if (k == i + 1) begin
				if (c_out_r_after_mux[k-1] == 1'b1) begin
					sum_r[k][i] <= sum_r_cin1[k-1];
					c_out_r_after_mux[k] <= c_out_r_cin1[k-1];
				end else begin
					sum_r[k][i] <= sum_r_cin0[k-1];
					c_out_r_after_mux[k] <= c_out_r_cin0[k-1];
				end
			end else begin
				sum_r[k][i] <= sum_r[k-1][i];
			end
		end
	end
end

generate
if (REMAINDER != 0) begin : remainder_logic
	logic [REMAINDER-1:0] a_r_remainder [NUM_FULL_CHUNKS-1:0];
	logic [REMAINDER-1:0] b_r_remainder [NUM_FULL_CHUNKS-1:0];
	logic [W-1:0] sum_r_remainder;
	logic c_out_r_after_mux_remainder, c_out_r_cin0_remainder, c_out_r_cin1_remainder;
	logic [REMAINDER-1:0] sum_r_cin0_remainder, sum_r_cin1_remainder;

	always_ff @(posedge clk) begin
		a_r_remainder[0] <= a[W-1 : M*NUM_FULL_CHUNKS];
		b_r_remainder[0] <= b[W-1 : M*NUM_FULL_CHUNKS];
		for (int i = 1; i < NUM_FULL_CHUNKS; i++) begin
			a_r_remainder[i] <= a_r_remainder[i-1];
			b_r_remainder[i] <= b_r_remainder[i-1];
		end

		{c_out_r_cin0_remainder, sum_r_cin0_remainder} <= a_r_remainder[NUM_FULL_CHUNKS-1] + b_r_remainder[NUM_FULL_CHUNKS-1];
		{c_out_r_cin1_remainder, sum_r_cin1_remainder} <= a_r_remainder[NUM_FULL_CHUNKS-1] + b_r_remainder[NUM_FULL_CHUNKS-1] + {{(REMAINDER-1){1'b0}}, 1'b1};

		for (int i = 0; i < NUM_FULL_CHUNKS; i++) begin
			sum_r_remainder[i*M +: M] <= sum_r[NUM_FULL_CHUNKS][i];
		end

		// Select remainder
		if (c_out_r_after_mux[NUM_FULL_CHUNKS] == 1'b1) begin
			sum_r_remainder[W-1 : M*NUM_FULL_CHUNKS] <= sum_r_cin1_remainder;
			c_out_r_after_mux_remainder <= c_out_r_cin1_remainder;
		end else begin
			sum_r_remainder[W-1 : M*NUM_FULL_CHUNKS] <= sum_r_cin0_remainder;
			c_out_r_after_mux_remainder <= c_out_r_cin0_remainder;
		end
	end

	assign sum = sum_r_remainder;
	assign c_out = c_out_r_after_mux_remainder;

end else begin : no_remainder
	always_comb begin
		for (int k = 0; k < NUM_FULL_CHUNKS; k++) begin
			sum[M*k +: M] = sum_r[NUM_FULL_CHUNKS][k];
		end
		c_out = c_out_r_after_mux[NUM_FULL_CHUNKS];
	end
end
endgenerate

assign out_valid = valid_pipe[PIPELINE_STAGES-1];

endmodule
*/

module csa_pipe #(
    parameter W = 128,
    parameter M = 1
) (
    input  logic clk,
    input  logic rst,        
    input  logic in_valid,
    input  logic [W-1:0] a,
    input  logic [W-1:0] b,
    input  logic c_in,
    output logic out_valid,
    output logic [W-1:0] sum,
    output logic c_out
);

    localparam int REMAINDER = W % M;
    localparam int NUM_FULL_CHUNKS = W / M;
    localparam int TOTAL_CHUNKS = NUM_FULL_CHUNKS + ((REMAINDER > 0) ? 1 : 0);
    localparam int PIPELINE_STAGES = (REMAINDER != 0) ? (NUM_FULL_CHUNKS + 2)
                                                     : (NUM_FULL_CHUNKS + 1);

    logic [PIPELINE_STAGES-1:0] valid_pipe;

    logic [M-1:0] sum_r [NUM_FULL_CHUNKS:1][NUM_FULL_CHUNKS-1:0];
    logic [M-1:0] a_r [NUM_FULL_CHUNKS-1:0][NUM_FULL_CHUNKS-1:0];
    logic [M-1:0] b_r [NUM_FULL_CHUNKS-1:0][NUM_FULL_CHUNKS-1:0];
    logic c_in_r;
    logic [M-1:0] sum_r_cin0 [NUM_FULL_CHUNKS-1:1];
    logic [M-1:0] sum_r_cin1 [NUM_FULL_CHUNKS-1:1];
    logic c_out_r_cin0[NUM_FULL_CHUNKS-1:1];
    logic c_out_r_cin1[NUM_FULL_CHUNKS-1:1];
    logic c_out_r_after_mux[NUM_FULL_CHUNKS:1];

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_pipe <= '0;
        end else begin
            valid_pipe <= {valid_pipe[PIPELINE_STAGES-2:0], in_valid};
        end
    end

    assign out_valid = valid_pipe[PIPELINE_STAGES-1];

    always_ff @(posedge clk) begin
        c_in_r <= c_in;
        for (int i = 0; i < NUM_FULL_CHUNKS; i++) begin
            a_r[0][i] <= a[i*M +: M];
            b_r[0][i] <= b[i*M +: M];
        end
    end

    always_ff @(posedge clk) begin
        {c_out_r_after_mux[1], sum_r[1][0]} <=
            a_r[0][0] + b_r[0][0] + {{(M-1){1'b0}}, c_in_r};

        for (int i = 2; i <= NUM_FULL_CHUNKS; i++) begin
            sum_r[i][0] <= sum_r[i-1][0];
        end

        for (int i = 1; i < NUM_FULL_CHUNKS; i++) begin
            for (int k = 1; k <= NUM_FULL_CHUNKS; k++) begin
                if (k < i) begin
                    a_r[k][i] <= a_r[k-1][i];
                    b_r[k][i] <= b_r[k-1][i];

                end else if (k == i) begin
                    {c_out_r_cin0[k], sum_r_cin0[k]} <= a_r[k-1][i] + b_r[k-1][i];
                    {c_out_r_cin1[k], sum_r_cin1[k]} <=
                        a_r[k-1][i] + b_r[k-1][i] + {{(M-1){1'b0}}, 1'b1};

                end else if (k == i + 1) begin
                    if (c_out_r_after_mux[k-1]) begin
                        sum_r[k][i] <= sum_r_cin1[k-1];
                        c_out_r_after_mux[k] <= c_out_r_cin1[k-1];
                    end else begin
                        sum_r[k][i] <= sum_r_cin0[k-1];
                        c_out_r_after_mux[k] <= c_out_r_cin0[k-1];
                    end

                end else begin
                    sum_r[k][i] <= sum_r[k-1][i];
                end
            end
        end
    end

    generate
        if (REMAINDER != 0) begin : remainder_logic
            logic [REMAINDER-1:0] a_r_remainder [NUM_FULL_CHUNKS-1:0];
            logic [REMAINDER-1:0] b_r_remainder [NUM_FULL_CHUNKS-1:0];
            logic [W-1:0] sum_r_remainder;
            logic c_out_r_after_mux_remainder, c_out_r_cin0_remainder, c_out_r_cin1_remainder;
            logic [REMAINDER-1:0] sum_r_cin0_remainder, sum_r_cin1_remainder;

            always_ff @(posedge clk) begin
                a_r_remainder[0] <= a[W-1 : M*NUM_FULL_CHUNKS];
                b_r_remainder[0] <= b[W-1 : M*NUM_FULL_CHUNKS];
                for (int i = 1; i < NUM_FULL_CHUNKS; i++) begin
                    a_r_remainder[i] <= a_r_remainder[i-1];
                    b_r_remainder[i] <= b_r_remainder[i-1];
                end

                {c_out_r_cin0_remainder, sum_r_cin0_remainder} <=
                    a_r_remainder[NUM_FULL_CHUNKS-1] +
                    b_r_remainder[NUM_FULL_CHUNKS-1];

                {c_out_r_cin1_remainder, sum_r_cin1_remainder} <=
                    a_r_remainder[NUM_FULL_CHUNKS-1] +
                    b_r_remainder[NUM_FULL_CHUNKS-1] +
                    {{(REMAINDER-1){1'b0}}, 1'b1};

                for (int i = 0; i < NUM_FULL_CHUNKS; i++) begin
                    sum_r_remainder[i*M +: M] <= sum_r[NUM_FULL_CHUNKS][i];
                end

                if (c_out_r_after_mux[NUM_FULL_CHUNKS]) begin
                    sum_r_remainder[W-1 : M*NUM_FULL_CHUNKS] <= sum_r_cin1_remainder;
                    c_out_r_after_mux_remainder <= c_out_r_cin1_remainder;
                end else begin
                    sum_r_remainder[W-1 : M*NUM_FULL_CHUNKS] <= sum_r_cin0_remainder;
                    c_out_r_after_mux_remainder <= c_out_r_cin0_remainder;
                end
            end

            assign sum = sum_r_remainder;
            assign c_out = c_out_r_after_mux_remainder;

        end else begin : no_remainder
            always_comb begin
                for (int k = 0; k < NUM_FULL_CHUNKS; k++) begin
                    sum[M*k +: M] = sum_r[NUM_FULL_CHUNKS][k];
                end
                c_out = c_out_r_after_mux[NUM_FULL_CHUNKS];
            end
        end
    endgenerate

endmodule

