# 0.4.0 美术与图标来源

角色依据《屁屁侦探》官方布朗立绘，保留橙棕色犬脸、低垂耳朵、黑眼睛、小鼻子、带两颗犬齿的笑脸、蓝色格纹帽、白衬衫、背带短裤和黄色挎包。3D 角色、场景模块与材质由项目脚本制作，属于同人适配，不是官方游戏素材。

本版采用明快的儿童侦探卡通方向：奶油纸张与深绿色文字、薄荷石墙、圆润树冠、蓝绿天空、蜂蜜金五角星。游戏使用真实立体网格；没有把生成图片贴到角色脸上。角色正、侧、背视图和 `screenshots/10-character-motion.png` 均为实际模型渲染。

## 图标

- 参考：https://oshiri-tantei.com/assets/img/character/osiri/02_img.png
- 官方角色页：https://oshiri-tantei.com/character/?char=char-brown
- 仓库参考：`model-source/maze3d/reference/brown-official.png`，从既有 `maze-godot/assets/characters/brown.png` 复制，未修改。
- 参考 SHA256：`01da6fe6b36a53db824819dafbd6e35800022d641d70509e4c7dba72a86949c4`
- 生成日期：2026-10-17，使用会话的 `image_gen.imagegen`，将上述官方立绘作为图像参考。
- 原尺寸输出：`maze3d/assets/icon.png`，1254 × 1254，完整不透明方形；直接使用生成结果，未再绘改。
- 输出 SHA256：`fca192abffa99b40410a3e39b5eb6a77dcaffa5df6776abb3510bbc7f43556af`
- 接入位置：`project.godot` 的应用图标，以及 `export_presets.cfg` 的 Android launcher icon；各启动器密度由 Godot 导出器生成。

2026-10-18 又以生成图标为参考，使用相同图像生成工具制作 `icon-adaptive.png`：保留布朗半身与星星，移除背景及装饰光芒，使用透明画布并扩大四周留白。Android 自适应前景采用这张透明图，背景为 `icon-background.svg` 的薄荷纯色；主题图标使用同一透明轮廓交给系统着色，替换引擎默认标志。导出后分别提取普通、前景、背景及主题资源核对。

生成要求：保持官方布朗身份，突出格纹蓝帽、橙棕犬脸、垂耳、黑色亮眼、粉色笑口和两颗小犬齿；大头半身、轻微三分之四视角，白衬衫、蓝背带和黄挎包，手边一颗金色五角星。粗而流畅的深棕轮廓，简洁日式儿童卡通赛璐珞配色，薄荷背景与奶油圆形光晕，不含文字、商标、水印或外框。颜色以蜂蜜棕、奶油、天空蓝、薄荷和明黄为主。

角色版权归 © トロル・ポプラ社／おしりたんてい製作委員会及相关原权利人；生成图标为本体验版的非官方同人创作。

## 0.6.0 森兰场景

码头、营地、展亭与植被直接改编自 azfiles/Sunland 的 Blender 网格，来源提交、比例改动、纯色材质适配与 OSM 署名见 [SUNLAND.md](SUNLAND.md)。新库未使用图片生成，未复制上游参考照片。
