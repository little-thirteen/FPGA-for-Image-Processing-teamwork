/*
 * Module: retinex_he_pipeline
 * Description: Image enhancement processing pipeline that combines Retinex and Histogram Equalization.
 */
module retinex_he_pipeline #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480
) (
    input             clk,
    input             rst_n,
    input             pixel_valid_in,
    input  [23:0]     rgb_in,       // Input 24-bit RGB
    output [23:0]     rgb_out       // Output 24-bit RGB
);

// --- Signal Wires ---
wire [7:0]  y_in, cb_in, cr_in;
wire [7:0]  y_retinex_out;
wire [7:0]  y_he_out;
wire [7:0]  y_final;

// --- Pipeline Stages ---
// 1. RGB to YCbCr
rgb_to_ycbcr u_rgb_to_ycbcr (
    .clk        (clk),
    .rgb_in     (rgb_in),
    .y_out      (y_in),
    .cb_out     (cb_in),
    .cr_out     (cr_in)
);

// 2. Retinex Processing (on Y channel only)
// Note: The Retinex module here is a simplified version suitable for FPGA pipelining.
// A full Retinex implementation (especially MSRCR) requires Gaussian blurs, which are resource-intensive.
// This simplified model serves as a structural placeholder.
retinex_simple u_retinex_simple (
    .clk        (clk),
    .rst_n      (rst_n),
    .pixel_valid_in(pixel_valid_in),
    .y_in       (y_in),
    .y_out      (y_retinex_out)
);

// 3. Histogram Equalization (on Y channel only)
// This is a single-pass implementation and does not require a frame buffer.
histogram_equalization_y u_he_y (
    .clk        (clk),
    .rst_n      (rst_n),
    .pixel_valid_in(pixel_valid_in),
    .y_data_in  (y_in),       // HE operates on the original Y channel
    .y_data_out (y_he_out)
);

// 4. Fuse the processed Y channel from Retinex and HE
// A simple weighted average is used for fusion.
// Y_final = 0.5 * Y_retinex + 0.5 * Y_he
assign y_final = (y_retinex_out + y_he_out) >> 1;

// 5. YCbCr to RGB
ycbcr_to_rgb u_ycbcr_to_rgb (
    .clk        (clk),
    .y_in       (y_final),
    .cb_in      (cb_in),      // Cb and Cr channels are passed through unmodified
    .cr_in      (cr_in),
    .rgb_out    (rgb_out)
);

endmodule