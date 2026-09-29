class_name MapDef
extends RefCounted

## Bir haritanın tanımı. data/maps/*.json dosyalarından gelir.
##
## Dosyayı core/ OKUMAZ — dosya okumak bir motor işidir. Görsel katman
## JSON'u çözüp buraya saf bir Dictionary verir. Böylece harita tanımları
## sunucuda, testlerde ve 3D sürümde aynı şekilde kullanılabilir.

var id: String = ""
var display_name: String = ""

## Güvenli bölge: şehirlerde canavar yoktur.
var safe: bool = false

## Haritanın yarı genişliği/yüksekliği (birim). Merkez (0,0).
var extent: Vector2 = Vector2(20.0, 15.0)

## Haritaya ilk girişte oyuncunun doğduğu nokta.
var spawn_point: Vector2 = Vector2.ZERO

## Dünya haritası şemasındaki yeri (sadece gösterim için).
var atlas_pos: Vector2 = Vector2.ZERO

## Önerilen seviye aralığı — dünya haritasında gösterilir.
var level_range: Vector2i = Vector2i(1, 1)

## Bu haritanın kendi rastgelelik tohumu. Sabit olduğu için aynı harita
## her girişte aynı düzeni kurar.
var seed_offset: int = 0

## Haritanın sunağı ve bölge bossu (boş olabilir).
var altar: Dictionary = {}
var boss: Dictionary = {}

var npcs: Array[Dictionary] = []
var monsters: Array[Dictionary] = []
var portals: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> MapDef:
	var m := MapDef.new()
	m.id = str(d.get("id", ""))
	m.display_name = str(d.get("name", m.id))
	m.safe = bool(d.get("safe", false))
	m.extent = _to_vec(d.get("extent", [20, 15]))
	m.spawn_point = _to_vec(d.get("spawn", [0, 0]))
	m.atlas_pos = _to_vec(d.get("atlas", [0, 0]))
	m.seed_offset = int(d.get("seed", 0))

	var lr: Array = d.get("levels", [1, 1])
	m.level_range = Vector2i(int(lr[0]), int(lr[1]))

	var alt = d.get("altar", null)
	if alt is Dictionary:
		m.altar = (alt as Dictionary).duplicate()
	var bs = d.get("boss", null)
	if bs is Dictionary:
		m.boss = (bs as Dictionary).duplicate()

	for n in d.get("npcs", []):
		m.npcs.append(n as Dictionary)
	for c in d.get("monsters", []):
		m.monsters.append(c as Dictionary)
	for p in d.get("portals", []):
		m.portals.append(p as Dictionary)
	return m


static func _to_vec(v) -> Vector2:
	if v is Vector2:
		return v
	var a: Array = v
	return Vector2(float(a[0]), float(a[1]))


## Bir noktanın harita sınırları içinde kalmasını sağlar.
func clamp_pos(p: Vector2) -> Vector2:
	return Vector2(
		clampf(p.x, -extent.x, extent.x),
		clampf(p.y, -extent.y, extent.y)
	)
