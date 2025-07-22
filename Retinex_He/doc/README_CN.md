# 基于FPGA的Retinex与直方图均衡化图像增强

## 1. 项目概述

本项目在FPGA上实现了一种混合图像增强算法，目标平台为搭载Xilinx Spartan-7 (xc7s50csga324-1)芯片的Boolean开发板。该算法结合了简化的Retinex方法和直方图均衡化（HE），旨在提升图像质量，特别是改善光照不足的图像。

为了保护颜色信息，所有的处理都在图像的亮度（Y）通道上进行。图像分辨率设置为**640x480**，以适应目标FPGA的资源限制。

### 主要特性:
- **混合算法**: 结合Retinex和直方图均衡化，实现稳健的图像增强。
- **颜色保真**: 所有处理都在YCbCr图像的Y通道上完成，防止色彩失真。
- **实时处理**: 整个流水线设计用于60Hz的实时视频处理。
- **目标平台**: 专为Boolean FPGA开发板设计。

## 2. 算法流程

图像处理流水线包括以下步骤：

1.  **RGB到YCbCr转换**: 将输入的24位RGB像素数据转换为YCbCr色彩空间。
2.  **亮度处理**: 对8位的亮度（Y）通道进行增强处理。
    a.  **简化Retinex**: 应用简化的Retinex算法来估计并移除光照分量，这有助于使整个图像的光照正常化。（注意：这是一个为FPGA实现而简化的版本）。
    b.  **直方图均衡化**: Retinex步骤的结果随后被一个两遍（two-pass）的直方图均衡化模块处理，以提升全局对比度。
3.  **YCbCr到RGB转换**: 将增强后的Y通道与原始的Cb和Cr（色度）通道重新组合，并转换回24位的RGB色彩空间。
4.  **VGA输出**: 最终的RGB数据被发送到VGA控制器进行显示。

## 3. 文件结构

```
FPGA-Retinex-HE-Enhancement/
├── src/                  # Verilog源文件
│   ├── top.v                 # 顶层模块
│   ├── retinex_he_pipeline.v # 主要处理流水线
│   ├── color_space_converter.v # RGB <-> YCbCr 转换器
│   ├── histogram_equalization_y.v # Y通道的直方图均衡化
│   ├── retinex_simple.v      # 简化的Retinex模块
│   ├── vga_controller.v      # VGA时序生成器
│   ├── image_rom.v           # (仿真用) 测试图像源
│   └── clk_wiz_0.v           # (占位符) Clocking Wizard IP
├── sim/                  # 仿真文件
│   └── tb_top.v              # 顶层模块的测试平台
├── constraints/          # 约束文件
│   └── boolean_board.xdc     # Boolean开发板的引脚约束
└── doc/                  # 文档
    └── README.md             # 英文说明文档
    └── README_CN.md          # 本文件
```

## 4. 模块描述

-   `top.v`: 连接所有子模块的主模块，包括时钟生成器、图像源、处理流水线和VGA控制器。
-   `retinex_he_pipeline.v`: 封装了整个增强算法，从色彩空间转换到最终转换回RGB。
-   `color_space_converter.v`: 包含`rgb_to_ycbcr`和`ycbcr_to_rgb`两个子模块，用于色彩空间变换。
-   `histogram_equalization_y.v`: 一个两遍实现的直方图均衡化。第一遍构建直方图和累积分布函数（CDF），第二遍应用映射。它使用一个单端口RAM作为帧缓存。
-   `retinex_simple.v`: 一个结构上具有代表性但经过简化的Retinex滤波器版本。它使用一个小的局部窗口来近似光照分量。
-   `vga_controller.v`: 生成标准的640x480 @ 60Hz VGA时序信号（`hsync`, `vsync`）。
-   `image_rom.v`: 一个仅用于仿真的模块，作为ROM提供测试图像。在硬件实现中，应替换为摄像头接口或DDR内存控制器。
-   `clk_wiz_0.v`: Xilinx Clocking Wizard IP的占位符。在Vivado项目中，应生成此IP，将100MHz的系统时钟转换为VGA所需的25.175MHz像素时钟。

