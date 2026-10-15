# v1.0.0 发布验证

- 已发布：[循光·舒尔特 v1.0.0](https://github.com/azfiles/apkGo/releases/tag/v1.0.0)
- 构建与测试：[Actions #4 · success](https://github.com/azfiles/apkGo/actions/runs/38573938332)
- 源码提交：`4be0e2c19e685006ceb087bac38b0824ce65e40e`
- 设备环境：Android 10 / API 29，x86_64 模拟器，720×1560 像素、320 dpi
- APK：140241 字节；最低 Android 8.0 / API 26；target API 35
- SHA256：`3dfd5a305273ae143831ddd430e2abd3b7239cf85a7d1bdfada41a769deb1ee3`

| 检查 | 结果 |
| --- | --- |
| 游戏逻辑断言 | 92 项通过 |
| 设备 UI 断言 | 169 项通过 |
| APK v2/v3 签名 | 通过 |
| APK 对齐 | 通过 |
| 安装与启动 | 通过 |
| 3×3、4×4、5×5 完整通关 | 通过 |
| 真实触摸正确和错误数字 | 通过 |
| 暂停停表、取消重开 | 通过 |
| Activity 重建后暂停恢复进度 | 通过 |
| 设置与分难度最佳纪录保存 | 通过 |

[逻辑报告](../dist/model-report.txt) · [UI 报告](../dist/smoke-report.txt) · [完整日志及六张截图](https://github.com/azfiles/apkGo/actions/runs/38573938332/artifacts/11898961927)

本报告只描述实际检查。未进行实体手机触感/听感评估，也未覆盖所有 Android 版本。应用以公开演示证书签名。
