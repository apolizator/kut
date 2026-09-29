class_name Item
extends RefCounted

## Kuşanılabilir bir eşya.
##
## Eşya artık kendisi gelişmez — gelişen KARAKTERDİR (core/mastery.gd).
## Eşyanın işi, taşıdığı bonusları karaktere eklemektir. Her slot türü
## farklı türde bonus taşır: kılıç saldırı, ayakkabı hız, küpe ganimet
## şansı, bandana deneyim kazancı...

## Beş kuşanma yeri. Her slotun bonus TÜRÜ sabittir: "bunu mu alsam
## şunu mu" ikilemi yok, tek fark kademe gücü.
enum Slot {
	WEAPON,
	ARMOR,
	HELMET,
	SHIELD,
	BOOTS,
	NONE,   ## kuşanılmaz: iksir, kitap, taş
}

const SLOT_ORDER: Array[Slot] = [
	Slot.WEAPON, Slot.ARMOR, Slot.HELMET, Slot.SHIELD, Slot.BOOTS, Slot.NONE,
]

const SLOT_NAMES := {
	Slot.WEAPON: "Silah",
	Slot.ARMOR: "Zırh",
	Slot.HELMET: "Kask",
	Slot.SHIELD: "Kalkan",
	Slot.BOOTS: "Ayakkabı",
	Slot.NONE: "Kullanılabilir",
}

const SLOT_KEYS := {
	"weapon": Slot.WEAPON,
	"armor": Slot.ARMOR,
	"helmet": Slot.HELMET,
	"shield": Slot.SHIELD,
	"boots": Slot.BOOTS,
	"none": Slot.NONE,
}

var item_id: String = ""
var display_name: String = ""
var slot: Slot = Slot.WEAPON
var required_level: int = 1
var sell_price: int = 10

## Kademe (1'den başlar). Aynı kademeden ÜÇ tanesi bir üst kademeye
## dönüşür; bunu şehirdeki ustalar yapar.
var tier: int = 1
var upgrade_to: String = ""

## Kullanılabilir eşyalar (iksir, kitap, sunak taşı) yığınlanır.
var consumable: bool = false
var count: int = 1
var heal_hp: int = 0
var heal_mp: int = 0
## "book" ya da "stone": yetenek ilerletme malzemesi
var material: String = ""

## Taşıdığı bonuslar: attack, defense, hp, crit, crit_damage, pierce,
## regen, move_speed, attack_speed, exp, gold, drop
var bonus: Dictionary = {}


func apply_bonus(stats: Stats) -> void:
	stats.bonus_attack += int(bonus.get("attack", 0))
	stats.bonus_defense += int(bonus.get("defense", 0))
	stats.bonus_hp += int(bonus.get("hp", 0))
	stats.bonus_crit += float(bonus.get("crit", 0.0))
	stats.bonus_crit_damage += float(bonus.get("crit_damage", 0.0))
	stats.bonus_pierce += float(bonus.get("pierce", 0.0))
	stats.bonus_regen += float(bonus.get("regen", 0.0))
	stats.bonus_move_speed += float(bonus.get("move_speed", 0.0))
	stats.bonus_attack_speed += float(bonus.get("attack_speed", 0.0))
	stats.bonus_exp += float(bonus.get("exp", 0.0))
	stats.bonus_gold += float(bonus.get("gold", 0.0))
	stats.bonus_drop += float(bonus.get("drop", 0.0))
	stats.bonus_lifesteal += float(bonus.get("lifesteal", 0.0))
	stats.bonus_range += float(bonus.get("range", 0.0))
	stats.bonus_mp += float(bonus.get("mp", 0.0))