## 5. 如何使用

1.  **创建Vivado工程**: 在Vivado中创建一个新工程，目标器件选择`xc7s50csga324-1`。
2.  **添加源文件**: 将`src/`目录下的所有文件添加到工程的设计源文件中。
3.  **添加仿真文件**: 将`sim/`目录下的`tb_top.v`文件添加到仿真源文件中。
4.  **添加约束文件**: 将`constraints/`目录下的`boolean_board.xdc`文件添加到工程的约束文件中。
5.  **生成IP核**: 使用IP Catalog生成一个**Clocking Wizard** IP (`clk_wiz_0`)。将其配置为接收100MHz输入并生成25.175MHz输出。
6.  **准备图像数据 (用于仿真)**: 创建一个`.mem`文件，其中包含十六进制格式的测试图像数据（每行一个24位RGB值）。如有必要，请更新`image_rom.v`中的`IMAGE_FILE`参数。
7.  **运行仿真**: 运行行为级仿真以验证设计的功能。
8.  **综合与实现**: 运行综合与实现。Vivado将生成一个比特流（bitstream）文件。
9.  **烧录开发板**: 使用Hardware Manager将生成的比特流文件烧录到Boolean开发板。

## 6. Vivado IP核配置详解

### 6.1 Clocking Wizard (clk_wiz_0) 配置

在Vivado项目中，你需要使用IP Catalog生成一个时钟管理IP核，以将板载的100MHz时钟转换为VGA所需的25.175MHz像素时钟。以下是详细步骤：

1.  在 **Flow Navigator** 中，点击 **IP Catalog**。
2.  在搜索框中输入 `Clocking Wizard` 并双击打开它。
3.  **时钟选项 (Clocking Options)**:
    *   **输入时钟信息 (Input Clock Information)**: 将 `Primary` 输入时钟设置为 `100` MHz (与Boolean开发板晶振匹配)。
4.  **输出时钟 (Output Clocks)**:
    *   勾选 `clk_out1`。
    *   在 **Output Freq (MHz)** 列中，为 `clk_out1` 请求 `25.175` 的频率。
    *   在 **Port Name** 列中，确保名称为 `clk_out1`。
5.  **MMCM/PLL 设置 (MMCM/PLL Settings)**:
    *   通常情况下，Vivado会自动选择合适的参数。你可以检查 `Jitter` 和 `Phase Error` 是否在可接受范围内。
6.  **端口和复位选项 (Port Renaming and Reset Options)**:
    *   **复位 (Reset)**: **取消勾选** `reset` 端口。本设计使用非同步复位，直接由顶层模块的 `rst_n` 信号控制，不需要IP核的同步复位端口。
    *   **锁定 (Locked)**: 保持 `locked` 端口的勾选状态，它是一个有用的状态信号。
7.  点击 **OK** 生成IP核。在弹出的 **Generate Output Products** 对话框中，点击 **Generate**。

生成后，Vivado会自动在项目中包含 `clk_wiz_0.v` 的正确实现，替换掉我们提供的占位符文件。

### 6.2 将.mem文件加载到ROM (image_rom)

在仿真时，`image_rom.v` 模块使用 `$readmemh` 系统任务从一个 `.mem` 文件加载图像数据。然而，为了进行综合并让FPGA上电时BRAM中就包含图像数据，你需要将 `.mem` 文件与一个Block Memory Generator IP核关联，或者让综合工具自动推断ROM并初始化它。

以下是推荐的、**无需额外生成IP核**的方法，利用Vivado的自动推断功能：

