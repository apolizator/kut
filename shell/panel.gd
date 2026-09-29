class_name Panel2D
extends RefCounted

## Pencerelerin ortak çizim parçaları. Her pencere kendi dosyasında,
## ama kutu/düğme/çubuk/metin hep buradan çizilir ki görünüm tek elden
## çıksın.

const BG := Color(0.08, 0.085, 0.105, 0.97)
const EDGE := Color(1.0, 1.0, 1.0, 0.13)
const TEXT := Color(0.90, 0.91, 0.94)
const DIM := Color(0.58, 0.60, 0.66)
const GOLD := Color(0.95, 0.80, 0.35)
const GREEN := Color(0.52, 0.85, 0.50)
const RED := Color(0.88, 0.45, 0.42)
const ROW := Color(0.13, 0.14, 0.17, 0.95)
const ROW_HOT := Color(0.22, 0.30, 0.42, 0.98)
const BTN := Color(0.20, 0.24, 0.32, 0.95)
const BTN_HOT := Color(0.32, 0.42, 0.58, 0.98)
const BTN_OFF := Color(0.15, 0.16, 0.19, 0.85)

## Slot türüne göre renk — envanterde ve dükkânda bölümleri ayırır.
const SLOT_COLORS := {
	Item.Slot.WEAPON: Color(0.62, 0.78, 1.00),
	Item.Slot.ARMOR: Color(0.58, 0.88, 0.64),
	Item.Slot.HELMET: Color(0.85, 0.80, 0.55),
	Item.Slot.SHIELD: Color(0.70, 0.86, 0.92),
	Item.Slot.BOOTS: Color(0.95, 0.72, 0.50),
	Item.Slot.NONE: Color(0.90, 0.66, 0.90),
}

var font: Font

## Fareyle üstüne gelinen kısaltılmış metnin tamamı. Çizim sırasında
## doldurulur, kare sonunda draw_tooltip ile en üste çizilir.
var tip_text: String = ""
var tip_at: Vector2 = Vector2.ZERO


func _init(f: Font) -> void:
	font = f


## Bir alanın üstündeyken tam metni göster. Kısaltılmış ("…") her
## yazının yanında çağrılır ki kullanıcı devamını görebilsin.
func hover(r: Rect2, mouse: Vector2, full: String) -> void:
	if full.is_empty() or not r.has_point(mouse):
		return
	tip_text = full
	tip_at = mouse


func draw_tooltip(c: CanvasItem, view: Vector2) -> void:
	if tip_text.is_empty():
		return
	var satirlar := tip_text.split("\n")
	var en_genis := 0.0
	for satir in satirlar:
		en_genis = maxf(en_genis, font.get_string_size(satir, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x)
	var w := en_genis + 20.0
	var h := float(satirlar.size()) * 15.0 + 14.0
	var at := tip_at + Vector2(16.0, 16.0)
	at.x = minf(at.x, view.x - w - 8.0)
	at.y = minf(at.y, view.y - h - 8.0)

	var r := Rect2(at, Vector2(w, h))
	c.draw_rect(r, Color(0.04, 0.045, 0.06, 0.98))
	c.draw_rect(r, Color(0.95, 0.80, 0.35, 0.55), false, 1.0)
	for i in satirlar.size():
		text(c, at + Vector2(10.0, 18.0 + float(i) * 15.0), satirlar[i], 11, TEXT)
	tip_text = ""


static func slot_color(s: Item.Slot) -> Color:
	return SLOT_COLORS.get(s, Color(0.80, 0.80, 0.85))


func dim_screen(c: CanvasItem, view: Vector2, alpha: float = 0.72) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, view), Color(0.03, 0.03, 0.045, alpha))


func window(c: CanvasItem, r: Rect2, title: String, subtitle: String = "") -> void:
	c.draw_rect(r, BG)
	c.draw_rect(r, EDGE, false, 1.0)
	center(c, r.position + Vector2(r.size.x * 0.5, 28.0), title, 17, TEXT, r.size.x)
	if not subtitle.is_empty():
		center(c, r.position + Vector2(r.size.x * 0.5, 46.0), subtitle, 11, DIM, r.size.x)


func button(c: CanvasItem, r: Rect2, label: String, enabled: bool, hot: bool) -> void:
	var bg := BTN_OFF
	if enabled:
		bg = BTN_HOT if hot else BTN
	c.draw_rect(r, bg)
	c.draw_rect(r, Color(1, 1, 1, 0.18 if enabled else 0.07), false, 1.0)
	center(c, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5 + 4.0),
			label, 11, TEXT if enabled else Color(0.45, 0.46, 0.50), r.size.x)


func bar(c: CanvasItem, r: Rect2, ratio: float, fill: Color) -> void:
	c.draw_rect(r, Color(0.0, 0.0, 0.0, 0.55))
	var k := clampf(ratio, 0.0, 1.0)
	if k > 0.0:
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), fill)
	c.draw_rect(r, Color(1, 1, 1, 0.16), false, 1.0)


func text(c: CanvasItem, at: Vector2, s: String, size: int, col: Color) -> void:
	c.draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func right(c: CanvasItem, at: Vector2, s: String, size: int, col: Color, width: float) -> void:
	c.draw_string(font, at, s, HORIZONTAL_ALIGNMENT_RIGHT, width, size, col)


func center(c: CanvasItem, at: Vector2, s: String, size: int, col: Color, width: float) -> void:
	c.draw_string(font, Vector2(at.x - width * 0.5, at.y), s, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


static func shorten(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, n - 1) + "…"
