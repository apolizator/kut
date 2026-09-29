class_name SkillsView
extends RefCounted

## Beceri ağacı (K) — yukarıdan aşağı akan beş katman.
##
## Üstte temeller, aşağı indikçe uzmanlaşma. Bir katmana inebilmek için
## üstteki katmanlarda belli bir toplam seviyeye ulaşmak gerekir; yani
## ağacın dibine koşamazsın, temeli sağlamlaştırmak zorundasın.

const BOX := Vector2(168.0, 62.0)
const GAP := Vector2(180.0, 70.0)

## Bir katmanda yan yana en fazla kaç kutu. Katman bundan kalabalıksa
## alt satıra taşar — 12 düğümlük katmanlar ekrana sığmıyordu.
const PER_ROW := 6

## Katmanlar arası boşluk ve üst şerit.
const TIER_GAP := 26.0
const TOP := 118.0

## Solda katman başlıklarına ayrılan şerit.
const LEFT_GUTTER := 132.0

const BG := Color(0.05, 0.055, 0.07, 0.97)
const TEXT := Color(0.90, 0.91, 0.94)
const DIM := Color(0.55, 0.57, 0.63)
const GOLD := Color(0.95, 0.80, 0.35)
const GREEN := Color(0.52, 0.85, 0.50)
const RED := Color(0.85, 0.47, 0.44)
const LINE := Color(0.50, 0.55, 0.68, 0.40)
const BOX_LOCKED := Color(0.10, 0.10, 0.12, 0.95)
const BOX_READY := Color(0.15, 0.20, 0.28, 0.98)
const BOX_OWNED := Color(0.13, 0.25, 0.17, 0.98)
const BOX_FULL := Color(0.20, 0.33, 0.20, 0.99)

var node_rects: Array[Rect2] = []
var node_ids: Array[String] = []
var scroll: float = 0.0
var max_scroll: float = 0.0

var _font: Font


func _init(font: Font) -> void:
	_font = font


func draw_all(c: CanvasItem, view: Vector2, game: Game, mouse: Vector2) -> void:
	node_rects.clear()
	node_ids.clear()

	c.draw_rect(Rect2(Vector2.ZERO, view), BG)
	_text_center(c, view.x * 0.5, 42.0, "BECERİLER", 20, TEXT, view.x)
	_text_center(c, view.x * 0.5, 64.0,
			"Kutuya tıkla: öğren   ·   Tekerlek: yukarı/aşağı   ·   K veya Esc: kapat",
			11, DIM, view.x)
	_text_center(c, view.x * 0.5, 90.0, "Kesende %d altın" % game.player_gold, 14, GOLD, view.x)

	var tree := game.skills
	var yerler := _layout(view, tree)

	# Bağlantılar önce, kutuların altında kalsın.
	for e in tree.defs:
		var id := str(e.get("id", ""))
		for gereken in e.get("requires", []):
			var g := str(gereken)
			if not (yerler.has(id) and yerler.has(g)):
				continue
			var a: Vector2 = yerler[g]
			var b: Vector2 = yerler[id]
			if b.y - a.y > 1.0:
				c.draw_line(a + Vector2(0.0, BOX.y * 0.5), b - Vector2(0.0, BOX.y * 0.5), LINE, 2.0)
			else:
				# Aynı hizadaki bağ: kutuların yanından geçir.
				c.draw_line(a + Vector2(BOX.x * 0.5, 0.0), b - Vector2(BOX.x * 0.5, 0.0), LINE, 1.5)

	for t in tree.tier_count():
		_draw_tier_header(c, view, tree, t, yerler)

	for e in tree.defs:
		var id := str(e.get("id", ""))
		if yerler.has(id):
			_draw_node(c, yerler[id], e, game, mouse)


func _layout(view: Vector2, tree: SkillTree) -> Dictionary:
	var katman_sayisi := tree.tier_count()

	# Önce her katmanın kaç satır tutacağını hesapla.
	var satir_sayilari: Array[int] = []
	var toplam_satir := 0
	for t in katman_sayisi:
		var n := tree.skills_in_tier(t).size()
		var satir := int(ceil(float(n) / float(PER_ROW)))
		satir_sayilari.append(maxi(1, satir))
		toplam_satir += satir_sayilari[t]

	var icerik := float(toplam_satir) * GAP.y + float(katman_sayisi) * TIER_GAP
	max_scroll = maxf(0.0, icerik - (view.y - TOP - 20.0))
	scroll = clampf(scroll, 0.0, max_scroll)

	var alan := view.x - LEFT_GUTTER - 16.0
	var out := {}
	var y := TOP + BOX.y * 0.5 - scroll
	for t in katman_sayisi:
		var liste := tree.skills_in_tier(t)
		for i in liste.size():
			var satir := i / PER_ROW
			var sutun := i % PER_ROW
			var bu_satirda := mini(PER_ROW, liste.size() - satir * PER_ROW)
			var genislik := float(bu_satirda - 1) * GAP.x
			var sol := LEFT_GUTTER + (alan - genislik) * 0.5
			out[liste[i]] = Vector2(sol + float(sutun) * GAP.x, y + float(satir) * GAP.y)
		y += float(satir_sayilari[t]) * GAP.y + TIER_GAP
	return out


