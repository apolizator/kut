extends Node2D

## GÖRSEL KATMAN (Faz 6'da sökülüp yerine 3D gelecek olan kısım).
##
## Buradaki tek görev: girdiyi komuta çevirmek ve core/'un ürettiği
## durumu ekrana çizmek. Burada HİÇBİR oyun kuralı, hiçbir formül,
## hiçbir zamanlama kararı olmayacak.

const PLAYER_NAME := "Apo"
const WORLD_SEED := 20260920
const PICK_RADIUS_PX := 30.0
const AUTOSAVE_EVERY := 30.0

const COL_BG := Color(0.07, 0.08, 0.10)
const COL_GRID := Color(1.0, 1.0, 1.0, 0.045)
const COL_EDGE := Color(0.95, 0.80, 0.35, 0.22)
const COL_MARKER := Color(1.0, 1.0, 1.0, 0.32)
const COL_PORTAL := Color(0.42, 0.72, 0.95)

enum Sayfa { NONE, INVENTORY, SKILLS, QUESTS, STATS, ATLAS, SHOP, ABILITIES }

## Otomatik avlanma: bir tuşla etraftaki canavarlara ya da metinlere
## durmadan saldırır; canın düşünce iksirini de kendiliğinden içer.
enum Oto { OFF, MONSTERS, STONES }

var game: Game
var clock := SimClock.new()

var _view_center := Vector2.ZERO
var _camera := Vector2.ZERO
var _selected_id := 0
var _shop_npc_id := 0
var _window: Sayfa = Sayfa.NONE
var _mouse := Vector2.ZERO
var _floaters: Array[Dictionary] = []
var _toast := ""
var _toast_age := 0.0
var _save_timer := 0.0
var _auto: Oto = Oto.OFF
var _quest_banner := ""
var _quest_banner_age := 0.0
var _time := 0.0

var _font: Font
var _panel: Panel2D
var _hud: Hud
var _atlas: Atlas
var _skills: SkillsView
var _bag: InventoryView
var _shop: ShopView
var _quests: QuestView
var _stats: StatsView
var _abilities: AbilityView
var _fx: Effects
var _theme: Dictionary = ZoneTheme.DEFAULT


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_panel = Panel2D.new(_font)
	_hud = Hud.new(_font)
	_atlas = Atlas.new(_font)
	_skills = SkillsView.new(_font)
	_bag = InventoryView.new(_panel)
	_shop = ShopView.new(_panel)
	_quests = QuestView.new(_panel)
	_stats = StatsView.new(_panel)
	_abilities = AbilityView.new(_panel)
	_fx = Effects.new()

	game = Game.new(PLAYER_NAME, WORLD_SEED)
	for m in MapLoader.load_all():
		game.register_map(m)

	var esya := MapLoader.read_json("res://data/items.json")
	var db := ItemDb.new()
	db.load_from(esya)
	game.setup_items(db, esya.get("starting", {}), float(esya.get("drop_chance", 0.3)))
	game.setup_skills(MapLoader.read_json("res://data/skills.json"))
	game.setup_quests(MapLoader.read_json("res://data/quests.json"))
	game.setup_abilities(MapLoader.read_json("res://data/abilities.json"))
	game.setup_perks(MapLoader.read_json("res://data/perks.json"))

	if SaveState.restore(game, SaveFile.read()):
		_toast_at("Kaldığın yerden devam — Sv. %d, %s" % [game.player.stats.level, game.current_map.display_name])
	else:
		game.start(MapLoader.start_map())
		_toast_at("%s — Umurca Köyü'ne hoş geldin" % PLAYER_NAME)

	_camera = game.player.pos
	game.refresh_hotbar()
	_theme = ZoneTheme.of(game.current_map.id)


func _process(delta: float) -> void:
	_view_center = get_viewport_rect().size * 0.5
	_mouse = get_global_mouse_position()

	game.world.command_move_dir(game.player.id, _keyboard_dir())

	# Boşluk BASILI TUTULDUĞU sürece vurmaya devam eder; yürürken de.
	if _window == Sayfa.NONE and Input.is_physical_key_pressed(KEY_SPACE):
		_ensure_attacking()
	if _auto != Oto.OFF and _window == Sayfa.NONE:
		_auto_step()

	# --- simülasyon: sabit adım, kare hızından bağımsız ---
	var ticks := clock.advance(delta)
	for _i in ticks:
		game.step()
		_consume_events()
		if not game.last_travel.is_empty():
			_on_travel()

	# --- sunum ---
	var p := game.player
	_camera = p.prev_pos.lerp(p.pos, clock.alpha())
	_age_floaters(delta)
	_toast_age = maxf(0.0, _toast_age - delta)
	_quest_banner_age = maxf(0.0, _quest_banner_age - delta)
	_time += delta
	_fx.update(delta)
	_save_timer += delta
	if _save_timer >= AUTOSAVE_EVERY:
		_autosave()
	queue_redraw()


# --- girdi ---

func _keyboard_dir() -> Vector2:
	if _window != Sayfa.NONE:
		return Vector2.ZERO
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1.0
	return d


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_on_key(event as InputEventKey)
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	var mb := event as InputEventMouseButton

	if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll(-2 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 2)
		return

	match _window:
		Sayfa.INVENTORY:
			_on_inventory_click(mb.position)
		Sayfa.SKILLS:
			_on_skills_click(mb.position)
		Sayfa.QUESTS:
			_on_quests_click(mb.position)
		Sayfa.SHOP:
			_on_shop_click(mb.position)
		Sayfa.ABILITIES:
			_on_abilities_click(mb.position)
		Sayfa.ATLAS:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_on_atlas_click(mb.position)
		Sayfa.STATS:
			pass
		_:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_on_left_click(mb.position)
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_on_right_click(mb.position)


