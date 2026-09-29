class_name QuestLog
extends RefCounted

## Görev defteri: hangi görev alınabilir, hangisi sürüyor, hangisi bitti.

var quests: Array[Quest] = []
var by_id: Dictionary = {}


func load_defs(d: Dictionary) -> void:
	quests.clear()
	by_id.clear()
	for raw in d.get("quests", []):
		var q := Quest.from_dict(raw as Dictionary)
		if q.quest_id.is_empty():
			continue
		quests.append(q)
		by_id[q.quest_id] = q


func get_quest(quest_id: String) -> Quest:
	return by_id.get(quest_id, null)


## Bu NPC'nin oyuncuya gösterebileceği görevler (bitmişler gizlenir).
func for_giver(npc_name: String) -> Array[Quest]:
	var out: Array[Quest] = []
	for q in quests:
		if q.giver != npc_name or q.state == Quest.State.DONE:
			continue
		out.append(q)
	return out


## Alınabilir görevler — artık NPC'ye gitmeye gerek yok.
func available() -> Array[Quest]:
	var out: Array[Quest] = []
	for q in quests:
		if q.state == Quest.State.AVAILABLE:
			out.append(q)
	out.sort_custom(func(a, b): return a.required_level < b.required_level)
	return out


func accept(quest_id: String, player_level: int) -> bool:
	var q := get_quest(quest_id)
	if q == null or q.state != Quest.State.AVAILABLE:
		return false
	if player_level < q.required_level:
		return false
	q.state = Quest.State.ACTIVE
	q.progress = 0
	return true


## Bir canavar öldüğünde çağrılır. Tamamlanan görevlerin adlarını döner.
func on_kill(monster_name: String) -> Array[String]:
	var tamamlanan: Array[String] = []
	for q in quests:
		if q.state != Quest.State.ACTIVE or q.target_name != monster_name:
			continue
		q.progress += 1
		if q.progress >= q.target_count:
			q.state = Quest.State.READY
			tamamlanan.append(q.title)
	return tamamlanan


## Ödülü al. Boş sözlük = alınamadı.
func claim(quest_id: String) -> Dictionary:
	var q := get_quest(quest_id)
	if q == null or q.state != Quest.State.READY:
		return {}
	q.state = Quest.State.DONE
	return {"gold": q.reward_gold, "exp": q.reward_exp, "title": q.title}


## Tamamlanmış zor görevlerin kalıcı ödülleri.
func apply_to(stats: Stats) -> void:
	for q in quests:
		if q.state == Quest.State.DONE and not q.bonus.is_empty():
			SkillTree._add(stats, q.bonus, 1)


func active() -> Array[Quest]:
	var out: Array[Quest] = []
	for q in quests:
		if q.state == Quest.State.ACTIVE or q.state == Quest.State.READY:
			out.append(q)
	return out


func to_dict() -> Dictionary:
	var liste := []
	for q in quests:
		if q.state == Quest.State.AVAILABLE:
			continue
		liste.append({"id": q.quest_id, "st": int(q.state), "pr": q.progress})
	return {"quests": liste}


func load_dict(d: Dictionary) -> void:
	for raw in d.get("quests", []):
		var e: Dictionary = raw
		var q := get_quest(str(e.get("id", "")))
		if q == null:
			continue
		q.state = clampi(int(e.get("st", 0)), 0, 3) as Quest.State
		q.progress = maxi(0, int(e.get("pr", 0)))
