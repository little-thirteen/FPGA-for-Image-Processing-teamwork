/*
 * Module: histogram_equalization_y
 * Description: Performs single-pass histogram equalization on the Y channel (Optimized Single-Pass Histogram Equalization).
 *              This module uses statistics from the previous frame to process the current frame, eliminating the need for a frame buffer.
 *              It operates in a pipelined manner for real-time processing, significantly reducing resource consumption and synthesis time,
 *              while ensuring the logic is synthesizable.
 */
module histogram_equalization_y #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480,
    parameter SCALE_BITS = 16 // Precision bits for fixed-point calculations
) (
    input               clk,
    input               rst_n,
    input               pixel_valid_in,
    input  [9:0]        x_in,
    input  [9:0]        y_in,
    input  [7:0]        y_data_in,
    output reg [7:0]    y_data_out
);

localparam PIXEL_COUNT = H_ACTIVE * V_ACTIVE;

// --- State Machine ---
localparam S_IDLE         = 3'd0;
localparam S_PROCESS      = 3'd1; // Process frame data and build histogram for the next frame
localparam S_FIND_CDFIN   = 3'd2; // Find the minimum CDF value
localparam S_CALC_SCALE   = 3'd3; // Calculate the scale factor for division optimization
localparam S_CALC_LUT     = 3'd4; // Calculate the Look-Up Table (LUT)
localparam S_RESET_HIST   = 3'd5; // Reset the histogram

reg [2:0] state, next_state;

// --- Memories ---
(* ram_style = "block" *)
reg [19:0] histogram [0:255];      // Histogram for building the next frame's statistics
(* ram_style = "block" *)
reg [7:0]  equalization_lut [0:255]; // Equalization LUT used for the current frame

// --- Logic for Calculation Pipeline ---
reg [8:0]  addr_cnt;         // Address counter for traversing memories
reg [19:0] cdf;              // Cumulative Distribution Function (CDF)
reg [19:0] cdf_min;          // The first non-zero CDF value
reg [19:0] hist_val_rd;      // Histogram value read from BRAM
reg [31+SCALE_BITS:0] scale_factor; // Scale factor for division optimization
wire [19:0] divisor;
integer i;

// --- Frame End Detection ---
wire frame_end = (y_in == V_ACTIVE - 1) && (x_in == H_ACTIVE - 1) && pixel_valid_in;

assign divisor = (PIXEL_COUNT > cdf_min) ? (PIXEL_COUNT - cdf_min) : PIXEL_COUNT;

// State Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S_IDLE;
    else        state <= next_state;
end

// Next State Logic
always @(*) begin
    next_state = state;
    case(state)
        S_IDLE:         if (pixel_valid_in) next_state = S_PROCESS;
        S_PROCESS:      if (frame_end) next_state = S_FIND_CDFIN;
        S_FIND_CDFIN:   if (addr_cnt == 255) next_state = S_CALC_SCALE;
        S_CALC_SCALE:   next_state = S_CALC_LUT;
        S_CALC_LUT:     if (addr_cnt == 255) next_state = S_RESET_HIST;
        S_RESET_HIST:   if (addr_cnt == 255) next_state = S_PROCESS;
    endcase
end

// Main Processing Logic
always @(posedge clk) begin
    if (!rst_n) begin
        // --- Global Reset --- 
        y_data_out <= 0;
        addr_cnt <= 0;
        cdf <= 0;
        cdf_min <= 0;
        scale_factor <= 0;
        for (i = 0; i < 256; i = i + 1) begin
            histogram[i] <= 0;
            equalization_lut[i] <= i; // Default to pass-through
        end
    end else begin
        // --- State Transitions Actions ---
        if (state != next_state) begin
            addr_cnt <= 0;
            if (next_state == S_FIND_CDFIN) begin
                cdf <= 0;
                cdf_min <= PIXEL_COUNT;
            end
            if (next_state == S_CALC_LUT) begin
                cdf <= 0;
            end
        end

        // --- State Actions ---
        case (state)
            S_PROCESS: begin
                if (pixel_valid_in) begin
                    y_data_out <= equalization_lut[y_data_in];
                    histogram[y_data_in] <= histogram[y_data_in] + 1;
                end
            end

            S_FIND_CDFIN: begin
                addr_cnt <= addr_cnt + 1;
                hist_val_rd <= histogram[addr_cnt];
                cdf <= cdf + hist_val_rd;
                if (cdf != 0 && cdf < cdf_min) begin
                    cdf_min <= cdf;
                end
            end

            S_CALC_SCALE: begin
                if (divisor > 0) begin
                    scale_factor <= ((255 << SCALE_BITS) / divisor);
                end else begin
                    scale_factor <= 0;
                end
            end

            S_CALC_LUT: begin
                addr_cnt <= addr_cnt + 1;
                hist_val_rd <= histogram[addr_cnt];
                cdf <= cdf + hist_val_rd;
                if (cdf > cdf_min) begin
                    equalization_lut[addr_cnt] <= (((cdf - cdf_min) * scale_factor) >> SCALE_BITS);
                end else begin
                    equalization_lut[addr_cnt] <= 0;
                end
            end

            S_RESET_HIST: begin
                addr_cnt <= addr_cnt + 1;
                histogram[addr_cnt] <= 0;
            end

            default: begin
                y_data_out <= y_data_in; // Pass-through
            end
        endcase
    end
end

endmodule