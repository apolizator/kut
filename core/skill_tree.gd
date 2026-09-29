class_name SkillTree
extends RefCounted

## Parayla öğrenilen kalıcı beceriler — beş katmanlı, kademeli ağaç.
##
## Üç tür ödül var:
##   1. Her seviye kendi bonusunu verir.
##   2. Bir beceriyi SONUNA KADAR yükseltmek ek bir bonus açar ("full").
##   3. Bir katmanın tamamını açmak, sonra tamamını fullemek katman
##      ödülü verir — fulleme ödülü belirgin biçimde daha büyüktür.
##
## Ayrıca katman kilidi var: alt katmanlara inmek için üstteki
## katmanlarda belli bir toplam seviyeye ulaşmak gerekir. Böylece
## oyuncu ağacın dibine koşmak yerine temeli sağlamlaştırmak zorunda.

var defs: Array[Dictionary] = []
var by_id: Dictionary = {}

## Katman ödülleri ve katman kilidi eşikleri (data/skills.json).
var tiers: Array[Dictionary] = []
var gates: Array[int] = []

## id -> öğrenilmiş seviye
var learned: Dictionary = {}

var _tier_cache: Dictionary = {}


func load_defs(d: Dictionary) -> void:
	defs.clear()
	by_id.clear()
	_tier_cache.clear()
	for raw in d.get("skills", []):
		var e: Dictionary = raw
		var id := str(e.get("id", ""))
		if id.is_empty():
			continue
		defs.append(e)
		by_id[id] = e

	tiers.clear()
	for t in d.get("tiers", []):
		tiers.append(t as Dictionary)

	gates.clear()
	for g in d.get("tier_gates", []):
		gates.append(int(g))


# --- katmanlar ---

## Bir becerinin katmanı: önkoşul zincirinin derinliği.
func tier_of(skill_id: String) -> int:
	if _tier_cache.has(skill_id):
		return int(_tier_cache[skill_id])
	if not by_id.has(skill_id):
		return 0
	var en_derin := -1
	for gereken in (by_id[skill_id] as Dictionary).get("requires", []):
		en_derin = maxi(en_derin, tier_of(str(gereken)))
	var t := en_derin + 1
	_tier_cache[skill_id] = t
	return t


func tier_count() -> int:
	var n := 0
	for e in defs:
		n = maxi(n, tier_of(str(e.get("id", ""))) + 1)
	return n


func skills_in_tier(tier: int) -> Array[String]:
	var out: Array[String] = []
	for e in defs:
		var id := str(e.get("id", ""))
		if tier_of(id) == tier:
			out.append(id)
	return out


## Bu katmanın üstündeki bütün katmanlarda toplanan seviye.
func levels_above(tier: int) -> int:
	var toplam := 0
	for e in defs:
		var id := str(e.get("id", ""))
		if tier_of(id) < tier:
			toplam += level_of(id)
	return toplam


## Katman kilidi açıldı mı: üsttekilerde yeterince seviye var mı?
func tier_unlocked(tier: int) -> bool:
	return levels_above(tier) >= tier_gate(tier)


func tier_gate(tier: int) -> int:
	if tier < 0 or tier >= gates.size():
		return 0
	return gates[tier]


## Katmandaki her becerinin en az bir seviyesi var mı?
func tier_all_learned(tier: int) -> bool:
	var liste := skills_in_tier(tier)
	if liste.is_empty():
		return false
	for id in liste:
		if level_of(id) <= 0:
			return false
	return true


## Katmandaki her beceri sonuna kadar yükseltildi mi?
func tier_mastered(tier: int) -> bool:
	var liste := skills_in_tier(tier)
	if liste.is_empty():
		return false
	for id in liste:
		if level_of(id) < max_level(id):
			return false
	return true


# --- tek beceri ---

func level_of(skill_id: String) -> int:
	return int(learned.get(skill_id, 0))


func max_level(skill_id: String) -> int:
	if not by_id.has(skill_id):
		return 0
	return int((by_id[skill_id] as Dictionary).get("max", 1))


func is_full(skill_id: String) -> bool:
	return level_of(skill_id) >= max_level(skill_id) and max_level(skill_id) > 0


