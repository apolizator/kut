class_name Mastery
extends RefCounted

## Karakterin KALICI pasif yetenekleri.
##
## Önceden gelişen şey eşyanın kendisiydi (+1, +2 kılıç). Artık gelişen
## KARAKTER: verdiğin hasar silah ustalığını, yediğin hasar zırh
## ustalığını besler. Kazanılan rütbeler kalıcıdır — silahını
## değiştirsen de, ölsen de kaybolmaz. Eşya sadece taban statı verir.

## Rütbe tavanı. Ustalık oyunun sonuna kadar ilerlemeye devam eder.
const MAX_RANK := 30

## Rütbe bonusları KÜMÜLATİFTİR: rütbe 12'deysen 1'den 12'ye kadarki
## bonusların hepsi senindir. Tablo yerine desen kullanılıyor ki 30
## rütbe elle yazılmasın ve ölçek rütbeyle birlikte büyüsün.
##
## Beşin katı olan rütbeler "büyük rütbe": iki bonusu birden verir.


static func weapon_bonus(rank: int) -> Dictionary:
	if rank < 1 or rank > MAX_RANK:
		return {}
	var k := int(ceil(float(rank) / 5.0))  # 1..6, rütbe yükseldikçe ölçek büyür
	match rank % 5:
		1:
			return {"attack": 4 + k * 3}
		2:
			return {"crit": 0.02 + float(k) * 0.004}
		3:
			return {"attack": 6 + k * 4}
		4:
			return {"crit_damage": 0.15 + float(k) * 0.05}
		_:
			return {"pierce": 0.03 + float(k) * 0.005, "attack": 8 + k * 6}


static func armor_bonus(rank: int) -> Dictionary:
	if rank < 1 or rank > MAX_RANK:
		return {}
	var k := int(ceil(float(rank) / 5.0))
	match rank % 5:
		1:
			return {"defense": 4 + k * 3}
		2:
			return {"hp": 60 + k * 40}
		3:
			return {"defense": 6 + k * 4}
		4:
			return {"regen": 0.015 + float(k) * 0.004}
		_:
			return {"hp": 120 + k * 90, "defense": 8 + k * 5}


## Bir bonus sözlüğünü okunur metne çevirir (arayüzde gösterilir).
static func bonus_text(d: Dictionary) -> String:
	var parca: Array[String] = []
	if d.has("attack"):
		parca.append("Saldırı +%d" % int(d["attack"]))
	if d.has("defense"):
		parca.append("Zırh +%d" % int(d["defense"]))
	if d.has("hp"):
		parca.append("Can +%d" % int(d["hp"]))
	if d.has("crit"):
		parca.append("Kritik şansı +%%%d" % int(round(float(d["crit"]) * 100.0)))
	if d.has("crit_damage"):
		parca.append("Kritik hasarı +%%%d" % int(round(float(d["crit_damage"]) * 100.0)))
	if d.has("pierce"):
		parca.append("Delici +%%%d" % int(round(float(d["pierce"]) * 100.0)))
	if d.has("regen"):
		parca.append("Yenilenme +%%%.1f" % (float(d["regen"]) * 100.0))
	return " · ".join(parca)


var weapon_xp: int = 0
var armor_xp: int = 0
var weapon_rank: int = 0
var armor_rank: int = 0


## Bir rütbeden bir üste çıkmak için gereken hasar puanı.
## İlk rütbeler çabuk gelir ki gelişme hemen hissedilsin; üst rütbeler
## doğrusala yakın büyür, böylece 30'a kadar tırmanış mümkün kalır.
static func required(rank: int) -> int:
	if rank >= MAX_RANK:
		return 0
	return 900 + rank * rank * 900 + rank * 4200


## Verilen hasar silah ustalığını besler. Kazanılan rütbe sayısını döner.
func add_weapon_damage(amount: int) -> int:
	return _advance(amount, true)


## Yenilen hasar zırh ustalığını besler.
func add_armor_damage(amount: int) -> int:
	return _advance(amount, false)


func _advance(amount: int, is_weapon: bool) -> int:
	if amount <= 0:
		return 0
	var rank := weapon_rank if is_weapon else armor_rank
	if rank >= MAX_RANK:
		return 0

	var xp := (weapon_xp if is_weapon else armor_xp) + amount
	var kazanilan := 0
	while rank < MAX_RANK:
		var gerekli := required(rank)
		if gerekli <= 0 or xp < gerekli:
			break
		xp -= gerekli
		rank += 1
		kazanilan += 1

	if is_weapon:
		weapon_xp = xp
		weapon_rank = rank
	else:
		armor_xp = xp
		armor_rank = rank
	return kazanilan


func weapon_ratio() -> float:
	if weapon_rank >= MAX_RANK:
		return 1.0
	return clampf(float(weapon_xp) / float(required(weapon_rank)), 0.0, 1.0)


func armor_ratio() -> float:
	if armor_rank >= MAX_RANK:
		return 1.0
	return clampf(float(armor_xp) / float(required(armor_rank)), 0.0, 1.0)


## Kazanılmış bütün rütbelerin bonuslarını stat bloğuna ekler.
func apply_to(stats: Stats) -> void:
	for r in range(1, weapon_rank + 1):
		_add(stats, weapon_bonus(r))
	for r in range(1, armor_rank + 1):
		_add(stats, armor_bonus(r))


static func _add(stats: Stats, bonus: Dictionary) -> void:
	stats.bonus_attack += int(bonus.get("attack", 0))
	stats.bonus_defense += int(bonus.get("defense", 0))
	stats.bonus_hp += int(bonus.get("hp", 0))
	stats.bonus_crit += float(bonus.get("crit", 0.0))
	stats.bonus_crit_damage += float(bonus.get("crit_damage", 0.0))
	stats.bonus_pierce += float(bonus.get("pierce", 0.0))
	stats.bonus_regen += float(bonus.get("regen", 0.0))
	stats.bonus_move_speed += float(bonus.get("move_speed", 0.0))
	stats.bonus_attack_speed += float(bonus.get("attack_speed", 0.0))


## Bir sonraki rütbede ne açılacak (arayüzde gösterilir).
static func next_reward(rank: int, is_weapon: bool) -> String:
	if rank >= MAX_RANK:
		return "en üst rütbe"
	var d := weapon_bonus(rank + 1) if is_weapon else armor_bonus(rank + 1)
	return bonus_text(d)


func to_dict() -> Dictionary:
	return {"wxp": weapon_xp, "wr": weapon_rank, "axp": armor_xp, "ar": armor_rank}


func load_dict(d: Dictionary) -> void:
	weapon_xp = maxi(0, int(d.get("wxp", 0)))
	armor_xp = maxi(0, int(d.get("axp", 0)))
	weapon_rank = clampi(int(d.get("wr", 0)), 0, MAX_RANK)
	armor_rank = clampi(int(d.get("ar", 0)), 0, MAX_RANK)
