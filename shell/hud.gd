class_name Hud
extends RefCounted

## Arayüz çizimi ve tıklanabilir alanları.
##
## Node değil, çizim yardımcısı: main.gd'nin _draw'ı içinden çizer ve
## düğmelerin ekrandaki dikdörtgenlerini dışarı verir. Böylece tıklama
## denetimi tek yerde (main.gd) toplanır ve dokunmatikte de çalışır.

const PANEL_BG := Color(0.10, 0.11, 0.14, 0.93)
const PANEL_EDGE := Color(1.0, 1.0, 1.0, 0.13)
const TEXT := Color(0.90, 0.91, 0.94)
const TEXT_DIM := Color(0.62, 0.64, 0.70)
const HP_FILL := Color(0.80, 0.26, 0.26)
const HP_LOW := Color(0.92, 0.55, 0.18)
const MP_FILL := Color(0.30, 0.48, 0.85)
const EXP_FILL := Color(0.45, 0.76, 0.36)
const BTN_BG := Color(0.20, 0.24, 0.32, 0.95)
const BTN_HOT := Color(0.32, 0.42, 0.58, 0.98)
const BTN_OFF := Color(0.16, 0.17, 0.20, 0.85)
const GEAR_TEXT := Color(0.82, 0.78, 0.62)
const GEAR_FILL := Color(0.72, 0.60, 0.30)
const SLOT_BG := Color(0.14, 0.15, 0.18, 0.95)
const SLOT_EDGE := Color(1.0, 1.0, 1.0, 0.10)
const GOLD := Color(0.95, 0.80, 0.35)

## Tıklanabilir alanlar — main.gd okur.
var attack_rect := Rect2()
var stop_rect := Rect2()
var atlas_rect := Rect2()
var attack_enabled := false

## Stat artırma düğmeleri: "str"/"dex"/"int"/"vit" -> Rect2
var stat_rects: Dictionary = {}

var talk_rect := Rect2()
var talk_enabled := false

## Hızlı çubuk yuvaları (1-6 tuşları).
var hotbar_rects: Array[Rect2] = []

## Sol taraftaki görev takipçisi: tıklanabilir satırlar.
var quest_rects: Array[Rect2] = []
var quest_ids: Array[String] = []
var quest_actions: Array[String] = []  ## "accept" | "claim"

var _font: Font


func _init(font: Font) -> void:
	_font = font


func draw_all(c: CanvasItem, view: Vector2, game: Game, selected: SimEntity, mouse: Vector2) -> void:
	_draw_player_panel(c, game, mouse)
	_draw_map_banner(c, view, game)
	_draw_target_panel(c, view, game, selected, mouse)
	_draw_hint(c, view)


# --- Oyuncu paneli: sol üst ---

func _draw_player_panel(c: CanvasItem, game: Game, mouse: Vector2) -> void:
	stat_rects.clear()
	var p := game.player
	if p == null:
		return
	var r := Rect2(14, 12, 300, 190)
	_panel(c, r)

	var st := p.stats
	var x := r.position.x + 12
	var w := r.size.x - 24

	_text(c, Vector2(x, r.position.y + 24), p.display_name, 16, TEXT)
	_text(c, Vector2(x + _width(p.display_name, 16) + 10, r.position.y + 24), "Sv. %d" % st.level, 13, TEXT_DIM)
	if not p.alive:
		_text_right(c, Vector2(x, r.position.y + 24), "ÖLDÜ", 13, Color(0.95, 0.35, 0.35), w)
	elif st.stat_points > 0:
		_text_right(c, Vector2(x, r.position.y + 24), "%d puan dağıt" % st.stat_points, 12, Color(1.0, 0.85, 0.35), w)

	_bar(c, Rect2(x, r.position.y + 32, w, 12), p.hp_ratio(), HP_LOW if p.hp_ratio() < 0.3 else HP_FILL)
	_text(c, Vector2(x + 6, r.position.y + 42), "CAN  %d / %d" % [maxi(0, p.hp), st.max_hp()], 11, TEXT)
	_bar(c, Rect2(x, r.position.y + 48, w, 9), float(p.mp) / float(maxi(1, st.max_mp())), MP_FILL)
	_text(c, Vector2(x + 6, r.position.y + 56), "MANA  %d / %d" % [maxi(0, p.mp), st.max_mp()], 10, TEXT)
	_bar(c, Rect2(x, r.position.y + 59, w, 7), p.exp_ratio(), EXP_FILL)

	# --- ham statlar ve artırma düğmeleri ---
	var puanli := st.stat_points > 0 and p.alive
	_stat_button(c, x, r.position.y + 80, "str", "STR", st.strength, puanli, mouse)
	_stat_button(c, x + 132, r.position.y + 80, "dex", "DEX", st.dexterity, puanli, mouse)
	_stat_button(c, x, r.position.y + 102, "int", "INT", st.intelligence, puanli, mouse)
	_stat_button(c, x + 132, r.position.y + 102, "vit", "VIT", st.vitality, puanli, mouse)

	_text(c, Vector2(x, r.position.y + 126), "Zırh %d (%%%d)" % [st.defense_value(),
			int(round(st.damage_reduction() * 100.0))], 12, TEXT_DIM)
	_text(c, Vector2(x + 96, r.position.y + 126), "Saldırı %d" % st.attack_power(), 12, TEXT_DIM)
	_text_right(c, Vector2(x, r.position.y + 126), "%d altın" % game.player_gold, 12, GOLD, w)

	# --- ustalıklar: dövüştükçe kendiliğinden gelen kalıcı pasifler ---
	_mastery_row(c, x, r.position.y + 148, w, "Silah Ustalığı", game.mastery.weapon_rank,
			game.mastery.weapon_ratio(), Mastery.next_reward(game.mastery.weapon_rank, true))
	_mastery_row(c, x, r.position.y + 172, w, "Zırh Ustalığı", game.mastery.armor_rank,
			game.mastery.armor_ratio(), Mastery.next_reward(game.mastery.armor_rank, false))


