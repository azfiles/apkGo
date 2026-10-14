# 体验版安装包

下载 [Schulte-Flow-1.0.0.apk](./Schulte-Flow-1.0.0.apk)，点击 GitHub 文件页面的 **Download raw file**，然后在 Android 8.0 或以上手机打开安装。

当前本地构建：92 项状态机检查通过；APK v2/v3 签名验证、zipalign 对齐验证通过。设备 UI 冒烟尚未完成，GitHub Actions 尚未出现运行记录，Release 尚未发布。此包适合先安装体验，不能据此声称已经通过真机或模拟器端完整测试。

此包使用 Android SDK 35、Build Tools 35.0.0 和 Eclipse ECJ 3.38.0（Java 8 目标）构建。源码中的默认构建脚本使用 JDK 17 javac；当前工作环境的 JDK 模块加载异常，因此本次采用 ECJ 编译。无新增应用运行时依赖。

公开演示证书签名，仅供体验。校验值见 SHA256SUMS.txt。测试自动化就绪后，通过完整检查的版本将发布到 Releases。
