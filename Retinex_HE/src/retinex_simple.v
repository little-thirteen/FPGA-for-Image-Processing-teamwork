/*
 * Module: retinex_simple (Optimized)
 * Description: A simplified Retinex module using a pipelined 3x3 local average to
 *              estimate the illumination component (L) and enhance the image.
 *              The non-pipelined loops and division are replaced with a fully
 *              pipelined adder tree and multiplication for high performance.
 *              R = S - L
 */
module retinex_simple(
    input             clk,
    input             rst_n,
    input             pixel_valid_in,
    input  [7:0]      y_in,         // Input Y channel data (S)
    output reg [7:0]  y_out         // Output enhanced data (R)
);

// Image dimensions
parameter H_ACTIVE = 640;

// Two line buffers to store the previous two rows for 3x3 window processing.
reg [7:0] line_buffer1 [0:H_ACTIVE-1];
reg [7:0] line_buffer2 [0:H_ACTIVE-1];

// 3x3 window register
reg [7:0] window [0:2][0:2];

// Column counter
reg [9:0] x_cnt = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_cnt <= 0;
    end else if (pixel_valid_in) begin
        if (x_cnt == H_ACTIVE - 1) begin
            x_cnt <= 0;
        end else begin
            x_cnt <= x_cnt + 1;
        end
    end
end

// Line buffer and window update logic
always @(posedge clk) begin
    if (pixel_valid_in) begin
        // 1. Update line buffers
        line_buffer1[x_cnt] <= line_buffer2[x_cnt]; // The old second buffer content moves to the first
        line_buffer2[x_cnt] <= y_in;              // Current input goes to the second buffer

        // 2. Load new column into the window from line buffers and current input
        window[0][2] <= line_buffer1[x_cnt];
        window[1][2] <= line_buffer2[x_cnt];
        window[2][2] <= y_in;

        // 3. Shift the window columns to the left
        for (integer i = 0; i < 3; i = i + 1) begin
            window[i][0] <= window[i][1];
            window[i][1] <= window[i][2];
        end
    end
end

// --- Pipelined Adder Tree for Local Average Calculation ---
// To avoid long combinatorial paths, we pipeline the summation of the 3x3 window.

// Pipeline Stage 1: Sum pairs of window pixels
reg [8:0] sum_s1_0, sum_s1_1, sum_s1_2, sum_s1_3;
always @(posedge clk) begin
    sum_s1_0 <= window[0][0] + window[0][1];
    sum_s1_1 <= window[0][2] + window[1][0];
    sum_s1_2 <= window[1][1] + window[1][2];
    sum_s1_3 <= window[2][0] + window[2][1];
    // window[2][2] is passed through to the final stage
end

// Pipeline Stage 2
reg [9:0] sum_s2_0, sum_s2_1;
always @(posedge clk) begin
    sum_s2_0 <= sum_s1_0 + sum_s1_1;
    sum_s2_1 <= sum_s1_2 + sum_s1_3;
end

// Pipeline Stage 3
reg [10:0] sum_s3_0;
always @(posedge clk) begin
    sum_s3_0 <= sum_s2_0 + sum_s2_1;
end

// Pipeline Stage 4: Final sum
reg [11:0] sum_final;
always @(posedge clk) begin
    sum_final <= sum_s3_0 + window[2][2]; // Add the last pixel
end

// Division by 9 optimization: multiply by reciprocal
// local_avg = sum_final / 9  =>  sum_final * (1/9)
// 1/9 is approx 0.1111... In binary, for 8-bit precision: (2^8)/9 = 256/9 approx 28
reg [7:0] local_avg;
always @(posedge clk) begin
    local_avg <= (sum_final * 28) >> 8;
end

// --- Delay input signals to match pipeline latency ---
// The adder tree has a 4-stage pipeline latency.
reg [7:0] y_in_dly [0:3];
reg pixel_valid_dly [0:3];

always @(posedge clk) begin
    y_in_dly[0] <= y_in;
    pixel_valid_dly[0] <= pixel_valid_in;
    for (integer i = 1; i < 4; i = i + 1) begin
        y_in_dly[i] <= y_in_dly[i-1];
        pixel_valid_dly[i] <= pixel_valid_dly[i-1];
    end
end

// --- Final Output Calculation ---
// R = S - L, with proper synchronization
always @(posedge clk) begin
    if (!rst_n) begin
        y_out <= 0;
    end else if (pixel_valid_dly[3]) begin
        if (y_in_dly[3] > local_avg) begin
            y_out <= y_in_dly[3] - local_avg;
        end else begin
            y_out <= 0; // Saturation to prevent underflow
        end
    end else begin
        y_out <= 0;
    end
end

endmodule