## Bir ustalık satırı: rütbe, ilerleme çubuğu ve bir sonraki ödül.
func _mastery_row(c: CanvasItem, x: float, y: float, w: float, baslik: String, rank: int, ratio: float, sonraki: String) -> void:
	_text(c, Vector2(x, y), baslik, 11, TEXT_DIM)
	_text(c, Vector2(x + 96, y), "R%d" % rank, 11, GEAR_TEXT)
	_bar(c, Rect2(x + 118, y - 8, 64, 6), ratio, GEAR_FILL)
	var not_metni := sonraki if rank < Mastery.MAX_RANK else "en üst rütbe"
	_text(c, Vector2(x + 190, y), not_metni, 10, TEXT_DIM)


func _stat_button(c: CanvasItem, x: float, y: float, key: String, label: String, value: int, enabled: bool, mouse: Vector2) -> void:
	_text(c, Vector2(x, y), "%s %d" % [label, value], 13, TEXT)
	var r := Rect2(x + 76, y - 13, 18, 17)
	stat_rects[key] = r if enabled else Rect2()
	_button(c, r, "+", enabled, enabled and r.has_point(mouse))


# --- Harita afişi: sol alt ---

func _draw_map_banner(c: CanvasItem, view: Vector2, game: Game) -> void:
	var m := game.current_map
	if m == null:
		return
	var r := Rect2(14, view.y - 78, 250, 62)
	_panel(c, r)
	_text(c, Vector2(r.position.x + 12, r.position.y + 24), m.display_name, 15, TEXT)

	var alt := "Güvenli Bölge" if m.safe else "Seviye %d - %d" % [m.level_range.x, m.level_range.y]
	var alt_renk := Color(0.5, 0.82, 0.55) if m.safe else Color(0.88, 0.62, 0.42)
	_text(c, Vector2(r.position.x + 12, r.position.y + 44), alt, 12, alt_renk)

	atlas_rect = Rect2(r.position.x + r.size.x - 74, r.position.y + 28, 62, 22)
	_button(c, atlas_rect, "Harita  M", true, false)


# --- Hedef paneli: sağ üst ---