func _draw_tier_header(c: CanvasItem, view: Vector2, tree: SkillTree, tier: int, yerler: Dictionary) -> void:
	var liste := tree.skills_in_tier(tier)
	if liste.is_empty() or not yerler.has(liste[0]):
		return
	var y: float = (yerler[liste[0]] as Vector2).y
	if y < TOP - 40.0 or y > view.y + 40.0:
		return

	var acik := tree.tier_unlocked(tier)
	var tamam := tree.tier_all_learned(tier)
	var usta := tree.tier_mastered(tier)

	var baslik := "KATMAN %d" % (tier + 1)
	var renk := TEXT if acik else RED
	_text_wrapped(c, Vector2(14.0, y - 14.0), baslik, 12, renk)

	var alt := ""
	if not acik:
		alt = "kilitli — üstte %d/%d seviye" % [tree.levels_above(tier), tree.tier_gate(tier)]
	elif usta:
		alt = "◆ tamamen dolduruldu"
	elif tamam:
		alt = "◆ hepsi açıldı"
	else:
		alt = "%d beceri" % liste.size()
	_text_wrapped(c, Vector2(14.0, y + 4.0), _kisalt(alt, 21), 10, GREEN if (usta or tamam) else DIM)

	# Katman ödülü
	if tier < tree.tiers.size():
		var odul: Dictionary = tree.tiers[tier]
		var metin := "hepsi açılınca: " + Mastery.bonus_text(odul.get("unlock", {}))
		if tamam:
			metin = "hepsi dolunca: " + Mastery.bonus_text(odul.get("master", {}))
		_text_wrapped(c, Vector2(14.0, y + 20.0), _kisalt(metin, 19), 9, GOLD if tamam else DIM)
		_text_wrapped(c, Vector2(14.0, y + 32.0), _kisalt(metin.substr(19), 19), 9, GOLD if tamam else DIM)


func _draw_node(c: CanvasItem, center: Vector2, e: Dictionary, game: Game, mouse: Vector2) -> void:
	var id := str(e.get("id", ""))
	var tree := game.skills
	var seviye := tree.level_of(id)
	var tavan := tree.max_level(id)
	var dolu := tree.is_full(id)
	var alinabilir := tree.can_learn(id, game.player_gold)
	var engel := tree.block_reason(id, game.player_gold)

	var r := Rect2(center - BOX * 0.5, BOX)
	if r.position.y + r.size.y < TOP - 4.0:
		return
	node_rects.append(r)
	node_ids.append(id)

	var bg := BOX_LOCKED
	if dolu:
		bg = BOX_FULL
	elif seviye > 0:
		bg = BOX_OWNED
	elif engel.is_empty() or engel.begins_with("%d altın" % tree.cost_of(id)):
		bg = BOX_READY
	if alinabilir and r.has_point(mouse):
		bg = bg.lightened(0.18)
	c.draw_rect(r, bg)
	var kenar := GOLD if alinabilir else (GREEN if dolu else Color(1, 1, 1, 0.12))
	c.draw_rect(r, kenar, false, 2.0 if (alinabilir or dolu) else 1.0)

	_text(c, Vector2(r.position.x + 8.0, r.position.y + 17.0), str(e.get("name", id)), 11,
			TEXT if seviye > 0 or alinabilir else DIM)
	_right(c, r.position.x, r.position.y + 17.0, "%d/%d " % [seviye, tavan], 9,
			GREEN if dolu else DIM, r.size.x)
	_text(c, Vector2(r.position.x + 8.0, r.position.y + 32.0), str(e.get("desc", "")), 9, DIM)

	# Sonuna kadar yükseltilen beceri ek bir bonus açar.
	if e.has("full"):
		var full_metin := "◆ " + Mastery.bonus_text(e["full"] as Dictionary)
		_text(c, Vector2(r.position.x + 8.0, r.position.y + 46.0), _kisalt(full_metin, 25), 9,
				GREEN if dolu else Color(0.55, 0.57, 0.63, 0.7))

	var alt := engel if not engel.is_empty() else "%d altın — tıkla" % tree.cost_of(id)
	var alt_renk := GOLD if alinabilir else (GREEN if dolu else RED)
	if dolu:
		alt = "en üst seviye"
	_text(c, Vector2(r.position.x + 8.0, r.position.y + 59.0), _kisalt(alt, 30), 9, alt_renk)


## Sol şeride sığan metin (kutu genişliğiyle sınırlı değil).
func _text_wrapped(c: CanvasItem, at: Vector2, s: String, size: int, col: Color) -> void:
	c.draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, LEFT_GUTTER - 20.0, size, col)


func _text(c: CanvasItem, at: Vector2, s: String, size: int, col: Color) -> void:
	c.draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, BOX.x - 14.0, size, col)


func _right(c: CanvasItem, x: float, y: float, s: String, size: int, col: Color, w: float) -> void:
	c.draw_string(_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_RIGHT, w, size, col)


func _text_center(c: CanvasItem, x: float, y: float, s: String, size: int, col: Color, w: float) -> void:
	c.draw_string(_font, Vector2(x - w * 0.5, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


static func _kisalt(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, n - 1) + "…"
