class_name InventoryView
extends RefCounted

## Çanta penceresi (I).
##
## Solda on bir kuşanma yeri, sağda çanta. Çanta slot türüne göre
## bölümlere ayrılır ve her bölüm güçlüden zayıfa sıralanır.

const ROW_H := 25.0
const HEAD_H := 22.0

var equip_rects: Array[Rect2] = []
var equip_slots: Array[Item.Slot] = []
var bag_rects: Array[Rect2] = []
var bag_indexes: Array[int] = []
var scroll: int = 0

var _p: Panel2D


func _init(panel: Panel2D) -> void:
	_p = panel


func draw_all(c: CanvasItem, view: Vector2, game: Game, mouse: Vector2) -> void:
	equip_rects.clear()
	equip_slots.clear()
	bag_rects.clear()
	bag_indexes.clear()

	_p.dim_screen(c, view)
	var w := minf(960.0, view.x - 40.0)
	var h := minf(596.0, view.y - 40.0)
	var r := Rect2((view.x - w) * 0.5, (view.y - h) * 0.5, w, h)
	var yukseltme_sayisi := game.player_inventory.upgrades_available().size()
	var alt := "Çantadakine tıkla: kuşan   ·   Kuşanılıya tıkla: çıkar   ·   Tekerlek: kaydır   ·   I: kapat"
	if yukseltme_sayisi > 0:
		alt = "▲ %d eşya kuşandığından güçlü   ·   %s" % [yukseltme_sayisi, alt]
	_p.window(c, r, "ÇANTA", alt)
	_p.right(c, r.position + Vector2(0.0, 28.0), "%d altın   " % game.player_gold, 13, Panel2D.GOLD, w)

	var ust := r.position.y + 62.0
	_draw_equipment(c, game, r.position.x + 18.0, ust, 290.0, mouse)
	_draw_bag(c, game, r.position.x + 324.0, ust, w - 342.0, h - 80.0, mouse)


func _draw_equipment(c: CanvasItem, game: Game, x: float, y: float, w: float, mouse: Vector2) -> void:
	var inv := game.player_inventory
	_p.text(c, Vector2(x, y + 12.0), "KUŞANILI", 12, Panel2D.DIM)
	_p.right(c, Vector2(x, y + 12.0), "toplam güç %d" % inv.equipped_power(), 11, Panel2D.DIM, w)

	var sy := y + 22.0
	for s in Item.SLOT_ORDER:
		var it := inv.equipped(s)
		var rr := Rect2(x, sy, w, 40.0)
		var sicak := it != null and rr.has_point(mouse)
		c.draw_rect(rr, Panel2D.ROW_HOT if sicak else Panel2D.ROW)
		c.draw_rect(Rect2(x, sy, 3.0, 40.0), Panel2D.slot_color(s))

		_p.text(c, Vector2(x + 12.0, sy + 16.0), Item.slot_name(s), 10, Panel2D.DIM)
		if it == null:
			_p.text(c, Vector2(x + 12.0, sy + 32.0), "— boş —", 11, Panel2D.DIM)
		else:
			_p.text(c, Vector2(x + 12.0, sy + 32.0), Panel2D.shorten(it.display_name, 20), 12, Panel2D.slot_color(s))
			_p.right(c, Vector2(x, sy + 32.0), Panel2D.shorten(it.summary(), 26) + "  ", 10, Panel2D.TEXT, w)
			_p.hover(rr, mouse, "%s\n%s\nÇıkarmak için tıkla" % [it.display_name, it.summary()])
			equip_rects.append(rr)
			equip_slots.append(s)
		sy += 44.0


