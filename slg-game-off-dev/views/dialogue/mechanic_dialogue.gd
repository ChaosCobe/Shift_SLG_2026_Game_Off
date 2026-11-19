extends RefCounted

const DialogueSession := preload("res://views/dialogue/dialogue_session.gd")
const PORTRAIT := preload("res://views/dialogue/mechanic_portrait.tres")


static func create_session(already_repaired: bool) -> DialogueSession:
	var lines := {
		&"opening": {"text": "好了，销子扣回去了。你听听，稳流器还响吗？", "next": &"reply"},
		&"reply": {"player": true, "text": "还响啊。咚、咚、咚……", "next": &"answer"},
		&"answer": {"text": "那是你手里的扳手。松一松，你都紧张得敲上桌了。"},
	}
	if already_repaired:
		lines[&"opening"]["text"] = "稳流器今天安静得很。怎么，又听见怪声了？"
		lines[&"reply"]["text"] = "这回我可没拿扳手。"
		lines[&"answer"]["text"] = "我知道。午饭铃响了，走吧。"

	return DialogueSession.new("机修师", {
		SceneRouter.World.SURFACE: PORTRAIT,
		SceneRouter.World.INNER: PORTRAIT,
	}, lines)
