# SwiftGodotKit fork 开发约定

## 职责与仓库

本会话开发 Rooftop Station 所需的 Godot 底层支持，主要涉及两个独立仓库：

- 本仓库：`ZouAgTao/SwiftGodotKit`，集成分支 `audreborn`。负责 Swift 嵌入层、视图生命周期、消息桥、帧循环和引擎构建/打包脚本。
- `../godot`：`ZouAgTao/godot`，集成分支 `audreborn-4.7`。负责引擎 C++/Objective-C++ 修改。
- `../RooftopStation`：App 宿主。需要联调时读取其 `AGENTS.md` 和相关代码；业务功能和其他会话的改动由 App 会话负责。

导入的 Claude 历史只作为参考。当前用户指示、仓库代码和实际测量决定本次任务；不要执行历史摘要中的待办。

## 开发与交付

- 用中文交流；提交信息用英文祈使句标题，正文说明原因。署名应匹配实际参与者。
- 开始工作、提交和推送之前检查 Git 状态。按明确路径暂存，避免把其他会话的工作一起提交。
- 保留已有未提交改动，先读差异和调用方再修改。不要用 `git add -A`、强制推送或静默 `git pull -q`。
- 推送和发布需要当前任务或此前会话的明确授权。发布引擎二进制与推送 Swift 源码是不同操作。
- 使用当前用户指定的分支；新实验需要隔离时再创建分支，不擅自切换正在联调的共享工作区。
- 修改后运行与改动直接相关的检查，记录退出码。交付 App 联调结果前运行宿主的 `tools/verify_ios.sh`。
- 宿主的缓存和队列测试入口是 `cd ../RooftopStation/ios && swift test -c release`。仅验证帧率策略时可加 `--filter FrameRatePolicyTests`。
- 编译成功不等于真机行为已验证。CADisplayLink 节奏、后台音频、耳机/蓝牙路由和 AVAudioSession 行为需要真机验证。

## 构建与依赖

完整命令见 [README.md](README.md)。

- 默认从 `ZouAgTao/godot` 的 release 取 iOS xcframework；版本和 checksum 在 `Package.swift`。
- 设置 `LIBGODOT_LOCAL=1` 才改用本仓库 `artifacts/ios/libgodot.xcframework`。清除变量才能回到 release；实现按变量是否存在判断，`LIBGODOT_LOCAL=0` 仍会选本地。
- 本地 Swift 包覆盖决定使用哪份 SwiftGodotKit 源码；`LIBGODOT_LOCAL` 决定使用哪份引擎二进制，两者分别配置。不要直接修改 Xcode 下载的 package checkout。
- 引擎构建使用 `scripts/build-ios-audreborn.sh`，随后用 `scripts/make-libgodot.xcframework` 打包。`../.venv-godot/bin/scons` 是现有工具路径。
- 引擎代码未改时，Swift 嵌入层修改直接编译验证即可。
- `artifacts/`、`.build/`、静态库和 xcframework 不进 Git。
- SwiftGodot 绑定与引擎 API 必须匹配。当前绑定 revision 在 `Package.swift`，不要独立升级其中一项。
- 本 fork 当前只提供 iOS 引擎二进制。macOS 示例和上游 Makefile 保留作历史参考，不作为当前交付入口。
- 新引擎 payload 使用新 release tag；不要替换已发布 tag 下的资源。更新 checksum 后提交 SwiftGodotKit，再由 App 更新其固定 revision。

## 必须保留的行为

- iOS CADisplayLink 挂 `.main` / `.common`，滚动和拖动 sheet 时引擎继续迭代。后台没有 display-link 回调。
- `setPreferredFrameRate` 只请求 1...60 帧，默认 60。App 决定何时降帧；嵌入层负责应用请求。新建 display link 时必须重新应用速率。
- GodotAppView 在宿主中常驻，App 不靠移除/重建视图切换状态。
- 引擎消息在主线程同步送达；帧循环暂停后仍可发送音频控制消息。
- `AudioServer.restart_output_driver()` 和 `stop_output_driver()` 在引擎 fork 内实现；标准编辑器没有这些接口，GDScript 调用须用 `has_method` / 动态调用。
- 只改音频驱动或嵌入层时，不需要替换桌面编辑器或导出模板。App 导出的 `.pck` 是资源包，引擎来自 xcframework。