func _scroll(amount: int) -> void:
	match _window:
		Sayfa.INVENTORY:
			_bag.scroll = maxi(0, _bag.scroll + amount)
		Sayfa.SHOP:
			_shop.scroll = maxi(0, _shop.scroll + amount)
		Sayfa.QUESTS:
			_quests.scroll = maxi(0, _quests.scroll + amount)
		Sayfa.SKILLS:
			_skills.scroll = clampf(_skills.scroll + float(amount) * 28.0, 0.0, _skills.max_scroll)
		Sayfa.SHOP:
			_shop.scroll = maxi(0, _shop.scroll + amount)
		_:
			pass


func _toggle(w: Sayfa) -> void:
	_window = Sayfa.NONE if _window == w else w
	if _window != Sayfa.SHOP:
		_shop_npc_id = 0


func _on_key(k: InputEventKey) -> void:
	match k.keycode:
		KEY_I:
			_toggle(Sayfa.INVENTORY)
		KEY_K:
			_toggle(Sayfa.SKILLS)
		KEY_J:
			_toggle(Sayfa.QUESTS)
		KEY_T:
			_toggle(Sayfa.STATS)
		KEY_B:
			_toggle(Sayfa.ABILITIES)
		KEY_F:
			if _window == Sayfa.NONE:
				_toggle_auto(Oto.MONSTERS)
		KEY_G:
			if _window == Sayfa.NONE:
				_toggle_auto(Oto.STONES)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			if _window == Sayfa.NONE:
				_use_hotbar(k.keycode - KEY_1)
		KEY_M:
			_toggle(Sayfa.ATLAS)
		KEY_ESCAPE:
			if _window != Sayfa.NONE:
				_window = Sayfa.NONE
				_shop_npc_id = 0
			else:
				_autosave()
				get_tree().quit()
		KEY_TAB:
			if _window == Sayfa.NONE:
				_select_nearest_enemy()
		KEY_SPACE:
			if _window == Sayfa.NONE:
				_attack_key()


## Boşluk basılı tutulduğu sürece vurmayı sürdürür: hedefi ölürse
## en yakınına geçer, yürürken de çalışır.
## Otomatik avlanma turu: hedef yoksa en yakınını seç, canın düşükse iç.
func _auto_step() -> void:
	var p := game.player
	if not p.alive:
		return

	# Canın üçte birinin altına düştüyse iksirini kendiliğinden iç.
	if p.hp < p.stats.max_hp() / 3:
		game.use_hotbar(0)

	var suanki := game.world.get_entity(p.attack_target_id) if p.attack_target_id != 0 else null
	if suanki != null and suanki.alive and _auto_matches(suanki):
		return

	var en_iyi: SimEntity = null
	var en_yakin := INF
	for e in game.world.entities:
		if e.id == p.id or not e.is_attackable() or not _auto_matches(e):
			continue
		var d := p.pos.distance_to(e.pos)
		if d < en_yakin:
			en_yakin = d
			en_iyi = e
	if en_iyi != null:
		_selected_id = en_iyi.id
		game.world.command_attack(p.id, en_iyi.id)


func _auto_matches(e: SimEntity) -> bool:
	if _auto == Oto.STONES:
		return e.kind == SimEntity.Kind.STONE
	return e.kind == SimEntity.Kind.MONSTER


func _toggle_auto(mode: Oto) -> void:
	_auto = Oto.OFF if _auto == mode else mode
	match _auto:
		Oto.MONSTERS:
			_toast_at("Otomatik av açık — etraftaki canavarları biçiyorsun.")
		Oto.STONES:
			_toast_at("Otomatik metin avı açık — taşları kırıyorsun.")
		_:
			_toast_at("Otomatik av kapalı.")
			game.world.command_stop(game.player.id)


func _ensure_attacking() -> void:
	var p := game.player
	if not p.alive:
		return
	var suanki := game.world.get_entity(p.attack_target_id) if p.attack_target_id != 0 else null
	if suanki != null and suanki.is_attackable():
		return
	var hedef := _selected()
	if hedef == null or not hedef.is_attackable() or hedef.id == p.id:
		_select_nearest_enemy()
		hedef = _selected()
	if hedef != null and hedef.is_attackable():
		game.world.command_attack(p.id, hedef.id)


## Düğmeyle / tek basışla saldır-vazgeç.
func _attack_key() -> void:
	var p := game.player
	if not p.alive:
		return
	var hedef := _selected()
	if hedef == null or not hedef.is_attackable() or hedef.id == p.id:
		_select_nearest_enemy()
		hedef = _selected()
	if hedef == null:
		return
	if p.attack_target_id == hedef.id:
		game.world.command_stop(p.id)
	else:
		game.world.command_attack(p.id, hedef.id)


func _on_left_click(at: Vector2) -> void:
	for key in _hud.stat_rects:
		var sr: Rect2 = _hud.stat_rects[key]
		if sr.size.x > 0.0 and sr.has_point(at):
			if game.world.command_spend_stat(game.player.id, str(key)):
				_autosave()
			return
	for i in _hud.quest_rects.size():
		if not _hud.quest_rects[i].has_point(at):
			continue
		var qid := _hud.quest_ids[i]
		if _hud.quest_actions[i] == "accept":
			var q := game.quest_log.get_quest(qid)
			if game.quest_log.accept(qid, game.player.stats.level):
				_toast_at("Görev alındı: %s" % q.title)
				_autosave()
		else:
			var odul := game.quest_log.claim(qid)
			if not odul.is_empty():
				game.grant_reward(int(odul["gold"]), int(odul["exp"]))
				_toast_at("Görev tamam: %s — +%d altın, +%d EXP" % [
						str(odul["title"]), int(odul["gold"]), int(odul["exp"])])
				_quest_banner = ""
				_autosave()
		return

	if _hud.atlas_rect.has_point(at):
		_window = Sayfa.ATLAS
		return
	if _hud.talk_enabled and _hud.talk_rect.has_point(at):
		var n := _selected()
		if n != null:
			_shop_npc_id = n.id
			_window = Sayfa.SHOP
			_shop.scroll = 0
		return
	if _hud.attack_rect.has_point(at) and _hud.attack_enabled:
		_attack_key()
		return
	if _hud.stop_rect.has_point(at):
		_selected_id = 0
		return

	var hedef := _pick(at)
	if hedef != null:
		_selected_id = hedef.id
		return
	if game.player.alive:
		game.world.command_move(game.player.id, game.current_map.clamp_pos(_to_world(at)))


