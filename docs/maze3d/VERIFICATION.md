# 0.2.0 验证范围

## 本地检查

Godot 4.6.3、Linux Compatibility / Mesa 软件渲染环境。

- `MODEL: 473 checks, 0 failures`：三章全图连通、坐标变换、目标数量、目标可达、引路合法、固定种子可复现。
- `SCENE: 702 checks, 0 failures`：真实角色通过连续输入逐格行走，完成三章所有灯塔、全部萤光和出口；未用目标传送替代通关测试。另检查墙体碰撞、体力、提示冷却、双指移动与环顾、暂停/地图/后台、存档恢复和损坏位置处理。
- 实际渲染截图：主页、第三人称玩法、引路、暂停、灯塔、点亮、出口与结算。截图脚本为构图可移动角色；它与连续行走通关测试分开。
- 签名与安装包：`apksigner verify`、16 KiB `zipalign` 检查、包名/版本/ABI/权限检查。包名 `com.alex.pipimaze.ruins`，min SDK 24，ARM64 / ARMv7 / x86_64，仅震动权限。

## 发布门禁

`.github/workflows/maze3d.yml` 从源码重新构建，在上述检查之外，用 Android 10 x86_64 / ANGLE 软件图形模拟器安装并启动同一签名 APK，发送实际 Android 触屏、滑动、返回键和后台操作，验证游戏画面、状态切换和进程恢复。只有所有步骤通过，才公开发布 GitHub 体验版。

流水线原始报告和 Android 截图保存在 Release 的 `Pipi-Maze-Ruins-Verification.zip`，发布说明提供对应运行链接。以该运行的结果和最终 APK 哈希为准。

## 尚未验证

没有 Android 实体手机的触感、帧率、功耗或机型覆盖测试。ARM64/ARMv7 的库与包格式已检查，Android 运行测试使用 x86_64 模拟器。桌面软件渲染帧率不能代表手机性能。
