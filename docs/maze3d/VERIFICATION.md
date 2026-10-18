# 0.4.0 验证范围

2026-10-17 至 2026-10-18，基于已发布的 0.3.0 提交 `db37d6e`，在 `codex/pipi-3d-preview` 发布布朗与庭院美术更新。

## 本地检查

Godot 4.6.3、Linux Compatibility / Mesa 软件渲染环境。

| 检查 | 结果 | 覆盖范围 |
| --- | --- | --- |
| MODEL | 545 项通过 | 三章连通、固定布局、目标可达、3 / 5 / 7 处挑战、两侧安全落脚点及高处星星数量 |
| SCENE | 666 项通过 | 真实连续移动和跳跃完成三章全部灯塔、12 颗星星和出口；碰撞、提示、体力、暂停、后台、存档及星级 |
| JUMP | 56 项通过 | 起跳、空中拒绝重复跳、落地缓冲、离边宽限、空中暂停、石栏和断桥跨越、落下保留进度、高处拾取、旧存档安全恢复、首页旋转与缩放、零相对位移的触屏事件 |
| CHARACTER | 36 项通过 | 14 个关节的连接层级、头和衬衫厚度、跑动时颈部与头部重叠、肘膝屈伸、腾空与落地变化、四表情互斥、眨眼、首页表情保持、真实拾星触发开心 |
| RENDER | 9 项通过 | 实际画面中的触屏旋转、表情切换、回正、滚轮、开始按钮、三指移动/环顾/跳跃、点灯和结算 |
| 动作与表情画面 | 通过 | Godot 渲染四种表情、左右步态、起跳和接地姿态的对照图，逐项检查头身和肢体连接 |
| Linux 导出成品 | 通过 | 在工程外静音运行嵌入资源的导出程序，启动至首页；此项不验证音频设备 |
| Android 包检查 | 通过 | v2/v3 签名、16 KiB 对齐、包名、0.4.0 / versionCode 400、三种 ABI、仅震动权限；提取启动器图标检查 |

合计 1,312 项规则与交互断言通过。最终自动检查日志没有脚本错误、失败断言或资源加载错误。软件显示服务的 V-Sync 不支持提示不影响画面检查。

截图位于 `docs/maze3d/screenshots/`：首页正面/侧面/背面/俯视/开心、跳跃、玩法、引路、暂停、点灯、出口、结算、石栏、断桥及动作表情对照图。截图脚本为构图调整位置；连续三章通关测试另行使用真实移动，不以传送到目标替代通关验证。

复现：`bash scripts/maze3d/test.sh`。有显示服务时运行 `godot --fixed-fps 60 --audio-driver Dummy --path maze3d --script res://tests/capture.gd -- /absolute/output`，动作对照图使用 `res://tests/art_capture.gd`。构建与安装包校验入口为 `scripts/maze3d/build.sh`。

## Android 与发布门禁

本地没有 Android 模拟器或实体手机。发布工作流 `.github/workflows/maze3d.yml` 会在 Android 10 x86_64 / ANGLE 中安装本次签名 APK，操作首页表情和旋转、移动、镜头、地图、暂停、画质、返回键、后台及存档恢复，并检查渲染帧和崩溃日志。全部门禁通过后才允许公开 Release；本次流水线链接附在 Release 正文，实际 Android 结果与截图收录在 `Pipi-Maze-Ruins-Verification.zip`。

未进行实体手机帧率、功耗、触感和多机型覆盖测试；桌面软件渲染及模拟器结果不代表所有手机表现。

## 交付

- `Pipi-Maze-Ruins-0.4.0.apk`：Android 安装包。
- `Pipi-Maze-Ruins-0.4.0-Source.zip`：完整工程、生成脚本和可编辑模型。
- `Brown-Character-0.4.0.zip`：布朗模型、源文件、四视图和结构说明。
- `Pipi-Maze-Ruins-3D-Models.zip`：全部独立 GLB 与 Blender 模型库。
- `Pipi-Maze-Ruins-Verification.zip`：构建、自动检查及 Android 运行证据。
- `Brown-App-Icon-0.4.0.png`：原尺寸生成图标，来源见 ART.md。
- `SHA256SUMS.txt`：本次实际发布文件的校验和；以 Release 中的文件为准。

Android 包名 `com.alex.pipimaze.ruins` 和既有演示签名不变，可覆盖安装 0.3.0 并保留本机存档。