func _on_right_click(at: Vector2) -> void:
	var hedef := _pick(at)
	if hedef != null and hedef.is_attackable() and hedef.id != game.player.id:
		_selected_id = hedef.id
		game.world.command_attack(game.player.id, hedef.id)
		return
	if game.player.alive:
		game.world.command_move(game.player.id, game.current_map.clamp_pos(_to_world(at)))


func _on_inventory_click(at: Vector2) -> void:
	var inv := game.player_inventory
	for i in _bag.equip_rects.size():
		if _bag.equip_rects[i].has_point(at):
			if inv.unequip(_bag.equip_slots[i]):
				_after_gear_change()
			return
	for i in _bag.bag_rects.size():
		if not _bag.bag_rects[i].has_point(at):
			continue
		var idx := _bag.bag_indexes[i]
		if idx >= inv.slots.size():
			return
		var it := inv.slots[idx]
		if it.required_level > game.player.stats.level:
			_toast_at("%s için Sv. %d gerekiyor." % [it.display_name, it.required_level])
			return
		if inv.equip_at(idx, game.player.stats.level):
			_toast_at("Kuşandın: %s" % it.display_name)
			_after_gear_change()
		return


func _use_hotbar(index: int) -> void:
	var sonuc := game.use_hotbar(index)
	if sonuc.is_empty():
		return
	if sonuc == "can" or sonuc == "mana" or sonuc == "can ve mana":
		_toast_at("%s yenilendi." % sonuc)
	else:
		_floater(game.player.pos, sonuc, Color(0.75, 0.70, 1.0), 1.1)


## Dünya haritasında gezilmiş bir bölgeye tıkla, oraya ışınlan.
func _on_atlas_click(at: Vector2) -> void:
	for i in _atlas.map_rects.size():
		if not _atlas.map_rects[i].has_point(at):
			continue
		game.travel_to(_atlas.map_ids[i])
		_window = Sayfa.NONE
		_on_travel()
		return


func _on_shop_click(at: Vector2) -> void:
	if _shop.close_rect.has_point(at):
		_window = Sayfa.NONE
		_shop_npc_id = 0
		return

	for i in _shop.buy_rects.size():
		if _shop.buy_rects[i].has_point(at):
			var id := _shop.buy_ids[i]
			var tpl: Item = game.item_db.templates.get(id, null)
			if tpl != null and game.player_gold >= tpl.sell_price:
				game._set_gold(game.player_gold - tpl.sell_price)
				game.player_inventory.add(game.item_db.make(id))
				game.refresh_hotbar()
				_toast_at("%s alındı." % tpl.display_name)
				_autosave()
			return

	for i in _shop.combine_rects.size():
		if _shop.combine_rects[i].has_point(at):
			var yeni := game.combine_item(_shop.combine_ids[i])
			if yeni != null:
				_toast_at("Üç eşya birleşti: %s" % yeni.display_name)
				_autosave()
			return

	if not _shop.perk_id.is_empty() and _shop.perk_rect.has_point(at):
		var harcanan := game.buy_perk(_shop.perk_id)
		if harcanan > 0:
			_toast_at("Yeni özellik öğrenildi — %d altın" % harcanan)
			_autosave()
		return

	if _shop.sell_all_rect.has_point(at):
		var toplam := 0
		var adet := 0
		var i2 := 0
		while i2 < game.player_inventory.slots.size():
			if game.player_inventory.slots[i2].is_equipment():
				toplam += game.sell_item(i2)
				adet += 1
			else:
				i2 += 1
		if toplam > 0:
			_toast_at("%d eşya satıldı — +%d altın" % [adet, toplam])
			_autosave()
		return

	for i in _shop.sell_rects.size():
		if not _shop.sell_rects[i].has_point(at):
			continue
		var idx := _shop.sell_indexes[i]
		if idx >= game.player_inventory.slots.size():
			return
		var ad := game.player_inventory.slots[idx].label()
		var kazanc := game.sell_item(idx)
		if kazanc > 0:
			game.refresh_hotbar()
			_toast_at("%s satıldı — +%d altın" % [ad, kazanc])
			_autosave()
		return


## Yetenek defteri: puan, kitap, taş ve hızlı çubuk ataması.
func _on_abilities_click(at: Vector2) -> void:
	for i in _abilities.learn_rects.size():
		if _abilities.learn_rects[i].has_point(at):
			if game.spend_ability_point(_abilities.learn_ids[i]):
				_autosave()
			return
	for i in _abilities.book_rects.size():
		if _abilities.book_rects[i].has_point(at):
			var id := _abilities.book_ids[i]
			if game.abilities.books <= 0:
				return
			if game.advance_ability(id, false):
				game.player_inventory.consume_one(game.item_db.book_item)
				_toast_at("Kitap okundu: %s" % game.abilities.get_ability(id).grade_label())
				_autosave()
			return
	for i in _abilities.stone_rects.size():
		if _abilities.stone_rects[i].has_point(at):
			var id2 := _abilities.stone_ids[i]
			if game.advance_ability(id2, true):
				game.player_inventory.consume_one(game.item_db.stone_item)
				_toast_at("Sunak taşı kullanıldı: %s" % game.abilities.get_ability(id2).grade_label())
				_autosave()
			return
	for i in _abilities.slot_rects.size():
		if _abilities.slot_rects[i].has_point(at):
			_assign_hotbar(_abilities.slot_ids[i])
			return


## Yeteneği hızlı çubuğun ilk boş yuvasına koy (1-2 iksirlere ayrılmıştır).
func _assign_hotbar(ability_id: String) -> void:
	var hb := game.abilities.hotbar
	var mevcut := hb.find(ability_id)
	if mevcut >= 2:
		hb[mevcut] = ""
		_toast_at("Çubuktan çıkarıldı.")
		return
	for i in range(2, hb.size()):
		if hb[i].is_empty():
			hb[i] = ability_id
			_toast_at("%d numaraya kondu." % (i + 1))
			_autosave()
			return
	hb[2] = ability_id
	_toast_at("3 numaraya kondu.")
	_autosave()


