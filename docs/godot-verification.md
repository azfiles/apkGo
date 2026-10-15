# Godot 2.0 发布验证

2026-10-15 发布的安装包来自提交 `bdc250e5712d455d27ab2033d0d1844959df7578`，由 GitHub Actions 自动编译、签名、验证并发布。

- [Actions 完整成功记录](https://github.com/azfiles/apkGo/actions/runs/38737005212)
- [Release 与安装包](https://github.com/azfiles/apkGo/releases/tag/godot-v2.0.0-4-bdc250e)
- [完整报告、logcat 与设备截图](https://github.com/azfiles/apkGo/releases/download/godot-v2.0.0-4-bdc250e/verification.tar.gz)

| 验证层 | 结果 | 范围 |
| --- | --- | --- |
| Godot 逻辑 | 368 项通过 | 状态机、顺序输入、计时、星级、保存恢复 |
| Godot 实际场景 | 53 项通过 | 输入事件、刚体与墙体反弹、粒子、暂停冻结、全部 9 关通关与解锁 |
| Android 10 / x86_64 | 22 项通过 | 安装实际 Release APK、启动、触摸、取消/确认重开、后台暂停、进程重启恢复、四张画面截图、无脚本/渲染错误和崩溃 |
| APK 静态检查 | 通过 | v2/v3 签名、16 KB ZIP 与 64 位 ELF 对齐、SDK、三种 ABI、离线权限、资源 |
| 发布后复核 | 通过 | 从公开 Release 下载成品，核对 SHA256、签名，人工查看首页、游戏与恢复截图 |

APK：`Schulte-Flow-Godot-2.0.0.apk`，77,152,522 字节（约 73.6 MiB）。

```text
d76a349adf0f83ae373cbe21f0340769781249d68b0c430d9cf23ee572c3a805
```

Android 7.0+、OpenGL ES 3.0；包含 ARM64、ARMv7、x86_64。安装测试运行于 Android 10 模拟器，未代替所有系统版本/实体手机的适配、听感和触感测试。使用仓库原有公开演示证书；独立包名可与 Java 版并存。

## 发布门槛修正

早期构建的模拟器旧图形后端出现着色器错误，输入与状态日志正常但画面未正常显示。当前工作流改用 ANGLE / SwiftShader，并同时检查实际画面区域与 Godot 渲染错误。旧构建 `godot-v2.0.0-3-594a382` 已标注验证不足并指向此版本，不作为画面验证通过的依据。

## 本次 Android 截图

<img src="screenshots/godot-home.png" width="260" alt="实际 APK 首页"> <img src="screenshots/godot-play.png" width="260" alt="实际 APK 关卡">
