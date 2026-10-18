# 布朗 / Brown / ブラウン · 0.4.0

本模型以《屁屁侦探》动画版布朗为对象，从网格重建，替换 0.2.0 的小熊角色。

## 核实的参考

- 官方角色页：https://oshiri-tantei.com/character/?char=char-brown
- 官方立绘：https://oshiri-tantei.com/assets/img/character/osiri/02_img.png
- 官方第 44 话《ブラウンのたんていしゅぎょう》及剧照：https://oshiri-tantei.com/story/story44.html
- 东映动画角色页：https://lineup.toei-anim.co.jp/ja/tv/oshiri/character/

原立绘已存在于旧项目 `maze-godot/assets/characters/brown.png`，其来源与哈希保留在该项目的 ASSET_SOURCES.md。新模型没有把原画当作面部贴片：脸、眼睛、鼻子、嘴、帽子、服装与挎包均为立体几何。帽子格纹为本次制作的嵌入式纹理。

以正面立绘为比例和服饰依据。未取得官方三视图或制作模型，侧面深度、背面帽型、背带走向与挎包背面细节属于适配推定，不声称是官方精确设定。

## 可编辑资源

- `maze3d/assets/models/brown.glb`：游戏使用的模型，纹理嵌入，Y 向上。
- `model-source/maze3d/brown_character.blend`：Blender 4.3.2 源文件，保留部件层级及摄影棚。Blender 中为 Z 向上、-Y 朝前。
- `scripts/maze3d/brown_model.py`：可复现的网格及材质构建脚本。
- `maze3d/scripts/character.gd`：Godot 跑跳、眨眼与表情驱动，随独立模型包附带；实例化后调用 `bind(avatar)`，每帧通过 `step(...)` 传入速度、着地状态、步态相位与时间。
- `docs/maze3d/brown/01-front.png` 至 `04-back.png`：实际模型渲染，不是概念图。
- `model-stats.json`：三角面和网格数量。

保留 14 个动作节点：Body、Torso、Head、ArmL/R、ElbowL/R、LegL/R、KneeL/R、EarL/R、Satchel。头部挂在躯干下，躯干与双腿挂在共同的 Body 下，颈部球面同时与头和衬衫重叠；呼吸和步态不再使头身分开。衬衫前后厚度为 0.55 米、头部为 0.78 米，帽子、短裤、手脚和挎包也同步加深。

当前采用相互覆盖的圆润部件及层级枢轴动画，并非连续蒙皮骨骼。`maze3d/scripts/character.gd` 按实际移动速度驱动交替摆臂、肘膝屈伸、身体前倾和挎包滞后摆动；起跳收腿、下落伸腿、接地压缩使用连续混合。全身共同起伏，头部只作小幅转动。

FaceSmile / FaceJoy / FaceSurprise / FaceFocus 为四组独立表情几何，运行时只显示一组。双眼节点支持眨眼；开心时切换为弧线笑眼。待机微笑、冲刺专注、腾空惊讶，拾取星星和点灯开心。首页可以手动轮换预览。新增 `10-character-motion.png` 为 Godot 实际渲染的四表情和四动作阶段对照图。

模型包含 45,448 个三角面、22 个网格对象（包含互斥表情），高度约 2.03 米。各节点下的刚性几何按部件合并，减少移动设备绘制调用。

复现：在仓库根目录执行 `blender -b -t 4 --python scripts/maze3d/brown_model.py`。只需替换角色 GLB 即可接入现有场景，角色碰撞及迷宫规则未改变。

角色版权归 © トロル・ポプラ社／おしりたんてい製作委員会及相关原权利人。此资源为非官方同人重建；附带源文件便于本原型继续修改，不代表获得角色商业授权。
