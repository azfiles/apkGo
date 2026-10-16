# 0.1.0 交付验证

日期：2026-10-15。环境：Godot 4.6.3、Linux x86_64、Mesa llvmpipe、OpenGL Compatibility。结果：**473 项自动检查通过，0 失败**。

| 验证 | 结果 | 内容 |
| --- | --- | --- |
| 迷宫规则与本机存档 | 408 项通过 | 三关路网全部可达、拒绝穿墙/越界/瞬移、提示不代走、合法路径逐格通关、三印记完整收集、最短路线留有额外探索空间、非法和损坏存档处理、各关最佳记录与音效设置保存 |
| Godot 场景与物理交互 | 57 项通过 | 真实按钮点击、投影路面点击、键盘输入、暂停与继续、碰撞保持在路网内、CharacterBody3D 遍历三个关卡全部印记与终点、三星结算 |
| 导出 Linux 成品 | 8 项通过 | 直接启动导出可执行文件，通过 X11 系统鼠标和键盘操作开始、暂停、继续、提示、点击走到小考拉并切换下一关；运行无脚本错误 |
| Android APK | 构建与静态验证通过 | 独立包名、版本 0.1.0、ARM64 / ARMv7 / x86_64、APK v2 / v3 签名、16 KB 对齐、资源打包、权限检查 |
| 素材 | 逐字节一致 | 布朗、屁屁侦探、小考拉三张 PNG 的 SHA-256 与 pipi-maze 原记录完全一致 |

Android 包尚未进行真机安装和操作体验验证。`aapt2 dump badging` 对导出包的 `themed_icon` 资源引用有警告；主包检查与签名验证仍通过，该启动器图标适配需要在 Android 设备上进一步确认。

渲染截图包括 [首页](screenshots/01-home.png)、[探索](screenshots/02-play.png)、[池畔回廊](screenshots/03-pond.png)、[暮色林地](screenshots/04-twilight.png)、[结算](screenshots/05-complete.png)。源码截图使用真实 Godot 渲染；完整物理通关由独立场景测试验证。静态网格合批后，本次截图的总绘制调用为 184—224（包含界面与阴影），不代表手机帧率。

## 重跑

```bash
bash scripts/maze/test.sh
bash scripts/maze/build.sh
# 启动 Xvfb，或在已有 X11 会话中运行：
python3 scripts/maze/desktop-smoke.py
# 可选：用真实渲染器重新截图
godot --audio-driver Dummy --path maze-godot --script res://tests/capture.gd -- "$PWD/docs/maze/screenshots"
python3 scripts/maze/package.py
```

原始检查报告、导出报告、APK 验证报告和系统输入截图保存于 `build/maze/`。成品与工程压缩包的完整性散列在 `build/maze/output/SHA256SUMS.txt`。
