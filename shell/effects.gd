class_name Effects
extends RefCounted

## Vuruş kıvılcımları, yükselen halkalar ve kamera sarsıntısı.
##
## Tamamen görsel: simülasyona hiç dokunmaz, sadece core'un ürettiği
## olaylara bakarak çizer. Faz 6'da 3D'ye geçilince bu dosya atılır.

const MAX_PARTICLES := 260

## {pos, vel, life, age, size, color}
var particles: Array[Dictionary] = []

## {pos, r0, r1, life, age, color, width}
var rings: Array[Dictionary] = []

var shake: float = 0.0
var shake_seed: float = 0.0


## Bir vuruşun kıvılcımları.
func burst(at: Vector2, color: Color, amount: int, speed: float = 5.0) -> void:
	for i in amount:
		if particles.size() >= MAX_PARTICLES:
			return
		var aci := randf() * TAU
		var h := speed * (0.45 + randf() * 0.75)
		particles.append({
			"pos": at, "vel": Vector2.from_angle(aci) * h,
			"life": 0.30 + randf() * 0.35, "age": 0.0,
			"size": 1.6 + randf() * 2.4, "color": color,
		})


## Genişleyen bir halka: yetenekler, ölümler, seviye atlama.
func ring(at: Vector2, r0: float, r1: float, color: Color, life: float = 0.5, width: float = 3.0) -> void:
	rings.append({"pos": at, "r0": r0, "r1": r1, "life": life, "age": 0.0,
			"color": color, "width": width})


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 14.0)
	shake_seed = randf() * 100.0


func update(delta: float) -> void:
	var kalan: Array[Dictionary] = []
	for p in particles:
		p["age"] = float(p["age"]) + delta
		if float(p["age"]) >= float(p["life"]):
			continue
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["vel"] = (p["vel"] as Vector2) * (1.0 - 3.2 * delta)
		kalan.append(p)
	particles = kalan

	var halka: Array[Dictionary] = []
	for r in rings:
		r["age"] = float(r["age"]) + delta
		if float(r["age"]) < float(r["life"]):
			halka.append(r)
	rings = halka

	shake = maxf(0.0, shake - delta * 26.0)


## Kameraya eklenecek sarsıntı kayması (piksel).
func shake_offset(t: float) -> Vector2:
	if shake <= 0.0:
		return Vector2.ZERO
	return Vector2(sin(t * 47.0 + shake_seed) , cos(t * 39.0 + shake_seed * 1.7)) * shake


## world_to_screen: dünya noktasını ekrana çeviren fonksiyon.
func draw_all(c: CanvasItem, to_screen: Callable, px_per_unit: float) -> void:
	for r in rings:
		var k := float(r["age"]) / float(r["life"])
		var yaricap: float = lerpf(float(r["r0"]), float(r["r1"]), k)
		var col: Color = r["color"]
		col.a *= 1.0 - k
		c.draw_arc(to_screen.call(r["pos"]), yaricap * px_per_unit, 0.0, TAU, 40, col, float(r["width"]))

	for p in particles:
		var k2 := float(p["age"]) / float(p["life"])
		var col2: Color = p["color"]
		col2.a *= 1.0 - k2 * k2
		c.draw_circle(to_screen.call(p["pos"]), float(p["size"]) * (1.0 - k2 * 0.5), col2)
