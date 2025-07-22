/*
 * Module: rgb_to_ycbcr
 * Description: Converts 24-bit RGB data to YCbCr data.
 * Formula (Floating Point): 
 * Y  = 0.299*R + 0.587*G + 0.114*B
 * Cb = -0.169*R - 0.331*G + 0.500*B + 128
 * Cr = 0.500*R - 0.419*G - 0.081*B + 128
 * Converted to Fixed Point (scaled by 256):
 * Y  = (77*R + 150*G + 29*B) >> 8
 * Cb = (-43*R - 85*G + 128*B) >> 8 + 128
 * Cr = (128*R - 107*G - 21*B) >> 8 + 128
 */
module rgb_to_ycbcr(
    input             clk,
    input  [23:0]     rgb_in,
    output reg [7:0]  y_out,
    output reg [7:0]  cb_out,
    output reg [7:0]  cr_out
);

    reg [7:0] r, g, b;
    
    always @(posedge clk) begin
        r <= rgb_in[23:16];
        g <= rgb_in[15:8];
        b <= rgb_in[7:0];

        y_out  <= (77 * r + 150 * g + 29 * b) >> 8;
        cb_out <= ((-43 * r - 85 * g + 128 * b) >> 8) + 128;
        cr_out <= ((128 * r - 107 * g - 21 * b) >> 8) + 128;
    end

endmodule

/*
 * Module: ycbcr_to_rgb
 * Description: Converts YCbCr data back to 24-bit RGB data.
 * Formula (Floating Point):
 * R = Y + 1.402*(Cr - 128)
 * G = Y - 0.344*(Cb - 128) - 0.714*(Cr - 128)
 * B = Y + 1.772*(Cb - 128)
 * Converted to Fixed Point (scaled by 256):
 * R = Y + ((359 * (Cr - 128)) >> 8)
 * G = Y - ((88 * (Cb - 128) + 183 * (Cr - 128)) >> 8)
 * B = Y + ((454 * (Cb - 128)) >> 8)
 */
module ycbcr_to_rgb(
    input             clk,
    input  [7:0]      y_in,
    input  [7:0]      cb_in,
    input  [7:0]      cr_in,
    output reg [23:0] rgb_out
);

    reg signed [10:0] cb_s, cr_s;
    reg signed [10:0] r_s, g_s, b_s;

    always @(posedge clk) begin
        cb_s <= cb_in - 128;
        cr_s <= cr_in - 128;

        r_s <= y_in + ((359 * cr_s) >> 8);
        g_s <= y_in - ((88 * cb_s + 183 * cr_s) >> 8);
        b_s <= y_in + ((454 * cb_s) >> 8);
        
        rgb_out[23:16] <= (r_s > 255) ? 255 : ((r_s < 0) ? 0 : r_s[7:0]);
        rgb_out[15:8]  <= (g_s > 255) ? 255 : ((g_s < 0) ? 0 : g_s[7:0]);
        rgb_out[7:0]   <= (b_s > 255) ? 255 : ((b_s < 0) ? 0 : b_s[7:0]);
    end

endmodule