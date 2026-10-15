# 已验证体验版安装包

优先从 [v1.0.0 Release](https://github.com/azfiles/apkGo/releases/tag/v1.0.0) 下载；本目录的 [Schulte-Flow-1.0.0.apk](./Schulte-Flow-1.0.0.apk) 是同一文件。支持 Android 8.0 及以上，GitHub 私有仓库下载需要登录有权限的账号。

已通过：92 项游戏逻辑检查、Android 10 模拟器上的 169 项 UI 检查、APK v2/v3 签名和 zipalign 对齐验证。覆盖三档完整通关、实际触摸、误触、暂停停表、取消重开、Activity 重建恢复、设置和最佳纪录持久化。

构建来源：[GitHub Actions #4](https://github.com/azfiles/apkGo/actions/runs/38573938332)，提交 `4be0e2c19e685006ceb087bac38b0824ce65e40e`。采用 JDK 17 javac、Android SDK 35 和 Build Tools 35.0.0。

校验值见 `SHA256SUMS.txt`，报告见 `model-report.txt` 和 `smoke-report.txt`。SHA256 与 Release 资产摘要一致。

使用公开演示证书签名，仅供体验。模拟器已验证功能；触感强度、声音听感和其他系统版本兼容性仍需实体手机体验。
