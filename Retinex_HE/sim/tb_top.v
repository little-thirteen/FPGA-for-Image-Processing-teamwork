/*
 * Module: tb_top
 * Description: Testbench for the top-level module.
 */
`timescale 1ns / 1ps

module tb_top();

// --- Parameters ---
localparam CLK_PERIOD = 10; // 100MHz

// --- Signals ---
reg sys_clk;
reg rst_n;

wire vga_hs;
wire vga_vs;
wire [11:0] vga_rgb;

// --- Instantiate the Device Under Test (DUT) ---
top u_top (
    .sys_clk    (sys_clk),
    .rst_n      (rst_n),
    .vga_hs     (vga_hs),
    .vga_vs     (vga_vs),
    .vga_rgb    (vga_rgb)
);

// --- Clock Generation ---
initial begin
    sys_clk = 0;
    forever #(CLK_PERIOD/2) sys_clk = ~sys_clk;
end

// --- Reset and Simulation Control ---
initial begin
    rst_n = 0;
    #200;
    rst_n = 1;
    
    // Run for enough time to display a few frames
    #(CLK_PERIOD * 800 * 525 * 5);
    
    $finish;
end

// --- (Optional) Waveform Dumping ---
initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
end

endmodule