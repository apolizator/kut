class_name StatsView
extends RefCounted

## İstatistik ekranı (T).
##
## Solda oyun boyunca biriken sayaçlar, sağda bu sayaçlara bağlı
## KALICI dönüm noktaları: yeterince canavar kesince güç, yeterince
## yürüyünce hız, yeterince vurunca saldırı hızı açılır.

var _p: Panel2D


func _init(panel: Panel2D) -> void:
	_p = panel


func draw_all(c: CanvasItem, view: Vector2, game: Game) -> void:
	_p.dim_screen(c, view)
	var w := minf(880.0, view.x - 40.0)
	var h := minf(560.0, view.y - 40.0)
	var r := Rect2((view.x - w) * 0.5, (view.y - h) * 0.5, w, h)
	_p.window(c, r, "İSTATİSTİKLER", "T veya Esc: kapat")

	var pr := game.progress
	var yarim := (w - 54.0) * 0.5
	_draw_counters(c, game, pr, r.position.x + 18.0, r.position.y + 62.0, yarim)
	_draw_milestones(c, pr, r.position.x + 36.0 + yarim, r.position.y + 62.0, yarim)


func _draw_counters(c: CanvasItem, game: Game, pr: Progress, x: float, y: float, w: float) -> void:
	_p.text(c, Vector2(x, y + 12.0), "SAYAÇLAR", 12, Panel2D.DIM)
	var st := game.player.stats
	var satirlar := [
		["Seviye", "%d" % st.level],
		["Oynama süresi", _sure(pr.play_seconds())],
		["", ""],
		["Kesilen canavar", _sayi(pr.kills)],
		["Kırılan metin taşı", _sayi(pr.stones_broken)],
		["Yok edilen bekçi", _sayi(pr.guards_killed)],
		["Ölüm", _sayi(pr.deaths)],
		["", ""],
		["Toplam verilen hasar", _sayi(pr.damage_dealt)],
		["Toplam yenilen hasar", _sayi(pr.damage_taken)],
		["Yapılan vuruş", _sayi(pr.attacks)],
		["Kritik vuruş", _sayi(pr.crits)],
		["", ""],
		["Yürünen mesafe", "%s birim" % _sayi(pr.steps)],
		["Kazanılan altın", _sayi(pr.gold_earned)],
		["Kazanılan deneyim", _sayi(pr.exp_earned)],
		["Toplanan ganimet", _sayi(pr.items_looted)],
		["Satılan eşya", _sayi(pr.items_sold)],
		["Biten görev", _sayi(pr.quests_done)],
		["Gezilen bölge", "%d" % game.visited.size()],
	]

	var sy := y + 30.0
	for satir in satirlar:
		if str(satir[0]).is_empty():
			sy += 8.0
			continue
		_p.text(c, Vector2(x + 6.0, sy + 12.0), str(satir[0]), 11, Panel2D.DIM)
		_p.right(c, Vector2(x, sy + 12.0), str(satir[1]) + "  ", 12, Panel2D.TEXT, w)
		sy += 20.0


func _draw_milestones(c: CanvasItem, pr: Progress, x: float, y: float, w: float) -> void:
	_p.text(c, Vector2(x, y + 12.0), "DÖNÜM NOKTALARI", 12, Panel2D.DIM)
	_p.right(c, Vector2(x, y + 12.0), "toplam %d rütbe  " % pr.total_ranks(), 10, Panel2D.GOLD, w)

	var sy := y + 30.0
	for m in pr.milestones():
		var kutu := Rect2(x, sy, w, 76.0)
		c.draw_rect(kutu, Panel2D.ROW)
		c.draw_rect(Rect2(x, sy, 3.0, 76.0), Panel2D.GOLD)

		_p.text(c, Vector2(x + 12.0, sy + 20.0), str(m["name"]), 13, Panel2D.TEXT)
		_p.right(c, Vector2(x, sy + 20.0), "rütbe %d  " % int(m["rank"]), 11, Panel2D.GOLD, w)
		_p.text(c, Vector2(x + 12.0, sy + 38.0),
				"%s %s" % [_sayi(int(m["value"])), str(m["detail"])], 10, Panel2D.DIM)

		var sonraki := int(m["next"])
		if sonraki > 0:
			var onceki := _previous(int(m["value"]), sonraki)
			var oran := float(int(m["value"]) - onceki) / float(maxi(1, sonraki - onceki))
			_p.bar(c, Rect2(x + 12.0, sy + 48.0, w - 24.0, 8.0), oran, Panel2D.GOLD)
			_p.text(c, Vector2(x + 12.0, sy + 70.0),
					"sonraki: %s  →  %s" % [_sayi(sonraki), str(m["reward"])], 10, Panel2D.DIM)
		else:
			_p.text(c, Vector2(x + 12.0, sy + 64.0), "bütün rütbeler açıldı", 10, Panel2D.GREEN)
		sy += 82.0


static func _previous(value: int, next_threshold: int) -> int:
	# Çubuğun başlangıcı: bir önceki eşik. Kabaca yarısı yeterli.
	return maxi(0, mini(value, next_threshold / 2))


static func _sayi(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var sayac := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		sayac += 1
		if sayac % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if n < 0 else "") + out


static func _sure(seconds: int) -> String:
	var sa := seconds / 3600
	var dk := (seconds % 3600) / 60
	if sa > 0:
		return "%d sa %d dk" % [sa, dk]
	return "%d dk %d sn" % [dk, seconds % 60]