## Bir sonraki seviyenin fiyatı. Her seviye bir öncekinden pahalı.
func cost_of(skill_id: String) -> int:
	if not by_id.has(skill_id):
		return 0
	var taban := int((by_id[skill_id] as Dictionary).get("cost", 100))
	return taban + taban * level_of(skill_id)


## Önkoşullar: gereken becerilerin en az bir seviyesi olmalı.
func prerequisites_met(skill_id: String) -> bool:
	if not by_id.has(skill_id):
		return false
	for gereken in (by_id[skill_id] as Dictionary).get("requires", []):
		if level_of(str(gereken)) <= 0:
			return false
	return true


func can_learn(skill_id: String, gold: int) -> bool:
	if not by_id.has(skill_id):
		return false
	if is_full(skill_id) or not prerequisites_met(skill_id):
		return false
	if not tier_unlocked(tier_of(skill_id)):
		return false
	return gold >= cost_of(skill_id)


## Beceriyi bir seviye yükseltir, harcanan parayı döner (0 = olmadı).
func learn(skill_id: String, gold: int) -> int:
	if not can_learn(skill_id, gold):
		return 0
	var fiyat := cost_of(skill_id)
	learned[skill_id] = level_of(skill_id) + 1
	return fiyat


## Neden öğrenilemiyor — arayüzde gösterilir.
func block_reason(skill_id: String, gold: int) -> String:
	if is_full(skill_id):
		return "en üst seviye"
	var t := tier_of(skill_id)
	if not tier_unlocked(t):
		return "üst katmanda %d seviye gerek (%d/%d)" % [tier_gate(t), levels_above(t), tier_gate(t)]
	if not prerequisites_met(skill_id):
		return "önce bağlı olduğu beceriyi öğren"
	if gold < cost_of(skill_id):
		return "%d altın gerek" % cost_of(skill_id)
	return ""


# --- bonuslar ---

func apply_to(stats: Stats) -> void:
	for id in learned.keys():
		var sid := str(id)
		if not by_id.has(sid):
			continue
		var e: Dictionary = by_id[sid]
		_add(stats, e, level_of(sid))
		# Sonuna kadar yükseltilmiş beceri ek bir bonus açar.
		if is_full(sid) and e.has("full"):
			_add(stats, e["full"] as Dictionary, 1)

	for t in tiers.size():
		var odul: Dictionary = tiers[t]
		if tier_all_learned(t) and odul.has("unlock"):
			_add(stats, odul["unlock"] as Dictionary, 1)
		if tier_mastered(t) and odul.has("master"):
			_add(stats, odul["master"] as Dictionary, 1)


static func _add(stats: Stats, e: Dictionary, times: int) -> void:
	var k := float(times)
	stats.bonus_attack += int(e.get("attack", 0)) * times
	stats.bonus_defense += int(e.get("defense", 0)) * times
	stats.bonus_hp += int(e.get("hp", 0)) * times
	stats.bonus_crit += float(e.get("crit", 0.0)) * k
	stats.bonus_crit_damage += float(e.get("crit_damage", 0.0)) * k
	stats.bonus_pierce += float(e.get("pierce", 0.0)) * k
	stats.bonus_regen += float(e.get("regen", 0.0)) * k
	stats.bonus_move_speed += float(e.get("move_speed", 0.0)) * k
	stats.bonus_attack_speed += float(e.get("attack_speed", 0.0)) * k
	stats.bonus_exp += float(e.get("exp", 0.0)) * k
	stats.bonus_gold += float(e.get("gold", 0.0)) * k
	stats.bonus_drop += float(e.get("drop", 0.0)) * k


func to_dict() -> Dictionary:
	return {"learned": learned.duplicate()}


func load_dict(d: Dictionary) -> void:
	learned.clear()
	var ham = d.get("learned", {})
	if not (ham is Dictionary):
		return
	for id in (ham as Dictionary).keys():
		var sid := str(id)
		if by_id.has(sid):
			learned[sid] = clampi(int((ham as Dictionary)[id]), 0, max_level(sid))
