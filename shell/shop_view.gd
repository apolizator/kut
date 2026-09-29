class_name ShopView
extends RefCounted

## Şehirdeki usta penceresi. Dört iş birden yapar:
##   · iksir satar
##   · çantandaki fazlalığı satın alır
##   · aynı eşyadan üç tanesini bir üst kademeye dönüştürür
##   · zincirin sıradaki kalıcı özelliğini satar

const ROW_H := 26.0

var buy_rects: Array[Rect2] = []
var buy_ids: Array[String] = []
var sell_rects: Array[Rect2] = []
var sell_indexes: Array[int] = []
var combine_rects: Array[Rect2] = []
var combine_ids: Array[String] = []
var perk_rect := Rect2()
var perk_id := ""
var sell_all_rect := Rect2()
var close_rect := Rect2()
var scroll: int = 0

var _p: Panel2D


func _init(panel: Panel2D) -> void:
	_p = panel


func draw_all(c: CanvasItem, view: Vector2, game: Game, npc: SimEntity, mouse: Vector2) -> void:
	buy_rects.clear()
	buy_ids.clear()
	sell_rects.clear()
	sell_indexes.clear()
	combine_rects.clear()
	combine_ids.clear()
	perk_rect = Rect2()
	perk_id = ""
	if npc == null:
		return

	_p.dim_screen(c, view)
	var w := minf(960.0, view.x - 40.0)
	var h := minf(620.0, view.y - 40.0)
	var r := Rect2((view.x - w) * 0.5, (view.y - h) * 0.5, w, h)
	_p.window(c, r, npc.display_name, "İksir al · Fazlalığı sat · Üç aynı eşyayı birleştir · Özellik öğren")
	_p.right(c, r.position + Vector2(0.0, 28.0), "%d altın   " % game.player_gold, 13, Panel2D.GOLD, w)

	close_rect = Rect2(r.position.x + w - 92.0, r.position.y + h - 40.0, 76.0, 26.0)
	_p.button(c, close_rect, "Kapat", true, close_rect.has_point(mouse))

	var sol := r.position.x + 18.0
	var sag := r.position.x + w * 0.5 + 8.0
	var yarim := w * 0.5 - 30.0
	var ust := r.position.y + 62.0

	_draw_buy(c, game, sol, ust, yarim, mouse)
	_draw_combine(c, game, sol, ust + 168.0, yarim, mouse)
	_draw_perk(c, game, sol, r.position.y + h - 128.0, yarim, mouse)
	_draw_sell(c, game, sag, ust, yarim, h - 150.0, mouse)


func _draw_buy(c: CanvasItem, game: Game, x: float, y: float, w: float, mouse: Vector2) -> void:
	_p.text(c, Vector2(x, y + 12.0), "SATILIK", 12, Panel2D.DIM)
	var sy := y + 24.0
	for id in game.item_db.shop_items:
		var tpl: Item = game.item_db.templates.get(id, null)
		if tpl == null:
			continue
		var rr := Rect2(x, sy, w, ROW_H - 2.0)
		c.draw_rect(rr, Panel2D.ROW)
		_p.text(c, Vector2(x + 8.0, sy + 17.0), Panel2D.shorten(tpl.display_name, 22), 11, Panel2D.slot_color(tpl.slot))
		_p.text(c, Vector2(x + 168.0, sy + 17.0), Panel2D.shorten(tpl.summary(), 16), 10, Panel2D.DIM)
		_p.hover(rr, mouse, "%s\n%s\nfiyat %d altın" % [tpl.display_name, tpl.summary(), tpl.sell_price])
		var br := Rect2(x + w - 78.0, sy + 2.0, 70.0, ROW_H - 6.0)
		var alabilir := game.player_gold >= tpl.sell_price
		_p.button(c, br, "Al %d" % tpl.sell_price, alabilir, alabilir and br.has_point(mouse))
		if alabilir:
			buy_rects.append(br)
			buy_ids.append(id)
		sy += ROW_H


func _draw_combine(c: CanvasItem, game: Game, x: float, y: float, w: float, mouse: Vector2) -> void:
	_p.text(c, Vector2(x, y + 12.0), "BİRLEŞTİR  —  üç aynı eşya bir üst kademe", 12, Panel2D.DIM)
	var sayim := {}
	for it in game.player_inventory.slots:
		if it.is_equipment() and not it.upgrade_to.is_empty():
			sayim[it.item_id] = int(sayim.get(it.item_id, 0)) + 1

	var sy := y + 24.0
	var bulundu := false
	for id in sayim.keys():
		if int(sayim[id]) < 3 or sy > y + 110.0:
			continue
		bulundu = true
		var tpl: Item = game.item_db.templates.get(id, null)
		var hedef: Item = game.item_db.templates.get(tpl.upgrade_to, null) if tpl != null else null
		var rr := Rect2(x, sy, w, ROW_H - 2.0)
		c.draw_rect(rr, Panel2D.ROW)
		_p.text(c, Vector2(x + 8.0, sy + 17.0),
				"%s ×%d" % [Panel2D.shorten(tpl.display_name, 16), int(sayim[id])], 11,
				Panel2D.slot_color(tpl.slot))
		if hedef != null:
			_p.text(c, Vector2(x + 168.0, sy + 17.0), "→ " + Panel2D.shorten(hedef.display_name, 16), 10, Panel2D.GREEN)
			_p.hover(rr, mouse, "%s ×3  →  %s\n%s" % [tpl.display_name, hedef.display_name, hedef.summary()])
		var br := Rect2(x + w - 84.0, sy + 2.0, 76.0, ROW_H - 6.0)
		_p.button(c, br, "Birleştir", true, br.has_point(mouse))
		combine_rects.append(br)
		combine_ids.append(id)
		sy += ROW_H
	if not bulundu:
		_p.text(c, Vector2(x, y + 44.0), "Aynı eşyadan üç tane biriktir.", 11, Panel2D.DIM)