func _draw_target_panel(c: CanvasItem, view: Vector2, game: Game, t: SimEntity, mouse: Vector2) -> void:
	attack_enabled = false
	if t == null:
		attack_rect = Rect2()
		stop_rect = Rect2()
		talk_rect = Rect2()
		talk_enabled = false
		_text(c, Vector2(view.x - 250, 30), "Bir birime tıkla", 13, TEXT_DIM)
		return

	var r := Rect2(view.x - 282, 12, 268, 172)
	_panel(c, r)

	var st := t.stats
	_text(c, Vector2(r.position.x + 12, r.position.y + 24), t.display_name, 16, _kind_text_color(t.kind))
	_text(c, Vector2(r.position.x + 12, r.position.y + 42), "%s · Sv. %d" % [_kind_name(t.kind), st.level], 12, TEXT_DIM)

	var bar_x := r.position.x + 12
	var bar_w := r.size.x - 24

	if t.alive:
		_bar(c, Rect2(bar_x, r.position.y + 52, bar_w, 12), t.hp_ratio(), HP_FILL)
		_text(c, Vector2(bar_x + 6, r.position.y + 62), "%d / %d" % [maxi(0, t.hp), st.max_hp()], 11, TEXT)
	else:
		_bar(c, Rect2(bar_x, r.position.y + 52, bar_w, 12), 0.0, HP_FILL)
		_text(c, Vector2(bar_x + 6, r.position.y + 62), "ölü — geri gelecek", 11, TEXT_DIM)

	var y := r.position.y + 84
	_stat_row(c, bar_x, y, bar_w, "Zırh", str(st.defense_value()))
	_stat_row(c, bar_x, y + 16, bar_w, "Saldırı Gücü", str(st.attack_power()))
	_stat_row(c, bar_x, y + 32, bar_w, "STR / DEX", "%d / %d" % [st.strength, st.dexterity])
	_stat_row(c, bar_x, y + 48, bar_w, "INT / VIT", "%d / %d" % [st.intelligence, st.vitality])

	# --- komut düğmeleri ---
	var by := r.position.y + r.size.x * 0.0 + 142
	attack_rect = Rect2(bar_x, by, 124, 26)
	stop_rect = Rect2(bar_x + 132, by, 112, 26)

	var p := game.player
	var oyuncu_hazir := p != null and p.alive and t.id != p.id
	talk_enabled = oyuncu_hazir and t.kind == SimEntity.Kind.NPC

	if talk_enabled:
		# NPC'ye vurulmaz; onunla konuşulur.
		attack_enabled = false
		attack_rect = Rect2()
		talk_rect = Rect2(bar_x, by, 124, 26)
		_button(c, talk_rect, "Konuş", true, talk_rect.has_point(mouse))
	else:
		talk_rect = Rect2()
		attack_enabled = t.is_attackable() and oyuncu_hazir
		var saldiriyor := p != null and p.attack_target_id == t.id
		_button(c, attack_rect, "Vazgeç" if saldiriyor else "Saldır", attack_enabled,
				attack_enabled and attack_rect.has_point(mouse))

	_button(c, stop_rect, "Seçimi Bırak", true, stop_rect.has_point(mouse))


## --- Hızlı çubuk: 1-2 iksir, 3-6 yetenek ---

func draw_hotbar(c: CanvasItem, view: Vector2, game: Game, mouse: Vector2, panel: Panel2D) -> void:
	hotbar_rects.clear()
	var book := game.abilities
	var n := book.hotbar.size()
	var kutu := 54.0
	var toplam := float(n) * (kutu + 6.0) - 6.0
	var x := (view.x - toplam) * 0.5
	var y := view.y - 92.0

	for i in n:
		var r := Rect2(x + float(i) * (kutu + 6.0), y, kutu, kutu)
		hotbar_rects.append(r)
		var id := book.hotbar[i]

		c.draw_rect(r, SLOT_BG)
		c.draw_rect(r, SLOT_EDGE, false, 1.0)
		_text(c, Vector2(r.position.x + 4.0, r.position.y + 13.0), str(i + 1), 10, TEXT_DIM)

		if id.is_empty():
			_text_center(c, Vector2(r.position.x + kutu * 0.5, r.position.y + 34.0), "—", 12, TEXT_DIM, kutu)
			continue

		var a := book.get_ability(id)
		if a != null:
			var hazir := a.ready(game.player.mp)
			_text_center(c, Vector2(r.position.x + kutu * 0.5, r.position.y + 30.0),
					_kisalt(a.display_name.split(" ")[0], 8), 10,
					GEAR_TEXT if hazir else Color(0.45, 0.46, 0.50), kutu)
			_text_center(c, Vector2(r.position.x + kutu * 0.5, r.position.y + 44.0),
					a.grade_label(), 10, GOLD if hazir else TEXT_DIM, kutu)
			if a.cooldown_left > 0:
				var oran := float(a.cooldown_left) / float(maxi(1, a.cooldown_ticks))
				c.draw_rect(Rect2(r.position.x, r.position.y + kutu * (1.0 - oran),
						kutu, kutu * oran), Color(0.0, 0.0, 0.0, 0.55))
			panel.hover(r, mouse, "%s [%s]\n%s\nmana %d · bekleme %.1f sn" % [
					a.display_name, a.grade_label(), a.description,
					a.total_mana_cost(), float(a.cooldown_ticks) * SimClock.TICK_DELTA])
			continue

		# İksir yuvası
		var adet := game.player_inventory.count_of(id)
		var tpl: Item = game.item_db.templates.get(id, null)
		var ad := tpl.display_name.split(" ")[0] if tpl != null else id
		_text_center(c, Vector2(r.position.x + kutu * 0.5, r.position.y + 30.0),
				_kisalt(ad, 8), 10, TEXT if adet > 0 else Color(0.45, 0.46, 0.50), kutu)
		_text_center(c, Vector2(r.position.x + kutu * 0.5, r.position.y + 45.0),
				"×%d" % adet, 11, GOLD if adet > 0 else TEXT_DIM, kutu)
		if tpl != null:
			panel.hover(r, mouse, "%s\n%s\nçantanda %d tane" % [tpl.display_name, tpl.summary(), adet])


