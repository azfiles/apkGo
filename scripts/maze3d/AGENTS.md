# 建模、导出与验证工具

先读 [仓库约定](../../AGENTS.md) 和 [建模规范](../../docs/maze3d/MODELING.md)。命令均从仓库根执行。

## 模型工具的边界

- `export_models.py` 是手工编辑 Blender 源文件后的标准导出入口。按资源目录的 ID、`source`、`source_root` 选取根节点及后代，只输出 GLB，不保存覆盖 `.blend`。
- 保持 `GLB`、`use_selection=True` 与 `export_yup=True`；临时归零源库根节点的展示位置并恢复，不把编辑用摆放偏移带入运行时，不破坏子节点枢轴。角色导出保留动作节点检查。
- 使用 `--asset` 精确导出所需资源，使用 `--output-dir /tmp/model-review` 审阅临时结果；不要为导出一个手工模型重建整个库。

| 程序化入口 | 会重写的内容 |
| --- | --- |
| `model_assets.py` | 原有场景库 `pipi_ruins_library.blend` 与对应 GLB |
| `brown_model.py` | `brown_character.blend`、对应角色 GLB 与工作室 |
| `starbridge_models.py` | `starbridge_library.blend` 与对应八个模块 GLB |
| `starbridge_level.py` | 第四章 `starbridge_garden.json` |

运行重建前检查工作区和源文件历史，保留已跟踪及尚未提交的手工编辑；提交或备份用于恢复，不能把保存过等同于可以覆盖。手工源文件的正常导出使用 `export_models.py`。新增程序化资产保持脚本可复现；手工修改不必为适应生成器而丢弃。

前三章是兼容存档的固定 JSON 快照；普通模型改动不重新生成或重新设种子。修改关卡生成器后只重建相应章节，审阅稳定 ID、目标顺序、摆放和碰撞差异。

## 验证与发布

- 生产工具变更同时核对 `.blend` 根层级、GLB 实际导入与目录元数据；按影响范围运行 `test.sh`，并审阅真实渲染。生成器成功退出不等同于游戏可玩。
- `test.sh` 中保留严格的 `SCRIPT ERROR` / `ERROR:` 检查。带游戏音频的测试退出时清理场景、等待帧和资源释放，不能靠放宽错误门禁掩盖退出问题。
- `build.sh` 验证签名、对齐、版本、权限和成品内嵌资源包；`package.py` 从工程版本生成交付名与校验和，新增源库、GLB 和验证附件应同步打包。
- 版本来自 `project.godot`，Android `version/name` 与 `version/code` 同步更新。保持既有包名、签名和离线权限边界。
- 普通检查为 `.github/workflows/verify.yml`；完整构建、Android 安装操作、截图、打包和发布为 `.github/workflows/maze3d.yml`。后者的手动触发和 `release/maze-3d-*` 分支推送具有发布效果，只在发布任务中使用。
- 发布必须等待本次完整验证成功；检查新 APK 的安装、FPS 偏好、章节选择和冷启动恢复。不能复用旧包的证据宣称新包通过。保留旧 Release，使用新的不可变标签与附件。
