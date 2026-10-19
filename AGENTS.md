# apkGo · Agent 工作约定

适用于整个仓库；子目录的 `AGENTS.md` 补充对应领域规则。当前开发对象是 Godot 第三人称 3D 游戏，已拆分的演示项目见 [项目记录](docs/PROJECTS.md)。

## 固定的建模策略

以已发布的 `maze-3d-v0.5.0` 为架构基线，后续建模、角色和复杂场景默认沿用：

**Blender 可编辑源文件 `.blend` → glTF 2.0 二进制 `.glb` → JSON 资源目录与关卡描述 → Godot `.gd` / `.tscn`。**

- `.blend` 长期保存在 `model-source/maze3d/`；运行时资产保存在 `maze3d/assets/models/`。
- 模型通过 `assets/model_catalog.json` 的稳定 ID 引用；章节通过 `levels/index.json` 和各章 JSON 组织。
- Blender 负责网格、材质、部件层级；JSON 负责布局与摆放；Godot 负责数据校验、组合、物理、交互与存档。
- 保持米制、Blender Z-up、GLB/Godot Y-up，以及 `import/blender/enabled=false`。手工修改源文件后显式导出 GLB。
- 新增复杂场景优先复用或扩展模块库和 JSON 数据；一次场景扩展不应另建一套资产格式、加载器或硬编码摆放流程。

[建模与数据关卡规范](docs/maze3d/MODELING.md) 是详细约定的唯一维护入口。涉及模型、角色、关卡、资源加载、生成或导出时，先读取它及下表对应指令。旧版设计与验证资料按其版本理解，早期固定种子生成方案不覆盖当前 JSON 关卡策略。

| 工作范围 | 目录指令 | 相关资料 |
| --- | --- | --- |
| Godot、资源目录、关卡与测试 | [maze3d/AGENTS.md](maze3d/AGENTS.md) | [运行与构建](maze3d/README.md) |
| 模型生成、导出、构建与打包 | [scripts/maze3d/AGENTS.md](scripts/maze3d/AGENTS.md) | [验证范围](docs/maze3d/DATA_LEVEL_VERIFICATION.md) |
| Blender 源文件与角色造型 | [model-source/maze3d/AGENTS.md](model-source/maze3d/AGENTS.md) | [布朗](docs/maze3d/BROWN.md)、[美术来源](docs/maze3d/ART.md) |

用户明确要求调整架构时，在同一变更中说明迁移范围、更新本约定和建模规范，并同步生产工具、运行时、验证与存档兼容处理。日常新增资产和章节沿用现有策略即可。

## 验证与交付

- 仅修改文档或 Agent 指令：检查路径、链接、约定与实际代码一致，并执行 `git diff --check`。
- 修改模型、资源目录、关卡或运行逻辑：运行 `bash scripts/maze3d/test.sh`；改动画面还需实际 Godot 渲染审阅。场景摆放与碰撞须以连续移动、跳跃、收集、点灯和出口交互验证。
- 保留测试中的脚本错误、资源加载错误检查；修复原因，不通过删除断言或忽略错误获得通过结果。
- Godot 当前固定为 **4.6.3**，复现 Blender 源文件使用 **4.3+**。工具升级应同步安装脚本、导出模板和复现说明。
- 只报告本次实际执行的验证。截图构图、模拟器与实体手机验证分开说明，软件渲染 FPS 不代表手机性能。
- 文档和配置改动不自动升游戏版本或发布 APK。用户要求 Release 时使用完整验证工作流，保留既有包名、演示签名、存档兼容和旧版下载；已发布标签与附件保持不可变。
- `build/` 和 `.godot/` 是本地输出，不提交。保留已有 `.glb.import` 与 `.gd.uid` 的资源身份；新增资源提交相应导入配置与 UID。