## --- Görev takipçisi: hep açık, sol tarafta ---
##
## Alınabilir görevler altın çerçeveyle YANIP SÖNER; tıklayınca alınır.
## Tamamlananlar yeşile döner, tıklayınca ödül alınır.

func draw_quest_tracker(c: CanvasItem, view: Vector2, game: Game, mouse: Vector2, t: float) -> void:
	quest_rects.clear()
	quest_ids.clear()
	quest_actions.clear()

	var seviye := game.player.stats.level
	var aktif := game.quest_log.active()
	var acik := game.quest_log.available()

	# Seviyene uygun, henüz alınmamış görevler
	var alinabilir: Array[Quest] = []
	for q in acik:
		if q.required_level <= seviye:
			alinabilir.append(q)
		if alinabilir.size() >= 4:
			break

	if aktif.is_empty() and alinabilir.is_empty():
		return

	var w := 250.0
	var x := 14.0
	var y := 212.0
	var parla := 0.55 + 0.45 * sin(t * 3.2)

	_text(c, Vector2(x + 4, y), "GÖREVLER", 11, TEXT_DIM)
	y += 10.0

	for q in aktif:
		var hazir := q.state == Quest.State.READY
		var h := 46.0
		var r := Rect2(x, y, w, h)
		var sicak := r.has_point(mouse)
		c.draw_rect(r, Color(0.10, 0.16, 0.10, 0.92) if hazir else Color(0.09, 0.10, 0.13, 0.88))
		var kenar := Color(0.45, 0.90, 0.45, parla if hazir else 0.30)
		c.draw_rect(r, kenar, false, 2.0 if hazir else 1.0)
		if sicak and hazir:
			c.draw_rect(r, Color(1, 1, 1, 0.06))

		_text(c, Vector2(x + 8, y + 16), _kisalt(q.title, 26), 11, TEXT)
		if hazir:
			_text(c, Vector2(x + 8, y + 33), "TAMAMLANDI — tıkla, ödülü al", 10, Color(0.55, 0.95, 0.55, parla))
			quest_rects.append(r)
			quest_ids.append(q.quest_id)
			quest_actions.append("claim")
		else:
			_text(c, Vector2(x + 8, y + 33), q.progress_text(), 10, TEXT_DIM)
			_bar(c, Rect2(x + w - 92, y + 26, 84, 7), q.ratio(), EXP_FILL)
		y += h + 4.0

	for q in alinabilir:
		var h2 := 42.0
		var r2 := Rect2(x, y, w, h2)
		var sicak2 := r2.has_point(mouse)
		c.draw_rect(r2, Color(0.15, 0.13, 0.07, 0.92) if sicak2 else Color(0.11, 0.10, 0.07, 0.88))
		c.draw_rect(r2, Color(0.95, 0.80, 0.35, parla), false, 2.0)
		_text(c, Vector2(x + 8, y + 16), "★ " + _kisalt(q.title, 24), 11, Color(1.0, 0.88, 0.45))
		_text(c, Vector2(x + 8, y + 32), "%s × %d  ·  tıkla ve başla" % [
				_kisalt(q.target_name, 14), q.target_count], 10, TEXT_DIM)
		quest_rects.append(r2)
		quest_ids.append(q.quest_id)
		quest_actions.append("accept")
		y += h2 + 4.0


