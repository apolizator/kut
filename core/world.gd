class_name SimWorld
extends RefCounted

## Oyunun BEYNİ. Tek bir tick'i ilerletir, başka hiçbir şey yapmaz.
##
## Buradaki kod motor olmadan, terminalde, sunucuda ve testlerde
## birebir aynı sonucu üretir. Faz 6'da 2D arayüz söküldüğünde
## bu dosyaya dokunulmayacak.
##
## TASARIM KURALI — saldırganlık:
## Canavarlar kendiliğinden saldırmaz. Bir canavar ancak VURULDUĞUNDA
## karşılık verir ve bir süre sonra sakinleşip bölgesine döner.
## Harita, oyuncu ilk vuruşu yapana kadar huzurludur.

## Vurulan canavarın kaç tick boyunca karşılık verdiği (her vuruşta tazelenir).
const AGGRO_TICKS := SimClock.TICK_RATE * 8

## Ölen canavarın kaç tick sonra geri döndüğü.
const RESPAWN_TICKS := SimClock.TICK_RATE * 10

## Ölen oyuncunun kaç tick sonra ayağa kalktığı.
const PLAYER_RESPAWN_TICKS := SimClock.TICK_RATE * 5

## Savaş dışındayken kaç tick'te bir can yenilendiği ve oranı.
const REGEN_INTERVAL := SimClock.TICK_RATE
const REGEN_RATIO := 0.04

## SÜRÜ DAVRANIŞI: bir canavara vurunca çevresindeki kaç arkadaşı
## kavgaya katılır ve ne kadar uzaktan duyarlar.
## Sayı bilerek düşük: bütün harita üstüne gelirse oyuncu ölür.
const PACK_ALERT_RANGE := 5.0
const PACK_MAX_HELPERS := 2

## Bir oyuncuya aynı anda kaç canavar saldırabilir. Sürü uyarısı
## zincirleme yayılıyordu: vurulan her canavar iki arkadaşını
## çağırınca birkaç saniyede bütün bölge üstüne geliyor ve dövüş
## kazanılamaz hâle geliyordu. Sunağa dokunmak bu sınırı aşan tek şey.
const MAX_ENGAGED := 6

## Varlıklar birbirinin içine girmesin: sürü hâlinde saldırdıklarında
## tek bir kareye yığılıp hangi canın kime ait olduğu okunmaz oluyordu.
const SEPARATION_RADIUS := 0.85
const SEPARATION_PUSH := 0.40

## Metin taşı belli can eşiklerinde bekçi çağırır. Taşı kırmak artık
## sabırla dayak atmak değil, üç dalga bekçiyle başa çıkmak demek.
## Metin taşı beş dalga bekçi çıkarır; her dalga bir öncekinden güçlü.
## Taşın kendisi çok canlı ama zırhı zayıftır: uzun süren, sürekli
## vurduğun bir kuşatma olsun diye.
const STONE_GUARD_WAVES := 5
const STONE_GUARDS_PER_WAVE := 2

## SUNAK: her haritanın tek bir cismi. Dokunduğun anda bölgedeki
## bütün canavarlar üstüne gelir ve sunak beş dalga BOSS çağırır.
## Kırması oyunun en zor işi, ödülü de en büyüğü.
const ALTAR_WAVES := 5
const ALTAR_BOSSES_PER_WAVE := 2

## Geçici varlığın cesedi kaç tick sahnede kalır.
const CORPSE_TICKS := SimClock.TICK_RATE * 2

## Bir grup tamamen temizlendikten kaç tick sonra hep birlikte doğar.
const GROUP_RESPAWN_TICKS := SimClock.TICK_RATE * 3

## Grup bir türlü temizlenmezse tek tek doğmadan önceki en uzun bekleme.
const SOLO_RESPAWN_TIMEOUT := SimClock.TICK_RATE * 45

var rng: SimRng
var entities: Array[SimEntity] = []
var tick: int = 0

## Ganimet için eşya havuzu (Game tarafından verilir; boş da olabilir).
var item_db: ItemDb = null
var drop_chance: float = 0.0

## Görev defteri (Game tarafından verilir). Canavar ölünce ilerler.
var quest_log: QuestLog = null

## Haritanın yarı genişlik/yükseklik sınırı — kimse dışarı çıkamaz.
var bounds: Vector2 = Vector2(1000.0, 1000.0)

## Bu tick'te olan biten. Görsel katman okur (hasar yazısı, ses),
## Faz 4'te aynı liste ağ üzerinden istemciye gidecek.
var events: Array[Dictionary] = []

var _next_id: int = 1
var _regen_timer: int = 0

## Tick'in ORTASINDA doğan varlıklar (metin taşı bekçileri) doğrudan
## listeye eklenemez — üzerinde yürüdüğümüz diziyi bozar. Kuyruğa
## alınır, tick bitince eklenir.
var _spawn_queue: Array[SimEntity] = []

## Grup temizliği tick başında bir kez hesaplanır. Yoksa gruptaki ilk
## canavar dirildiği anda grup "temiz değil" sayılıp geri kalanlar
## sonsuza kadar ölü kalıyordu.
var _cleared_groups: Dictionary = {}


func _init(seed_value: int = 20260920) -> void:
	rng = SimRng.new(seed_value)


func spawn(display_name: String, at: Vector2, kind: SimEntity.Kind = SimEntity.Kind.MONSTER, team: int = 1, entity_stats: Stats = null) -> SimEntity:
	var e := _make(display_name, at, kind, team, entity_stats)
	entities.append(e)
	return e


