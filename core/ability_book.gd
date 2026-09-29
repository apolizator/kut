class_name AbilityBook
extends RefCounted

## Karakterin yetenek defteri ve üç ayrı ilerleme kaynağı:
##   · beceri puanı — her karakter seviyesinde bir tane
##   · kitap        — metin taşlarından düşer, M kademesini açar
##   · sunak taşı   — sunaklardan çıkar, Poly kademesini açar

## M1'e geçmek için gereken kitap; sonraki her M için artar.
const BOOKS_FOR_MASTER := 4
const STONES_FOR_POLY := 10

var abilities: Array[Ability] = []
var by_id: Dictionary = {}

var points: int = 0
var books: int = 0
var stones: int = 0

## Hızlı çubuktaki yerleşim: yuva -> ability_id ya da item_id
var hotbar: Array[String] = ["", "", "", "", "", ""]


func load_defs(d: Dictionary) -> void:
	abilities.clear()
	by_id.clear()
	for raw in d.get("abilities", []):
		var a := Ability.from_dict(raw as Dictionary)
		if a.ability_id.is_empty():
			continue
		abilities.append(a)
		by_id[a.ability_id] = a


func get_ability(id: String) -> Ability:
	return by_id.get(id, null)


func learned() -> Array[Ability]:
	var out: Array[Ability] = []
	for a in abilities:
		if a.is_learned():
			out.append(a)
	return out


## Beceri puanıyla bir seviye yükselt.
func spend_point(id: String) -> bool:
	var a := get_ability(id)
	if a == null or points <= 0:
		return false
	if a.grade != Ability.Grade.NORMAL or a.level >= Ability.MAX_NORMAL:
		return false
	a.level += 1
	points -= 1
	return true


## Kaçıncı kitap gerekiyor?
func books_needed(a: Ability) -> int:
	if a.grade == Ability.Grade.NORMAL:
		return BOOKS_FOR_MASTER
	return BOOKS_FOR_MASTER + a.master_level


## Metin kitabı oku — M kademesini ilerletir.
func read_book(id: String) -> bool:
	var a := get_ability(id)
	if a == null or books <= 0:
		return false
	if a.level < Ability.MAX_NORMAL:
		return false  # önce normal seviyeyi doldur
	if a.grade == Ability.Grade.POLY:
		return false
	if a.grade == Ability.Grade.MASTER and a.master_level >= Ability.MAX_MASTER:
		return false

	books -= 1
	a.book_progress += 1
	if a.book_progress < books_needed(a):
		return true

	a.book_progress = 0
	if a.grade == Ability.Grade.NORMAL:
		a.grade = Ability.Grade.MASTER
		a.master_level = 1
	else:
		a.master_level += 1
	return true


## Sunak taşı kullan — M10'dan Poly'ye geçirir.
func use_stone(id: String) -> bool:
	var a := get_ability(id)
	if a == null or stones <= 0:
		return false
	if a.grade != Ability.Grade.MASTER or a.master_level < Ability.MAX_MASTER:
		return false

	stones -= 1
	a.stone_progress += 1
	if a.stone_progress >= STONES_FOR_POLY:
		a.stone_progress = 0
		a.grade = Ability.Grade.POLY
	return true


## Bir sonraki kademeye ne gerekiyor (arayüz metni).
func next_step(a: Ability) -> String:
	if a.level < Ability.MAX_NORMAL:
		return "beceri puanı (%d/%d)" % [a.level, Ability.MAX_NORMAL]
	if a.grade == Ability.Grade.NORMAL:
		return "kitap (%d/%d)" % [a.book_progress, books_needed(a)]
	if a.grade == Ability.Grade.MASTER and a.master_level < Ability.MAX_MASTER:
		return "kitap (%d/%d)" % [a.book_progress, books_needed(a)]
	if a.grade == Ability.Grade.MASTER:
		return "sunak taşı (%d/%d)" % [a.stone_progress, STONES_FOR_POLY]
	return "en üst kademe"


func apply_to(stats: Stats) -> void:
	for a in abilities:
		a.apply_passive(stats)


func tick_cooldowns() -> void:
	for a in abilities:
		if a.cooldown_left > 0:
			a.cooldown_left -= 1


func to_dict() -> Dictionary:
	var liste := []
	for a in abilities:
		if a.is_learned():
			liste.append(a.to_dict())
	return {"abilities": liste, "points": points, "books": books,
			"stones": stones, "hotbar": hotbar.duplicate()}


func load_dict(d: Dictionary) -> void:
	points = maxi(0, int(d.get("points", 0)))
	books = maxi(0, int(d.get("books", 0)))
	stones = maxi(0, int(d.get("stones", 0)))
	for raw in d.get("abilities", []):
		var e: Dictionary = raw
		var a := get_ability(str(e.get("id", "")))
		if a != null:
			a.load_dict(e)
	var hb = d.get("hotbar", null)
	if hb is Array:
		for i in mini(hotbar.size(), (hb as Array).size()):
			hotbar[i] = str((hb as Array)[i])
