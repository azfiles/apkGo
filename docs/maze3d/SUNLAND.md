# 0.6.0 · 森兰寻光

第五章把 [azfiles/Sunland](https://github.com/azfiles/Sunland) 的森兰湖场景模块接入 apkGo 主游戏。上游固定在 `243b4e2cf0c7b77225c38e28aa2a1b73a07de044`，保留红栏码头、白色遮棚、彩色皮划艇、湖畔帐篷、无界展亭示意体量、水杉、柳树、长椅和芦苇。

## 玩法与改编范围

25×25 格、三座灯塔、24 颗星星、11 处跳跃挑战（6 颗高处星星）。环湖栈道与跨湖红栏桥连通迎风林岸、湖畔营地、无界展亭、红栏星桥和东岸归途。落水后回到安全落脚点，保留已收集进度；首页可直接选择第五章。

这是为现有四米网格和手机探索重新编排的紧凑关卡，不是把原场景约三公里的地理范围等比例导入。原有码头作为湖面景观，红栏星桥提供可通行桥面；营地与展亭是岸边景观。没有宣称原始路线已经变成导航网格，也没有加入多层导航或游泳。

直接提取上游 Blender 对象，分别保留材质后，按玩法尺度缩放；使用低面数植被和卡通纯色材质，去除大范围 PBR 贴图。木栈道、护栏桥、草岸与岛台是适配模块。水面共用网格参与静态合批。原四章 JSON、出生点、目标顺序及存档含义保持不变。

## 可编辑与复现

- `model-source/maze3d/sunland_library.blend`：11 个稳定根节点；记录上游仓库、提交和提取对象。
- `maze3d/assets/models/sunland_*.glb`：11 个运行模块，经现有资源目录加载；整库总计34个 GLB。
- `scripts/maze3d/sunland_models.py`：从固定版本 Sunland 源工程重建适配库。
- `scripts/maze3d/sunland_level.py`：只生成第五章和对应目录项，不重建前四章。
- `model-source/maze3d/sunland/`：原始署名、场景清单与 OSM 数据提取快照，随源码和模型包交付。

```bash
git clone https://github.com/azfiles/Sunland.git /path/to/Sunland
git -C /path/to/Sunland checkout 243b4e2cf0c7b77225c38e28aa2a1b73a07de044
blender -b --python scripts/maze3d/sunland_models.py -- /path/to/Sunland
python3 scripts/maze3d/sunland_level.py
python3 scripts/maze3d/prepare_assets.py
bash scripts/maze3d/test.sh
```

手工修改适配库后，使用现有 `export_models.py --asset sunland_dock` 等按 ID 导出，不必重新提取上游。运行 APK 不访问上游仓库。

`version:1` 关卡新增可选 `surface_assets` 对象，允许通过既有资源 ID 设置 `floor`、`bridge`、`wall`。省略时完全沿用原有地面和墙；校验器拒绝未知角色、未知资源或无碰撞的表面资产。旧字段、符号和坐标的含义不变。

## 来源

场景地理数据 © OpenStreetMap contributors，ODbL 1.0。森兰场景为基于开放地图与公开资料的艺术化重建。

- https://www.openstreetmap.org/copyright
- https://opendatacommons.org/licenses/odbl/1-0/
- 游戏首页「场景与来源」提供可见署名与许可链接。
- 完整上游说明见 `model-source/maze3d/sunland/ATTRIBUTION.md`；本次未复制摄影、航拍或地图截图。

布朗的角色权利及同人说明继续见 [BROWN.md](BROWN.md)、[ART.md](ART.md)。