func _on_skills_click(at: Vector2) -> void:
	for i in _skills.node_rects.size():
		if not _skills.node_rects[i].has_point(at):
			continue
		var id := _skills.node_ids[i]
		var harcanan := game.learn_skill(id)
		if harcanan > 0:
			var ad := str((game.skills.by_id[id] as Dictionary).get("name", id))
			_toast_at("%s öğrenildi — %d altın" % [ad, harcanan])
			_autosave()
		return


func _on_quests_click(at: Vector2) -> void:
	for i in _quests.accept_rects.size():
		if _quests.accept_rects[i].has_point(at):
			var qid := _quests.accept_ids[i]
			var q := game.quest_log.get_quest(qid)
			if game.quest_log.accept(qid, game.player.stats.level):
				_toast_at("Görev alındı: %s" % q.title)
				_autosave()
			return
	for i in _quests.claim_rects.size():
		if _quests.claim_rects[i].has_point(at):
			var odul := game.quest_log.claim(_quests.claim_ids[i])
			if odul.is_empty():
				return
			game.grant_reward(int(odul["gold"]), int(odul["exp"]))
			_toast_at("Görev tamam: %s — +%d altın, +%d EXP" % [
					str(odul["title"]), int(odul["gold"]), int(odul["exp"])])
			_autosave()
			return


func _after_gear_change() -> void:
	game.refresh_stats()
	_autosave()


func _select_nearest_enemy() -> void:
	var p := game.player
	var en_iyi: SimEntity = null
	var en_yakin := INF
	for e in game.world.entities:
		if e.id == p.id or not e.is_attackable():
			continue
		var d := p.pos.distance_to(e.pos)
		if d < en_yakin:
			en_yakin = d
			en_iyi = e
	if en_iyi != null:
		_selected_id = en_iyi.id


func _pick(at: Vector2) -> SimEntity:
	var en_iyi: SimEntity = null
	var en_yakin := PICK_RADIUS_PX
	for e in game.world.entities:
		var d := _to_screen(e.pos).distance_to(at)
		if d <= en_yakin:
			en_yakin = d
			en_iyi = e
	return en_iyi


func _selected() -> SimEntity:
	return game.world.get_entity(_selected_id) if _selected_id != 0 else null


func _shop_npc() -> SimEntity:
	return game.world.get_entity(_shop_npc_id) if _shop_npc_id != 0 else null


# --- olaylar ---

func _consume_events() -> void:
	for ev in game.world.drain_events():
		match str(ev["type"]):
			"attack_hit":
				_on_attack_hit(ev)
			"died":
				_on_died(ev)
			"exp_gained":
				_floater(game.player.pos, "+%d EXP" % int(ev["amount"]), Color(0.55, 0.85, 0.45), 1.3)
			"gold_gained":
				_floater(game.player.pos, "+%d altın" % int(ev["amount"]), Color(0.95, 0.80, 0.35), 1.2)
			"level_up":
				_floater(game.player.pos, "SEVİYE %d!" % int(ev["level"]), Color(1.0, 0.85, 0.35), 2.0)
				_fx.ring(game.player.pos, 0.3, 5.0, Color(1.0, 0.88, 0.40, 0.95), 0.9, 5.0)
				_fx.burst(game.player.pos, Color(1.0, 0.90, 0.50), 30, 7.0)
				_toast_at("Seviye atladın — Sv. %d · 1 stat puanı kazandın" % int(ev["level"]))
				_autosave()
			"mastery_up":
				var hat := "Silah" if str(ev["track"]) == "weapon" else "Zırh"
				_floater(game.player.pos, "%s Ustalığı R%d" % [hat, int(ev["rank"])], Color(0.80, 0.70, 1.0), 2.0)
				_toast_at("%s Ustalığı rütbe %d — %s" % [hat, int(ev["rank"]), str(ev["reward"])])
				_autosave()
			"quest_ready":
				_quest_banner = str(ev["title"])
				_quest_banner_age = 6.0
				_autosave()
			"map_alerted":
				_fx.add_shake(11.0)
				_fx.ring(game.player.pos, 1.0, 20.0, Color(1.0, 0.35, 0.28, 0.85), 1.4, 6.0)
				_toast_at("SUNAĞA DOKUNDUN — bölgedeki her şey üstüne geliyor! (%d yaratık)" % int(ev["count"]))
			"altar_wave":
				var son_dalga := bool(ev.get("final", false))
				_toast_at("SUNAK %d / %d dalga — %s" % [int(ev["wave"]), int(ev.get("total", 5)),
						"SUNAK EFENDİSİ GELDİ!" if son_dalga else "muhafızlar çağrıldı"])
			"altar_wave":
				var son2 := bool(ev.get("final", false))
				_fx.ring(game.player.pos, 1.0, 14.0, Color(1.0, 0.45, 0.30, 0.9), 1.0, 5.0)
				_fx.add_shake(9.0 if son2 else 6.0)
				_toast_at("SUNAK %d / %d dalga — %s" % [int(ev["wave"]), int(ev.get("total", 5)),
						"SUNAK EFENDİSİ GELDİ!" if son2 else "muhafızlar çağrıldı"])
			"guards_summoned":
				var son := bool(ev.get("final", false))
				_toast_at("Metin taşı bekçi çağırdı! (%d / %d dalga)%s" % [
						int(ev["wave"]), int(ev.get("total", 10)), "  —  SON DALGA!" if son else ""])
			"item_looted":
				_floater(game.player.pos, str(ev["item"]), Color(0.95, 0.82, 0.45), 1.5)
				_toast_at("Ganimet: %s" % str(ev["item"]))
			"lifesteal":
				_floater(game.player.pos, "+%d" % int(ev["amount"]), Color(0.45, 0.90, 0.55), 0.8)
				_fx.burst(game.player.pos, Color(0.40, 0.95, 0.55), 4, 2.5)
			"ability_cast":
				var n := int(ev.get("hits", 0))
				var yaricap := float(ev.get("radius", 2.0))
				_fx.ring(ev["at"], 0.3, yaricap, Color(0.72, 0.66, 1.0, 0.95), 0.45, 4.0)
				_fx.burst(ev["at"], Color(0.78, 0.70, 1.0), 18, yaricap * 2.0)
				_fx.add_shake(3.0)
				if n > 0:
					_floater(ev["at"], "%d isabet" % n, Color(0.75, 0.70, 1.0), 1.0)
			"ability_buff":
				_toast_at("Savaş narası — kısa süre daha güçlüsün!")
				_fx.ring(game.player.pos, 0.4, 3.2, Color(1.0, 0.82, 0.40, 0.95), 0.6, 4.0)
			"material_gained":
				var ad := "kitap" if str(ev["item"]) == game.item_db.book_item else "sunak taşı"
				_toast_at("%d %s kazandın — B tuşundan yeteneklerine harca." % [int(ev["count"]), ad])
				game.abilities.books = game.player_inventory.count_of(game.item_db.book_item)
				game.abilities.stones = game.player_inventory.count_of(game.item_db.stone_item)
				_autosave()
			"inventory_full":
				_toast_at("Çantan dolu — ganimet yere düştü.")
			"pack_alerted":
				var y := game.world.get_entity(int(ev["entity"]))
				if y != null:
					_floater(y.pos, "!", Color(1.0, 0.55, 0.30), 0.9)
			"respawned":
				var e := game.world.get_entity(int(ev["entity"]))
				if e != null and e.kind == SimEntity.Kind.PLAYER:
					_toast_at("Ayağa kalktın.")


