# Shrinkle 缩一缩

一个简单直接的 macOS 照片压缩小工具：把手机拍的照片拖进去，一键压到原来大小的 **20%**（可调），统一转成 JPG。

## 功能

- **按目标体积压缩**：默认压到原文件的 20%，滑块可调 5%–90%。先降低 JPG 质量；质量降到会明显变差时，改为等比例缩小尺寸，尽量保住画质。
- **自动转成 JPG**：HEIC / PNG / TIFF / WebP 等都转成兼容性最好的 JPG，自动按照片方向转正，透明背景铺白。
- **可选的快速裁剪**：点每行的裁剪图标或双击打开，拖动框移动、拖四角缩放，支持自由、原比例、1:1、4:3、3:4、16:9、9:16。不点就完全不影响压缩。
- **批量处理**：可以拖入多张照片或整个文件夹，也可以拖到 Dock 图标上，多张照片并行处理。
- **不动原图**：输出为 `原文件名_compressed.jpg`，保存在原图旁边或你选择的文件夹。
- **隐私**：保留拍摄时间、相机型号等 EXIF 信息，去掉 GPS 位置。

## 安装

在[发布页面（Releases）](../../releases)下载 `Shrinkle.zip`，解压后把 `Shrinkle.app` 拖到「应用程序」文件夹。

> App 没有经过 Apple 公证，第一次打开时请**右键点 App → 打开**，再确认一次即可。

要求 macOS 13 或更高版本，支持 Apple Silicon 和 Intel。

## 从源码构建

需要安装 Xcode（或 Command Line Tools）：

```bash
git clone https://github.com/YuanF-661/Shrinkle.git
cd Shrinkle
./build.sh        # 生成 build/Shrinkle.app
```

## 项目结构

```
Sources/
  App.swift          App 入口
  ContentView.swift  主界面：列表、拖放、底部操作栏
  CropView.swift     裁剪界面
  Model.swift        状态管理、批量压缩调度
  Compressor.swift   读取 / 裁剪 / 按目标体积编码 JPG（ImageIO）
Resources/Info.plist
scripts/make_icon.swift  生成 App 图标
build.sh                 编译 + 打包 .app
```

纯 SwiftUI + ImageIO，没有任何第三方依赖。

## 开源许可

本项目采用 [MIT 许可证](LICENSE)，可以自由使用、修改和分发。