## Görev tamamlandığında ekranın üstünde beliren şerit.
func draw_quest_banner(c: CanvasItem, view: Vector2, title: String, alpha: float, t: float) -> void:
	if title.is_empty() or alpha <= 0.0:
		return
	var parla := 0.6 + 0.4 * sin(t * 4.0)
	var w := 460.0
	var r := Rect2((view.x - w) * 0.5, 64.0, w, 56.0)
	c.draw_rect(r, Color(0.08, 0.16, 0.09, 0.94 * alpha))
	c.draw_rect(r, Color(0.5, 0.95, 0.5, parla * alpha), false, 2.0)
	_text_center(c, Vector2(r.position.x + w * 0.5, r.position.y + 24), "GÖREV TAMAMLANDI", 16,
			Color(0.6, 1.0, 0.6, alpha), w)
	_text_center(c, Vector2(r.position.x + w * 0.5, r.position.y + 44),
			"%s  —  J tuşundan ya da soldaki listeden ödülünü al" % title, 11,
			Color(0.85, 0.95, 0.85, alpha), w)


func _draw_hint(c: CanvasItem, view: Vector2) -> void:
	var s := "WASD: yürü · Boşluk: vur · 1-6: çubuk · F: oto av · G: oto metin · I: çanta · B: yetenek · K: beceri · J: görev · T: istatistik · M: harita · Esc: çık"
	_text_center(c, Vector2(view.x * 0.5, view.y - 22), s, 12, Color(1, 1, 1, 0.38), view.x)


# --- ortak çizim parçaları ---

func _panel(c: CanvasItem, r: Rect2) -> void:
	c.draw_rect(r, PANEL_BG)
	c.draw_rect(r, PANEL_EDGE, false, 1.0)


func _button(c: CanvasItem, r: Rect2, label: String, enabled: bool, hot: bool) -> void:
	var bg := BTN_OFF
	if enabled:
		bg = BTN_HOT if hot else BTN_BG
	c.draw_rect(r, bg)
	c.draw_rect(r, Color(1, 1, 1, 0.18 if enabled else 0.07), false, 1.0)
	var col := TEXT if enabled else Color(0.45, 0.46, 0.50)
	_text_center(c, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5 + 5), label, 12, col, r.size.x)


func _stat_row(c: CanvasItem, x: float, y: float, w: float, label: String, value: String) -> void:
	_text(c, Vector2(x, y), label, 12, TEXT_DIM)
	_text_right(c, Vector2(x, y), value, 12, TEXT, w)


func _bar(c: CanvasItem, r: Rect2, ratio: float, fill: Color) -> void:
	c.draw_rect(r, Color(0.0, 0.0, 0.0, 0.55))
	var k := clampf(ratio, 0.0, 1.0)
	if k > 0.0:
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), fill)
	c.draw_rect(r, Color(1, 1, 1, 0.16), false, 1.0)


func _text(c: CanvasItem, at: Vector2, s: String, size: int, col: Color) -> void:
	c.draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _text_right(c: CanvasItem, at: Vector2, s: String, size: int, col: Color, width: float) -> void:
	c.draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_RIGHT, width, size, col)


func _text_center(c: CanvasItem, at: Vector2, s: String, size: int, col: Color, width: float) -> void:
	c.draw_string(_font, Vector2(at.x - width * 0.5, at.y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


static func _kisalt(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, n - 1) + "…"


func _width(s: String, size: int) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func _kind_name(k: SimEntity.Kind) -> String:
	match k:
		SimEntity.Kind.PLAYER:
			return "Oyuncu"
		SimEntity.Kind.NPC:
			return "Köylü"
		SimEntity.Kind.STONE:
			return "Metin Taşı"
		SimEntity.Kind.ALTAR:
			return "SUNAK"
		_:
			return "Canavar"


static func _kind_text_color(k: SimEntity.Kind) -> Color:
	match k:
		SimEntity.Kind.PLAYER:
			return Color(0.55, 0.76, 1.0)
		SimEntity.Kind.NPC:
			return Color(0.60, 0.88, 0.62)
		SimEntity.Kind.STONE:
			return Color(0.78, 0.60, 0.98)
		SimEntity.Kind.ALTAR:
			return Color(0.98, 0.82, 0.38)
		_:
			return Color(0.96, 0.55, 0.52)
