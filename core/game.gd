class_name Game
extends RefCounted

## Haritaların üstündeki katman: hangi haritadayız, oyuncunun kalıcı
## verisi nedir, geçitten geçince ne olur.
##
## SimWorld tek bir haritanın simülasyonudur. Harita değişince yeni bir
## SimWorld kurulur, ama oyuncunun statları ve deneyimi taşınır —
## tıpkı Metin2'de bir haritadan diğerine geçmek gibi.

var maps: Dictionary = {}  ## id -> MapDef
var current_map: MapDef = null
var world: SimWorld = null
var player: SimEntity = null

var player_name: String = "Oyuncu"

## Haritalar arası taşınan kalıcı veri.
var player_stats: Stats = null
var player_experience: int = 0
var player_inventory: Inventory = null
var player_gold: int = 0

## Kalıcı pasif yetenekler, satın alınan beceriler ve görev defteri.
var mastery: Mastery = null
var skills: SkillTree = null
var quest_log: QuestLog = null
var progress: Progress = null
var abilities: AbilityBook = null
var perks: PerkShop = null

## Haritalar arasında taşınan can. 0 = tam canla başla.
var player_hp: int = 0

## Eşya havuzu ve ganimet ayarları (shell tarafından yüklenir).
var item_db: ItemDb = null
var drop_chance: float = 0.0

## Oyuncunun tek vuruşta kaç düşmana birden değeceği. Savuruş tam
## çevreyi kapsadığı için sayı da geniş: seni saran bütün sürüye
## aynı anda değebilmelisin.
const PLAYER_STRIKE_TARGETS := 6

## Vuruşun kapsadığı yarım açı. PI = tam çevre: savurduğunda
## etrafındaki herkes hasar alır, arkandaki dahil.
const PLAYER_STRIKE_ARC := PI

## Oyuncunun taban yürüme hızı (birim/saniye).
const PLAYER_BASE_SPEED := 5.6

## Ziyaret edilmiş haritalar — dünya haritasında işaretlenir.
var visited: Dictionary = {}

var base_seed: int = 20260920

## Bu tick'te harita değiştiyse buraya yazılır (görsel katman okur).
var last_travel: Dictionary = {}

## Seviye yetmediği için geçilemeyen kapı (görsel katman uyarı gösterir).
var last_blocked: Dictionary = {}


func _init(name_of_player: String = "Oyuncu", seed_value: int = 20260920) -> void:
	player_name = name_of_player
	base_seed = seed_value
	player_stats = Stats.for_player()
	player_inventory = Inventory.new()
	mastery = Mastery.new()
	skills = SkillTree.new()
	quest_log = QuestLog.new()
	progress = Progress.new()
	abilities = AbilityBook.new()
	perks = PerkShop.new()


func register_map(m: MapDef) -> void:
	maps[m.id] = m


## Eşya havuzunu bağlar ve oyuncuya başlangıç takımını verir.
func setup_items(db: ItemDb, starting: Dictionary, chance: float) -> void:
	item_db = db
	drop_chance = chance
	for anahtar in starting.keys():
		var id := str(starting[anahtar])
		if not db.has(id):
			continue
		var it := db.make(id)
		if player_inventory.equipped(it.slot) == null:
			player_inventory.equipment[it.slot] = it
	refresh_stats()


func setup_skills(d: Dictionary) -> void:
	skills.load_defs(d)
	refresh_stats()


func setup_quests(d: Dictionary) -> void:
	quest_log.load_defs(d)


func setup_abilities(d: Dictionary) -> void:
	abilities.load_defs(d)
	refresh_stats()


func setup_perks(d: Dictionary) -> void:
	perks.load_defs(d)
	refresh_stats()


## Şehirdeki ustadan zincirin sıradaki özelliğini satın al.
func buy_perk(perk_id: String) -> int:
	var seviye := player.stats.level if player != null else 1
	var harcanan := perks.buy(perk_id, player_gold, seviye)
	if harcanan <= 0:
		return 0
	_set_gold(player_gold - harcanan)
	refresh_stats()
	return harcanan