func _on_attack_hit(ev: Dictionary) -> void:
	var hedef := game.world.get_entity(int(ev["target"]))
	if hedef == null:
		return
	var oyuncu_vurdu := int(ev["attacker"]) == game.player.id

	if bool(ev.get("out_of_range", false)):
		_floater(hedef.pos, "menzil dışı", Color(0.62, 0.64, 0.70), 0.8)
		return
	if not bool(ev["hit"]):
		_floater(hedef.pos, "ıskaladı", Color(0.70, 0.72, 0.78), 0.9)
		return

	var metin := str(int(ev["damage"]))
	var renk := Color(1.0, 0.92, 0.55) if oyuncu_vurdu else Color(1.0, 0.45, 0.42)
	var kivilcim := 5
	if bool(ev["critical"]):
		metin = "KRİTİK  " + metin
		renk = Color(1.0, 0.60, 0.20)
		kivilcim = 14
		_fx.ring(hedef.pos, 0.2, 1.4, Color(1.0, 0.65, 0.25, 0.9), 0.35, 3.0)
		if oyuncu_vurdu:
			_fx.add_shake(5.0)
	elif bool(ev["pierced"]):
		metin = "delici  " + metin
		renk = Color(0.60, 0.85, 1.0)
		kivilcim = 9
	_fx.burst(hedef.pos, renk, kivilcim, 4.0 + float(kivilcim) * 0.2)
	_floater(hedef.pos, metin, renk, 1.1)


func _on_died(ev: Dictionary) -> void:
	var olen := game.world.get_entity(int(ev["entity"]))
	if olen == null:
		return
	if olen.kind == SimEntity.Kind.PLAYER:
		_toast_at("Öldün. Birazdan ayağa kalkacaksın.")
		return
	_fx.ring(olen.pos, 0.2, 2.2, Color(0.85, 0.85, 0.92, 0.8), 0.5, 2.5)
	_fx.burst(olen.pos, Color(0.80, 0.78, 0.82), 12, 4.5)
	if olen.is_boss or olen.is_objective():
		_fx.add_shake(8.0)
		_fx.ring(olen.pos, 0.5, 7.0, Color(1.0, 0.80, 0.35, 0.9), 1.1, 5.0)
	_floater(olen.pos, "%s öldü" % olen.display_name, Color(0.80, 0.80, 0.85), 1.2)


func _on_travel() -> void:
	_theme = ZoneTheme.of(game.current_map.id)
	_fx = Effects.new()
	_selected_id = 0
	_shop_npc_id = 0
	_floaters.clear()
	_camera = game.player.pos
	game.refresh_hotbar()
	_theme = ZoneTheme.of(game.current_map.id)
	_toast_at("%s  ·  Seviye %d - %d" % [game.current_map.display_name,
			game.current_map.level_range.x, game.current_map.level_range.y])
	_autosave()


func _autosave() -> void:
	_save_timer = 0.0
	SaveFile.write(SaveState.capture(game))


# --- dünya <-> ekran ---

func _to_screen(world_pos: Vector2) -> Vector2:
	return _view_center + Units.to_px(world_pos - _camera) + _fx.shake_offset(_time)


func _to_world(screen_pos: Vector2) -> Vector2:
	return _camera + Units.to_world(screen_pos - _view_center)


# --- uçuşan yazılar ---

func _floater(at: Vector2, text: String, color: Color, life: float) -> void:
	var n := _floaters.size()
	var kayma := Vector2(float(n % 3 - 1) * 30.0, float(n % 2) * -13.0)
	_floaters.append({"pos": at, "offset": kayma, "text": text, "color": color, "age": 0.0, "life": life})


func _age_floaters(delta: float) -> void:
	var kalan: Array[Dictionary] = []
	for f in _floaters:
		f["age"] = float(f["age"]) + delta
		if float(f["age"]) < float(f["life"]):
			kalan.append(f)
	_floaters = kalan


func _toast_at(s: String) -> void:
	_toast = s
	_toast_age = 3.2


# --- çizim ---

