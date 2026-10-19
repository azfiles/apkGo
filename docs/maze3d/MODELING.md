# 建模与数据关卡规范

**策略状态：已采用，作为后续默认设计；基线：已发布的 `maze-3d-v0.5.0`。** 本文是建模与数据关卡约定的维护入口，[仓库 Agent 指令](../../AGENTS.md) 及相关目录指令引用此规范。

项目使用 **Blender → GLB → JSON → Godot** 流水线。前三章已从原固定种子生成器迁为 JSON 快照，通道、出生点、灯塔、星星顺序及障碍坐标保留，旧存档可继续读取。第四章「星桥水庭」直接使用这套数据层。

## 设计延续与扩展

- 延续明快卡通、圆润实体几何与奶油、薄荷、天空蓝、蜂蜜金配色；角色保留正侧背体积、头身连接与已有辨识特征。造型依据见 [BROWN.md](BROWN.md) 与 [ART.md](ART.md)。
- 复杂场景通过可复用模块、区域、水道、桥梁与 JSON 摆放组合扩展。新增主要美术资产进入 Blender/GLB 资源库；Godot 保留通用碰撞、特效、辅助几何与合批能力。
- 资源 ID、源根节点、角色层级、单位坐标及已发布关卡的存档语义保持兼容。四章、23 个 GLB 和三个源库是 0.5.0 的交付规模，后续可沿用规范继续增加。
- 任务明确需要改变资产格式、动画系统、坐标或高度模型时，在同一变更说明迁移范围，同步生产工具、数据版本、运行时、存档兼容、验证与 Agent 指令；普通资产和场景扩展遵循当前策略。

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `model-source/maze3d/*.blend` | 可长期编辑的美术源文件，不随游戏运行加载 |
| `maze3d/assets/models/*.glb` | glTF 2.0 游戏网格、材质与稳定节点层级 |
| `maze3d/assets/model_catalog.json` | 稳定资源 ID → GLB、Blender 源文件、源根节点和简化碰撞盒 |
| `maze3d/levels/index.json` | 章节顺序、显示名称、难度与数据路径 |
| `maze3d/levels/*.json` | 通路、目标、挑战、区域、环境与场景模块摆放 |
| `asset_library.gd` / `level_data.gd` | 资源缓存、数据校验和加载 |
| `maze.gd` | 坐标转换、寻路、迷雾和安全落脚点查询 |
| `world.gd` / `main.gd` / `interface.gd` | 物理、交互、渲染组合、存档和界面 |

`project.godot` 继续设置 `import/blender/enabled=false`。修改 `.blend` 后需明确导出 GLB，再由 Godot 导入；运行游戏不依赖 Blender。

## 单位、方向与命名

- 1 个 Blender/Godot 单位 = 1 米。Blender 源文件使用 Z-up，GLB 以 `export_yup=True` 转为 Y-up。
- JSON 的场景 `position` 使用 **Godot 世界坐标 `[x,y,z]`**；`rotation_y` 使用角度，`scale` 为正的统一缩放倍数。
- JSON 的玩法 `cell` 使用网格坐标 `[x,z]`。一格 4 米，世界位置为 `[(x-floor(width/2))*4, 0, (z-floor(width/2))*4]`。
- 模块原点位于落地位置。源库为了编辑而排列的偏移不应进入游戏；统一导出脚本会临时归零根节点的位置。
- 资源 ID 和源根节点稳定。更换网格或 GLB 路径时更新资源目录，关卡仍引用同一个 ID。
- 碰撞使用资源目录中的简化盒体，避免把装饰细节全部转成三角网格碰撞。动态石栏与断桥尺寸仍由玩法数据控制。

布朗保持 `Brown` 源根节点及以下 14 个动作节点：`Body`、`Torso`、`Head`、`ArmL/R`、`ElbowL/R`、`LegL/R`、`KneeL/R`、`EarL/R`、`Satchel`。表情保留 `FaceSmile`、`FaceJoy`、`FaceSurprise`、`FaceFocus`。当前为分部件刚性动画；修改角色时同时保留父子关系和关节原点。

## 手工修改与批量生成

打开任意源文件修改模型后，用资源 ID 导出：

```bash
blender --background --python scripts/maze3d/export_models.py -- \
  --asset garden_bridge --asset ruins_arch

# 也可导出原有资产与布朗；角色导出会检查 14 个动作节点。
blender --background --python scripts/maze3d/export_models.py -- --asset brown
```

