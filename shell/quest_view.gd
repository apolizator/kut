class_name QuestView
extends RefCounted

## Görev defteri (J).
##
## Görevler artık NPC'ye gitmeyi gerektirmiyor: nerede olursan ol
## defteri aç, göreve başla, ilerlemeni gör, ödülünü al.

var accept_rects: Array[Rect2] = []
var accept_ids: Array[String] = []
var claim_rects: Array[Rect2] = []
var claim_ids: Array[String] = []
var scroll: int = 0

var _p: Panel2D


func _init(panel: Panel2D) -> void:
	_p = panel


func draw_all(c: CanvasItem, view: Vector2, game: Game, mouse: Vector2) -> void:
	accept_rects.clear()
	accept_ids.clear()
	claim_rects.clear()
	claim_ids.clear()

	_p.dim_screen(c, view)
	var w := minf(900.0, view.x - 40.0)
	var h := minf(580.0, view.y - 40.0)
	var r := Rect2((view.x - w) * 0.5, (view.y - h) * 0.5, w, h)

	var aktif := game.quest_log.active()
	var acik := game.quest_log.available()
	_p.window(c, r, "GÖREV DEFTERİ",
			"Nerede olursan ol görev al ve ödülünü burada topla   ·   Tekerlek: kaydır   ·   J: kapat")
	_p.right(c, r.position + Vector2(0.0, 28.0), "%d altın   " % game.player_gold, 13, Panel2D.GOLD, w)

	var yarim := (w - 54.0) * 0.5
	_draw_active(c, game, r.position.x + 18.0, r.position.y + 62.0, yarim, h - 84.0, aktif, mouse)
	_draw_available(c, game, r.position.x + 36.0 + yarim, r.position.y + 62.0, yarim, h - 84.0, acik, mouse)


func _draw_active(c: CanvasItem, game: Game, x: float, y: float, w: float, h: float,
		liste: Array[Quest], mouse: Vector2) -> void:
	_p.text(c, Vector2(x, y + 12.0), "SÜRENLER  (%d)" % liste.size(), 12, Panel2D.DIM)
	if liste.is_empty():
		_p.text(c, Vector2(x, y + 40.0), "Elinde görev yok. Sağdan birini al.", 11, Panel2D.DIM)
		return

	var sy := y + 24.0
	for q in liste:
		if sy > y + h - 70.0:
			break
		var kutu := Rect2(x, sy, w, 78.0)
		c.draw_rect(kutu, Panel2D.ROW)
		var hazir := q.state == Quest.State.READY
		c.draw_rect(Rect2(x, sy, 3.0, 78.0), Panel2D.GREEN if hazir else Panel2D.GOLD)

		_p.text(c, Vector2(x + 12.0, sy + 20.0), q.title, 13, Panel2D.TEXT)
		_p.right(c, Vector2(x, sy + 20.0), "%d altın · %d EXP  " % [q.reward_gold, q.reward_exp],
				10, Panel2D.GOLD, w)
		_p.text(c, Vector2(x + 12.0, sy + 38.0), Panel2D.shorten(q.description, 52), 10, Panel2D.DIM)

		if hazir:
			_p.text(c, Vector2(x + 12.0, sy + 62.0), "Tamamlandı!", 12, Panel2D.GREEN)
			var br := Rect2(x + w - 108.0, sy + 48.0, 96.0, 24.0)
			_p.button(c, br, "Ödülü Al", true, br.has_point(mouse))
			claim_rects.append(br)
			claim_ids.append(q.quest_id)
		else:
			_p.text(c, Vector2(x + 12.0, sy + 62.0), q.progress_text(), 11, Panel2D.TEXT)
			_p.bar(c, Rect2(x + w - 150.0, sy + 54.0, 138.0, 9.0), q.ratio(), Panel2D.GREEN)
		sy += 84.0


func _draw_available(c: CanvasItem, game: Game, x: float, y: float, w: float, h: float,
		liste: Array[Quest], mouse: Vector2) -> void:
	_p.text(c, Vector2(x, y + 12.0), "ALINABİLİR  (%d)" % liste.size(), 12, Panel2D.DIM)
	if liste.is_empty():
		_p.text(c, Vector2(x, y + 40.0), "Şimdilik yeni görev yok.", 11, Panel2D.DIM)
		return

	var seviye := game.player.stats.level
	var satir_h := 62.0
	var gorunur := int((h - 30.0) / satir_h)
	scroll = clampi(scroll, 0, maxi(0, liste.size() - gorunur))

	var sy := y + 24.0
	for i in range(scroll, mini(liste.size(), scroll + gorunur)):
		var q := liste[i]
		var uygun := seviye >= q.required_level
		var kutu := Rect2(x, sy, w, satir_h - 6.0)
		c.draw_rect(kutu, Panel2D.ROW)

		_p.text(c, Vector2(x + 12.0, sy + 20.0), q.title, 12,
				Panel2D.TEXT if uygun else Panel2D.DIM)
		_p.right(c, Vector2(x, sy + 20.0), "Sv.%d  " % q.required_level, 10,
				Panel2D.DIM if uygun else Panel2D.RED, w)
		_p.text(c, Vector2(x + 12.0, sy + 38.0),
				"%s × %d   ·   %d altın · %d EXP" % [q.target_name, q.target_count, q.reward_gold, q.reward_exp],
				10, Panel2D.DIM)

		var br := Rect2(x + w - 96.0, sy + 28.0, 84.0, 22.0)
		_p.button(c, br, "Kabul Et", uygun, uygun and br.has_point(mouse))
		if uygun:
			accept_rects.append(br)
			accept_ids.append(q.quest_id)
		sy += satir_h

	if liste.size() > gorunur:
		_p.right(c, Vector2(x, y + h - 6.0), "tekerlekle kaydır  ", 10, Panel2D.DIM, w)
