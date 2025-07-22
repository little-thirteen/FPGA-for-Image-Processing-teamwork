/*
 * Module: top
 * Description: Top-level module that integrates the VGA controller, image source,
 *              and the image enhancement pipeline.
 */
module top(
    input             sys_clk,      // System clock (e.g., 100MHz)
    input             rst_n,        // Asynchronous active-low reset

    // VGA Interface
    output            vga_hs,       // Horizontal sync
    output            vga_vs,       // Vertical sync
    output  [11:0]    vga_rgb       // 12-bit RGB color (4 bits per channel)
);

// --- Parameters ---
localparam H_ACTIVE   = 640;  // Horizontal active pixels
localparam V_ACTIVE   = 480;  // Vertical active pixels

// --- Signal Declarations ---
wire            pixel_clk;    // Pixel clock (25.175MHz for 640x480@60Hz)
wire            locked;

wire [9:0]      pixel_x;      // Current horizontal pixel coordinate
wire [9:0]      pixel_y;      // Current vertical pixel coordinate
wire            pixel_valid;  // Indicates active display area

wire [23:0]     rgb_in;       // Input RGB data from image source
wire [23:0]     rgb_out;      // Output processed RGB data

// --- Clock Management ---
// Use a Clocking Wizard IP to convert the system clock to the 25.175MHz pixel clock.
clk_wiz_0 u_clk_wiz (
    .clk_in1    (sys_clk),
    .clk_out1   (pixel_clk),
    .locked     (locked)
);

// --- Image Source (ROM) ---
// In a real hardware implementation, this would be connected to a camera interface or DDR memory.
image_rom u_image_rom (
    .clk        (pixel_clk),
    .x          (pixel_x),
    .y          (pixel_y),
    .rgb_data   (rgb_in)
);

// --- VGA Timing Controller ---
vga_controller #(
    .H_ACTIVE(H_ACTIVE),
    .V_ACTIVE(V_ACTIVE)
) u_vga_controller (
    .pixel_clk  (pixel_clk),
    .rst_n      (rst_n && locked), // Only enable when clock is stable
    
    .vga_hs     (vga_hs),
    .vga_vs     (vga_vs),
    .pixel_x    (pixel_x),
    .pixel_y    (pixel_y),
    .pixel_valid(pixel_valid)
);

// --- Image Processing Pipeline ---
retinex_he_pipeline #(
    .H_ACTIVE(H_ACTIVE),
    .V_ACTIVE(V_ACTIVE)
) u_retinex_he_pipeline (
    .clk        (pixel_clk),
    .rst_n      (rst_n && locked),
    .pixel_valid_in (pixel_valid),
    .rgb_in     (rgb_in),
    .rgb_out    (rgb_out)
);

// --- Output Logic ---
// Convert 24-bit RGB to 12-bit for the VGA DAC
assign vga_rgb = {rgb_out[23:20], rgb_out[15:12], rgb_out[7:4]};

endmodule