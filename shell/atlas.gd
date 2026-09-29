class_name Atlas
extends RefCounted

## Dünya haritası: hangi bölge nerede, kaç seviyelik, şu an neredeyiz.
## Bölgelerin yerleşimi harita dosyalarındaki "atlas" alanından,
## aralarındaki yollar ise gerçek geçitlerden çizilir — yani şema
## her zaman oyunun kendisiyle tutarlıdır.

const BOX := Vector2(164.0, 66.0)
const GAP := Vector2(210.0, 116.0)

const BG := Color(0.05, 0.055, 0.07, 0.96)
const LINE := Color(0.55, 0.60, 0.72, 0.55)
const BOX_BG := Color(0.13, 0.15, 0.19, 0.98)
const BOX_HERE := Color(0.20, 0.30, 0.42, 0.98)
const BOX_UNSEEN := Color(0.10, 0.10, 0.12, 0.95)
const TEXT := Color(0.90, 0.91, 0.94)
const TEXT_DIM := Color(0.55, 0.57, 0.63)

## Tıklanabilir bölge kutuları.
var map_rects: Array[Rect2] = []
var map_ids: Array[String] = []

var _font: Font


func _init(font: Font) -> void:
	_font = font


func draw_all(c: CanvasItem, view: Vector2, game: Game) -> void:
	map_rects.clear()
	map_ids.clear()
	c.draw_rect(Rect2(Vector2.ZERO, view), BG)
	c.draw_string(_font, Vector2(0.0, 58.0), "DÜNYA HARİTASI",
			HORIZONTAL_ALIGNMENT_CENTER, view.x, 22, TEXT)
	c.draw_string(_font, Vector2(0.0, 82.0),
			"Gezdiğin bir bölgeye tıkla: oraya ışınlan   ·   M veya Esc: kapat",
			HORIZONTAL_ALIGNMENT_CENTER, view.x, 12, TEXT_DIM)

	var yerler := _layout(view, game)

	# Önce yollar, sonra kutular — çizgiler kutuların altında kalsın.
	for m in game.maps.values():
		for p in m.portals:
			var hedef := str(p.get("to", ""))
			if not yerler.has(m.id) or not yerler.has(hedef):
				continue
			# Her yol bir kez çizilsin.
			if m.id > hedef:
				continue
			c.draw_line(yerler[m.id], yerler[hedef], LINE, 2.0)

	for m in game.maps.values():
		if not yerler.has(m.id):
			continue
		_draw_box(c, yerler[m.id], m, game)


func _layout(view: Vector2, game: Game) -> Dictionary:
	var en_az := Vector2(INF, INF)
	var en_cok := Vector2(-INF, -INF)
	for m in game.maps.values():
		en_az = Vector2(minf(en_az.x, m.atlas_pos.x), minf(en_az.y, m.atlas_pos.y))
		en_cok = Vector2(maxf(en_cok.x, m.atlas_pos.x), maxf(en_cok.y, m.atlas_pos.y))
	if en_az.x > en_cok.x:
		return {}

	var genislik := (en_cok.x - en_az.x) * GAP.x
	var yukseklik := (en_cok.y - en_az.y) * GAP.y
	var sol := (view.x - genislik) * 0.5
	var ust := (view.y - yukseklik) * 0.5 + 20.0

	var out := {}
	for m in game.maps.values():
		out[m.id] = Vector2(
			sol + (m.atlas_pos.x - en_az.x) * GAP.x,
			ust + (m.atlas_pos.y - en_az.y) * GAP.y
		)
	return out


func _draw_box(c: CanvasItem, center: Vector2, m: MapDef, game: Game) -> void:
	var burada := game.current_map != null and game.current_map.id == m.id
	var gorulmus := game.visited.has(m.id)

	var r := Rect2(center - BOX * 0.5, BOX)
	if gorulmus and not burada:
		map_rects.append(r)
		map_ids.append(m.id)
	var bg := BOX_BG
	if burada:
		bg = BOX_HERE
	elif not gorulmus:
		bg = BOX_UNSEEN
	c.draw_rect(r, bg)
	c.draw_rect(r, Color(0.95, 0.80, 0.35, 0.95) if burada else Color(1, 1, 1, 0.14),
			false, 2.0 if burada else 1.0)

	var ad := m.display_name if gorulmus else "? ? ?"
	c.draw_string(_font, Vector2(r.position.x, r.position.y + 26), ad,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, TEXT if gorulmus else TEXT_DIM)

	var alt := ""
	if not gorulmus:
		alt = "keşfedilmedi"
	elif m.safe:
		alt = "Güvenli Bölge"
	else:
		alt = "Seviye %d - %d" % [m.level_range.x, m.level_range.y]
	var alt_renk := TEXT_DIM
	if gorulmus and m.safe:
		alt_renk = Color(0.5, 0.82, 0.55)
	elif gorulmus:
		alt_renk = Color(0.88, 0.62, 0.42)
	c.draw_string(_font, Vector2(r.position.x, r.position.y + 45), alt,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, alt_renk)

	if burada:
		c.draw_string(_font, Vector2(r.position.x, r.position.y + 61), "◆ BURADASIN",
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, Color(0.95, 0.80, 0.35))
	elif gorulmus:
		c.draw_string(_font, Vector2(r.position.x, r.position.y + 61), "tıkla → ışınlan",
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, Color(0.62, 0.78, 0.95))
