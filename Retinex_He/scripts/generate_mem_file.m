% MATLAB Script: generate_mem_file.m
% Description: Converts a standard image file (JPG, PNG, etc.) to a .mem file
%              for FPGA simulation.
% Author: Trae AI

clc;
clear;
close all;

% --- 用户配置 ---  这里会将输入的图像进行处理，压缩成设定大小，设定像素的图片。
IMAGE_WIDTH = 640;          % 图像宽度 (必须与FPGA设计中的H_ACTIVE匹配)
IMAGE_HEIGHT = 480;         % 图像高度 (必须与FPGA设计中的V_ACTIVE匹配)
INPUT_IMAGE_FILE = 'noodles.jpg'; % 输入图片文件名 (将此文件放在与脚本相同的目录下)
OUTPUT_MEM_FILE = 'image_data.mem'; % 输出的.mem文件名

% --- 1. 读取并预处理图像 ---

% 检查输入文件是否存在
if ~exist(INPUT_IMAGE_FILE, 'file')
    error('输入图片文件 "%s" 不存在。请将图片文件放在此脚本所在的目录。', INPUT_IMAGE_FILE);
end

% 读取图像
[img, map] = imread(INPUT_IMAGE_FILE);

% 如果是索引图像，则转换为RGB图像
if ~isempty(map)
    img = ind2rgb(img, map);
end

% 调整图像尺寸以匹配FPGA设计
fprintf('正在将图像尺寸调整为 %d x %d ...\n', IMAGE_WIDTH, IMAGE_HEIGHT);
img_resized = imresize(img, [IMAGE_HEIGHT, IMAGE_WIDTH]);

% 确保图像是uint8类型
if ~isa(img_resized, 'uint8')
    img_resized = uint8(img_resized * 255);
end

% 显示调整后的图像以供预览
figure;
imshow(img_resized);
title(sprintf('调整后的图像 (%d x %d)', IMAGE_WIDTH, IMAGE_HEIGHT));

% --- 2. 将RGB数据转换为十六进制格式 ---

% 打开（或创建）输出文件
fid = fopen(OUTPUT_MEM_FILE, 'w');
if fid == -1
    error('无法创建或打开输出文件 "%s"。', OUTPUT_MEM_FILE);
end

fprintf('正在将图像数据写入 "%s" ...\n', OUTPUT_MEM_FILE);

% 逐像素处理并写入文件
for y = 1:IMAGE_HEIGHT
    for x = 1:IMAGE_WIDTH
        % 获取R, G, B分量
        R = img_resized(y, x, 1);
        G = img_resized(y, x, 2);
        B = img_resized(y, x, 3);
        
        % 将24位RGB值合并并格式化为6位十六进制字符串
        hex_val = sprintf('%02x%02x%02x', R, G, B);
        
        % 写入文件，每行一个像素值
        fprintf(fid, '%s\n', hex_val);
    end
end

% 关闭文件
fclose(fid);

fprintf('成功！\n');
fprintf('输出文件 "%s" 已生成，包含 %d 个像素值。\n', OUTPUT_MEM_FILE, IMAGE_WIDTH * IMAGE_HEIGHT);