## Hızlı çubuğun ilk iki yuvası iksirlere ayrılmıştır; çantadaki en
## güçlü can ve mana iksirini kendiliğinden oraya koyar.
func refresh_hotbar() -> void:
	abilities.hotbar[0] = _best_potion(true)
	abilities.hotbar[1] = _best_potion(false)


func _best_potion(heal_hp: bool) -> String:
	var en_iyi := ""
	var en_guclu := 0
	for it in player_inventory.slots:
		if not it.consumable or it.material != "":
			continue
		var deger := it.heal_hp if heal_hp else it.heal_mp
		if deger > en_guclu:
			en_guclu = deger
			en_iyi = it.item_id
	return en_iyi


## Hızlı çubuktaki yuvayı kullan. Dönen metin arayüzde gösterilir.
func use_hotbar(index: int) -> String:
	if index < 0 or index >= abilities.hotbar.size() or player == null:
		return ""
	var id := abilities.hotbar[index]
	if id.is_empty():
		return ""
	var a := abilities.get_ability(id)
	if a != null:
		if not a.ready(player.mp):
			return ""
		if world.command_use_ability(player.id, id, player.pos + player.facing * a.cast_range):
			return a.display_name
		return ""
	# İksir
	for i in player_inventory.slots.size():
		if player_inventory.slots[i].item_id == id:
			var etki := use_item(i)
			if not etki.is_empty():
				refresh_hotbar()
				return etki
			return ""
	return ""


## Çantadaki bir iksiri ya da malzemeyi kullan.
func use_item(index: int) -> String:
	if player == null or index < 0 or index >= player_inventory.slots.size():
		return ""
	var it := player_inventory.slots[index]
	if not it.consumable or it.material != "":
		return ""
	var etki := ""
	if it.heal_hp > 0 and player.hp < player.stats.max_hp():
		player.hp = mini(player.stats.max_hp(), player.hp + it.heal_hp)
		etki = "can"
	if it.heal_mp > 0 and player.mp < player.stats.max_mp():
		player.mp = mini(player.stats.max_mp(), player.mp + it.heal_mp)
		etki = "mana" if etki.is_empty() else "can ve mana"
	if etki.is_empty():
		return ""
	player_inventory.consume_one(it.item_id)
	return etki


## Aynı eşyadan üç tane, bir üst kademeye.
func combine_item(item_id: String) -> Item:
	var yeni := player_inventory.combine(item_id, item_db)
	if yeni != null:
		refresh_stats()
	return yeni


## Kitap oku / sunak taşı kullan.
func advance_ability(ability_id: String, with_stone: bool) -> bool:
	var ok := abilities.use_stone(ability_id) if with_stone else abilities.read_book(ability_id)
	if ok:
		refresh_stats()
	return ok


func spend_ability_point(ability_id: String) -> bool:
	if not abilities.spend_point(ability_id):
		return false
	refresh_stats()
	return true


## Eşya + ustalık + beceri bonuslarını baştan toplar.
## Bonus veren her şey değiştiğinde çağrılmalı.
func refresh_stats() -> void:
	var oran := player.hp_ratio() if player != null else 1.0
	player_stats.reset_bonuses()
	player_inventory.apply_to(player_stats)
	mastery.apply_to(player_stats)
	skills.apply_to(player_stats)
	progress.apply_to(player_stats)
	abilities.apply_to(player_stats)
	perks.apply_to(player_stats)
	quest_log.apply_to(player_stats)
	if player != null:
		player.hp = clampi(int(round(oran * float(player_stats.max_hp()))), 1, player_stats.max_hp())


## Çantadaki eşyayı satar, kazanılan parayı döner (0 = satılamadı).
func sell_item(index: int) -> int:
	var it := player_inventory.remove_at(index)
	if it == null:
		return 0
	var kazanc := maxi(1, it.sell_price)
	_set_gold(player_gold + kazanc)
	progress.items_sold += 1
	progress.gold_earned += kazanc
	return kazanc


func _set_gold(amount: int) -> void:
	player_gold = maxi(0, amount)
	if player != null:
		player.gold = player_gold


