# Pipi Maze · 花园捉迷藏

Godot 4.6.3 制作的 2.5D 迷宫新作首版，版本 `0.1.0`。沿用 `pipi-maze` 的布朗、屁屁侦探和小考拉原图，以正交三维花园和纸片角色重新设计探索体验。

三个完整关卡：晨光花园、池畔回廊、暮色林地。引导布朗穿过树篱，到达小考拉所在的尽头；每关另有三枚可选自然印记。没有时间限制，支持提示、暂停、分关进度保存与最佳发现记录。

[Android 试玩包](https://github.com/azfiles/apkGo/releases/download/maze-v0.1.0/Pipi-Maze-Garden-0.1.0.apk) · [Release 与完整工程](https://github.com/azfiles/apkGo/releases/tag/maze-v0.1.0)

![游戏首页](../docs/maze/screenshots/01-home.png)

## 运行与操作

用 **Godot 4.6.3** 导入本目录的 `project.godot`，按 F6 / F5 运行。命令行：

```bash
godot --path maze-godot
```

- 点「开始探险」，或在首页按 Enter / Space。
- 点击浅色小路：按合法路线走到目标位置；点击树篱会提示。
- WASD / 方向键 / 右下方向盘：按屏幕方向连续移动，真实碰撞阻止穿墙。
- H 或「给我一点提示」：显示接下来的五格路线，数秒后消失。
- Esc / P / Android 返回键：暂停与继续。暂停菜单支持重新开始和回到首页。
- 抵达小考拉即可完成；收集零枚 / 一至两枚 / 三枚印记分别获得一 / 二 / 三颗星。

进度、音效设置和各关最佳印记数保存在本机 Godot `user://garden-progress.json`。暂停、切换后台和关闭窗口时保存；重新打开可继续各关上一次未完成的探索。损坏或非法位置的存档会安全回到入口。

## 成品与构建

仓库根目录运行：

```bash
bash scripts/maze/test.sh
# 安装 Godot 4.6.3 与对应导出模板后：
export JAVA_HOME=/path/to/jdk-17
export ANDROID_SDK_ROOT=/path/to/android-sdk
bash scripts/maze/build.sh
python3 scripts/maze/package.py
```

`build/maze/output/` 输出签名 APK、嵌入资源的 Linux x86_64 可执行文件及 SHA-256。Android 使用独立包名 `com.alex.pipimaze.garden`，Android 7.0+、OpenGL ES 3.0，ARM64 / ARMv7 / x86_64，横屏运行。使用本仓库现有公开演示签名。游戏离线运行，无账号、联网或存储权限。

`package.py` 另行生成完整工程 ZIP 与 Linux ZIP；源码包包含素材、测试、构建脚本、演示签名和设计文档，不包含 Godot 导入缓存。验证记录见 [交付验证](../docs/maze/VERIFICATION.md)。

`maze-godot.yml` 在推送到主分支时构建并验证，全部通过后将当前版本发布为 `maze-v0.1.0` 试玩 Release。公开附件汇集于 `build/maze/release/`，已经发布的同版本保持不变。

导出模板可用 `scripts/maze/setup.sh` 安装。运行完该脚本后，将它打印的 `GODOT`、`XDG_DATA_HOME` 设置用于构建。`export_presets.cfg` 包含 Android / Linux 两套预设。

设计依据见 [设计文档](../docs/maze/DESIGN.md)，复用原图与许可证见 [素材来源](ASSET_SOURCES.md)。桌面场景和物理交互已自动验证；当前版本的 Android APK 完成构建、签名和包内容检查，尚未经过 Android 真机体验验证。

## 工程结构

- `scripts/main.gd`：界面、输入、暂停、存档和关卡切换。
- `scripts/garden_world.gd`：正交相机、三维花园、角色碰撞、点击寻路及拾取反馈。
- `scripts/maze_model.gd`：格子规则、BFS 路径、提示、完成判断与存档校验。
- `assets/levels.json`：三个固定原创布局；`#` 为树篱，`S` 为入口，`G` 为小考拉，`*` 为自然印记。
- `tests/`：规则测试、真实场景交互测试、渲染截图脚本。

新增文字后可用 `python3 scripts/maze/subset-font.py` 更新随包中文字体。运行源码测试和重新导出即可验证改动。
