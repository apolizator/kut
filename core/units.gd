class_name Units
extends RefCounted

## Dünya birimi <-> ekran pikseli dönüşümü.
##
## KURAL: core/ içindeki HER mesafe, hız ve menzil "birim" cinsindendir,
## asla piksel cinsinden değildir. 1 birim = 1 metre kabul edilir.
## 3D'ye geçildiğinde bu dosyanın dışında hiçbir sayı değişmez;
## sadece buradaki ölçek ve Vector2 -> Vector3 dönüşümü değişir.

const PIXELS_PER_UNIT := 32.0


static func to_px(world_pos: Vector2) -> Vector2:
	return world_pos * PIXELS_PER_UNIT


static func to_world(pixel_pos: Vector2) -> Vector2:
	return pixel_pos / PIXELS_PER_UNIT


static func px(world_length: float) -> float:
	return world_length * PIXELS_PER_UNIT
