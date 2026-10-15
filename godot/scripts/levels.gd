extends RefCounted

const DATA = [
	{"name": "初见微光", "grid": 3, "speed": 12.0, "par": 18.0, "hint": "从 1 开始，依次点亮每个数字"},
	{"name": "轻轻漂流", "grid": 3, "speed": 24.0, "par": 16.0, "hint": "数字开始漂流，跟随它的节奏"},
	{"name": "微光相遇", "grid": 3, "speed": 42.0, "par": 15.0, "hint": "相遇会反弹，专注下一个数字"},
	{"name": "星海漫步", "grid": 4, "speed": 16.0, "par": 32.0, "hint": "16 颗星光，慢慢找到自己的节奏"},
	{"name": "潮汐之间", "grid": 4, "speed": 30.0, "par": 29.0, "hint": "碰撞与漂流，让目光保持轻盈"},
	{"name": "流光回旋", "grid": 4, "speed": 46.0, "par": 26.0, "hint": "点亮数字会轻轻推动周围的星光"},
	{"name": "繁星入梦", "grid": 5, "speed": 14.0, "par": 55.0, "hint": "25 颗星光，先准确，再追求速度"},
	{"name": "星河涌动", "grid": 5, "speed": 28.0, "par": 49.0, "hint": "流动中的专注，是新的挑战"},
	{"name": "循光而行", "grid": 5, "speed": 42.0, "par": 44.0, "hint": "最后一片星海，按自己的节奏完成"},
]

static func stars(elapsed: float, mistakes: int, par: float) -> int:
	if mistakes == 0 and elapsed <= par:
		return 3
	if mistakes <= 2:
		return 2
	return 1