## Görev ödülü gibi dışarıdan gelen kazanç.
func grant_reward(gold: int, exp_amount: int) -> void:
	progress.quests_done += 1
	refresh_stats()  # kalıcı görev ödülü varsa hemen işlesin
	if gold > 0:
		_set_gold(player_gold + gold)
		progress.gold_earned += gold
	if exp_amount > 0 and world != null and player != null:
		world.award_experience(player.id, exp_amount)


## Beceriyi bir seviye yükseltir. Harcanan parayı döner (0 = olmadı).
func learn_skill(skill_id: String) -> int:
	var harcanan := skills.learn(skill_id, player_gold)
	if harcanan <= 0:
		return 0
	_set_gold(player_gold - harcanan)
	refresh_stats()
	return harcanan


func start(map_id: String) -> void:
	travel_to(map_id)


## Haritaya geç. entry_at verilmezse haritanın kendi doğuş noktası kullanılır.
func travel_to(map_id: String, entry_at = null) -> void:
	if not maps.has(map_id):
		push_error("Bilinmeyen harita: %s" % map_id)
		return

	var onceki := current_map.id if current_map != null else ""
	if player != null:
		player_experience = player.experience
		player_hp = player.hp
		player_gold = player.gold

	var m: MapDef = maps[map_id]
	current_map = m
	visited[map_id] = true

	world = SimWorld.new(base_seed + m.seed_offset)
	world.item_db = item_db
	world.drop_chance = drop_chance
	world.quest_log = quest_log
	world.bounds = m.extent
	_populate(m)

	var giris: Vector2 = m.spawn_point if entry_at == null else entry_at
	player = world.spawn(player_name, m.clamp_pos(giris), SimEntity.Kind.PLAYER, 0, player_stats)
	player.experience = player_experience
	player.inventory = player_inventory
	player.mastery = mastery
	player.skills = skills
	player.progress = progress
	player.abilities = abilities
	player.gold = player_gold
	player.move_speed = PLAYER_BASE_SPEED
	player.attack_max_targets = PLAYER_STRIKE_TARGETS
	player.attack_arc = PLAYER_STRIKE_ARC
	refresh_stats()
	# Can haritayı geçerken korunur; ilk açılışta tam dolu başlar.
	player.hp = player_stats.max_hp() if player_hp <= 0 else clampi(player_hp, 1, player_stats.max_hp())

	last_travel = {"from": onceki, "to": map_id}


## Bir tick ilerlet, sonra geçit kontrolü yap.
func step() -> void:
	last_travel = {}
	last_blocked = {}
	if world == null:
		return
	world.step()
	if player != null:
		player_gold = player.gold  # para tek kaynaktan: simülasyon yazar, biz okuruz
	_check_portals()


func portals() -> Array[Dictionary]:
	return current_map.portals if current_map != null else []


## Oyuncu bir geçidin üstüne bastı mı?
func _check_portals() -> void:
	if player == null or not player.alive or current_map == null:
		return
	for p in current_map.portals:
		var at := MapDef._to_vec(p.get("at", [0, 0]))
		var r := float(p.get("radius", 1.3))
		if player.pos.distance_to(at) > r:
			continue
		var hedef := str(p.get("to", ""))
		if hedef.is_empty() or not maps.has(hedef):
			continue

		# Kapılar kilitli değil: her bölgeye her seviyede girilebilir.
		# Zorluk farkını kapı değil, bölgenin kendisi anlatır.
		var giris = p.get("entry", null)
		travel_to(hedef, null if giris == null else MapDef._to_vec(giris))
		return


func _populate(m: MapDef) -> void:
	for n in m.npcs:
		var e := world.spawn(str(n.get("name", "NPC")), MapDef._to_vec(n.get("at", [0, 0])), SimEntity.Kind.NPC, 0)
		e.move_speed = 0.0
		e.npc_role = str(n.get("role", "quest"))

	var grup_no := 0
	for c in m.monsters:
		grup_no += 1
		_spawn_group(c, grup_no)

	if not m.altar.is_empty():
		_spawn_altar(m.altar)
	if not m.boss.is_empty():
		_spawn_boss(m.boss)