func _draw_bag(c: CanvasItem, game: Game, x: float, y: float, w: float, h: float, mouse: Vector2) -> void:
	var inv := game.player_inventory
	_p.text(c, Vector2(x, y + 12.0), "ÇANTA  (%d / %d)" % [inv.slots.size(), Inventory.MAX_SLOTS], 12, Panel2D.DIM)

	var gruplar := inv.grouped()
	if gruplar.is_empty():
		_p.text(c, Vector2(x, y + 44.0), "Çantan boş.", 11, Panel2D.DIM)
		return

	# Bölüm başlıkları ve satırlar tek bir akışa dizilir, sonra iki sütuna bölünür.
	var akis: Array[Dictionary] = []
	for g in gruplar:
		akis.append({"head": true, "slot": g["slot"], "count": (g["items"] as Array).size()})
		for e in (g["items"] as Array):
			akis.append({"head": false, "item": e["item"], "index": e["index"], "slot": g["slot"]})

	var sutun_w := (w - 16.0) * 0.5
	var gorunur := int((h - 40.0) / ROW_H)
	var toplam_sutun := 2
	var kapasite := gorunur * toplam_sutun
	scroll = clampi(scroll, 0, maxi(0, akis.size() - kapasite))

	var seviye := game.player.stats.level
	var yukseltmeler := {}
	for idx in inv.upgrades_available():
		yukseltmeler[idx] = true

	for i in range(scroll, mini(akis.size(), scroll + kapasite)):
		var yerel := i - scroll
		var sutun := yerel / gorunur
		var satir := yerel % gorunur
		var rx := x + float(sutun) * (sutun_w + 16.0)
		var ry := y + 34.0 + float(satir) * ROW_H
		var e: Dictionary = akis[i]

		if bool(e["head"]):
			var renk := Panel2D.slot_color(e["slot"])
			_p.text(c, Vector2(rx + 2.0, ry + 15.0),
					"%s (%d)" % [Item.slot_name(e["slot"]), int(e["count"])], 11, renk)
			c.draw_line(Vector2(rx + 2.0, ry + 19.0), Vector2(rx + sutun_w - 2.0, ry + 19.0),
					Color(renk.r, renk.g, renk.b, 0.25), 1.0)
			continue

		var it: Item = e["item"]
		var rr := Rect2(rx, ry, sutun_w, ROW_H - 2.0)
		var yetersiz := it.required_level > seviye
		var sicak := rr.has_point(mouse)
		var yukseltme := yukseltmeler.has(int(e["index"])) and not yetersiz
		var zemin := Panel2D.ROW_HOT if sicak else Panel2D.ROW
		if yukseltme:
			# Kuşandığından güçlü ve henüz takılmamış: göze çarpsın.
			zemin = Color(0.20, 0.30, 0.16, 0.98) if not sicak else Panel2D.ROW_HOT
		c.draw_rect(rr, zemin)
		if yukseltme:
			c.draw_rect(rr, Panel2D.GREEN, false, 2.0)
		var renk2 := Panel2D.slot_color(it.slot)
		if yetersiz:
			renk2 = Panel2D.RED
		var ad := ("▲ " if yukseltme else "") + Panel2D.shorten(it.label(), 16)
		_p.text(c, Vector2(rx + 8.0, ry + 16.0), ad, 11, Panel2D.GREEN if yukseltme else renk2)
		var sag := "Sv.%d" % it.required_level if yetersiz else Panel2D.shorten(it.summary(), 22)
		_p.right(c, Vector2(rx, ry + 16.0), sag + "  ", 10, Panel2D.RED if yetersiz else Panel2D.DIM, sutun_w)
		var ipucu := "%s\n%s\nSv.%d · %d altın" % [it.label(), it.summary(), it.required_level, it.sell_price]
		if yukseltme:
			ipucu += "\n▲ Kuşandığından güçlü — tıkla, kuşan"
		_p.hover(rr, mouse, ipucu)
		bag_rects.append(rr)
		bag_indexes.append(int(e["index"]))

	if akis.size() > kapasite:
		_p.right(c, Vector2(x, y + h - 10.0), "tekerlekle kaydır (%d / %d)  " % [
				scroll + 1, akis.size()], 10, Panel2D.DIM, w)
