extends RefCounted

const DialogueSession := preload("res://views/dialogue/dialogue_session.gd")
const PORTRAITS := {
	SceneRouter.World.SURFACE: preload("res://assets/portraits/anna_yanami_cutout.png"),
	SceneRouter.World.INNER: preload("res://assets/portraits/tiara_basori_cutout.png"),
}


static func create_session(world: int, regulator_repaired: bool) -> DialogueSession:
	var lines := {
		&"opening": {
			"text": "你来得正好。我在核对今晚的通行记录，刚发现两边在同一时刻都有波动。",
			"next": &"questions",
		},
		&"questions": {
			"text": "你想先看哪一边的记录？",
			"options": {"问表世界的飞艇": &"surface", "问里世界的法阵": &"inner"},
		},
		&"surface": {
			"text": "机修所的稳流器一直在抖。你可以先检查那台设备。",
		},
		&"inner": {
			"text": "法阵的阵纹每隔一会儿就暗一下。我在记录它和另一侧的风向有没有关系。",
		},
	}
	if regulator_repaired:
		lines[&"opening"]["text"] = "我看过新一轮记录了。稳流器修好之后，飞艇的航线稳定多了。"
		lines[&"surface"]["text"] = "机修所的稳流器已经恢复运转，接下来的飞艇可以照常通行。"
		if world == SceneRouter.World.INNER:
			lines[&"opening"]["text"] = "法阵的波动还在，不过空港那边的记录稳定多了。"
	elif world == SceneRouter.World.INNER:
		lines[&"opening"]["text"] = "你来得正好。法阵又闪了一下，阵纹变暗的时间和空港的阵风对得上。"

	return DialogueSession.new("年轻研究者", PORTRAITS, lines)