func _draw_perk(c: CanvasItem, game: Game, x: float, y: float, w: float, mouse: Vector2) -> void:
	_p.text(c, Vector2(x, y + 12.0), "ÖZELLİKLER  —  sırayla açılır (%d alındı)" % game.perks.owned_count(),
			12, Panel2D.DIM)
	var p := game.perks.next_perk()
	if p.is_empty():
		_p.text(c, Vector2(x, y + 38.0), "Bütün özellikleri öğrendin.", 11, Panel2D.GREEN)
		return

	var id := str(p.get("id", ""))
	var seviye := game.player.stats.level
	var alinabilir := game.perks.can_buy(id, game.player_gold, seviye)
	var kutu := Rect2(x, y + 22.0, w, 62.0)
	c.draw_rect(kutu, Panel2D.ROW)
	c.draw_rect(Rect2(x, y + 22.0, 3.0, 62.0), Panel2D.GOLD)
	_p.text(c, Vector2(x + 12.0, y + 42.0), str(p.get("name", id)), 13, Panel2D.TEXT)
	_p.text(c, Vector2(x + 12.0, y + 58.0), str(p.get("desc", "")), 10, Panel2D.DIM)

	var gereken := int(p.get("level", 1))
	var alt := "%d altın" % int(p.get("cost", 0))
	if seviye < gereken:
		alt = "Sv. %d gerekiyor" % gereken
	_p.text(c, Vector2(x + 12.0, y + 76.0), alt, 10, Panel2D.GOLD if alinabilir else Panel2D.RED)

	perk_rect = Rect2(x + w - 96.0, y + 44.0, 88.0, 26.0)
	perk_id = id
	_p.button(c, perk_rect, "Öğren", alinabilir, alinabilir and perk_rect.has_point(mouse))


func _draw_sell(c: CanvasItem, game: Game, x: float, y: float, w: float, h: float, mouse: Vector2) -> void:
	var inv := game.player_inventory
	_p.text(c, Vector2(x, y + 12.0), "ÇANTANDAN SAT", 12, Panel2D.DIM)

	var deger := 0
	for it in inv.slots:
		if it.is_equipment():
			deger += it.sell_price
	sell_all_rect = Rect2(x + w - 176.0, y, 176.0, 22.0)
	_p.button(c, sell_all_rect, "Kuşanılmayanları sat (%d)" % deger, deger > 0,
			deger > 0 and sell_all_rect.has_point(mouse))

	var gruplar := inv.grouped()
	var akis: Array[Dictionary] = []
	for g in gruplar:
		akis.append({"head": true, "slot": g["slot"], "count": (g["items"] as Array).size()})
		for e in (g["items"] as Array):
			akis.append({"head": false, "item": e["item"], "index": e["index"]})

	var gorunur := int((h - 40.0) / ROW_H)
	scroll = clampi(scroll, 0, maxi(0, akis.size() - gorunur))

	for i in range(scroll, mini(akis.size(), scroll + gorunur)):
		var ry := y + 30.0 + float(i - scroll) * ROW_H
		var e: Dictionary = akis[i]
		if bool(e["head"]):
			_p.text(c, Vector2(x + 2.0, ry + 17.0),
					"%s (%d)" % [Item.slot_name(e["slot"]), int(e["count"])], 11,
					Panel2D.slot_color(e["slot"]))
			continue
		var it: Item = e["item"]
		var rr := Rect2(x, ry, w, ROW_H - 2.0)
		c.draw_rect(rr, Panel2D.ROW)
		_p.text(c, Vector2(x + 8.0, ry + 17.0), Panel2D.shorten(it.label(), 20), 11, Panel2D.slot_color(it.slot))
		_p.text(c, Vector2(x + 150.0, ry + 17.0), Panel2D.shorten(it.summary(), 18), 10, Panel2D.DIM)
		_p.hover(rr, mouse, "%s\n%s\nsatış %d altın" % [it.label(), it.summary(), it.sell_price])
		var br := Rect2(x + w - 74.0, ry + 2.0, 66.0, ROW_H - 6.0)
		_p.button(c, br, "Sat %d" % it.sell_price, true, br.has_point(mouse))
		sell_rects.append(br)
		sell_indexes.append(int(e["index"]))

	if akis.size() > gorunur:
		_p.right(c, Vector2(x, y + h - 4.0), "tekerlekle kaydır  ", 10, Panel2D.DIM, w)