## Eşyanın toplam ağırlığı. Envanteri güçlüden zayıfa sıralamak ve
## fiyat biçmek için tek bir sayıya indirger.
func power() -> int:
	var p := 0
	p += int(bonus.get("attack", 0)) * 3
	p += int(bonus.get("defense", 0)) * 3
	p += int(bonus.get("hp", 0)) / 4
	p += int(round(float(bonus.get("crit", 0.0)) * 900.0))
	p += int(round(float(bonus.get("crit_damage", 0.0)) * 320.0))
	p += int(round(float(bonus.get("pierce", 0.0)) * 800.0))
	p += int(round(float(bonus.get("regen", 0.0)) * 1000.0))
	p += int(round(float(bonus.get("move_speed", 0.0)) * 220.0))
	p += int(round(float(bonus.get("attack_speed", 0.0)) * 600.0))
	p += int(round(float(bonus.get("exp", 0.0)) * 450.0))
	p += int(round(float(bonus.get("gold", 0.0)) * 350.0))
	p += int(round(float(bonus.get("drop", 0.0)) * 450.0))
	p += int(round(float(bonus.get("lifesteal", 0.0)) * 1200.0))
	p += int(round(float(bonus.get("range", 0.0)) * 300.0))
	return p


func label() -> String:
	return "%s ×%d" % [display_name, count] if consumable and count > 1 else display_name


func is_equipment() -> bool:
	return not consumable and slot != Slot.NONE


func slot_label() -> String:
	return str(SLOT_NAMES.get(slot, "Eşya"))


## Kısa bonus özeti — envanterde ve dükkânda gösterilir.
func summary() -> String:
	var parca: Array[String] = []
	if bonus.has("attack"):
		parca.append("Sal +%d" % int(bonus["attack"]))
	if bonus.has("defense"):
		parca.append("Zırh +%d" % int(bonus["defense"]))
	if bonus.has("hp"):
		parca.append("Can +%d" % int(bonus["hp"]))
	if bonus.has("crit"):
		parca.append("Kri +%%%d" % int(round(float(bonus["crit"]) * 100.0)))
	if bonus.has("crit_damage"):
		parca.append("KrH +%%%d" % int(round(float(bonus["crit_damage"]) * 100.0)))
	if bonus.has("pierce"):
		parca.append("Del +%%%d" % int(round(float(bonus["pierce"]) * 100.0)))
	if bonus.has("regen"):
		parca.append("Yen +%%%.1f" % (float(bonus["regen"]) * 100.0))
	if bonus.has("move_speed"):
		parca.append("Hız +%.1f" % float(bonus["move_speed"]))
	if bonus.has("attack_speed"):
		parca.append("SalHız +%%%d" % int(round(float(bonus["attack_speed"]) * 100.0)))
	if bonus.has("exp"):
		parca.append("EXP +%%%d" % int(round(float(bonus["exp"]) * 100.0)))
	if bonus.has("gold"):
		parca.append("Altın +%%%d" % int(round(float(bonus["gold"]) * 100.0)))
	if bonus.has("drop"):
		parca.append("Ganimet +%%%d" % int(round(float(bonus["drop"]) * 100.0)))
	if bonus.has("lifesteal"):
		parca.append("Can çalma +%%%d" % int(round(float(bonus["lifesteal"]) * 100.0)))
	if bonus.has("range"):
		parca.append("Menzil +%.1f" % float(bonus["range"]))
	if heal_hp > 0:
		parca.append("Can +%d" % heal_hp)
	if heal_mp > 0:
		parca.append("Mana +%d" % heal_mp)
	if material == "book":
		parca.append("yetenek kitabı")
	elif material == "stone":
		parca.append("sunak taşı")
	return "  ".join(parca)


func clone() -> Item:
	var it := Item.new()
	it.item_id = item_id
	it.display_name = display_name
	it.slot = slot
	it.required_level = required_level
	it.sell_price = sell_price
	it.bonus = bonus.duplicate()
	it.tier = tier
	it.upgrade_to = upgrade_to
	it.consumable = consumable
	it.count = 1
	it.heal_hp = heal_hp
	it.heal_mp = heal_mp
	it.material = material
	return it


func to_dict() -> Dictionary:
	return {"id": item_id, "n": count} if consumable else {"id": item_id}


static func from_template(tpl: Item, d: Dictionary) -> Item:
	var it := tpl.clone()
	if it.consumable:
		it.count = maxi(1, int(d.get("n", 1)))
	return it


static func slot_from_text(s: String) -> Slot:
	return SLOT_KEYS.get(s.to_lower(), Slot.WEAPON)


static func slot_name(s: Slot) -> String:
	return str(SLOT_NAMES.get(s, "Eşya"))
