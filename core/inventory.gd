class_name Inventory
extends RefCounted

## Envanter ve kuşanma.
##
## On bir kuşanma yeri var: silah, zırh, kask, kalkan, ayakkabı,
## bilezik, kolye, küpe, yüzük, bandana, dizlik. Her yere bir eşya.

const MAX_SLOTS := 72

var slots: Array[Item] = []

## Slot -> Item
var equipment: Dictionary = {}


func is_full() -> bool:
	return slots.size() >= MAX_SLOTS


func add(it: Item) -> bool:
	if it == null:
		return false
	# Kullanılabilir eşyalar yığınlanır, yer kaplamaz.
	if it.consumable:
		for mevcut in slots:
			if mevcut.consumable and mevcut.item_id == it.item_id:
				mevcut.count += it.count
				return true
	if is_full():
		return false
	slots.append(it)
	return true


## Aynı kimlikten kaç tane var (yığınlar dahil).
func count_of(item_id: String) -> int:
	var n := 0
	for it in slots:
		if it.item_id == item_id:
			n += it.count if it.consumable else 1
	return n


## Bir yığından tek bir tane harcar.
func consume_one(item_id: String) -> Item:
	for i in slots.size():
		var it := slots[i]
		if it.item_id != item_id:
			continue
		if it.consumable and it.count > 1:
			it.count -= 1
			return it
		slots.remove_at(i)
		return it
	return null


## Aynı eşyadan üç tane varsa bir üst kademeye yükseltir.
## Şehirdeki ustaların yaptığı iş; birleşme başarısız olmaz.
func combine(item_id: String, db: ItemDb) -> Item:
	if count_of(item_id) < 3:
		return null
	var ornek: Item = null
	for it in slots:
		if it.item_id == item_id:
			ornek = it
			break
	if ornek == null or ornek.upgrade_to.is_empty() or not db.has(ornek.upgrade_to):
		return null
	for i in 3:
		consume_one(item_id)
	var yeni := db.make(ornek.upgrade_to)
	add(yeni)
	return yeni


## Çantada kuşanılandan daha güçlü, henüz takılmamış bir eşya var mı?
func upgrades_available() -> Array[int]:
	var out: Array[int] = []
	for i in slots.size():
		var it := slots[i]
		if not it.is_equipment():
			continue
		var takili := equipped(it.slot)
		if takili == null or it.power() > takili.power():
			out.append(i)
	return out


func remove_at(index: int) -> Item:
	if index < 0 or index >= slots.size():
		return null
	var it := slots[index]
	slots.remove_at(index)
	return it


func equipped(slot: Item.Slot) -> Item:
	return equipment.get(slot, null)


## Envanterdeki eşyayı kuşanır; o yerdeki eşyayla takas eder.
func equip_at(index: int, player_level: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var yeni := slots[index]
	if not yeni.is_equipment() or yeni.required_level > player_level:
		return false

	var eski := equipped(yeni.slot)
	if eski == null:
		slots.remove_at(index)
	else:
		slots[index] = eski
	equipment[yeni.slot] = yeni
	return true


func unequip(slot: Item.Slot) -> bool:
	var it := equipped(slot)
	if it == null or is_full():
		return false
	equipment.erase(slot)
	slots.append(it)
	return true


## Çantayı bölümlere ayırır: slot türüne göre gruplanır, her grup
## güçlüden zayıfa sıralanır. Dönen dizideki her eleman
## {"slot": Item.Slot, "items": Array[Dictionary{item, index}]}
func grouped() -> Array[Dictionary]:
	var kova := {}
	for i in slots.size():
		var it := slots[i]
		if not kova.has(it.slot):
			kova[it.slot] = []
		(kova[it.slot] as Array).append({"item": it, "index": i})

	var out: Array[Dictionary] = []
	for s in Item.SLOT_ORDER:
		if not kova.has(s):
			continue
		var liste: Array = kova[s]
		liste.sort_custom(func(a, b): return (a["item"] as Item).power() > (b["item"] as Item).power())
		out.append({"slot": s, "items": liste})
	return out


func equipped_power() -> int:
	var t := 0
	for it in equipment.values():
		t += (it as Item).power()
	return t


## Kuşanılan her şeyin bonusunu stat bloğuna yazar.
func apply_to(stats: Stats) -> void:
	for it in equipment.values():
		(it as Item).apply_bonus(stats)


func to_dict() -> Dictionary:
	var liste := []
	for it in slots:
		liste.append(it.to_dict())
	var kusanili := {}
	for s in equipment.keys():
		kusanili[str(int(s))] = (equipment[s] as Item).to_dict()
	return {"slots": liste, "equipment": kusanili}


func load_dict(d: Dictionary, db: ItemDb) -> void:
	slots.clear()
	equipment.clear()
	for raw in d.get("slots", []):
		var it := _rebuild(raw, db)
		if it != null:
			slots.append(it)
	var kusanili = d.get("equipment", {})
	if kusanili is Dictionary:
		for anahtar in (kusanili as Dictionary).keys():
			var it := _rebuild((kusanili as Dictionary)[anahtar], db)
			if it != null:
				equipment[it.slot] = it


func _rebuild(raw, db: ItemDb) -> Item:
	if raw == null or not (raw is Dictionary):
		return null
	var id := str((raw as Dictionary).get("id", ""))
	if not db.has(id):
		return null
	return db.make(id)
