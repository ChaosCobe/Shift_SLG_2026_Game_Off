extends RefCounted

const DialogueSession := preload("res://views/dialogue/dialogue_session.gd")
const PORTRAITS := {
	SceneRouter.World.SURFACE: preload("res://assets/portraits/anna_yanami_cutout.png"),
	SceneRouter.World.INNER: preload("res://assets/portraits/tiara_basori_cutout.png"),
}


static func create_session(world: int, regulator_repaired: bool) -> DialogueSession:
	var lines := {
		&"opening": {
			"text": "帮我按住这张纸！飞艇刚一靠站，我的铅笔就一路滚到了桌边。",
			"options": {"看飞艇记录": &"ask_surface", "看法阵记录": &"ask_inner"},
		},
		&"ask_surface": {
			"player": true,
			"text": "这条抖线也是铅笔自己画的？",
			"next": &"surface",
		},
		&"surface": {
			"text": "嗯，我把它绑在了仪表上。飞艇停稳了，笔还在抖。去机修所看看稳流器吧。",
		},
		&"ask_inner": {
			"player": true,
			"text": "这一排黑点，你在画星座？",
			"next": &"inner",
		},
		&"inner": {
			"text": "阵纹每暗一次，我就点一下。把两张纸叠起来看，每个点都落在一道抖线上。",
		},
	}
	if regulator_repaired:
		lines[&"opening"]["text"] = "今天铅笔总算能在桌上待住了。给，你修好稳流器之后的第一张记录。"
		lines[&"ask_surface"]["text"] = "这么直……铅笔睡着了？"
		lines[&"surface"]["text"] = "我刚也这么想，还特意敲了一下仪表。看，就这一个小尖。飞艇一路都很稳。"
		lines[&"ask_inner"]["text"] = "飞艇稳了，怎么还有黑点？"
		lines[&"inner"]["text"] = "你也看到了？阵纹还在闪。看来明天我还得来这儿蹲一趟。"
		if world == SceneRouter.World.INNER:
			lines[&"opening"]["text"] = "嘘，看第三圈……又暗了！空港那边已经平稳，我这张纸上却还在添点。"
	elif world == SceneRouter.World.INNER:
		lines[&"opening"]["text"] = "看第三圈阵纹。它每暗一下，我就点一笔。空港的记录也在这儿，你挑一张。"

	return DialogueSession.new("年轻研究者", PORTRAITS, lines)