## Bölge bossu: haritada gezen tek, çok güçlü canavar.
## Sunaktan farkı, kendi başına dolaşması ve tek başına avlanabilmesi.
func _spawn_boss(b: Dictionary) -> void:
	var seviye := int(b.get("level", 10))
	var nokta := current_map.clamp_pos(MapDef._to_vec(b.get("at", [0, 0])))
	var e := world.spawn(str(b.get("name", "Bölge Bossu")), nokta, SimEntity.Kind.MONSTER, 1,
			Stats.for_monster(seviye, float(b.get("toughness", 2.5))))
	e.stats.hp_scale = 5.5
	e.hp = e.stats.max_hp()
	e.move_speed = 3.6
	e.attack_windup_ticks = 6
	e.attack_recover_ticks = 16
	e.attack_range = 3.0
	e.attack_max_targets = 2
	e.exp_value = seviye
	e.exp_multiplier = 12.0
	e.gold_value = seviye * 80
	e.leash_range = 26.0
	e.is_boss = true
	e.spawn_group = 99
	e.group_center = nokta
	e.group_spread = 5.0
	world.set_wander(e, 6.0)


## Haritanın sunağı: dokunulduğu anda bölgeyi ayağa kaldıran cisim.
func _spawn_altar(a: Dictionary) -> void:
	var seviye := int(a.get("level", 10))
	var nokta := current_map.clamp_pos(MapDef._to_vec(a.get("at", [0, 0])))
	var e := world.spawn(str(a.get("name", "Sunak")), nokta, SimEntity.Kind.ALTAR, 1,
			Stats.for_monster(seviye, 1.0))
	e.move_speed = 0.0
	# Devasa can, ince zırh: uzun süren bir kuşatma olsun, vuruşlar 1'e
	# düşmesin diye savunması bilerek düşük tutuluyor.
	e.stats.hp_scale = 55.0
	e.stats.vitality = maxi(1, seviye / 4)
	e.hp = e.stats.max_hp()
	e.exp_multiplier = float(a.get("exp_mult", 25.0))
	e.gold_value = int(a.get("gold", seviye * 150))
	e.spawn_group = 0


func _spawn_group(c: Dictionary, group_id: int = 0) -> void:
	var isim := str(c.get("name", "Canavar"))
	var seviye := int(c.get("level", 1))
	var merkez := MapDef._to_vec(c.get("at", [0, 0]))
	var adet := maxi(1, int(c.get("count", 1)))
	var yayilma := float(c.get("spread", 0.0))
	var dolasma := float(c.get("wander", 2.5))
	var saglamlik := float(c.get("toughness", 1.0))
	var tas := bool(c.get("stone", false))

	for i in adet:
		var nokta := merkez
		if yayilma > 0.0:
			# Deterministik dağılım: aynı harita her girişte aynı düzende.
			var aci := world.rng.float_range(0.0, TAU)
			var yaricap := world.rng.float_range(0.0, yayilma)
			nokta = merkez + Vector2.from_angle(aci) * yaricap
		nokta = current_map.clamp_pos(nokta)

		var kind := SimEntity.Kind.STONE if tas else SimEntity.Kind.MONSTER
		var e := world.spawn(isim, nokta, kind, 1, Stats.for_monster(seviye, saglamlik))
		e.exp_value = seviye
		e.spawn_group = group_id

		e.group_center = merkez
		e.group_spread = maxf(yayilma, 2.5)

		if tas:
			# Metin taşı yerinden kıpırdamaz. Canı çok yüksek ama zırhı
			# ince: dövüş uzun sürsün, vuruşların da 1'e düşmesin.
			e.move_speed = 0.0
			e.stats.hp_scale = 9.0
			e.stats.vitality = maxi(1, seviye / 3)
			e.hp = e.stats.max_hp()
			e.exp_multiplier = float(c.get("exp_mult", 7.0))
			e.gold_value = int(c.get("gold", seviye * 40))
		else:
			e.gold_value = int(c.get("gold", seviye * 2 + 3))
			e.move_speed = float(c.get("speed", 3.2))
			# Canavarlar oyuncudan yavaş vurur: sürü hâlinde geldiklerinde
			# bile oyuncuya nefes alacak boşluk kalsın.
			e.attack_windup_ticks = 6
			e.attack_recover_ticks = 20
			world.set_wander(e, dolasma)
