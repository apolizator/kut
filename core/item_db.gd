class_name ItemDb
extends RefCounted

## Eşya şablonları havuzu ve düşme (drop) seçimi.
##
## Dosyayı core/ okumaz; görsel katman data/items.json'u çözüp buraya
## saf bir Dictionary verir.

var templates: Dictionary = {}  ## item_id -> Item (şablon)
var order: Array[String] = []

## Yalnız metin taşından ve sunaktan çıkan özel eşyalar.
var stone_drops: Array[String] = []
var altar_drops: Array[String] = []

## Dükkânda satılanlar ve yetenek malzemelerinin kimlikleri.
var shop_items: Array[String] = []
var book_item: String = ""
var stone_item: String = ""


func load_from(d: Dictionary) -> void:
	for raw in d.get("items", []):
		var e: Dictionary = raw
		var it := Item.new()
		it.item_id = str(e.get("id", ""))
		it.display_name = str(e.get("name", it.item_id))
		it.slot = Item.slot_from_text(str(e.get("slot", "weapon")))
		it.required_level = int(e.get("level", 1))
		it.sell_price = int(e.get("price", 10))
		it.tier = int(e.get("tier", 1))
		it.upgrade_to = str(e.get("upgrade_to", ""))
		it.consumable = bool(e.get("consumable", false))
		it.heal_hp = int(e.get("heal_hp", 0))
		it.heal_mp = int(e.get("heal_mp", 0))
		it.material = str(e.get("material", ""))
		var b = e.get("bonus", {})
		it.bonus = (b as Dictionary).duplicate() if b is Dictionary else {}
		if it.item_id.is_empty():
			continue
		templates[it.item_id] = it
		order.append(it.item_id)

	for id in d.get("stone_drops", []):
		if templates.has(str(id)):
			stone_drops.append(str(id))
	for id in d.get("altar_drops", []):
		if templates.has(str(id)):
			altar_drops.append(str(id))
	for id in d.get("shop", []):
		if templates.has(str(id)):
			shop_items.append(str(id))
	book_item = str(d.get("book_item", ""))
	stone_item = str(d.get("stone_item", ""))


func has(item_id: String) -> bool:
	return templates.has(item_id)


## Şablondan yepyeni (+0) bir kopya üretir.
func make(item_id: String) -> Item:
	if not templates.has(item_id):
		return null
	return (templates[item_id] as Item).clone()


## Metin taşı ve sunak gibi özel hedeflerin garantili ganimeti.
func roll_special(liste: Array[String], rng: SimRng) -> Item:
	if liste.is_empty():
		return null
	return make(liste[rng.int_range(0, liste.size() - 1)])


## Bir canavar öldüğünde ne düşer? Seviyesine uygun olanlar arasından
## ağırlıklı seçim: canavara en yakın seviyedeki eşya en olası olan.
func roll_drop(monster_level: int, rng: SimRng, drop_chance: float) -> Item:
	if not rng.chance(drop_chance):
		return null

	var uygun: Array[String] = []
	var agirlik := PackedInt32Array()
	for id in order:
		var tpl: Item = templates[id]
		if tpl.required_level > monster_level:
			continue
		if stone_drops.has(id) or altar_drops.has(id):
			continue  # özel eşyalar sıradan ganimetten çıkmaz
		if tpl.consumable:
			continue  # iksir ve malzeme ganimet havuzunda değil
		var fark := monster_level - tpl.required_level
		# 0 fark -> 10, her seviye uzaklık ağırlığı yarıya indirir.
		var w := maxi(1, int(round(10.0 / pow(2.0, float(fark)))))
		uygun.append(id)
		agirlik.append(w)

	if uygun.is_empty():
		return null
	var secim := rng.weighted_index(agirlik)
	if secim < 0:
		return null
	return make(uygun[secim])