func _make(display_name: String, at: Vector2, kind: SimEntity.Kind, team: int, entity_stats: Stats) -> SimEntity:
	var e := SimEntity.new()
	e.id = _next_id
	_next_id += 1
	e.display_name = display_name
	e.kind = kind
	e.team = team
	e.pos = at
	e.prev_pos = at
	e.move_target = at
	e.spawn_pos = at
	e.stats = entity_stats if entity_stats != null else Stats.new()
	e.hp = e.stats.max_hp()
	e.mp = e.stats.max_mp()
	return e


func get_entity(id: int) -> SimEntity:
	for e in entities:
		if e.id == id:
			return e
	return null


## Varlığı doğduğu noktanın çevresinde gezinmeye ayarlar.
## Başlangıç beklemesi rastgeledir; yoksa bütün canavarlar aynı anda
## aynı ritimde yürüyüp robot sürüsü gibi görünür.
func set_wander(e: SimEntity, radius: float) -> void:
	e.wander_enabled = true
	e.wander_origin = e.pos
	e.wander_radius = radius
	e.wander_cooldown = rng.int_range(0, SimClock.TICK_RATE * 3)


# --- Komutlar ---
# Faz 4'te istemci bu fonksiyonları doğrudan değil, ağ paketi olarak
# çağıracak. İmzaları o yüzden "id + veri" şeklinde, nesne geçirerek değil.

func command_move(id: int, target: Vector2) -> void:
	var e := get_entity(id)
	if e == null or not e.alive or e.is_busy():
		return
	e.attack_target_id = 0  # elle yürümek saldırıyı iptal eder
	e.move_dir = Vector2.ZERO
	e.move_target = target
	e.has_move_target = true


## Klavyeyle sürekli yürüme. Her karede güncellenir; sıfır vektör durdurur.
## Yürümeye başlamak saldırıyı ve tıkla-yürü hedefini iptal eder.
func command_move_dir(id: int, dir: Vector2) -> void:
	var e := get_entity(id)
	if e == null or not e.alive:
		return
	if dir.length() < 0.01:
		e.move_dir = Vector2.ZERO
		return
	e.move_dir = dir.normalized()
	e.has_move_target = false


## Hedefe saldır. Hedef menzil dışındaysa varlık önce peşinden gider.
func command_attack(id: int, target_id: int) -> void:
	var e := get_entity(id)
	var hedef := get_entity(target_id)
	if e == null or hedef == null or not e.alive:
		return
	if not hedef.is_attackable() or hedef.id == e.id:
		return
	e.attack_target_id = target_id


## Seviye atlayınca kazanılan puanı ham bir stata yatır.
## "str" / "dex" / "int" / "vit"
func command_spend_stat(id: int, which: String) -> bool:
	var e := get_entity(id)
	if e == null or e.stats == null or e.stats.stat_points <= 0:
		return false

	match which:
		"str":
			e.stats.strength += 1
		"dex":
			e.stats.dexterity += 1
		"int":
			e.stats.intelligence += 1
		"vit":
			# Can tavanı yükseldi; kazanılan canı da hemen ver.
			var once := e.stats.max_hp()
			e.stats.vitality += 1
			e.hp += e.stats.max_hp() - once
		_:
			return false

	e.stats.stat_points -= 1
	events.append({"type": "stat_spent", "entity": e.id, "stat": which, "tick": tick})
	return true


## Mana harcayarak bir yetenek kullan.
## Dönen değer: kullanıldıysa true.
func command_use_ability(id: int, ability_id: String, aim: Vector2) -> bool:
	var e := get_entity(id)
	if e == null or not e.alive or e.abilities == null:
		return false
	var a := e.abilities.get_ability(ability_id)
	if a == null or not a.ready(e.mp):
		return false

	var maliyet := a.total_mana_cost()
	if e.mp < maliyet:
		return false
	e.mp -= maliyet
	a.cooldown_left = a.cooldown_ticks

	match a.kind:
		Ability.Kind.BUFF:
			e.buff_ticks = maxi(1, a.cooldown_ticks / 2)
			e.buff_bonus = a.bonus.duplicate()
			# Kademe yükseldikçe geçici güç de büyür.
			var k := a.effect_scale()
			for anahtar in e.buff_bonus.keys():
				e.buff_bonus[anahtar] = e.buff_bonus[anahtar] * k
			_refresh_entity_stats(e)
			events.append({"type": "ability_buff", "entity": e.id, "ability": ability_id, "tick": tick})
		Ability.Kind.RANGED:
			_cast_area(e, a, aim)
		_:
			_cast_area(e, a, e.pos)
	return true


## Alan hasarı: merkezin çevresindeki düşmanlara yetenek gücüyle vurur.
func _cast_area(e: SimEntity, a: Ability, center: Vector2) -> void:
	var carpan := a.power * a.effect_scale()
	var vurulan := 0
	for o in entities:
		if o.id == e.id or not o.is_attackable() or o.team == e.team:
			continue
		if o.pos.distance_to(center) > a.radius:
			continue
		var sonuc := Combat.resolve(e.stats, o.stats, rng)
		sonuc["damage"] = maxi(1, int(round(float(sonuc["damage"]) * carpan)))
		_deal(e, o, sonuc, true)
		vurulan += 1

	events.append({
		"type": "ability_cast",
		"entity": e.id,
		"ability": a.ability_id,
		"at": center,
		"radius": a.radius,
		"hits": vurulan,
		"tick": tick,
	})


func command_stop(id: int) -> void:
	var e := get_entity(id)
	if e == null:
		return
	e.has_move_target = false
	e.attack_target_id = 0


# --- Simülasyon ---

