# Pipi Maze · 灯火遗迹 Unity 试玩版

基于 `apkGo/main` 的 Godot 0.5.0（`8989d6450f9a579c4662f862278fdc5567e256bd`）移植；旧舒尔特 Unity 原型保存在独立仓库。本项目使用 Unity **6000.0.60f1**、内置渲染管线和 UGUI。

四章 JSON、布朗刚性角色层级、场景模型和音效来自当前 `maze3d/`。运行 `python3 scripts/unity/sync-assets.py` 同步关卡、原始 GLB 和显式导入元数据；`.pglb` 与源 GLB 的字节完全相同。编辑器导入器保留节点、网格、材质、UV、嵌入纹理，并将 Z 轴反射到 Unity 坐标。所有关卡位置和旋转对应反射。

## 操作

左摇杆移动，右侧拖动转镜头；点击跳跃，按住冲刺，靠近灯塔/出口互动。三座灯塔点亮后进入出口；星星可选收集。支持引路灯、地图、暂停、自动存档、声音及 FPS 开关；首页可拖动查看角色，并选择全部四章试玩。

桌面调试使用 WASD/方向键、空格跳跃、Shift 冲刺、E 互动、H 引路、M 地图、Esc 暂停。

## 构建与验证

`dotnet run --project tests/unity/Core.csproj` 检查实际关卡路径、坐标映射、跳跃能力及无效数据拒绝。打开 Unity 项目后，通过菜单 `Pipi Maze/Configure Unity preview` 创建入口场景，通过 `Pipi Maze/Build Android preview` 构建。

Actions 从仓库 Secrets 读取 Unity 激活信息，在实际引擎中验证导入并构建 ARM64 + x86_64 APK，随后签名、检查包名/ABI/对齐，运行 Android 模拟器交互冒烟，再发布预览。构建和冒烟失败时不发布 APK。

预览包名 `com.alex.pipimaze.unitypreview`，可与现有 Godot 版并存；存档独立，当前不导入 Godot 存档。公开演示签名沿用 `signing/`。布朗及相关美术的原有权利说明继续适用，参见 `docs/maze3d/BROWN.md`、`docs/maze3d/ART.md`；字体许可复制到 Resources/Fonts。