1.  **准备 `.mem` 文件**: 
    *   确保你的图像数据文件（例如 `image_data.mem`）已经按照要求生成。每一行包含一个十六进制的像素值。
    *   将此文件复制到你的Vivado工程目录的一个方便的位置，例如 `FPGA-Retinex-HE-Enhancement/sim/`。

2.  **确认 `image_rom.v` 的修改**:
    *   为了让综合工具能够正确推断和初始化ROM，`initial` 块中的 `$readmemh` 必须被注释掉或移除，因为它是一个不可综合的仿真构造。
    *   我们提供的 `image_rom.v` 在修复后已经注释了这一行，如下所示：
        ```verilog
        // initial begin
        //     $readmemh(IMAGE_FILE, image_memory);
        // end
        ```

3.  **在Vivado中设置ROM初始化文件**:

    **重要前提**：以下操作需要在**成功运行综合(Run Synthesis)之后**才能进行。因为ROM实例（如 `image_memory_reg`）是由综合工具根据Verilog代码推断生成的，在综合完成前它并不存在于设计中。

    *   **方法一：通过XDC约束设置 (强烈推荐)**
        这种方法最可靠且便于版本控制。
        1. 打开你的约束文件 (`boolean_board.xdc`)。
        2. 添加以下Tcl命令。这条命令会找到综合后生成的ROM单元，并将其初始化文件属性指向你的 `.mem` 文件。
           ```tcl
           # 将下面的层级路径替换为你的设计中ROM的实际路径
           # 你可以通过综合后的原理图或网表找到它
           set_property INIT_FILE {../sim/image_data.mem} [get_cells u_image_rom/image_memory_reg]
           ```
        3. **如何找到确切的路径?** 运行综合后，打开综合设计(Open Synthesized Design)，在Tcl Console中输入 `get_cells -hierarchical *image_memory*`，Tcl命令窗口会返回ROM的完整层级路径，将其复制到 `get_cells` 的参数中即可。
        4. **路径注意**: `INIT_FILE` 的路径是相对于 **XDC文件所在位置** 的相对路径。如果 `boolean_board.xdc` 在 `constraints/` 目录下，那么 `../sim/image_data.mem` 是正确的路径。

    *   **方法二：通过GUI设置 (用于验证或快速测试)**
        此方法不便于版本控制，但很直观。
        1. **运行综合**并等待其成功完成。
        2. 在 **Flow Navigator** 中，点击 **Open Synthesized Design**。
        3. 打开**原理图 (Schematic)**。在原理图中，双击顶层模块 `top`，然后找到并双击 `u_image_rom` 实例，深入其内部。
        4. 你会看到一个RAM/ROM块，其名称通常是 `image_memory_reg`。**这便是推断出的ROM实例**。
        5. 右键点击这个 `image_memory_reg` 块，选择 **Properties**。
        6. 在弹出的属性窗口中，找到 `INIT_FILE` 参数，将其值设置为你的 `.mem` 文件的路径。Vivado会自动计算相对路径。

4.  **运行综合**:
    *   重新运行综合。在综合过程中，Vivado会读取 `.mem` 文件的内容，并将其作为初始化数据生成一个BRAM。你可以在综合日志中看到相关信息，确认ROM被正确初始化。

通过以上步骤，`image_rom` 模块就可以在FPGA上作为一个预初始化的ROM工作，为处理流水线提供测试图像。

## 7. 设计考量

-   **分辨率**: 设计固定为640x480。提高分辨率需要进行重大修改，特别是直方图均衡化模块中的帧缓存大小，并且可能会超出Spartan-7 50T器件的BRAM容量。
-   **Retinex简化**: `retinex_simple.v`模块并非一个功能完整的MSRCR实现。一个完整的实现需要多个大规模的高斯模糊，这非常消耗资源。此版本仅作为演示数据流的占位符。
-   **帧缓存**: 直方图均衡化模块使用一个单端口BRAM作为帧缓存，这会给视频流水线带来一帧的延迟。