## Dünyayı TAM OLARAK bir tick ilerletir.
func step() -> void:
	_cleared_groups.clear()
	for e in entities:
		e.prev_pos = e.pos
	for e in entities:
		_step_entity(e)
	_step_buffs()
	_step_separation()
	_step_regen()
	_flush_spawns()
	_cleanup_temporary()
	_count_play_time()
	tick += 1


## Biriken olayları alır ve listeyi boşaltır.
func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


func _step_entity(e: SimEntity) -> void:
	if not e.alive:
		_step_dead(e)
		return

	# Karşılık verme süresi HER tick işler — saldırı animasyonunun
	# ortasında bile. Yoksa bir kez kızan canavar, oyuncu çoktan
	# çekilmiş olsa da sonsuza kadar vurmaya devam eder.
	if e.aggro_ticks > 0:
		e.aggro_ticks -= 1
		if e.aggro_ticks == 0:
			e.aggro_target_id = 0

	# Yürümek ve vurmak artık birlikte olur: WASD'ye basarken de
	# saldırabilirsin, saldırırken de yürüyebilirsin.
	var yuruyor := false
	if e.move_dir != Vector2.ZERO:
		_step_dir_move(e)
		yuruyor = true

	if e.attack_timer >= 0:
		_step_attack(e)
		return

	var hedef := _current_target(e)
	if hedef == null:
		_auto_retarget(e)
		hedef = _current_target(e)

	if hedef != null:
		if yuruyor:
			# Klavyedeysen yönünü sen seçersin; menzile girdiğinde vurur.
			if e.pos.distance_to(hedef.pos) <= e.effective_range():
				_begin_attack(e, hedef)
		else:
			_step_engage(e, hedef)
		if e.attack_timer >= 0:
			return

	if yuruyor:
		return

	if e.kind == SimEntity.Kind.MONSTER and not e.has_move_target and e.pos.distance_to(e.spawn_pos) > 0.05:
		# Kavga bitti: bölgene dön.
		e.move_target = e.spawn_pos
		e.has_move_target = true

	if not e.has_move_target and e.wander_enabled and e.can_move():
		_step_wander(e)

	if e.has_move_target:
		_step_move(e)
	else:
		e.state = SimEntity.State.IDLE


## Şu an kime saldırıyor: oyuncunun verdiği komut, yoksa karşılık hedefi.
func _current_target(e: SimEntity) -> SimEntity:
	var hedef_id := e.attack_target_id if e.attack_target_id != 0 else e.aggro_target_id
	if hedef_id == 0:
		return null
	var hedef := get_entity(hedef_id)
	if hedef == null or not hedef.is_attackable():
		e.attack_target_id = 0
		e.aggro_target_id = 0
		return null
	return hedef


## Hedefe yaklaş, menzile girince vur.
func _step_engage(e: SimEntity, hedef: SimEntity) -> void:
	# Canavar doğduğu yerden fazla uzaklaştıysa kovalamayı bırakır.
	if e.kind == SimEntity.Kind.MONSTER and e.pos.distance_to(e.spawn_pos) > e.leash_range:
		e.aggro_target_id = 0
		e.aggro_ticks = 0
		e.attack_target_id = 0
		e.move_target = e.spawn_pos
		e.has_move_target = true
		return

	var fark := hedef.pos - e.pos
	var mesafe := fark.length()
	if mesafe > 0.0001:
		e.facing = fark / mesafe

	if mesafe <= e.effective_range():
		_begin_attack(e, hedef)
		return

	if not e.can_move():
		return

	# Aynı hedefe saldıranlar hedefin ÖNÜNDE bir yay üzerine dizilir.
	# Böylece oyuncuyu çepeçevre kuşatıp arkadan vurmak yerine tek
	# vuruşla kapsanabilecek bir hizaya geçerler.
	e.move_target = _formation_point(e, hedef)
	e.has_move_target = true


func _begin_attack(e: SimEntity, hedef: SimEntity) -> void:
	var fark := hedef.pos - e.pos
	if fark.length() > 0.0001:
		e.facing = fark.normalized()
	e.has_move_target = false
	e.attack_timer = 0
	e.state = SimEntity.State.ATTACKING
	events.append({"type": "attack_start", "entity": e.id, "target": hedef.id, "tick": tick})


## Hedefin ölmesiyle boşa vurmayı bırak: sana saldıranlardan en yakınına geç.
## Oyuncu olduğu yerde çakılıp dayak yemesin diye.
func _auto_retarget(e: SimEntity) -> void:
	if e.kind != SimEntity.Kind.PLAYER or e.attack_target_id != 0 or not e.alive:
		return
	var en_iyi: SimEntity = null
	var en_yakin := INF
	for o in entities:
		if not o.alive or not o.is_attackable() or o.team == e.team:
			continue
		if o.aggro_target_id != e.id:
			continue  # yalnızca SANA saldıranlar
		var d := e.pos.distance_to(o.pos)
		if d < en_yakin:
			en_yakin = d
			en_iyi = o
	if en_iyi != null:
		e.attack_target_id = en_iyi.id
		events.append({"type": "auto_target", "entity": e.id, "target": en_iyi.id, "tick": tick})


