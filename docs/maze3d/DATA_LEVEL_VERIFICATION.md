# 0.6.0 森兰寻光验证

2026-10-19。Godot 4.6.3 / Blender 4.3.2，版本0.6.0、Android versionCode 600。原0.5.0验证保留在 [DATA_LEVEL_0_5_VERIFICATION.md](DATA_LEVEL_0_5_VERIFICATION.md)。本页与 Release 中的验证附件对应本次新增第五章。

## 本地实际执行

| 检查 | 结果 | 覆盖 |
| --- | --- | --- |
| DATA | 171项通过 | 五章数据、前四章布局与目标顺序指纹、34个真实GLB、源文件、FPS偏好、森兰桥面支撑和落水复位、无效表面资源拒绝 |
| MODEL | 1182项通过 | 五章通路连通、目标可达、提示路径、11处新挑战与安全落脚点 |
| SCENE | 1228项通过 | 五章连续物理移动、跳跃、全星收集、点亮灯塔、进入出口、暂停和存档恢复 |
| JUMP | 78项通过 | 五章石栏、断桥、高处拾取、落水复位及原有起跳/暂停行为 |
| CHARACTER | 36项通过 | 14个动作节点、角色动作与表情 |
| 导出成品资源包 | 26项通过 | 在工程外加载Linux成品，五章JSON、34个GLB、角色节点和FPS开关 |
| Blender源文件 | 34个根节点通过 | 四个源库中能找到目录声明的稳定根节点，森兰根节点记录上游提交 |
| 手工导出 | 通过 | 从适配源库按ID导出码头和岛台，未覆盖源库 |

`bash scripts/maze3d/test.sh` 合计 **2695项检查通过**，保留严格的脚本错误与资源加载错误门禁。新章单独连续通关也已完成。测试发现过长椅阻挡通路，已移动至步道边缘；最终通关使用实际角色物理移动，不通过传送代替。

使用既有包名和演示证书导出Android安装包，检查版本、v2/v3签名、16KiB对齐与权限；没有新增联网权限。源码中前四章JSON未修改。第五章24颗星星、11处挑战、6颗高处星星。

## 渲染与设备范围

Sunland渲染脚本通过真实触摸选择五个章节、启动第五章、暂停、FPS开关和来源页；截图另行调整角色与镜头用于构图。运行时画面在Linux/Xvfb/Mesa llvmpipe中审阅，检查了木栈道、码头、营地、展亭、草岸与地图，修正了缺少支撑的景观与水面绘制。

本地没有Android模拟器与实体手机。本次发布工作流另行构建并安装本次APK，执行触控移动、镜头、地图、暂停、FPS偏好、第四章与第五章启动、冷启动恢复以及来源页检查；只有完整工作流通过后才发布。Android实际结果和本次截图见Release中的 `Pipi-Maze-Ruins-Verification.zip` 及流水线链接。旧包的Android证据不计入本次验证。软件渲染和模拟器FPS不代表手机性能。

新画面：

- [五章选择](screenshots/17-five-chapters.png)
- [森兰红栏星桥](screenshots/18-sunland-crossing.png)
- [湖畔营地](screenshots/19-sunland-camp.png)
- [展亭](screenshots/20-sunland-pavilion.png)
- [关卡地图](screenshots/21-sunland-map.png)
- [湖区全景](screenshots/22-sunland-overview.png)
- [场景来源](screenshots/23-sunland-credits.png)

素材改编范围、署名、源库与复现见 [SUNLAND.md](SUNLAND.md)。
