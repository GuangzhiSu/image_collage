# 拼图 · Pintu for iPhone

[![Build iPhone App](https://github.com/GuangzhiSu/image_collage/actions/workflows/ios.yml/badge.svg)](https://github.com/GuangzhiSu/image_collage/actions/workflows/ios.yml)

参考美图秀秀拼图操作流程的原生 iPhone App，使用 SwiftUI + UIKit，支持 iOS 17.0 及以上。无广告、无水印、无第三方运行时依赖；界面和图标由本项目实现。

## 功能

- 从系统相册按顺序选择 1–12 张照片，可继续添加。
- 根据数量提供模板：主图与小图、均匀网格、上下或左右排列、错落分区。
- 比例：3:4、1:1、4:3、9:16、16:9、4:5、2:3。
- 竖向长图、横向拼接，按照片原始比例排列。
- 点击照片后拖动、双指缩放、滑块缩放、旋转、镜像或重置裁剪；取消不修改原裁剪。
- 长按缩略图可向前、向后移动或移除照片。
- 调整间距、圆角和六种背景色。
- 高清 JPEG，最长边 2048 / 3072 / 4096 像素，保存到相册或通过系统分享存储到文件。
- 内置示例；包含 iCloud 下载失败、格式不支持、相册权限被拒绝等错误提示。

所有照片在设备上处理，不会上传。选图器只提供你选中的照片，保存时才请求添加照片权限。支持系统可解码的 JPEG、PNG、HEIC 等静态图；Live Photo 使用静态帧。临时文件不作为持久草稿，请在退出前保存拼图。

## Windows 下载并安装

1. 打开 [Actions → Build iPhone App](https://github.com/GuangzhiSu/image_collage/actions/workflows/ios.yml)。
2. 进入最新一次绿色成功的记录；也可使用 **Run workflow** 手动构建。
3. 在底部 **Artifacts** 下载 **Pintu-iPhone-unsigned**，解压得到 **Pintu-unsigned.ipa**。下载时需要登录 GitHub。
4. 使用 Windows 上的 Sideloadly，或已配置好的 AltStore / SideStore 为 IPA 签名，再安装到 iPhone。

**未签名 IPA 不能直接点击安装。** Actions 不需要你的 Apple ID、密码或证书。个人签名的续签由你使用的侧载工具管理；TestFlight / App Store 发行需要单独配置开发者证书，本项目不自动发布到商店。

请从 Actions 运行页面进入下载，不要手动拼接 Artifact URL。IPA 保留 30 天，过期后重新运行构建即可。每次 main 分支的代码推送都会自动构建。**Pintu-preview-and-tests** 包含测试日志、结果及成功生成时的模拟器截图；截图是可选步骤，不阻塞 IPA。

## macOS / Xcode 开发

```sh
brew install xcodegen
python3 scripts/generate_assets.py
xcodegen generate
open Pintu.xcodeproj
```

在 Xcode 的 Signing & Capabilities 选择你的 Team 后运行到真机。模拟器无需签名。工程以 project.yml 为源，Xcode 工程、Info.plist 和图标在生成步骤中创建。

## 结构和测试

| 文件 | 功能 |
| --- | --- |
| CollageGeometry.swift | 模板、长图比例、裁剪坐标和画布尺寸 |
| PhotoStore.swift | 系统选图、临时文件、EXIF 方向、缩略图 |
| CollageModel.swift | 导入、编辑状态、排序和导出 |
| ContentView.swift / CropEditor.swift | 主界面、单图裁剪 |
| CollageRenderer.swift | 高清绘制、相册保存 |
| CollageAppTests/CollageTests.swift | 布局铺满与无重叠、裁剪无空白、极端比例、导出像素测试 |
| .github/workflows/ios.yml | 模拟器测试、真机编译、IPA 打包及可选截图 |

原始大图逐张读取，避免同时解码十二张全分辨率照片。4096 是生成图片的最长边；放大低分辨率原图不会增加细节，多张长图的单张有效分辨率也会受最长边限制。

真机验收：首次选图、iCloud 照片、HEIC 和旋转照片、1/3/12 张布局、裁剪确认/取消、排序与删除、最大间距、允许/拒绝保存权限、系统分享和存储到文件。自动测试不代替真机权限、触摸交互和侧载验证。