## Hedefe saldıran grubun ortak yönünü bulup herkese bir yer ayırır.
func _formation_point(e: SimEntity, hedef: SimEntity) -> Vector2:
	var mesafe := e.effective_range() * 0.8

	var grup: Array[int] = []
	var yon_toplami := Vector2.ZERO
	for o in entities:
		if not o.alive or o.kind != SimEntity.Kind.MONSTER:
			continue
		if o.aggro_target_id != hedef.id and o.attack_target_id != hedef.id:
			continue
		grup.append(o.id)
		var f := o.pos - hedef.pos
		if f.length() > 0.01:
			yon_toplami += f.normalized()

	grup.sort()
	var idx := grup.find(e.id)
	if grup.size() <= 1 or idx < 0 or yon_toplami.length() < 0.01:
		var kendi := e.pos - hedef.pos
		if kendi.length() < 0.01:
			kendi = Vector2.RIGHT
		return hedef.pos + kendi.normalized() * mesafe

	# Grubun ortalama yönü yavaş değişir; bu yüzden hiza titremez.
	var taban := yon_toplami.angle()
	var yay := 1.5
	var adim := yay / float(grup.size() - 1)
	var aci := taban - yay * 0.5 + float(idx) * adim
	return hedef.pos + Vector2.from_angle(aci) * mesafe


func _step_dir_move(e: SimEntity) -> void:
	if not e.can_move():
		e.state = SimEntity.State.IDLE
		return
	e.facing = e.move_dir
	var adim := e.current_speed() * SimClock.TICK_DELTA
	e.pos = _clamp_to_bounds(e.pos + e.move_dir * adim)
	e.state = SimEntity.State.MOVING
	_count_steps(e, adim)


var _step_carry: float = 0.0

func _count_steps(e: SimEntity, distance: float) -> void:
	if e.progress == null:
		return
	_step_carry += distance
	if _step_carry >= 1.0:
		var tam := int(_step_carry)
		e.progress.steps += tam
		_step_carry -= float(tam)


func _clamp_to_bounds(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, -bounds.x, bounds.x), clampf(p.y, -bounds.y, bounds.y))


func _flush_spawns() -> void:
	if _spawn_queue.is_empty():
		return
	entities.append_array(_spawn_queue)
	_spawn_queue.clear()


## Ölmüş geçici varlıkların cesetleri sahneden kalkar.
func _cleanup_temporary() -> void:
	var temizlenecek := false
	for e in entities:
		if e.temporary and not e.alive and e.respawn_ticks <= 0:
			temizlenecek = true
			break
	if not temizlenecek:
		return
	var kalan: Array[SimEntity] = []
	for e in entities:
		if e.temporary and not e.alive and e.respawn_ticks <= 0:
			continue
		kalan.append(e)
	entities = kalan


## Eşya, ustalık ve becerilerden gelen bonusları baştan toplar.
## Can tavanı büyüdüyse oran korunur, yani bonus almak canı düşürmez.
func _refresh_entity_stats(e: SimEntity) -> void:
	if e.stats == null:
		return
	var oran := e.hp_ratio()
	e.stats.reset_bonuses()
	if e.inventory != null:
		e.inventory.apply_to(e.stats)
	if e.mastery != null:
		e.mastery.apply_to(e.stats)
	if e.skills != null:
		e.skills.apply_to(e.stats)
	if e.abilities != null:
		e.abilities.apply_to(e.stats)
	if e.buff_ticks > 0 and not e.buff_bonus.is_empty():
		SkillTree._add(e.stats, e.buff_bonus, 1)
	e.hp = clampi(int(round(oran * float(e.stats.max_hp()))), 1, e.stats.max_hp())
	e.mp = clampi(e.mp, 0, e.stats.max_mp())


## Saldırı hızı bonusu hazırlık ve toparlanma sürelerini kısaltır.
func _windup_of(e: SimEntity) -> int:
	var k := e.stats.attack_speed_scale() if e.stats != null else 1.0
	return maxi(1, int(round(float(e.attack_windup_ticks) * k)))


func _recover_of(e: SimEntity) -> int:
	var k := e.stats.attack_speed_scale() if e.stats != null else 1.0
	return maxi(1, int(round(float(e.attack_recover_ticks) * k)))


func _step_attack(e: SimEntity) -> void:
	e.attack_timer += 1
	var windup := _windup_of(e)

	if e.attack_timer == windup:
		_resolve_attack(e)
	elif e.attack_timer >= windup + _recover_of(e):
		e.attack_timer = -1
		e.state = SimEntity.State.IDLE


## Vuruşun isabet ettiği an. Hasar zinciri core/combat.gd'de.
##
## Vuruş TEK hedefe değil, menzil ve bakış açısı içindeki en fazla
## attack_max_targets düşmana birden değer. Oyuncu sürüyle çevrildiğinde
## hepsine birden karşılık verebilsin diye.
func _resolve_attack(e: SimEntity) -> void:
	var ana := _current_target(e)
	if ana == null:
		return

	var hedefler := _strike_targets(e, ana)
	if hedefler.is_empty():
		# Hazırlık süresi içinde herkes menzilden çıktı.
		events.append({
			"type": "attack_hit",
			"attacker": e.id,
			"target": ana.id,
			"hit": false,
			"damage": 0,
			"critical": false,
			"pierced": false,
			"out_of_range": true,
			"tick": tick,
		})
		return

	if e.progress != null:
		e.progress.attacks += 1

	for hedef in hedefler:
		_apply_hit(e, hedef)


## Menzil ve bakış açısı içindeki hedefler. İlk sıradaki ana hedeftir.
func _strike_targets(e: SimEntity, ana: SimEntity) -> Array[SimEntity]:
	var out: Array[SimEntity] = []
	var menzil := e.effective_range() * 1.35

	if e.pos.distance_to(ana.pos) <= menzil:
		out.append(ana)

	if e.attack_max_targets <= 1:
		return out

	for o in entities:
		if out.size() >= e.attack_max_targets:
			break
		if o.id == e.id or o.id == ana.id or not o.is_attackable():
			continue
		if o.team == e.team:
			continue
		var fark := o.pos - e.pos
		var d := fark.length()
		if d > menzil:
			continue
		if d > 0.0001 and absf(e.facing.angle_to(fark / d)) > e.attack_arc:
			continue  # arkanda kalan düşmana vuramazsın
		out.append(o)
	return out


