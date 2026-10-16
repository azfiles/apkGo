# Pipi Maze · 灯火遗迹 0.2.0

原生 Godot 4.6.3 / OpenGL ES 3.0 第三人称 3D 迷宫体验版。三个完整关卡：初光庭院、回声回廊、星眠深境。

带着小熊探险家在遗迹里自由探索，**靠近并点亮三座灯塔，再走进归途之门**。每章有 12 枚可选萤光，收集 6 枚获得双星，全部收集获得三星。没有失败倒计时。

## 操作

- 横屏游玩。左下区域按住拖动：动态摇杆移动；右侧空白区域拖动：环顾视角。
- 按住冲刺：消耗体力快速移动，松开后恢复。
- 靠近灯塔，点击「点亮灯塔」；出口亮起后点击「走进出口」。
- 「引路灯」显示通向最近未点亮灯塔的六格合法路线，持续 8 秒，充能 13 秒；灯塔全部点亮后指向出口。
- 右上角地图展示已探索区域，查看地图时暂停。支持回正镜头。
- 暂停中可调声音与震动、精致/流畅画质、镜头灵敏度。
- 桌面：WASD/方向键移动，拖动右侧或 Q/R 转向，Shift 冲刺，E 互动，H 引路，C 回正，M 地图，Esc 暂停。

每 8 秒、点灯、暂停及转入后台时自动保存；首页「继续寻光」恢复未完成探索。重新开始会保留最佳星级、收集与用时记录。三个章节均可从首页直接体验。

## 设计与资源

- 透视跟随镜头和真实胶囊碰撞；镜头与角色之间的遮挡石墙局部消隐，避免角色被墙遮住或镜头挤进头部。
- 原创小熊探险家：完整 3D 网格、背包、围巾、提灯及可独立运动的四肢。运行时驱动走路、呼吸与围巾动画。
- 11 个独立 glTF 模型：角色、3 种石墙、灯塔、晶体、归途门、路灯、2 种树、草。
- Blender 原文件位于仓库 `model-source/maze3d/pipi_ruins_library.blend`，生成脚本 `scripts/maze3d/model_assets.py`。模型可单独导入 Blender、Godot 或其他支持 glTF 的引擎。
- 多实例合批、可关闭阴影及粒子、三盏最近路灯局部照明。兼容渲染器适合移动设备；真实帧率取决于设备，未作真机帧率承诺。
- 全部游戏模型、图标、声音均为本次制作。字体和引擎许可证随包附带；未使用第三方游戏角色贴图。

## 运行与构建

Godot 4.6.3 导入本目录的 `project.godot` 即可运行。仓库根目录：

```bash
bash scripts/maze3d/test.sh
export JAVA_HOME=/path/to/jdk-17
export ANDROID_SDK_ROOT=/path/to/android-sdk
# 安装匹配的 Godot 4.6.3 导出模板；也可以使用 scripts/maze/setup.sh
bash scripts/maze3d/build.sh
python3 scripts/maze3d/package.py
```

Android 包名 `com.alex.pipimaze.ruins`，Android 7.0+、OpenGL ES 3.0，ARM64 / ARMv7 / x86_64。独立包名可以和旧版花园 Demo 共存。离线运行，仅申请震动权限。使用仓库既有公开演示签名，只用于体验版分发。

`build/maze3d/output/` 生成已签名 APK 与 Linux 程序；`build/maze3d/release/` 生成完整交付。复现模型需 Blender 4.3+；复现字体子集需 fontTools 和 Noto CJK 字体，游戏运行不需要 Blender。

验证范围和限制见 `docs/maze3d/VERIFICATION.md`。
