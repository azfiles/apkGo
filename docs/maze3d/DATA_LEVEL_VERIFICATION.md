# 0.5.0 帧率与数据关卡验证

2026-10-18，基于 `357d34d` 的本地开发改动。发布版本为 0.5.0 / versionCode 500，保留既有包名与签名；发布工作流在 Android 验证通过后上传附件并公开 Release。旧版验证记录保留在 [VERIFICATION.md](VERIFICATION.md)。

## 自动检查

Godot 4.6.3、Blender 4.3.2，Linux Compatibility / Xvfb / Mesa llvmpipe 软件渲染。

| 检查 | 结果 | 覆盖 |
| --- | --- | --- |
| DATA | 126 项通过 | JSON 合约与错误输入、前三章通道和目标顺序指纹、23 个真实 GLB、Blender 源文件、14 个角色节点、FPS 偏好持久化、桥面支撑与落水复位 |
| MODEL | 866 项通过 | 四章通路连通、目标可达、稳定布局、跳跃边界、3 / 5 / 7 / 9 处挑战与两侧落脚点 |
| SCENE | 994 项通过 | 四章以连续物理移动和跳跃点亮全部灯塔、收集 12 / 12 / 12 / 18 颗星星、进入出口；碰撞、体力、提示、暂停、存档、地图和后台 |
| JUMP | 67 项通过 | 四章石栏与断桥跨越、高处拾取、安全复位，以及起跳缓冲、离边宽限、空中暂停和角色预览 |
| CHARACTER | 36 项通过 | 原有节点层级、动作连接、表情和拾取反馈 |
| STARBRIDGE RENDER | 5 项通过 | 实际触摸选择第四章、开始、暂停和 FPS 开关；输出七幅实际渲染图 |
| 导出资源包 | 22 项通过 | 在工程外用同版本 Godot 读取 Linux 成品内嵌资源包，实例化四章、23 个模型、角色节点、新场景和 FPS 开关 |
| Blender 源合同 | 23 个根节点通过 | 三个 `.blend` 中均能找到资源目录声明的源根节点 |
| 手工导出 | 通过 | 从新库导出石桥、从旧库导出 `wall_1`、从角色源文件导出布朗；未覆盖源文件 |
| Android 构建与包检查 | 通过 | v2/v3 签名、16 KiB 对齐、原包名、ARM64/ARMv7/x86_64、仅震动权限；包中实际存在章节目录、四章 JSON 和 23 个模型定义 |

`scripts/maze3d/test.sh` 合计 **2,089** 项检查通过；另有 5 项界面渲染检查及 22 项导出资源检查。最终检查日志无脚本错误和资源加载错误。

场景验证期间发现并修复两处真实摆放问题：拱门移入桥面，避免堵住沿岸通路；出口采用末端入口，避免从侧面接近时碰到门柱。最终四章通关检查使用真实移动，不通过传送代替路线验证。

## 画面与边界

- [四章首页](screenshots/11-four-chapters.png)
- [星桥与水道](screenshots/12-starbridge.png)
- [喷泉中庭](screenshots/13-fountain-court.png)
- [暂停菜单与帧率开关](screenshots/14-fps-on.png)
- [水道与桥梁地图](screenshots/15-waterways-map.png)
- [完整场景俯视](screenshots/16-starbridge-overview.png)

截图中的 FPS 为该次软件渲染会话的实测值，不代表手机性能。构图截图会调整角色与镜头位置；连续通关由独立的 SCENE 检查验证。引水渠为高架景观，当前通路仍使用单层网格与局部跳跃。

导出 Linux 程序另在工程外、静音设置下冷启动至首页后正常退出。本地未运行 Android 模拟器或实体手机，未验证手机帧率与音频设备输出。发布工作流会另行安装本次 APK，验证 FPS 开关与偏好、第四章启动与冷启动恢复；该次结果见 Release 中的流水线链接及验证附件。此前 Release 的 Android 证据不计入本次改动。

## 复现

```bash
bash scripts/maze3d/test.sh
# 需要 X11 / Xvfb；默认使用当前 Godot Compatibility 渲染器。
godot --audio-driver Dummy --path maze3d \
  --script res://tests/starbridge_capture.gd -- /absolute/screens

export JAVA_HOME=/path/to/jdk-17
export ANDROID_SDK_ROOT=/path/to/android-sdk
export XDG_DATA_HOME="$PWD/build/godot-tools/data"
bash scripts/maze3d/build.sh
```

`build.sh` 会自动通过 `tests/export_test.gd` 检查 Linux 成品内嵌资源包中的动态资源；此脚本不随游戏导出。本地成品位于 `build/maze3d/output/`。0.5.0 使用新的 Release 标签，原已发布的 0.4.0 下载保持不变。模型编辑与数据字段见 [MODELING.md](MODELING.md)。