func _apply_hit(e: SimEntity, hedef: SimEntity) -> void:
	var sonuc := Combat.resolve(e.stats, hedef.stats, rng)
	_deal(e, hedef, sonuc, false)


func _deal(e: SimEntity, hedef: SimEntity, sonuc: Dictionary, from_ability: bool) -> void:
	events.append({
		"type": "attack_hit",
		"attacker": e.id,
		"target": hedef.id,
		"hit": sonuc["hit"],
		"damage": sonuc["damage"],
		"critical": sonuc["critical"],
		"pierced": sonuc["pierced"],
		"out_of_range": false,
		"ability": from_ability,
		"tick": tick,
	})

	if not sonuc["hit"]:
		return

	var hasar := int(sonuc["damage"])
	hedef.hp -= hasar

	if e.progress != null:
		e.progress.damage_dealt += hasar
		if bool(sonuc["critical"]):
			e.progress.crits += 1

	# CAN ÇALMA: verdiğin hasarın bir kısmı cana döner.
	var calma := e.stats.lifesteal()
	if calma > 0.0 and e.alive:
		var kazanc := maxi(1, int(round(float(hasar) * calma)))
		var tavan := e.stats.max_hp()
		if e.hp < tavan:
			e.hp = mini(tavan, e.hp + kazanc)
			events.append({"type": "lifesteal", "entity": e.id, "amount": kazanc, "tick": tick})
	if hedef.progress != null:
		hedef.progress.damage_taken += hasar

	# USTALIK: verdiğin hasar silah, yediğin hasar zırh ustalığını besler.
	_train(e, hasar, true)
	_train(hedef, hasar, false)

	# Metin taşı ve sunak belli can eşiklerinde koruyucu çağırır.
	if hedef.is_objective() and hedef.hp > 0:
		if hedef.kind == SimEntity.Kind.ALTAR and hedef.guard_waves == 0:
			_alert_map(e)
		_check_stone_guards(hedef, e)

	# KARŞILIK VERME: canavar ancak vurulduğunda saldırgana kilitlenir.
	if hedef.kind == SimEntity.Kind.MONSTER and hedef.alive:
		hedef.aggro_target_id = e.id
		hedef.aggro_ticks = AGGRO_TICKS
		_alert_pack(hedef, e)

	if hedef.hp <= 0:
		_kill(hedef, e)


## Vurulan canavarın yakınındaki arkadaşları kavgaya katılır.
func _alert_pack(kurban: SimEntity, saldirgan: SimEntity) -> void:
	if _engaged_count(saldirgan) >= MAX_ENGAGED:
		return
	var katilan := 0
	for o in entities:
		if katilan >= PACK_MAX_HELPERS:
			break
		if o.id == kurban.id or not o.alive:
			continue
		if o.kind != SimEntity.Kind.MONSTER or o.team != kurban.team:
			continue
		if o.aggro_target_id != 0:
			continue
		if o.pos.distance_to(kurban.pos) > PACK_ALERT_RANGE:
			continue
		o.aggro_target_id = saldirgan.id
		o.aggro_ticks = AGGRO_TICKS
		katilan += 1
		events.append({"type": "pack_alerted", "entity": o.id, "tick": tick})


## Şu an kaç canavar bu hedefe saldırıyor?
func _engaged_count(hedef: SimEntity) -> int:
	var n := 0
	for o in entities:
		if o.alive and o.kind == SimEntity.Kind.MONSTER and o.aggro_target_id == hedef.id:
			n += 1
	return n


## Hasar, ustalık rütbelerini besler. Rütbe atlandıysa olay üretilir.
func _train(e: SimEntity, amount: int, is_weapon: bool) -> void:
	if e.mastery == null or amount <= 0:
		return
	var kazanilan := e.mastery.add_weapon_damage(amount) if is_weapon else e.mastery.add_armor_damage(amount)
	if kazanilan <= 0:
		return
	_refresh_entity_stats(e)
	var rutbe := e.mastery.weapon_rank if is_weapon else e.mastery.armor_rank
	var bonus := Mastery.weapon_bonus(rutbe) if is_weapon else Mastery.armor_bonus(rutbe)
	events.append({
		"type": "mastery_up",
		"entity": e.id,
		"track": "weapon" if is_weapon else "armor",
		"rank": rutbe,
		"reward": Mastery.bonus_text(bonus),
		"tick": tick,
	})


## Dalga eşiği: can oranı bu değerin altına düşünce sıradaki dalga çıkar.
static func wave_threshold(wave_index: int, total: int) -> float:
	# İlk dalga %85'te, son dalga %10'da.
	return 0.85 - float(wave_index) * (0.75 / float(maxi(1, total - 1)))


## Metin taşı yeterince hasar aldıysa yeni bir bekçi dalgası çıkarır.
func _check_stone_guards(tas: SimEntity, saldirgan: SimEntity) -> void:
	var toplam := ALTAR_WAVES if tas.kind == SimEntity.Kind.ALTAR else STONE_GUARD_WAVES
	var oran := tas.hp_ratio()
	while tas.guard_waves < toplam and oran <= wave_threshold(tas.guard_waves, toplam):
		tas.guard_waves += 1
		if tas.kind == SimEntity.Kind.ALTAR:
			# Her dalgada bölgeyi yeniden ayağa kaldır: arada ölüp
			# yeniden doğanlar da kavgaya katılsın.
			_alert_map(saldirgan)
			_spawn_bosses(tas, saldirgan)
		else:
			_spawn_guards(tas, saldirgan)


