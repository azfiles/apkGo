# 0.3.0 验证范围

2026-10-17，基于 `codex/pipi-3d-preview` 的 `5e69f7d`（0.2.1 布朗角色版）继续开发；本地工作分支 `codex/pipi-3d-jump`。本次结果不代表已经公开发布 GitHub Release。

## 已完成的本地检查

Godot 4.6.3、Linux Compatibility / Mesa 软件渲染环境。

| 检查 | 结果 | 覆盖范围 |
| --- | --- | --- |
| MODEL | 545 项通过 | 三章连通、固定布局、目标可达、3 / 5 / 7 处跳跃挑战、两侧安全落脚点、难度范围和高处萤光数量 |
| SCENE | 666 项通过 | 真实连续移动和跳跃完成三章全部灯塔、12 枚萤光及出口；碰撞、提示、体力、暂停、后台、原有存档及星级流程 |
| JUMP | 55 项通过 | 空格起跳、空中拒绝二段跳、落地缓冲、离边宽限、空中暂停/继续、三章石栏阻挡与跨越、实际断桥掉落与跨越、掉落保留进度、高处拾取、旧存档安全恢复、展示旋转/缩放及焦点切换 |
| RENDER | 8 项通过 | 实际渲染环境中的首页触屏旋转、回正按钮、鼠标滚轮、开始按钮、三指同时移动/环顾/跳跃，以及真实点灯和结算状态 |
| Linux 导出成品 | 通过 | 在工程外运行嵌入资源的可执行文件，启动至首页，无脚本或资源错误 |
| Android 包检查 | 通过 | 构建、v2/v3 签名、16 KiB 对齐、包名、0.3.0 / versionCode 300、三种 ABI、仅震动权限 |

合计 1,274 项规则与交互断言全部通过。测试脚本退出码均为 0，最终日志没有 `SCRIPT ERROR`、`ERROR:` 或失败断言。

截图位于 `docs/maze3d/screenshots/`：首页正面/侧面/背面/俯视、跳跃、玩法、引路、暂停、点灯、出口、结算、石栏和断桥。截图脚本可为构图调整位置；连续三章通关测试另行使用真实移动，不以传送到目标替代通关验证。

复现入口：`bash scripts/maze3d/test.sh`，以及有显示服务的环境下运行 `godot --fixed-fps 60 --audio-driver Dummy --path maze3d --script res://tests/capture.gd -- /absolute/output`。构建与安装包校验入口为 `scripts/maze3d/build.sh`。

## 交付

- APK：`build/maze3d/release/Pipi-Maze-Ruins-0.3.0.apk`
- APK SHA-256：`791226f05339ebe63842a476817504fc88a08e54b1ed4f1d33da994345b5e0bb`
- 完整工程：`build/maze3d/release/Pipi-Maze-Ruins-0.3.0-Source.zip`
- 验证日志：`build/maze3d/release/Pipi-Maze-Ruins-Verification.zip`
- Linux 可执行文件：`build/maze3d/output/Pipi-Maze-Ruins.x86_64`

Android 包名和演示签名沿用 0.2.x，可覆盖安装。独立布朗模型未更改，模型包仍使用 0.2.1 的版本名。

## 本次未完成的设备检查

本次环境没有可用的 Android 模拟器或实体手机，因此未运行 0.3.0 的 Android 安装与操作冒烟测试；未验证手机触感、帧率、功耗或机型覆盖。桌面软件渲染帧率不代表手机性能。

`.github/workflows/maze3d.yml` 保留 Android 10 x86_64 / ANGLE 的安装和操作门禁，并已更新 0.3.0 包路径；只有后续流水线的全部步骤通过才公开发布。不能将先前版本的 Android 运行结果当作 0.3.0 的设备验证。
