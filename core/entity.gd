class_name SimEntity
extends RefCounted

## Simülasyondaki bir varlık: oyuncu, NPC, canavar, metin taşı — hepsi budur.
##
## Burada sprite, node, animasyon, renk YOKTUR. Görsel katman bu veriyi
## OKUR ve ekrana çizer; asla tersi olmaz.
##
## NOT (Faz 6): pos bir Vector2. 3D'ye geçişte Vector3 olacak tek yer
## burası ve core/world.gd'deki hareket fonksiyonudur.

enum State {
	IDLE,
	MOVING,
	ATTACKING,
	DEAD,
}

## Varlığın ne olduğu. Görsel katman buna bakarak farklı çizer;
## hasar, EXP ve ganimet kuralları da buna bakar.
enum Kind {
	PLAYER,   ## oyuncu karakteri
	NPC,      ## satıcı, görev veren — saldırılamaz
	MONSTER,  ## kurt, yabani köpek, orman canavarı
	STONE,    ## metin taşı: yerinden kıpırdamaz, kırılınca ganimet verir
	ALTAR,    ## haritanın sunağı: dokunursan bütün bölge üstüne gelir
}

var id: int = 0
var display_name: String = ""
var kind: Kind = Kind.MONSTER

## Kim kimin düşmanı. 0 = oyuncu tarafı, 1 = canavarlar.
## kind'dan ayrıdır: bir satıcı NPC oyuncu tarafındadır ama oyuncu değildir.
var team: int = 1

var stats: Stats = null
var hp: int = 1
var mp: int = 0

## Kuşanılan eşyalar ve çanta. Yalnızca oyuncuda dolu olur.
var inventory: Inventory = null

## Kalıcı pasif yetenekler, beceriler ve sayaçlar (oyuncu).
var mastery: Mastery = null
var skills: SkillTree = null
var progress: Progress = null
var abilities: AbilityBook = null

## Geçici güçlenme (Savaş Narası gibi): kaç tick kaldı ve ne veriyor.
var buff_ticks: int = 0
var buff_bonus: Dictionary = {}

## Kesesindeki para; öldürülünce bırakacağı para.
var gold: int = 0
var gold_value: int = 0

## Biriken deneyim (yalnızca oyuncu) ve öldürülünce verdiği deneyim.
var experience: int = 0
var exp_value: int = 0

## Öldürüldüğünde verdiği deneyimin çarpanı. Metin taşları için yüksek.
var exp_multiplier: float = 1.0

## NPC'nin işi: "quest", "shop" ya da "both".
var npc_role: String = "quest"

# --- Konum: DÜNYA BİRİMİ (piksel değil) ---
var pos: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.RIGHT

## Bir önceki tick'teki konum. Sadece çizim katmanı ara değer hesabında
## kullanır; simülasyon mantığı buna bakmaz.
var prev_pos: Vector2 = Vector2.ZERO

var move_speed: float = 4.0  # birim / saniye. 0 = yerinden kıpırdamaz.
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false

## Klavyeyle sürekli yürüme yönü (WASD / yön tuşları).
## Sıfır değilse tıkla-yürü hedefinin ve saldırının önüne geçer.
var move_dir: Vector2 = Vector2.ZERO

var state: State = State.IDLE

# --- Savaş ---

## Kime saldırıyor (0 = kimseye). Hedef menzil dışındaysa peşinden gider.
var attack_target_id: int = 0

## Saldırı menzili — birim. Eşya ve yeteneklerden gelen menzil bunun
## üstüne biner (effective_range).
var attack_range: float = 2.4

## Tek vuruşta kaç düşmana birden değebileceği. Oyuncu için 3:
## sürü saldırdığında hepsine birden karşılık verebilsin.
var attack_max_targets: int = 1

## Çoklu vuruşun kapsadığı yarım açı (radyan). Arkandakine vuramazsın.
var attack_arc: float = 1.22

## Vuruşun isabet ettiği ana kadar geçen hazırlık süresi.
var attack_windup_ticks: int = 4

## Vuruştan sonra yeni vuruş yapılamayan toparlanma süresi.
## Metin2'deki "saldırı hızı" ileride bu iki sayıyı ölçekleyecek.
var attack_recover_ticks: int = 6

## -1 = saldırmıyor. 0'dan başlayıp her tick artar.
var attack_timer: int = -1

## Ölüm ve yeniden doğuş
var alive: bool = true
var respawn_ticks: int = 0
var spawn_pos: Vector2 = Vector2.ZERO

## Geçici varlık (metin taşının çağırdığı bekçi gibi): ölünce geri
## gelmez, cesedi kısa süre sonra sahneden kalkar.
var temporary: bool = false

## Metin taşının kaç bekçi dalgası çıkardığı.
var guard_waves: int = 0

## Bölge bossu mu? Ödülü ve çizimi farklıdır.
var is_boss: bool = false

## Aynı anda doğup aynı anda geri gelen canavar kümesi. Bir grubun
## tamamı temizlenmeden tek tek yeniden doğmazlar.
var spawn_group: int = 0

## Grubun merkezi ve yayılma yarıçapı. Yeniden doğarken tam öldüğü
## noktada değil, bu dairenin içinde rastgele bir yerde belirir.
var group_center: Vector2 = Vector2.ZERO
var group_spread: float = 0.0

## Kaç tick'tir ölü.
var dead_ticks: int = 0

# --- Yapay zekâ ---
# KURAL: canavarlar kendiliğinden saldırmaz. Yalnızca VURULDUKLARINDA
# karşılık verir. Oyuncu saldırmadıkça harita huzurludur.

var hostile_on_sight: bool = false  ## ileride bazı canavarlar için açılacak

## Kime karşılık veriyor (0 = kimseye).
var aggro_target_id: int = 0

## Karşılık verme süresi. Bitince canavar sakinleşip bölgesine döner.
var aggro_ticks: int = 0

## Doğduğu noktadan bu kadar uzaklaşınca kovalamayı bırakır.
var leash_range: float = 12.0

# --- Dolaşma davranışı ---

var wander_enabled: bool = false
var wander_origin: Vector2 = Vector2.ZERO
var wander_radius: float = 2.5  # birim
var wander_cooldown: int = 0  # tick


func is_busy() -> bool:
	return attack_timer >= 0


func can_move() -> bool:
	return move_speed > 0.0


## Bonuslar dahil gerçek saldırı menzili.
func effective_range() -> float:
	return attack_range + (stats.bonus_range if stats != null else 0.0)


## Bonuslar dahil gerçek yürüme hızı.
func current_speed() -> float:
	if move_speed <= 0.0:
		return 0.0
	return move_speed + (stats.bonus_move_speed if stats != null else 0.0)


## Saldırılabilir mi: NPC'lere ve ölülere vurulamaz.
func is_attackable() -> bool:
	return alive and kind != Kind.NPC


## Metin taşı ve sunak: yerinden kıpırdamayan, dalga dalga koruyucu
## çağıran hedefler.
func is_objective() -> bool:
	return kind == Kind.STONE or kind == Kind.ALTAR


func hp_ratio() -> float:
	if stats == null or stats.max_hp() <= 0:
		return 0.0
	return clampf(float(hp) / float(stats.max_hp()), 0.0, 1.0)


## Oyuncunun bir üst seviyeye ne kadar yaklaştığı (0..1).
func exp_ratio() -> float:
	if stats == null:
		return 0.0
	var gerekli := ExpTable.required_for(stats.level)
	if gerekli <= 0:
		return 1.0
	return clampf(float(experience) / float(gerekli), 0.0, 1.0)
