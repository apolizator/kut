class_name Ability
extends RefCounted

## Mana harcayarak kullanılan yetenek ya da kalıcı bir pasif.
##
## İlerleme Metin2'nin kademelerini izler:
##   Seviye 1-20  → her karakter seviyesinde kazanılan beceri puanıyla
##   M1-M10       → metin taşlarından düşen KİTAPLARLA
##   Poly         → sunaklardan çıkan TAŞLARLA
##
## Her kademe atlandığında güç belirgin biçimde sıçrar.

enum Kind {
	PASSIVE,  ## sürekli açık, mana harcamaz
	MELEE,    ## çevrendeki düşmanlara toplu vuruş
	RANGED,   ## uzaktaki hedefe atış
	BUFF,     ## bir süre kendine güç katar
}

enum Grade {
	NORMAL,
	MASTER,
	POLY,
}

const MAX_NORMAL := 20
const MAX_MASTER := 10

var ability_id: String = ""
var display_name: String = ""
var description: String = ""
var kind: Kind = Kind.MELEE

var mana_cost: int = 0
var cooldown_ticks: int = 0

## Hasar çarpanı ve etki alanı (dünya birimi).
var power: float = 1.0
var radius: float = 0.0
var cast_range: float = 0.0

## Pasif yeteneğin her seviyede verdiği bonuslar.
var bonus: Dictionary = {}

## İlerleme durumu
var level: int = 0
var grade: Grade = Grade.NORMAL
var master_level: int = 0
var book_progress: int = 0   ## M kademesi için okunan kitap
var stone_progress: int = 0  ## Poly için harcanan sunak taşı

## Soğuma sayacı (tick)
var cooldown_left: int = 0


func is_learned() -> bool:
	return level > 0


## Kademeyle birlikte büyüyen etkinlik katsayısı.
## M1'de bir sıçrama, Poly'de daha büyük bir sıçrama var.
func effect_scale() -> float:
	var k := float(level) / float(MAX_NORMAL)
	match grade:
		Grade.MASTER:
			return 1.6 + float(master_level) * 0.22
		Grade.POLY:
			return 7.5
		_:
			return 0.35 + k * 0.85


func grade_label() -> String:
	match grade:
		Grade.MASTER:
			return "M%d" % master_level
		Grade.POLY:
			return "POLY"
		_:
			return "%d" % level


## Bu yetenek şu an kullanılabilir mi?
func ready(current_mp: int) -> bool:
	return is_learned() and kind != Kind.PASSIVE and cooldown_left <= 0 and current_mp >= mana_cost


func total_mana_cost() -> int:
	return int(round(float(mana_cost) * (1.0 + float(level) * 0.03)))


## Pasif yeteneğin kazanılmış bonusunu stat bloğuna yazar.
func apply_passive(stats: Stats) -> void:
	if kind != Kind.PASSIVE or level <= 0:
		return
	var k := effect_scale()
	stats.bonus_attack += int(round(float(bonus.get("attack", 0)) * k))
	stats.bonus_defense += int(round(float(bonus.get("defense", 0)) * k))
	stats.bonus_hp += int(round(float(bonus.get("hp", 0)) * k))
	stats.bonus_attack_speed += float(bonus.get("attack_speed", 0.0)) * k
	stats.bonus_move_speed += float(bonus.get("move_speed", 0.0)) * k
	stats.bonus_crit += float(bonus.get("crit", 0.0)) * k
	stats.bonus_crit_damage += float(bonus.get("crit_damage", 0.0)) * k
	stats.bonus_lifesteal += float(bonus.get("lifesteal", 0.0)) * k
	stats.bonus_range += float(bonus.get("range", 0.0)) * k
	stats.bonus_mp += float(bonus.get("mp", 0.0)) * k
	stats.bonus_mp_regen += float(bonus.get("mp_regen", 0.0)) * k


static func from_dict(d: Dictionary) -> Ability:
	var a := Ability.new()
	a.ability_id = str(d.get("id", ""))
	a.display_name = str(d.get("name", a.ability_id))
	a.description = str(d.get("desc", ""))
	a.kind = _kind_from(str(d.get("kind", "melee")))
	a.mana_cost = int(d.get("mana", 0))
	a.cooldown_ticks = int(d.get("cooldown", 0))
	a.power = float(d.get("power", 1.0))
	a.radius = float(d.get("radius", 0.0))
	a.cast_range = float(d.get("range", 0.0))
	var b = d.get("bonus", {})
	a.bonus = (b as Dictionary).duplicate() if b is Dictionary else {}
	return a


static func _kind_from(s: String) -> Kind:
	match s.to_lower():
		"passive":
			return Kind.PASSIVE
		"ranged":
			return Kind.RANGED
		"buff":
			return Kind.BUFF
		_:
			return Kind.MELEE


func to_dict() -> Dictionary:
	return {
		"id": ability_id, "lv": level, "gr": int(grade),
		"m": master_level, "bp": book_progress, "sp": stone_progress,
	}


func load_dict(d: Dictionary) -> void:
	level = clampi(int(d.get("lv", 0)), 0, MAX_NORMAL)
	grade = clampi(int(d.get("gr", 0)), 0, 2) as Grade
	master_level = clampi(int(d.get("m", 0)), 0, MAX_MASTER)
	book_progress = maxi(0, int(d.get("bp", 0)))
	stone_progress = maxi(0, int(d.get("sp", 0)))
