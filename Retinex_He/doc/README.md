# FPGA-Based Image Enhancement using Retinex and Histogram Equalization

## 1. Project Overview

This project implements a hybrid image enhancement algorithm on an FPGA, targeting the Boolean board with a Xilinx Spartan-7 (xc7s50csga324-1) chip. The algorithm combines a simplified Retinex method with Histogram Equalization (HE) to improve the quality of images, particularly those with poor lighting conditions.

The processing is performed on the luminance (Y) channel of the image to preserve color information. The image resolution is set to **640x480** to fit within the resource constraints of the target FPGA.

### Key Features:
- **Hybrid Algorithm**: Combines Retinex and Histogram Equalization for robust enhancement.
- **Color Preservation**: All processing is done on the Y channel of a YCbCr image, preventing color distortion.
- **Real-time Processing**: The entire pipeline is designed for real-time video processing at 60Hz.
- **Target Platform**: Specifically designed for the Boolean FPGA board.

## 2. Algorithm Flow

The image processing pipeline consists of the following steps:

1.  **RGB to YCbCr Conversion**: The input 24-bit RGB pixel data is converted to the YCbCr color space.
2.  **Luminance Processing**: The 8-bit luminance (Y) channel undergoes enhancement.
    a.  **Simplified Retinex**: A simplified Retinex algorithm is applied to estimate and remove the illumination component. This helps to normalize lighting across the image. (Note: This is a simplified version for FPGA implementation).
    b.  **Histogram Equalization**: The result from the Retinex step is then processed by a two-pass Histogram Equalization module to improve global contrast.
3.  **YCbCr to RGB Conversion**: The enhanced Y channel is recombined with the original Cb and Cr (chrominance) channels and converted back to the 24-bit RGB color space.
4.  **VGA Output**: The final RGB data is sent to a VGA controller for display.

## 3. File Structure

```
FPGA-Retinex-HE-Enhancement/
├── src/                  # Verilog source files
│   ├── top.v                 # Top-level module
│   ├── retinex_he_pipeline.v # Main processing pipeline
│   ├── color_space_converter.v # RGB <-> YCbCr converters
│   ├── histogram_equalization_y.v # Histogram equalization for Y channel
│   ├── retinex_simple.v      # Simplified Retinex module
│   ├── vga_controller.v      # VGA timing generator
│   ├── image_rom.v           # (For simulation) Test image source
│   └── clk_wiz_0.v           # (Placeholder) Clocking Wizard IP
├── sim/                  # Simulation files
│   └── tb_top.v              # Testbench for the top-level module
├── constraints/          # Constraints files
│   └── boolean_board.xdc     # Pin constraints for the Boolean board
└── doc/                  # Documentation
    └── README.md             # This file
```

## 4. Module Descriptions

-   `top.v`: The main module that connects all sub-modules, including the clock generator, image source, processing pipeline, and VGA controller.
-   `retinex_he_pipeline.v`: Encapsulates the entire enhancement algorithm, from color space conversion to the final conversion back to RGB.
-   `color_space_converter.v`: Contains two sub-modules, `rgb_to_ycbcr` and `ycbcr_to_rgb`, for color space transformations.
-   `histogram_equalization_y.v`: A two-pass implementation of histogram equalization. The first pass builds the histogram and CDF, and the second pass applies the mapping. It uses a single-port RAM as a frame buffer.
-   `retinex_simple.v`: A structurally representative but simplified version of a Retinex filter. It uses a small local window to approximate the illumination component.
-   `vga_controller.v`: Generates the standard 640x480 @ 60Hz VGA timing signals (`hsync`, `vsync`).
-   `image_rom.v`: A simulation-only module that acts as a ROM to provide a test image. For hardware implementation, this should be replaced with a camera interface or DDR memory controller.
-   `clk_wiz_0.v`: A placeholder for the Xilinx Clocking Wizard IP. In a Vivado project, this IP should be generated to convert the 100MHz system clock to the 25.175MHz pixel clock required for VGA.

## 5. How to Use

1.  **Create a Vivado Project**: Create a new project in Vivado, targeting the `xc7s50csga324-1` device.
2.  **Add Source Files**: Add all files from the `src/` directory to the project's design sources.
3.  **Add Simulation Files**: Add the `tb_top.v` file from `sim/` to the simulation sources.
4.  **Add Constraints**: Add the `boolean_board.xdc` file from `constraints/` to the project's constraints.
5.  **Generate IP Core**: Use the IP Catalog to generate a **Clocking Wizard** IP (`clk_wiz_0`). Configure it to take a 100MHz input and generate a 25.175MHz output.
6.  **Prepare Image Data (for simulation)**: Create a `.mem` file containing your test image data in hexadecimal format (one 24-bit RGB value per line). Update the `IMAGE_FILE` parameter in `image_rom.v` if necessary.
7.  **Run Simulation**: Run the behavioral simulation to verify the design's functionality.
8.  **Synthesize and Implement**: Run synthesis and implementation. Vivado will generate a bitstream file.
9.  **Program the Board**: Use the Hardware Manager to program the Boolean board with the generated bitstream.

## 6. Design Considerations

-   **Resolution**: The design is fixed at 640x480. Increasing the resolution would require significant changes, especially to the frame buffer size in the histogram equalization module, and may exceed the BRAM capacity of the Spartan-7 50T device.
-   **Retinex Simplification**: The `retinex_simple.v` module is not a full-fledged MSRCR implementation. A full implementation would require multiple large-scale Gaussian blurs, which are resource-intensive. This version serves as a placeholder to demonstrate the data flow.
-   **Frame Buffer**: The histogram equalization module uses a single-port BRAM as a frame buffer. This introduces a one-frame latency to the video pipeline.