func _spawn_guards(tas: SimEntity, hedef: SimEntity) -> void:
	var dalga := tas.guard_waves  # 1..STONE_GUARD_WAVES
	# Son dalgalara doğru bekçiler belirgin biçimde güçlenir.
	var saglamlik := 0.95 + float(dalga) * 0.22
	var seviye := tas.stats.level + dalga
	var son_dalga := dalga >= STONE_GUARD_WAVES
	var isim := "Metin Muhafızı" if son_dalga else "Metin Bekçisi"

	for i in STONE_GUARDS_PER_WAVE:
		var aci := rng.float_range(0.0, TAU)
		var nokta := _clamp_to_bounds(tas.pos + Vector2.from_angle(aci) * 2.6)
		var g := _make(isim, nokta, SimEntity.Kind.MONSTER, tas.team,
				Stats.for_monster(seviye, saglamlik))
		g.temporary = true
		g.move_speed = 3.6 + float(dalga) * 0.06
		g.attack_windup_ticks = 6
		g.attack_recover_ticks = maxi(8, 14 - dalga)
		g.exp_value = seviye
		g.exp_multiplier = 1.0 + float(dalga) * 0.15
		g.gold_value = maxi(3, seviye * 3 + dalga * 2)
		g.leash_range = 24.0
		g.aggro_target_id = hedef.id
		g.aggro_ticks = AGGRO_TICKS
		_spawn_queue.append(g)

	events.append({
		"type": "guards_summoned",
		"stone": tas.id,
		"wave": dalga,
		"total": STONE_GUARD_WAVES,
		"count": STONE_GUARDS_PER_WAVE,
		"final": son_dalga,
		"tick": tick,
	})


## Sunağın boss dalgası. Her dalga ciddi biçimde güçlenir.
func _spawn_bosses(sunak: SimEntity, hedef: SimEntity) -> void:
	var dalga := sunak.guard_waves
	var son := dalga >= ALTAR_WAVES
	var saglamlik := 1.5 + float(dalga) * 0.30
	var seviye := sunak.stats.level + dalga
	var isim := "Sunak Efendisi" if son else "Sunak Muhafızı"

	for i in ALTAR_BOSSES_PER_WAVE:
		var aci := rng.float_range(0.0, TAU)
		var nokta := _clamp_to_bounds(sunak.pos + Vector2.from_angle(aci) * 3.2)
		var b := _make(isim, nokta, SimEntity.Kind.MONSTER, sunak.team,
				Stats.for_monster(seviye, saglamlik))
		b.temporary = true
		b.stats.hp_scale = 1.6 + float(dalga) * 0.20
		b.hp = b.stats.max_hp()
		b.move_speed = 3.4 + float(dalga) * 0.12
		b.attack_windup_ticks = 6
		b.attack_recover_ticks = maxi(7, 13 - dalga)
		b.attack_range = 2.0
		b.exp_value = seviye
		b.exp_multiplier = 2.0 + float(dalga) * 0.5
		b.gold_value = seviye * 12 + dalga * 40
		b.leash_range = 40.0
		b.aggro_target_id = hedef.id
		b.aggro_ticks = AGGRO_TICKS * 3
		_spawn_queue.append(b)

	events.append({
		"type": "altar_wave",
		"altar": sunak.id,
		"wave": dalga,
		"total": ALTAR_WAVES,
		"count": ALTAR_BOSSES_PER_WAVE,
		"final": son,
		"tick": tick,
	})


## Sunağa ilk dokunuş: bölgedeki BÜTÜN canavarlar saldırgana yönelir.
func _alert_map(saldirgan: SimEntity) -> void:
	var uyanan := 0
	for o in entities:
		if not o.alive or o.kind != SimEntity.Kind.MONSTER:
			continue
		if o.aggro_target_id == saldirgan.id:
			continue
		o.aggro_target_id = saldirgan.id
		o.aggro_ticks = AGGRO_TICKS * 4
		o.leash_range = 200.0  # sunak kavgasında kimse yuvasına dönmez
		uyanan += 1
	if uyanan > 0:
		events.append({"type": "map_alerted", "count": uyanan, "tick": tick})


func _kill(kurban: SimEntity, katil: SimEntity) -> void:
	kurban.hp = 0
	kurban.alive = false
	kurban.state = SimEntity.State.DEAD
	kurban.attack_target_id = 0
	kurban.aggro_target_id = 0
	kurban.aggro_ticks = 0
	kurban.has_move_target = false
	kurban.attack_timer = -1
	kurban.move_dir = Vector2.ZERO
	if kurban.temporary:
		kurban.respawn_ticks = CORPSE_TICKS
	elif kurban.kind == SimEntity.Kind.PLAYER:
		kurban.respawn_ticks = PLAYER_RESPAWN_TICKS
	else:
		kurban.respawn_ticks = RESPAWN_TICKS

	events.append({
		"type": "died",
		"entity": kurban.id,
		"killer": katil.id if katil != null else 0,
		"tick": tick,
	})

	if kurban.progress != null:
		kurban.progress.deaths += 1
	if katil != null and katil.progress != null and kurban.kind != SimEntity.Kind.NPC:
		katil.progress.kills += 1
		if kurban.kind == SimEntity.Kind.STONE:
			katil.progress.stones_broken += 1
		elif kurban.temporary:
			katil.progress.guards_killed += 1

	# Öldüreni takip eden herkes hedefini bıraksın.
	for e in entities:
		if e.attack_target_id == kurban.id:
			e.attack_target_id = 0
		if e.aggro_target_id == kurban.id:
			e.aggro_target_id = 0
			e.aggro_ticks = 0

	if katil == null or katil.kind != SimEntity.Kind.PLAYER:
		return

	_grant_experience(katil, kurban)
	_roll_loot(katil, kurban)

	if kurban.gold_value > 0:
		var altin := int(round(float(kurban.gold_value) * (1.0 + katil.stats.bonus_gold)))
		katil.gold += altin
		if katil.progress != null:
			katil.progress.gold_earned += altin
		events.append({
			"type": "gold_gained",
			"entity": katil.id,
			"amount": altin,
			"tick": tick,
		})

	if quest_log != null:
		for baslik in quest_log.on_kill(kurban.display_name):
			events.append({"type": "quest_ready", "title": baslik, "tick": tick})


