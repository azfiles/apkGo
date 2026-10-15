# Godot 开发与验证

打开 `godot/project.godot`，使用 **Godot 4.6.3 stable**。主场景是 `scenes/main.tscn`。游戏无第三方 Godot 插件、无 Gradle 构建依赖；资源和音效均在本机生成或随项目提供。

## 结构与行为

- `scripts/round.gd`：运行、暂停、完成状态机，顺序输入、误触和计时。
- `scripts/levels.gd`：9 关的数据与星级规则；通关至少一星，误触不超过 2 次得二星，零误触且不超过目标时间得三星。
- `scripts/orb.gd`：`RigidBody2D` + `CircleShape2D`，连续碰撞检测与反弹。
- `scripts/main.gd`：`StaticBody2D` 边界、触摸命中、限量 `CPUParticles2D`、音阶合成、UI 和生命周期。
- `scripts/save_store.gd`：本机 JSON 临时文件写入后重命名，保存关卡、星级、时间、设置、当前球位置；损坏数据回退。

暂停同时隐藏数字、停止计时与物理，后台也自动暂停。恢复的未完成关卡先停在暂停页，由玩家继续。数字球仍保留已完成数字的位置并参与碰撞。每次点击会给附近的球一个小冲量。粒子发射器最多同时 32 个，完成后释放。

Godot 版使用独立包名，方便与 Java 1.0 对比；两版成绩不互通。Java 源码保留，原工作流改为仅手动运行；Godot 负责后续自动发布。

## 本地命令

```bash
# 逻辑和真实物理场景测试（不需要 Android SDK）
bash scripts/godot/test.sh

# 下载固定版本工具和模板，并校验固定 SHA512
bash scripts/godot/setup.sh
export GODOT="$PWD/build/godot-tools/bin/godot"
export XDG_DATA_HOME="$PWD/build/godot-tools/data"
export ANDROID_SDK_ROOT=/path/to/android-sdk
export JAVA_HOME=/path/to/jdk-17
# SDK 包：platform-tools、platforms;android-35、build-tools;35.0.0
bash scripts/godot/build.sh

# 仅在专用、可清除数据的模拟器上执行；会清空 Godot 版的本机进度
python3 scripts/godot/android-smoke.py
```

非 Gradle 导出沿用官方 4.6.3 模板的 minSdk 24 / targetSdk 36。APK 构建输出在 `build/godot/output/`。`verify-apk.sh` 检查 v2/v3 签名、16 KB ZIP 对齐、64 位 ELF LOAD 段 16 KB 对齐、包名、SDK、三种 ABI、离线权限和资源。32 位 ARM 不要求 16 KB ELF 段。

## GitHub Actions

`.github/workflows/godot-android.yml` 在相关源码推送到 main、PR 和手动触发时运行验证。只有 main 且全部验证通过才进入独立的 Release job；PR 无写权限、不发布。每次发布采用包含 run number 和提交 SHA 的独立标签，不覆盖旧 Release。重复运行同一已发布提交不会替换资产。APK、SHA256、完整报告和截图一起发布。

`signing/demo-signing.p12.base64` 是之前已公开的演示签名；不是生产凭据。构建不需要新增 GitHub Secrets，Release 使用 job 限定的 `GITHUB_TOKEN`。

## 字体与许可

`assets/flow-font.otf` 是 Noto Sans CJK SC 的字符子集，覆盖游戏中文和符号。许可见 `assets/FONT-LICENSE.txt`；Godot 及其组件许可见 `assets/GODOT-LICENSE.txt` 和 `assets/GODOT-COPYRIGHT.txt`。新增文案时可运行 `scripts/godot/subset-font.py /path/to/NotoSansCJK-Regular.ttc` 重新生成子集，需要 fontTools；模板正常构建不依赖 fontTools。