脚本根据目录找到 `.blend` 和根节点，只导出对应层级，恢复源库的临时位置，不保存覆盖 `.blend`。`--output-dir /tmp/model-review` 可用于先审阅导出结果。

程序化重建入口：

```bash
blender --background --python scripts/maze3d/model_assets.py       # 原有场景库
blender --background --python scripts/maze3d/brown_model.py        # 布朗与角色工作室
blender --background --python scripts/maze3d/starbridge_models.py   # 新的 8 个模块
python3 scripts/maze3d/starbridge_level.py                         # 第四章 JSON
python3 scripts/maze3d/prepare_assets.py                          # 包含关卡文本的字体子集
```

重建模型会覆盖对应 GLB 与源 `.blend`；手工修改源文件后应使用 `export_models.py`，并先提交或备份修改。

新增源库 `starbridge_library.blend` 包含：拼花地砖、石桥、拱门、石柱、喷泉、凉亭、花槽和高架引水渠。拼花地砖也用于原三章；已有角色和其他模型源文件保留。

## 关卡 JSON

`index.json` 是章节入口。追加章节时，在此登记稳定 `id`、`path`、`title`、`subtitle` 和 `difficulty`；首页、下一章、存档恢复均读取章节目录。

每个关卡的 `version` 为 `1`，`tile_size` 为 `4.0`。`grid` 是 5～41 格的正方形字符串数组，最外圈为 `#`：

| 字符 | 行为 |
| --- | --- |
| `#` | 实体遗迹墙 |
| `.` | 可通行拼花地面 |
| `~` | 低处水面，无地板支撑；落下后安全复位 |
| `=` | 有地板与两侧护栏的桥面；`bridge_rotation_y` 控制桥轴 |

`start`、`goal`、三个 `beacons` 和若干 `motes` 使用 `[x,z]`，必须位于互不重叠、连通的通路上。`elevated_motes` 保存需要跳起收集的星星下标。星星总数由数组决定，双星要求收集至少一半，三星要求全部收集。

挑战示例：

```json
{"cell":[3,6],"axis":[0,1],"kind":"gap","height":0.75,"span":1.4}
```

`kind` 支持 `hurdle` 与 `gap`，方向为单位轴，两个相邻格必须安全。石栏不超过 0.75 米，缺口不超过 1.4 米；挑战不能覆盖出生点、灯塔、出口或星星。

场景实例示例：

```json
{
  "asset":"ruins_arch",
  "position":[-4,0,24],
  "rotation_y":90,
  "scale":1,
  "collisions":true
}
```

`scenery` 中每项通过 `asset` 引用资源目录；碰撞盒跟随位置、旋转和统一缩放。桥头拱门应置于桥面，避免柱子挡住沿岸纵向通路。新增摆放必须跑实走测试；拓扑连通检查无法代替实际碰撞验证。

可选 `environment` 设置背景、雾和水面颜色；`regions` 使用闭区间 `bounds:[x0,z0,x1,z1]` 设置区域名称与地砖颜色，重叠时采用第一个匹配区域。当前高度模型仍以单层通路、局部跳跃为主，高架引水渠为景观；多层可行走世界需要另行扩展寻路、落脚点和存档高度。

## 存档与导出

已有 `ruins-v2.json` 可直接读取。新存档同时保存 `level_id` 和原数字 `chapter`；恢复时优先匹配稳定 ID，旧存档按原章节序号读取。已发布章节应保持目标数组顺序，避免已有灯塔/星星位标记指向其他对象。

两个导出预设均显式包含 `levels/*.json` 与 `assets/*.json`。GLB 由资源目录动态加载，因此预设保持 `all_resources`，避免只打包静态引用而遗漏模型。

开发验证：

```bash
bash scripts/maze3d/test.sh
# 需要 X11 显示服务；无显示服务时可使用 Xvfb。
godot --audio-driver Dummy --path maze3d \
  --script res://tests/starbridge_capture.gd -- /absolute/screens
```

检查覆盖目录和无效数据、旧布局与目标顺序、四章真实连续移动通关、桥面支撑和落水复位、跳跃、角色动画及帧率偏好持久化。帧率读取 `Engine.get_frames_per_second()`，每 0.5 秒更新；显示绘制帧率，不使用物理帧率或设备性能估计。