func _grant_experience(oyuncu: SimEntity, kurban: SimEntity) -> void:
	var kazanc := float(ExpTable.reward_for(kurban.stats.level, oyuncu.stats.level)) * kurban.exp_multiplier
	kazanc *= 1.0 + oyuncu.stats.bonus_exp
	award_experience(oyuncu.id, int(round(kazanc)))


## Dışarıdan deneyim ver (görev ödülü gibi). Seviye atlatabilir.
func award_experience(id: int, amount: int) -> void:
	var oyuncu := get_entity(id)
	if oyuncu == null or amount <= 0:
		return
	oyuncu.experience += amount
	if oyuncu.progress != null:
		oyuncu.progress.exp_earned += amount
	events.append({
		"type": "exp_gained",
		"entity": oyuncu.id,
		"amount": amount,
		"tick": tick,
	})

	while oyuncu.stats.level < ExpTable.MAX_LEVEL:
		var gerekli := ExpTable.required_for(oyuncu.stats.level)
		if gerekli <= 0 or oyuncu.experience < gerekli:
			break
		oyuncu.experience -= gerekli
		oyuncu.stats.level_up()
		if oyuncu.abilities != null:
			oyuncu.abilities.points += 1
		if oyuncu.progress != null:
			oyuncu.progress.levels_gained += 1
		oyuncu.hp = oyuncu.stats.max_hp()
		oyuncu.mp = oyuncu.stats.max_mp()
		events.append({
			"type": "level_up",
			"entity": oyuncu.id,
			"level": oyuncu.stats.level,
			"tick": tick,
		})


## Ölen canavardan eşya düşer mi?
func _roll_loot(oyuncu: SimEntity, kurban: SimEntity) -> void:
	if item_db == null or oyuncu.inventory == null:
		return
	if kurban.kind == SimEntity.Kind.NPC:
		return
	var dusen: Item = null
	if kurban.kind == SimEntity.Kind.ALTAR:
		dusen = item_db.roll_special(item_db.altar_drops, rng)
		# Sunak ayrıca Poly kademesini açan taşı bırakır.
		_give_material(oyuncu, item_db.stone_item, rng.int_range(2, 4))
	elif kurban.is_boss:
		# Bölge bossu: kendi seviyesinin üstünde garanti bir parça.
		dusen = item_db.roll_drop(kurban.stats.level + 6, rng, 1.0)
		_give_material(oyuncu, item_db.book_item, rng.int_range(1, 2))
	elif kurban.kind == SimEntity.Kind.STONE:
		dusen = item_db.roll_special(item_db.stone_drops, rng)
		# Metin taşından yetenek kitabı çıkar.
		if rng.chance(0.55):
			_give_material(oyuncu, item_db.book_item, 1)
	if dusen == null:
		var sans := drop_chance + oyuncu.stats.bonus_drop
		dusen = item_db.roll_drop(kurban.stats.level, rng, sans)
	if dusen == null:
		return
	if oyuncu.inventory.add(dusen):
		if oyuncu.progress != null:
			oyuncu.progress.items_looted += 1
		events.append({
			"type": "item_looted",
			"entity": oyuncu.id,
			"item": dusen.label(),
			"tick": tick,
		})
	else:
		events.append({"type": "inventory_full", "entity": oyuncu.id, "tick": tick})


## Kitap ve sunak taşı gibi yetenek malzemeleri doğrudan çantaya girer.
func _give_material(oyuncu: SimEntity, item_id: String, adet: int) -> void:
	if item_db == null or oyuncu.inventory == null or item_id.is_empty() or adet <= 0:
		return
	for i in adet:
		var m := item_db.make(item_id)
		if m != null:
			oyuncu.inventory.add(m)
	events.append({"type": "material_gained", "entity": oyuncu.id,
			"item": item_id, "count": adet, "tick": tick})


func _step_dead(e: SimEntity) -> void:
	e.dead_ticks += 1

	if e.temporary:
		if e.respawn_ticks > 0:
			e.respawn_ticks -= 1
		return  # geri gelmez; cesedi _cleanup_temporary kaldırır

	if e.respawn_ticks > 0:
		e.respawn_ticks -= 1

	# Grup kuralı: bir küme tamamen temizlenmeden tek tek doğmaz.
	# Ama grup bir türlü bitmezse de sonsuza kadar ölü kalmaz.
	if e.kind == SimEntity.Kind.MONSTER or e.kind == SimEntity.Kind.STONE:
		var hazir := e.respawn_ticks <= 0
		if e.spawn_group > 0:
			var temiz := _group_cleared(e.spawn_group)
			hazir = (temiz and e.dead_ticks >= GROUP_RESPAWN_TICKS) or e.dead_ticks >= SOLO_RESPAWN_TIMEOUT
		if not hazir:
			return
	elif e.respawn_ticks > 0:
		return

	e.alive = true
	e.hp = e.stats.max_hp()
	e.mp = e.stats.max_mp()
	# Öldüğü noktada değil, grubunun bölgesinde rastgele bir yerde belirir.
	var nokta := e.spawn_pos
	if e.group_spread > 0.0:
		var aci := rng.float_range(0.0, TAU)
		var yaricap := rng.float_range(e.group_spread * 0.25, e.group_spread)
		nokta = _clamp_to_bounds(e.group_center + Vector2.from_angle(aci) * yaricap)
	e.pos = nokta
	e.prev_pos = nokta
	e.spawn_pos = nokta
	e.wander_origin = nokta
	e.move_target = nokta
	e.has_move_target = false
	e.state = SimEntity.State.IDLE
	e.guard_waves = 0  # taş yeniden dikildiğinde bekçileri de tazelenir
	e.dead_ticks = 0
	events.append({"type": "respawned", "entity": e.id, "tick": tick})


