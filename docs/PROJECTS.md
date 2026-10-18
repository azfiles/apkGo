# 项目拆分记录 · 2026-10-18

- 3D 主线：`azfiles/apkGo`，以 `135b2c3cef25bf060fd3366264961c2523a34c42` 为源码基础，集成到 `main`；仅保留 3D 游戏与完整构建所需文件。
- 舒尔特表：`azfiles/schulte-flow`，原生 Java 与 Godot 版来自 `ac9d2702de6fe98466b2f90163d68c01d2c05add`。自有代码为 MIT，第三方许可原样保留。原生与 Godot 已发布 APK 按 SHA-256 原样迁移，不重新签名。
- 2.5D 花园：`azfiles/pipi-maze-garden`，来自同一 main 快照；保留角色版权、素材来源、测试与手动构建，旧 Release 链接继续有效。
- Unity 原型：`azfiles/schulte-flow-unity`，来自 `228156918890fed46473e6e108d6e8b438aa2c79`；不迁移 Secrets，不声称已有 Unity APK。

独立仓库只复制各项目的文件，不导入整个混合仓库历史。原仓库的旧提交、分支、标签和 Release 继续提供历史追溯与回退。

3D 不再依赖已拆分 demo 的安装脚本。完整 Android 与发布流程保留为手动执行，日常提交仅运行较轻的 Godot 检查。修改工作流和包结构后需重新验证；本次文件整理不改变游戏脚本、包名或签名。

## 拆分后本地验证

使用 SHA-512 校验的 Godot 4.6.3 执行实际导入及既有测试：

| 项目 | 检查结果 |
| --- | --- |
| 3D 主项目 | MODEL 545、SCENE 666、JUMP 56、CHARACTER 36，合计 1303 项、零失败 |
| 舒尔特 Godot | MODEL 368、SCENE 53，合计 421 项、零失败 |
| 2.5D 花园 | MODEL 408、SCENE 57，合计 465 项、零失败 |

另检查 Python 语法、shell 语法、Git diff 空白错误及拆分依赖。原生 Java 在独立仓库 CI 执行。此次未重新执行 Android 模拟器或真机测试；舒尔特发布文件通过迁移时的 SHA-256 核对保持与原包一致。