func _draw() -> void:
	var view := get_viewport_rect().size
	_draw_ground(view)

	if _window == Sayfa.ATLAS:
		_atlas.draw_all(self, view, game)
		return
	if _window == Sayfa.SKILLS:
		_skills.draw_all(self, view, game, _mouse)
		return

	_draw_map_edge()
	_draw_portals()

	var p := game.player
	if p.has_move_target and p.attack_target_id == 0 and p.move_dir == Vector2.ZERO:
		var m := _to_screen(p.move_target)
		draw_line(m - Vector2(7.0, 0.0), m + Vector2(7.0, 0.0), COL_MARKER, 2.0)
		draw_line(m - Vector2(0.0, 7.0), m + Vector2(0.0, 7.0), COL_MARKER, 2.0)

	var a := clock.alpha()
	# Ölüler önce çizilsin ki canlılar cesetlerin üstünde görünsün.
	for e in game.world.entities:
		if not e.alive:
			_draw_entity(e, a)
	for e in game.world.entities:
		if e.alive:
			_draw_entity(e, a)

	_fx.draw_all(self, _to_screen, Units.PIXELS_PER_UNIT)
	_draw_floaters()
	_hud.draw_all(self, view, game, _selected(), _mouse)

	match _window:
		Sayfa.INVENTORY:
			_bag.draw_all(self, view, game, _mouse)
		Sayfa.QUESTS:
			_quests.draw_all(self, view, game, _mouse)
		Sayfa.STATS:
			_stats.draw_all(self, view, game)
		Sayfa.SHOP:
			_shop.draw_all(self, view, game, _shop_npc(), _mouse)
		Sayfa.ABILITIES:
			_abilities.draw_all(self, view, game, _mouse)
		_:
			pass

	if _window == Sayfa.NONE:
		_hud.draw_quest_tracker(self, view, game, _mouse, _time)
		_hud.draw_quest_banner(self, view, _quest_banner,
				clampf(_quest_banner_age, 0.0, 1.0), _time)
		_hud.draw_hotbar(self, view, game, _mouse, _panel)
		if _auto != Oto.OFF:
			draw_string(_font, Vector2(0.0, 162.0),
					"OTOMATİK AV AÇIK — %s   (kapatmak için aynı tuş)" % (
						"metin taşları" if _auto == Oto.STONES else "canavarlar"),
					HORIZONTAL_ALIGNMENT_CENTER, view.x, 13, Color(0.55, 0.95, 0.60, 0.9))

	_draw_toast(view)
	_panel.draw_tooltip(self, view)


func _draw_entity(e: SimEntity, a: float) -> void:
	var taban := _to_screen(e.prev_pos.lerp(e.pos, a))
	var color := _kind_color(e.kind)
	if not e.alive:
		color = color.darkened(0.6)
		color.a = 0.35

	# Yürürken hafif sekme — duran ve yürüyen ayırt edilsin.
	var sekme := 0.0
	if e.alive and e.state == SimEntity.State.MOVING:
		sekme = absf(sin(_time * 9.0 + float(e.id) * 0.7)) * 2.6
	var at := taban - Vector2(0.0, sekme)

	var buyukluk := 12.0
	if e.kind == SimEntity.Kind.ALTAR:
		buyukluk = 30.0
	elif e.kind == SimEntity.Kind.STONE:
		buyukluk = 18.0
	elif e.is_boss:
		buyukluk = 17.0

	# Gölge: gövdenin altında yassı bir leke.
	if e.alive:
		_ellipse(taban + Vector2(0.0, buyukluk * 0.82), buyukluk * 0.85, buyukluk * 0.34,
				Color(0.0, 0.0, 0.0, 0.30))

	if e.id == _selected_id:
		var nabiz := 1.0 + sin(_time * 5.0) * 0.06
		draw_arc(taban, (buyukluk + 10.0) * nabiz, 0.0, TAU, 44, Color(1.0, 0.86, 0.40, 0.85), 2.0)

	match e.kind:
		SimEntity.Kind.ALTAR:
			_draw_altar(at, color, e)
		SimEntity.Kind.STONE:
			_draw_stone(at, color, e)
		_:
			_draw_creature(at, color, e, buyukluk)

	if e.alive and e.state == SimEntity.State.ATTACKING:
		var mid := e.facing.angle()
		var menzil := Units.px(e.effective_range())
		var yanip := 0.30 + 0.25 * sin(_time * 16.0)
		if e.attack_arc >= PI - 0.01:
			draw_arc(taban, menzil, 0.0, TAU, 44, Color(1.0, 0.88, 0.5, yanip), 3.0)
		else:
			draw_arc(taban, menzil, mid - e.attack_arc, mid + e.attack_arc, 30,
					Color(1.0, 0.88, 0.5, yanip + 0.1), 3.0)

	_draw_entity_label(e, at)


## Canavar, NPC ve oyuncu: gövde + kafa + yön.
func _draw_creature(at: Vector2, color: Color, e: SimEntity, half: float) -> void:
	if e.is_boss and e.alive:
		var halka := 1.0 + sin(_time * 3.0) * 0.05
		draw_arc(at, (half + 12.0) * halka, 0.0, TAU, 40, Color(1.0, 0.42, 0.22, 0.75), 3.0)

	# Yön göstergesi: gövdenin önünde ince bir kama.
	if e.can_move() and e.alive:
		var uc := at + e.facing * (half + 11.0)
		var yan := e.facing.orthogonal() * (half * 0.42)
		draw_colored_polygon(PackedVector2Array([uc, at + yan, at - yan]),
				Color(color.r, color.g, color.b, 0.55))

	_body(at, half, color.darkened(0.25))
	_body(at - Vector2(0.0, half * 0.14), half * 0.82, color)
	# Küçük bir parlaklık — düz kare hissini kırar.
	_ellipse(at - Vector2(half * 0.26, half * 0.42), half * 0.34, half * 0.22,
			Color(1.0, 1.0, 1.0, 0.16))
	# Kafa
	draw_circle(at - Vector2(0.0, half * 0.86), half * 0.40, color.lightened(0.28))


