/*
 * Module: vga_controller
 * Description: Generates VGA timing signals (640x480 @ 60Hz).
 */
module vga_controller #(
    // Timing parameters for 640x480 @ 60Hz, 25.175MHz pixel clock
    parameter H_ACTIVE      = 640,  // Horizontal active display
    parameter H_FRONT_PORCH = 16,   // Horizontal front porch
    parameter H_SYNC_PULSE  = 96,   // Horizontal sync pulse
    parameter H_BACK_PORCH  = 48,   // Horizontal back porch
    parameter V_ACTIVE      = 480,  // Vertical active display
    parameter V_FRONT_PORCH = 10,   // Vertical front porch
    parameter V_SYNC_PULSE  = 2,    // Vertical sync pulse
    parameter V_BACK_PORCH  = 33    // Vertical back porch
) (
    input             pixel_clk,
    input             rst_n,
    
    output reg        vga_hs,
    output reg        vga_vs,
    output reg [9:0]  pixel_x,
    output reg [9:0]  pixel_y,
    output            pixel_valid
);

// --- Calculate Total Periods ---
localparam H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // 800
localparam V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // 525

// --- Counters ---
reg [9:0] h_count;
reg [9:0] v_count;

// --- Horizontal Counter ---
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        h_count <= 0;
    end else begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
        end else begin
            h_count <= h_count + 1;
        end
    end
end

// --- Vertical Counter ---
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        v_count <= 0;
    end else begin
        if (h_count == H_TOTAL - 1) begin // Update at the end of a line
            if (v_count == V_TOTAL - 1) begin
                v_count <= 0;
            end else begin
                v_count <= v_count + 1;
            end
        end
    end
end

// --- Generate Sync Signals ---
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        vga_hs <= 1;
        vga_vs <= 1;
    end else begin
        // Horizontal Sync (active low)
        if (h_count >= H_ACTIVE + H_FRONT_PORCH && h_count < H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE) begin
            vga_hs <= 0;
        end else begin
            vga_hs <= 1;
        end
        
        // Vertical Sync (active low)
        if (v_count >= V_ACTIVE + V_FRONT_PORCH && v_count < V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE) begin
            vga_vs <= 0;
        end else begin
            vga_vs <= 1;
        end
    end
end

// --- Generate Pixel Coordinates and Valid Signal ---
always @(posedge pixel_clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_x <= 0;
        pixel_y <= 0;
    end else begin
        pixel_x <= h_count;
        pixel_y <= v_count;
    end
end

assign pixel_valid = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

endmodule