func _count_play_time() -> void:
	for e in entities:
		if e.progress != null:
			e.progress.play_ticks += 1
			return


## Bir grubun bütün üyeleri ölmüş mü? (tick başına tek hesap)
func _group_cleared(group_id: int) -> bool:
	if _cleared_groups.has(group_id):
		return bool(_cleared_groups[group_id])
	var temiz := true
	for o in entities:
		if o.spawn_group == group_id and o.alive:
			temiz = false
			break
	_cleared_groups[group_id] = temiz
	return temiz


## Geçici güçlenmelerin süresi ve yetenek soğumaları.
func _step_buffs() -> void:
	for e in entities:
		if e.abilities != null:
			e.abilities.tick_cooldowns()
		if e.buff_ticks <= 0:
			continue
		e.buff_ticks -= 1
		if e.buff_ticks == 0:
			e.buff_bonus = {}
			_refresh_entity_stats(e)
			events.append({"type": "buff_ended", "entity": e.id, "tick": tick})


## Üst üste binen varlıkları nazikçe ayırır.
## RNG kullanmaz — tamamen konuma bağlı, dolayısıyla deterministik.
func _step_separation() -> void:
	for i in entities.size():
		var a := entities[i]
		if not a.alive:
			continue
		for j in range(i + 1, entities.size()):
			var b := entities[j]
			if not b.alive:
				continue
			var fark := b.pos - a.pos
			var d := fark.length()
			if d >= SEPARATION_RADIUS:
				continue
			if d < 0.0001:
				# Tam üst üsteler: kilitlenmesinler diye kimliklerinden
				# türeyen sabit bir yön seç.
				fark = Vector2.from_angle(float((a.id * 31 + b.id * 17) % 628) * 0.01)
				d = 0.0001
			var itme := (fark / d) * (SEPARATION_RADIUS - d) * SEPARATION_PUSH
			var a_oynar := a.can_move()
			var b_oynar := b.can_move()
			if a_oynar and b_oynar:
				a.pos -= itme * 0.5
				b.pos += itme * 0.5
			elif a_oynar:
				a.pos -= itme
			elif b_oynar:
				b.pos += itme


## Savaş dışındayken yavaş can yenilenmesi.
func _step_regen() -> void:
	_regen_timer += 1
	if _regen_timer < REGEN_INTERVAL:
		return
	_regen_timer = 0

	# Mana savaşta da yenilenir — yetenekler kullanılabilir kalsın.
	for e in entities:
		if not e.alive or e.stats == null or e.abilities == null:
			continue
		var mp_tavan := e.stats.max_mp()
		if e.mp < mp_tavan:
			e.mp = mini(mp_tavan, e.mp + maxi(1, int(round(e.stats.mp_regen()))))
	for e in entities:
		if not e.alive or e.kind == SimEntity.Kind.STONE:
			continue
		if e.aggro_ticks > 0 or e.attack_target_id != 0 or e.attack_timer >= 0:
			continue
		var tavan := e.stats.max_hp()
		if e.hp >= tavan:
			continue
		var oran := REGEN_RATIO + e.stats.bonus_regen
		e.hp = mini(tavan, e.hp + maxi(1, int(round(float(tavan) * oran))))


## Dolaşma. RNG çağrıları entities listesinin sabit sırasında yapıldığı
## için bu davranış da tamamen deterministiktir: aynı seed, aynı gezinti.
func _step_wander(e: SimEntity) -> void:
	if e.wander_cooldown > 0:
		e.wander_cooldown -= 1
		return
	e.wander_cooldown = rng.int_range(SimClock.TICK_RATE * 2, SimClock.TICK_RATE * 5)
	var angle := rng.float_range(0.0, TAU)
	var radius := rng.float_range(0.0, e.wander_radius)
	e.move_target = e.wander_origin + Vector2.from_angle(angle) * radius
	e.has_move_target = true


func _step_move(e: SimEntity) -> void:
	if not e.can_move():
		# Metin taşı, satıcı NPC: komut gelse de yerinden kıpırdamaz.
		e.has_move_target = false
		e.state = SimEntity.State.IDLE
		return

	var to_target := e.move_target - e.pos
	var distance := to_target.length()
	var step_length := e.current_speed() * SimClock.TICK_DELTA

	if distance < 0.0001:
		e.has_move_target = false
		e.state = SimEntity.State.IDLE
		return

	e.facing = to_target / distance

	if distance <= step_length:
		# Hedefi aşıp titremesin diye tam üstüne oturt.
		e.pos = e.move_target
		e.has_move_target = false
		e.state = SimEntity.State.IDLE
		return

	e.pos = _clamp_to_bounds(e.pos + e.facing * step_length)
	e.state = SimEntity.State.MOVING
	_count_steps(e, step_length)
