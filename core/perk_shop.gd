class_name PerkShop
extends RefCounted

## Şehirdeki ustalardan parayla alınan kalıcı özellikler.
##
## Zincirleme: sıradaki özelliği almak için bir öncekini almış olman
## gerekir. Böylece şehirler oyunun ikinci bir ilerleme hattı olur.

var perks: Array[Dictionary] = []
var owned: Dictionary = {}


func load_defs(d: Dictionary) -> void:
	perks.clear()
	for raw in d.get("perks", []):
		perks.append(raw as Dictionary)


func index_of(perk_id: String) -> int:
	for i in perks.size():
		if str(perks[i].get("id", "")) == perk_id:
			return i
	return -1


func has(perk_id: String) -> bool:
	return owned.has(perk_id)


## Sıradaki alınabilir özellik (hepsi alındıysa boş sözlük).
func next_perk() -> Dictionary:
	for p in perks:
		if not has(str(p.get("id", ""))):
			return p
	return {}


func can_buy(perk_id: String, gold: int, level: int) -> bool:
	var i := index_of(perk_id)
	if i < 0 or has(perk_id):
		return false
	if i > 0 and not has(str(perks[i - 1].get("id", ""))):
		return false  # zincir bozulamaz
	var p: Dictionary = perks[i]
	if level < int(p.get("level", 1)):
		return false
	return gold >= int(p.get("cost", 0))


## Satın alır, harcanan parayı döner (0 = olmadı).
func buy(perk_id: String, gold: int, level: int) -> int:
	if not can_buy(perk_id, gold, level):
		return 0
	var i := index_of(perk_id)
	owned[perk_id] = true
	return int((perks[i] as Dictionary).get("cost", 0))


func apply_to(stats: Stats) -> void:
	for p in perks:
		if not has(str(p.get("id", ""))):
			continue
		var b = p.get("bonus", {})
		if b is Dictionary:
			SkillTree._add(stats, b as Dictionary, 1)


func owned_count() -> int:
	return owned.size()


func to_dict() -> Dictionary:
	return {"owned": owned.keys()}


func load_dict(d: Dictionary) -> void:
	owned.clear()
	for id in d.get("owned", []):
		owned[str(id)] = true
