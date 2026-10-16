# 素材来源

复用仓库：[azfiles/pipi-maze](https://github.com/azfiles/pipi-maze)，参考提交 `0bfdef8573dba038de7f8d3f7763613d29de30c9`。完整原始声明见该仓库 [ASSET_SOURCES.md](https://github.com/azfiles/pipi-maze/blob/0bfdef8573dba038de7f8d3f7763613d29de30c9/ASSET_SOURCES.md)。

## 复用的原图

| 文件 | 官方来源 | SHA-256 |
| --- | --- | --- |
| `assets/characters/brown.png` | https://oshiri-tantei.com/assets/img/character/osiri/02_img.png | `01da6fe6b36a53db824819dafbd6e35800022d641d70509e4c7dba72a86949c4` |
| `assets/characters/koala.png` | https://oshiri-tantei.com/assets/img/character/other/04_img.png | `b7fcb6103133e45a3bb597d537d9ed2ad902c808b868de09c81f301d28d6999d` |
| `assets/characters/detective.png` | https://oshiri-tantei.com/assets/img/character/osiri/01_img.png | `1b4cecc8ffc39005d40a285a14a5ce063aa2bb628be6212a7aa9cb3b9ddbe4f9` |

这三张 PNG 从旧仓库逐字节复制，未修改文件。Godot 通过 Sprite3D 的 region 与 UI AtlasTexture 裁去透明留白。角色版权归 © トロル・ポプラ社／おしりたんてい製作委員会及相关原权利人。本项目为非官方个人兴趣原型，不声称取得再分发或商业授权；保留旧项目原有权利边界。

## 情景与原创内容

[官方第 44 话简介](https://oshiri-tantei.com/story/story44.html) 是旧项目核实的情景依据：小朋友找不到捉迷藏的小考拉，屁屁侦探让布朗帮忙寻找。新版本延续“布朗在公园寻找小考拉”的主题。

三个迷宫布局、立体地台、树篱、树木、花朵、池塘、长椅、自然印记、图标、界面、音乐音阶和全部交互均为此 Godot 适配新建。自然印记是可选的原创探索机制，抵达小考拉即可通关。章节名称和玩法不是动画官方剧情或原题。

没有复用旧版 `sprites-v2.png` 生成素材，也没有把官方原画迷宫直接当作三维新关卡。场景几何使用 Godot 基础网格和 MultiMesh 构建。

## 字体与引擎

- `garden-font.otf`、`garden-bold.otf`：Noto Sans CJK SC 的子集，来源为 Noto CJK；SIL Open Font License 1.1，见 `assets/FONT-LICENSE.txt`。可用 `scripts/maze/subset-font.py` 重建。
- `latin-font.otf`、`title-font.otf`：URW Base35 的 Nimbus Sans / Nimbus Roman，许可与版权见 `assets/LATIN-FONT-LICENSE.txt`。
- Godot 4.6.3：MIT License；随包保存 `assets/GODOT-LICENSE.txt`、`assets/GODOT-COPYRIGHT.txt`。
- 音效由 `scripts/sound.gd` 使用正弦波合成，未使用外部录音。
