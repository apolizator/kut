class_name SaveState
extends RefCounted

## Oyun durumunu saf bir Dictionary'e çevirir ve geri yükler.
##
## Dosyaya yazma işi burada DEĞİL (o bir motor işi, shell/save_file.gd).
## Burada sadece "neyin kaydedileceği" kararı var; böylece aynı kayıt
## biçimi ileride sunucu veritabanında da kullanılabilir.

const VERSION := 5


static func capture(game: Game) -> Dictionary:
	if game == null or game.player == null or game.current_map == null:
		return {}
	var p := game.player
	var st := p.stats
	return {
		"version": VERSION,
		"name": game.player_name,
		"map": game.current_map.id,
		"pos": [p.pos.x, p.pos.y],
		"hp": p.hp,
		"exp": p.experience,
		"stats": {
			"level": st.level,
			"str": st.strength,
			"dex": st.dexterity,
			"int": st.intelligence,
			"vit": st.vitality,
			"points": st.stat_points,
		},
		"gold": game.player_gold,
		"inventory": game.player_inventory.to_dict(),
		"mastery": game.mastery.to_dict(),
		"skills": game.skills.to_dict(),
		"quests": game.quest_log.to_dict(),
		"progress": game.progress.to_dict(),
		"abilities": game.abilities.to_dict(),
		"perks": game.perks.to_dict(),
		"mp": game.player.mp,
		"visited": game.visited.keys(),
	}


## Kayıt geçerliyse oyunu o duruma getirir ve true döner.
## Bozuk ya da eski sürüm bir kayıt sessizce reddedilir — oyun yeni başlar.
static func restore(game: Game, d: Dictionary) -> bool:
	if d.is_empty() or int(d.get("version", 0)) != VERSION:
		return false
	var map_id := str(d.get("map", ""))
	if not game.maps.has(map_id):
		return false

	game.player_name = str(d.get("name", game.player_name))

	var sd: Dictionary = d.get("stats", {})
	var st := game.player_stats
	st.level = clampi(int(sd.get("level", 1)), 1, ExpTable.MAX_LEVEL)
	st.strength = maxi(1, int(sd.get("str", 6)))
	st.dexterity = maxi(1, int(sd.get("dex", 6)))
	st.intelligence = maxi(1, int(sd.get("int", 4)))
	st.vitality = maxi(1, int(sd.get("vit", 8)))
	st.stat_points = maxi(0, int(sd.get("points", 0)))

	game.player_experience = maxi(0, int(d.get("exp", 0)))

	if game.item_db != null:
		game.player_inventory.load_dict(d.get("inventory", {}), game.item_db)
	game.mastery.load_dict(d.get("mastery", {}))
	game.skills.load_dict(d.get("skills", {}))
	game.quest_log.load_dict(d.get("quests", {}))
	game.progress.load_dict(d.get("progress", {}))
	game.abilities.load_dict(d.get("abilities", {}))
	game.perks.load_dict(d.get("perks", {}))
	game.player_gold = maxi(0, int(d.get("gold", 0)))
	game.refresh_stats()

	for v in d.get("visited", []):
		game.visited[str(v)] = true

	game.player_hp = int(d.get("hp", 0))

	var ham = d.get("pos", null)
	var nokta = null
	if ham != null and ham is Array and (ham as Array).size() >= 2:
		nokta = MapDef._to_vec(ham)
	game.travel_to(map_id, nokta)
	var kayitli_mp := int(d.get("mp", -1))
	if kayitli_mp >= 0:
		game.player.mp = clampi(kayitli_mp, 0, game.player.stats.max_mp())
	return true
