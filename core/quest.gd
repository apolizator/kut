class_name Quest
extends RefCounted

## Şehirdeki bir NPC'nin verdiği basit görev: "şu canavardan şu kadar
## öldür, karşılığında para ve deneyim al."

enum State {
	AVAILABLE,  ## alınabilir
	ACTIVE,     ## kabul edildi, sürüyor
	READY,      ## şartı tamamlandı, ödül bekliyor
	DONE,       ## ödülü alındı
}

var quest_id: String = ""
var title: String = ""
var description: String = ""
var giver: String = ""
var target_name: String = ""
var target_count: int = 1
var reward_gold: int = 0
var reward_exp: int = 0
var required_level: int = 1

var progress: int = 0
var state: State = State.AVAILABLE

## Zor görevlerin KALICI ödülü: tamamlandığında statlara işler.
var bonus: Dictionary = {}


static func from_dict(d: Dictionary) -> Quest:
	var q := Quest.new()
	q.quest_id = str(d.get("id", ""))
	q.title = str(d.get("title", q.quest_id))
	q.description = str(d.get("desc", ""))
	q.giver = str(d.get("giver", ""))
	q.target_name = str(d.get("target", ""))
	q.target_count = maxi(1, int(d.get("count", 1)))
	q.reward_gold = int(d.get("gold", 0))
	q.reward_exp = int(d.get("exp", 0))
	q.required_level = maxi(1, int(d.get("level", 1)))
	var b = d.get("bonus", null)
	if b is Dictionary:
		q.bonus = (b as Dictionary).duplicate()
	return q


func has_permanent_reward() -> bool:
	return not bonus.is_empty()


func ratio() -> float:
	return clampf(float(progress) / float(maxi(1, target_count)), 0.0, 1.0)


func progress_text() -> String:
	return "%s  %d / %d" % [target_name, mini(progress, target_count), target_count]