## Metin taşı: elmas, içinde nabız gibi atan bir çekirdek.
func _draw_stone(at: Vector2, color: Color, e: SimEntity) -> void:
	var r := 18.0
	var nabiz := 1.0 + sin(_time * 2.4 + float(e.id)) * 0.05
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -r * nabiz), at + Vector2(r * nabiz, 0.0),
		at + Vector2(0.0, r * nabiz), at + Vector2(-r * nabiz, 0.0),
	]), color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -r * 0.55), at + Vector2(r * 0.55, 0.0),
		at + Vector2(0.0, r * 0.55), at + Vector2(-r * 0.55, 0.0),
	]), color.lightened(0.25))
	if e.alive:
		draw_arc(at, r + 6.0 + sin(_time * 2.0) * 2.0, 0.0, TAU, 32,
				Color(color.r, color.g, color.b, 0.22), 2.0)


## Sunak: sekiz köşeli, çevresinde dönen iki halka.
func _draw_altar(at: Vector2, color: Color, e: SimEntity) -> void:
	var R := 30.0
	if e.alive:
		for k in 2:
			var d := _time * (0.7 + float(k) * 0.45) * (1.0 if k == 0 else -1.0)
			var yaricap := R + 12.0 + float(k) * 9.0
			for i in 8:
				var a1 := d + float(i) * TAU / 8.0
				draw_arc(at, yaricap, a1, a1 + 0.26, 6,
						Color(color.r, color.g, color.b, 0.40 - float(k) * 0.14), 2.5)

	var kose := PackedVector2Array()
	for i in 16:
		var aci := float(i) * TAU / 16.0 - PI * 0.5
		kose.append(at + Vector2.from_angle(aci) * (R if i % 2 == 0 else R * 0.6))
	draw_colored_polygon(kose, color.darkened(0.2))

	var ic := PackedVector2Array()
	for i in 8:
		var aci2 := float(i) * TAU / 8.0 - PI * 0.5 + _time * 0.3
		ic.append(at + Vector2.from_angle(aci2) * (R * 0.42))
	draw_colored_polygon(ic, color.lightened(0.35))


func _draw_entity_label(e: SimEntity, at: Vector2) -> void:
	var basamak := float(e.id % 3) * 12.0
	var yukseklik := 23.0
	if e.kind == SimEntity.Kind.STONE:
		yukseklik = 28.0
	elif e.kind == SimEntity.Kind.ALTAR:
		yukseklik = 42.0
	var ust := at.y - yukseklik - basamak
	var genislik := 220.0
	var kutu := Vector2(at.x - genislik * 0.5, ust)

	if e.alive and e.kind != SimEntity.Kind.NPC:
		var bw := 46.0
		if e.kind == SimEntity.Kind.ALTAR:
			bw = 92.0
		elif e.is_boss or e.kind == SimEntity.Kind.STONE:
			bw = 64.0
		var br := Rect2(at.x - bw * 0.5, ust + 3.0, bw, 6.0)
		draw_rect(br.grow(1.0), Color(0.0, 0.0, 0.0, 0.55))
		var k := e.hp_ratio()
		if k > 0.0:
			var dolgu := Color(0.82, 0.26, 0.26)
			if e.kind == SimEntity.Kind.PLAYER:
				dolgu = Color(0.32, 0.76, 0.40)
			elif e.kind == SimEntity.Kind.ALTAR:
				dolgu = Color(0.96, 0.72, 0.28)
			elif e.is_boss:
				dolgu = Color(0.95, 0.42, 0.24)
			draw_rect(Rect2(br.position, Vector2(br.size.x * k, br.size.y)), dolgu)
			# Üstte ince bir parlaklık bandı
			draw_rect(Rect2(br.position, Vector2(br.size.x * k, 2.0)),
					Color(1.0, 1.0, 1.0, 0.22))
		draw_rect(br, Color(1, 1, 1, 0.22), false, 1.0)

	var etiket := "Sv.%d  %s" % [e.stats.level, e.display_name]
	if not e.alive:
		etiket = e.display_name
	if e.alive and e.aggro_target_id == game.player.id:
		etiket = "! " + etiket

	var renk := Hud._kind_text_color(e.kind)
	if not e.alive:
		renk = Color(0.55, 0.55, 0.58)

	draw_string(_font, kutu + Vector2(1.0, 1.0), etiket, HORIZONTAL_ALIGNMENT_CENTER, genislik, 12,
			Color(0.0, 0.0, 0.0, 0.75))
	draw_string(_font, kutu, etiket, HORIZONTAL_ALIGNMENT_CENTER, genislik, 12, renk)


func _draw_portals() -> void:
	for p in game.portals():
		var at := _to_screen(MapDef._to_vec(p.get("at", [0, 0])))
		var r := Units.px(float(p.get("radius", 1.3)))
		var renk: Color = _theme["accent"]
		_ellipse(at + Vector2(0.0, r * 0.35), r * 0.9, r * 0.35, Color(0.0, 0.0, 0.0, 0.25))
		draw_arc(at, r, 0.0, TAU, 48, renk, 2.0)
		draw_arc(at, r * 0.62, 0.0, TAU, 40, Color(renk.r, renk.g, renk.b, 0.30), 8.0)
		# Dönen üç yay
		for i in 3:
			var a0 := _time * 1.4 + float(i) * TAU / 3.0
			draw_arc(at, r * 1.25, a0, a0 + 0.5, 8, Color(renk.r, renk.g, renk.b, 0.65), 3.0)
		var nabiz := 0.35 + 0.25 * sin(_time * 2.2)
		draw_circle(at, r * 0.3, Color(renk.r, renk.g, renk.b, nabiz))

		var hedef_id := str(p.get("to", ""))
		var ad := hedef_id
		var seviye := ""
		if game.maps.has(hedef_id):
			var m: MapDef = game.maps[hedef_id]
			ad = m.display_name
			seviye = "Güvenli" if m.safe else "Sv. %d-%d" % [m.level_range.x, m.level_range.y]
		var kutu := Vector2(at.x - 110.0, at.y - r - 24.0)
		draw_string(_font, kutu + Vector2(1.0, 1.0), "→ " + ad, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 12,
				Color(0, 0, 0, 0.7))
		draw_string(_font, kutu, "→ " + ad, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 12, _theme["accent"])
		draw_string(_font, kutu + Vector2(0.0, 15.0), seviye, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 10,
				Color(0.75, 0.78, 0.85, 0.8))


