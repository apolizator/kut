class_name SaveFile
extends RefCounted

## Kayıt dosyasının diske yazılması. Sadece dosya işi; neyin
## kaydedileceğine core/save_state.gd karar verir.
##
## Dosyanın yeri (macOS):
##   ~/Library/Application Support/Godot/app_userdata/Kut/kayit.json

const PATH := "user://kayit.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func write(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Kayıt yazılamadı: %s" % PATH)
		return false
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	return true


static func read() -> Dictionary:
	if not exists():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_warning("Kayıt dosyası bozuk, yeni oyun başlatılıyor.")
		return {}
	return parsed


static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
