class_name AbilityView
extends RefCounted

## Yetenek defteri (B).
##
## Solda yetenekler, sağda kademe ilerletme. Üç kaynak ayrı ayrı
## gösterilir: beceri puanı, metin kitabı, sunak taşı.

const ROW_H := 86.0

var learn_rects: Array[Rect2] = []
var learn_ids: Array[String] = []
var book_rects: Array[Rect2] = []
var book_ids: Array[String] = []
var stone_rects: Array[Rect2] = []
var stone_ids: Array[String] = []
var slot_rects: Array[Rect2] = []
var slot_ids: Array[String] = []

var _p: Panel2D


func _init(panel: Panel2D) -> void:
	_p = panel


func draw_all(c: CanvasItem, view: Vector2, game: Game, mouse: Vector2) -> void:
	learn_rects.clear()
	learn_ids.clear()
	book_rects.clear()
	book_ids.clear()
	stone_rects.clear()
	stone_ids.clear()
	slot_rects.clear()
	slot_ids.clear()

	_p.dim_screen(c, view)
	var w := minf(900.0, view.x - 40.0)
	var h := minf(600.0, view.y - 40.0)
	var r := Rect2((view.x - w) * 0.5, (view.y - h) * 0.5, w, h)
	_p.window(c, r, "YETENEKLER",
			"Puanla seviye · Kitapla M kademesi · Sunak taşıyla Poly   ·   B veya Esc: kapat")

	var book := game.abilities
	_p.right(c, r.position + Vector2(0.0, 28.0),
			"%d puan   ·   %d kitap   ·   %d taş   " % [book.points, book.books, book.stones],
			12, Panel2D.GOLD, w)

	var x := r.position.x + 18.0
	var y := r.position.y + 60.0
	var ic := w - 36.0

	for a in book.abilities:
		if y > r.position.y + h - ROW_H:
			break
		_draw_row(c, game, a, x, y, ic, mouse)
		y += ROW_H


func _draw_row(c: CanvasItem, game: Game, a: Ability, x: float, y: float, w: float, mouse: Vector2) -> void:
	var book := game.abilities
	var kutu := Rect2(x, y, w, ROW_H - 8.0)
	c.draw_rect(kutu, Panel2D.ROW)
	var renk := Panel2D.GREEN if a.grade == Ability.Grade.POLY else (
			Panel2D.GOLD if a.grade == Ability.Grade.MASTER else Panel2D.TEXT)
	c.draw_rect(Rect2(x, y, 3.0, ROW_H - 8.0), renk if a.is_learned() else Panel2D.DIM)

	var tur := _kind_name(a.kind)
	_p.text(c, Vector2(x + 12.0, y + 20.0), a.display_name, 14, renk if a.is_learned() else Panel2D.DIM)
	_p.text(c, Vector2(x + 12.0 + _w(a.display_name, 14) + 10.0, y + 20.0),
			"[%s]  %s" % [tur, a.grade_label() if a.is_learned() else "öğrenilmedi"], 10, Panel2D.DIM)
	_p.text(c, Vector2(x + 12.0, y + 38.0), a.description, 10, Panel2D.DIM)

	if a.kind != Ability.Kind.PASSIVE:
		_p.text(c, Vector2(x + 12.0, y + 56.0),
				"mana %d   ·   bekleme %.1f sn   ·   güç ×%.2f" % [
					a.total_mana_cost(), float(a.cooldown_ticks) * SimClock.TICK_DELTA, a.effect_scale()],
				10, Panel2D.DIM)
	else:
		_p.text(c, Vector2(x + 12.0, y + 56.0), "sürekli açık   ·   güç ×%.2f" % a.effect_scale(), 10, Panel2D.DIM)

	_p.text(c, Vector2(x + 300.0, y + 56.0), "sıradaki: " + book.next_step(a), 10, Panel2D.GOLD)

	# Düğmeler
	var bx := x + w - 300.0
	var puanla := Rect2(bx, y + 14.0, 92.0, 24.0)
	var acik := book.points > 0 and a.grade == Ability.Grade.NORMAL and a.level < Ability.MAX_NORMAL
	_p.button(c, puanla, "Seviye +1", acik, acik and puanla.has_point(mouse))
	if acik:
		learn_rects.append(puanla)
		learn_ids.append(a.ability_id)

	var kitap := Rect2(bx + 98.0, y + 14.0, 92.0, 24.0)
	var kitap_acik := book.books > 0 and a.level >= Ability.MAX_NORMAL and a.grade != Ability.Grade.POLY \
			and not (a.grade == Ability.Grade.MASTER and a.master_level >= Ability.MAX_MASTER)
	_p.button(c, kitap, "Kitap oku", kitap_acik, kitap_acik and kitap.has_point(mouse))
	if kitap_acik:
		book_rects.append(kitap)
		book_ids.append(a.ability_id)

	var tas := Rect2(bx + 196.0, y + 14.0, 92.0, 24.0)
	var tas_acik := book.stones > 0 and a.grade == Ability.Grade.MASTER and a.master_level >= Ability.MAX_MASTER
	_p.button(c, tas, "Taş kullan", tas_acik, tas_acik and tas.has_point(mouse))
	if tas_acik:
		stone_rects.append(tas)
		stone_ids.append(a.ability_id)

	if a.kind != Ability.Kind.PASSIVE and a.is_learned():
		var yuva := Rect2(bx + 98.0, y + 44.0, 190.0, 22.0)
		var mevcut := book.hotbar.find(a.ability_id)
		_p.button(c, yuva, "Hızlı çubuğa koy" if mevcut < 0 else "Çubukta: %d" % (mevcut + 1),
				true, yuva.has_point(mouse))
		slot_rects.append(yuva)
		slot_ids.append(a.ability_id)


func _w(s: String, size: int) -> float:
	return _p.font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func _kind_name(k: Ability.Kind) -> String:
	match k:
		Ability.Kind.PASSIVE:
			return "pasif"
		Ability.Kind.RANGED:
			return "uzak"
		Ability.Kind.BUFF:
			return "güçlenme"
		_:
			return "alan"