func _draw_map_edge() -> void:
	var m := game.current_map
	if m == null:
		return
	var ust_sol := _to_screen(-m.extent)
	var alt_sag := _to_screen(m.extent)
	draw_rect(Rect2(ust_sol, alt_sag - ust_sol), COL_EDGE, false, 2.0)


func _draw_floaters() -> void:
	for f in _floaters:
		var yas := float(f["age"])
		var omur := float(f["life"])
		var k := yas / omur
		var dunya: Vector2 = f["pos"]
		var kayma: Vector2 = f.get("offset", Vector2.ZERO)
		var at := _to_screen(dunya) + kayma + Vector2(0.0, -34.0 - k * 26.0)
		var col: Color = f["color"]
		col.a = 1.0 - k * k
		var metin := str(f["text"])
		draw_string(_font, Vector2(at.x - 100.0, at.y + 1.0), metin, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 14,
				Color(0, 0, 0, col.a * 0.7))
		draw_string(_font, Vector2(at.x - 100.0, at.y), metin, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 14, col)


func _draw_toast(view: Vector2) -> void:
	# Pencere açıkken bildirim yazısı içeriğin üstüne binmesin.
	if _window != Sayfa.NONE:
		return
	if _toast_age <= 0.0 or _toast.is_empty():
		return
	var alpha := clampf(_toast_age, 0.0, 1.0)
	draw_string(_font, Vector2(0.0, 138.0), _toast, HORIZONTAL_ALIGNMENT_CENTER, view.x, 16,
			Color(1.0, 0.92, 0.65, alpha))


## Zemin: bölgenin rengiyle yumuşak bir gradyan, üstünde ızgara ve
## dünyaya sabitlenmiş küçük doku lekeleri. Böylece yürürken zemin
## akıyormuş hissi oluşuyor.
func _draw_ground(view: Vector2) -> void:
	var bg: Color = _theme["bg"]
	var bg2: Color = _theme["bg2"]
	draw_rect(Rect2(Vector2.ZERO, view), bg)

	# Dikey gradyan — birkaç bantla, ucuz ve yeterli.
	var bant := 10
	for i in bant:
		var k := float(i) / float(bant - 1)
		var col := bg.lerp(bg2, 1.0 - k)
		col.a = 0.55 * (1.0 - k)
		draw_rect(Rect2(0.0, view.y * k, view.x, view.y / float(bant) + 1.0), col)

	_draw_ground_detail(view)
	_draw_grid(view)


## Dünya koordinatına sabitlenmiş doku lekeleri (çimen, taş, kum).
## Konumdan türeyen sabit bir karışımla üretilir, yani titremez.
func _draw_ground_detail(view: Vector2) -> void:
	var detay: Color = _theme["detail"]
	var adim := 3.0  # birim
	var sol := _camera.x - view.x / Units.PIXELS_PER_UNIT * 0.5 - adim
	var ust := _camera.y - view.y / Units.PIXELS_PER_UNIT * 0.5 - adim
	var sag := sol + view.x / Units.PIXELS_PER_UNIT + adim * 2.0
	var alt := ust + view.y / Units.PIXELS_PER_UNIT + adim * 2.0

	var gy: float = floor(ust / adim) * adim
	while gy < alt:
		var gx: float = floor(sol / adim) * adim
		while gx < sag:
			var h := _hash2(int(gx), int(gy))
			if h > 0.42:
				var nokta := Vector2(gx + fmod(h * 31.7, adim), gy + fmod(h * 17.3, adim))
				var at := _to_screen(nokta)
				var boy := 1.0 + h * 2.6
				var col := detay
				col.a *= 0.35 + h * 0.5
				if h > 0.86:
					# Seyrek, biraz daha iri lekeler
					draw_circle(at, boy * 1.7, col)
				else:
					draw_line(at, at + Vector2(0.0, -boy * 2.2), col, 1.0)
			gx += adim
		gy += adim


static func _hash2(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


func _draw_grid(view: Vector2) -> void:
	var step := Units.PIXELS_PER_UNIT * 2.0
	var grid: Color = _theme["grid"]
	var origin := _to_screen(Vector2.ZERO)
	var x := fposmod(origin.x, step)
	while x < view.x:
		draw_line(Vector2(x, 0.0), Vector2(x, view.y), grid, 1.0)
		x += step
	var y := fposmod(origin.y, step)
	while y < view.y:
		draw_line(Vector2(0.0, y), Vector2(view.x, y), grid, 1.0)
		y += step


## Yassı bir elips — gölgeler ve tabanlar için.
func _ellipse(center: Vector2, rx: float, ry: float, color: Color, n: int = 18) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := float(i) / float(n) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


## Yuvarlatılmış gövde: köşeleri kırpılmış sekizgen.
func _body(center: Vector2, half: float, color: Color) -> void:
	var k := half * 0.42
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-half + k, -half), center + Vector2(half - k, -half),
		center + Vector2(half, -half + k), center + Vector2(half, half - k),
		center + Vector2(half - k, half), center + Vector2(-half + k, half),
		center + Vector2(-half, half - k), center + Vector2(-half, -half + k),
	]), color)


func _kind_color(kind: SimEntity.Kind) -> Color:
	match kind:
		SimEntity.Kind.PLAYER:
			return Color(0.42, 0.68, 1.0)
		SimEntity.Kind.NPC:
			return Color(0.52, 0.85, 0.55)
		SimEntity.Kind.STONE:
			return Color(0.72, 0.52, 0.95)
		SimEntity.Kind.ALTAR:
			return Color(0.96, 0.78, 0.30)
		_:
			return Color(0.93, 0.44, 0.42)
