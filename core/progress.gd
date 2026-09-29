class_name Progress
extends RefCounted

## Oyun boyunca biriken sayaçlar ve bunlara bağlı KALICI dönüm noktaları.
##
## Ustalıktan ve becerilerden ayrı bir üçüncü gelişme hattı: sadece
## oynayarak gelen ödüller. Yeterince canavar kesersen gücün, yeterince
## yürürsen hızın, yeterince vurursan saldırı hızın kalıcı olarak artar.
##
## Aynı sayaçlar istatistik ekranını da besler.

# --- Sayaçlar ---
var kills: int = 0
var attacks: int = 0
var crits: int = 0
var steps: int = 0            ## yürünen dünya birimi
var damage_dealt: int = 0
var damage_taken: int = 0
var deaths: int = 0
var stones_broken: int = 0
var guards_killed: int = 0
var gold_earned: int = 0
var exp_earned: int = 0
var items_looted: int = 0
var items_sold: int = 0
var quests_done: int = 0
var levels_gained: int = 0
var play_ticks: int = 0
var maps_visited: int = 0

# --- Dönüm noktası eşikleri ---
# Her eşik geçildiğinde kalıcı bir bonus açılır.

const KILL_STEPS: Array[int] = [60, 180, 420, 850, 1600, 2800, 4800, 8000, 13000, 21000, 34000, 55000]
const ATTACK_STEPS: Array[int] = [500, 1500, 3500, 7000, 13000, 22000, 36000, 58000, 90000, 140000]
const STEP_STEPS: Array[int] = [900, 2600, 6000, 12000, 22000, 38000, 62000, 100000, 155000, 240000]
const TAKEN_STEPS: Array[int] = [4000, 13000, 34000, 75000, 150000, 280000, 480000, 800000, 1300000, 2100000]
const CRIT_STEPS: Array[int] = [90, 320, 800, 1700, 3300, 6000, 10500, 17500, 28000, 45000]

const KILL_ATTACK := 6          ## eşik başına saldırı gücü
const ATTACK_SPEED_STEP := 0.02 ## eşik başına saldırı hızı
const MOVE_SPEED_STEP := 0.07   ## eşik başına hareket hızı
const TAKEN_DEFENSE := 5        ## eşik başına zırh
const CRIT_DAMAGE_STEP := 0.04  ## eşik başına kritik hasarı


static func rank_of(value: int, table: Array[int]) -> int:
	var r := 0
	for esik in table:
		if value >= esik:
			r += 1
		else:
			break
	return r


static func next_threshold(value: int, table: Array[int]) -> int:
	for esik in table:
		if value < esik:
			return esik
	return 0


func kill_rank() -> int:
	return rank_of(kills, KILL_STEPS)


func attack_rank() -> int:
	return rank_of(attacks, ATTACK_STEPS)


func step_rank() -> int:
	return rank_of(steps, STEP_STEPS)


func taken_rank() -> int:
	return rank_of(damage_taken, TAKEN_STEPS)


func crit_rank() -> int:
	return rank_of(crits, CRIT_STEPS)


func total_ranks() -> int:
	return kill_rank() + attack_rank() + step_rank() + taken_rank() + crit_rank()


## Kazanılmış dönüm noktalarının kalıcı bonuslarını stat bloğuna ekler.
func apply_to(stats: Stats) -> void:
	stats.bonus_attack += kill_rank() * KILL_ATTACK
	stats.bonus_attack_speed += float(attack_rank()) * ATTACK_SPEED_STEP
	stats.bonus_move_speed += float(step_rank()) * MOVE_SPEED_STEP
	stats.bonus_defense += taken_rank() * TAKEN_DEFENSE
	stats.bonus_crit_damage += float(crit_rank()) * CRIT_DAMAGE_STEP


## Arayüz için: dönüm noktalarının adı, ilerlemesi ve ödülü.
func milestones() -> Array[Dictionary]:
	return [
		{
			"name": "Avcı", "detail": "kesilen canavar",
			"value": kills, "rank": kill_rank(),
			"next": next_threshold(kills, KILL_STEPS),
			"reward": "Saldırı gücü +%d" % KILL_ATTACK,
		},
		{
			"name": "Savaşçı", "detail": "yapılan vuruş",
			"value": attacks, "rank": attack_rank(),
			"next": next_threshold(attacks, ATTACK_STEPS),
			"reward": "Saldırı hızı +%%%d" % int(ATTACK_SPEED_STEP * 100.0),
		},
		{
			"name": "Yolcu", "detail": "yürünen birim",
			"value": steps, "rank": step_rank(),
			"next": next_threshold(steps, STEP_STEPS),
			"reward": "Hareket hızı +%.2f" % MOVE_SPEED_STEP,
		},
		{
			"name": "Dayanıklı", "detail": "yenilen hasar",
			"value": damage_taken, "rank": taken_rank(),
			"next": next_threshold(damage_taken, TAKEN_STEPS),
			"reward": "Zırh +%d" % TAKEN_DEFENSE,
		},
		{
			"name": "Nişancı", "detail": "kritik vuruş",
			"value": crits, "rank": crit_rank(),
			"next": next_threshold(crits, CRIT_STEPS),
			"reward": "Kritik hasarı +%%%d" % int(CRIT_DAMAGE_STEP * 100.0),
		},
	]


func play_seconds() -> int:
	return int(float(play_ticks) * SimClock.TICK_DELTA)


func to_dict() -> Dictionary:
	return {
		"kills": kills, "attacks": attacks, "crits": crits, "steps": steps,
		"dealt": damage_dealt, "taken": damage_taken, "deaths": deaths,
		"stones": stones_broken, "guards": guards_killed,
		"gold": gold_earned, "exp": exp_earned,
		"looted": items_looted, "sold": items_sold, "quests": quests_done,
		"levels": levels_gained, "ticks": play_ticks, "maps": maps_visited,
	}


func load_dict(d: Dictionary) -> void:
	kills = maxi(0, int(d.get("kills", 0)))
	attacks = maxi(0, int(d.get("attacks", 0)))
	crits = maxi(0, int(d.get("crits", 0)))
	steps = maxi(0, int(d.get("steps", 0)))
	damage_dealt = maxi(0, int(d.get("dealt", 0)))
	damage_taken = maxi(0, int(d.get("taken", 0)))
	deaths = maxi(0, int(d.get("deaths", 0)))
	stones_broken = maxi(0, int(d.get("stones", 0)))
	guards_killed = maxi(0, int(d.get("guards", 0)))
	gold_earned = maxi(0, int(d.get("gold", 0)))
	exp_earned = maxi(0, int(d.get("exp", 0)))
	items_looted = maxi(0, int(d.get("looted", 0)))
	items_sold = maxi(0, int(d.get("sold", 0)))
	quests_done = maxi(0, int(d.get("quests", 0)))
	levels_gained = maxi(0, int(d.get("levels", 0)))
	play_ticks = maxi(0, int(d.get("ticks", 0)))
	maps_visited = maxi(0, int(d.get("maps", 0)))
