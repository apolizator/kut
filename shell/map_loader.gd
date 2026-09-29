class_name MapLoader
extends RefCounted

## data/maps/*.json dosyalarını okur.
##
## Dosya okumak bir MOTOR işidir, bu yüzden core/ içinde değil burada.
## core/MapDef ham bir Dictionary alır ve onu saf veriye çevirir.

const MAPS_DIR := "res://data/maps/"


static func read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Harita dosyası açılamadı: %s" % path)
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("Harita dosyası bozuk: %s" % path)
		return {}
	return parsed


static func index() -> Dictionary:
	return read_json(MAPS_DIR + "index.json")


static func load_all() -> Array[MapDef]:
	var out: Array[MapDef] = []
	for map_id in index().get("maps", []):
		var d := read_json(MAPS_DIR + str(map_id) + ".json")
		if d.is_empty():
			continue
		out.append(MapDef.from_dict(d))
	return out


static func start_map() -> String:
	return str(index().get("start", "umurca_koyu"))
