/*
 * Module: image_rom
 * Description: A ROM that stores a test image (640x480).
 * In a real application, this would be replaced by a camera interface or DDR read logic.
 */
module image_rom #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480,
    parameter IMAGE_FILE = "image_data.mem" // Image data file
) (
    input             clk,
    input  [9:0]      x,
    input  [9:0]      y,
    output reg [23:0] rgb_data
);

localparam ADDR_WIDTH = $clog2(H_ACTIVE * V_ACTIVE);
reg [23:0] image_memory [0:(H_ACTIVE*V_ACTIVE)-1];

// Note: $readmemh is for simulation only and is not synthesizable.
// In Vivado, the .mem file should be configured as the initialization source for the ROM,
// and the synthesis tool will automatically initialize the data into BRAM.
// initial begin
//     $readmemh(IMAGE_FILE, image_memory);
// end

always @(posedge clk) begin
    if (x < H_ACTIVE && y < V_ACTIVE) begin
        rgb_data <= image_memory[y * H_ACTIVE + x];
    end else begin
        rgb_data <= 24'h000000; // Black for non-display area
    end
end

endmodule