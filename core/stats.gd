class_name Stats
extends RefCounted

## Bir karakterin ham statları ve bunlardan TÜRETİLEN değerler.
##
## Metin2 mantığı: oyuncu sadece 4 ham stata puan dağıtır, geri kalan
## her şey (can, zırh, isabet, kritik) bu dörtlüden hesaplanır.
##
## Not: "str" ve "int" GDScript'in yerleşik adları olduğu için alanlar
## açık adlarıyla yazıldı. Arayüzde yine STR / DEX / INT / VIT görünür.

var level: int = 1

var strength: int = 4      # STR — vurulan hasar
var dexterity: int = 4     # DEX — isabet, kaçınma, kritik
var intelligence: int = 4  # INT — mana
var vitality: int = 4      # VIT — can ve zırh

## Dağıtılmayı bekleyen stat puanı (seviye başına 1).
var stat_points: int = 0

## Can çarpanı. Oyuncu için 1.0; canavarlar için daha düşük, çünkü
## aynı formülle hesaplanan canları savaşı gereksiz uzatıyordu.
var hp_scale: float = 1.0

# --- Pasif bonuslar ---
# Ustalık rütbeleri ve öğrenilen beceriler buraya yazar. Her yeniden
# hesaplamada sıfırlanıp baştan toplanırlar; böylece bir beceri
# unutulduğunda ya da eşya çıkarıldığında artık iz kalmaz.

var bonus_attack: int = 0
var bonus_defense: int = 0
var bonus_hp: int = 0
var bonus_crit: float = 0.0
var bonus_crit_damage: float = 0.0
var bonus_pierce: float = 0.0
var bonus_regen: float = 0.0

## Hareket ve saldırı hızı, kazanç çarpanları.
var bonus_move_speed: float = 0.0   ## birim/saniye
var bonus_attack_speed: float = 0.0 ## 0.25 = %25 daha hızlı vuruş
var bonus_exp: float = 0.0
var bonus_gold: float = 0.0
var bonus_drop: float = 0.0

## Verdiğin hasarın yüzde kaçı cana döner.
var bonus_lifesteal: float = 0.0

## Saldırı menziline eklenen birim.
var bonus_range: float = 0.0

## Mana havuzuna ve yenilenmesine eklenenler.
var bonus_mp: float = 0.0
var bonus_mp_regen: float = 0.0


func reset_bonuses() -> void:
	bonus_attack = 0
	bonus_defense = 0
	bonus_hp = 0
	bonus_crit = 0.0
	bonus_crit_damage = 0.0
	bonus_pierce = 0.0
	bonus_regen = 0.0
	bonus_move_speed = 0.0
	bonus_attack_speed = 0.0
	bonus_exp = 0.0
	bonus_gold = 0.0
	bonus_drop = 0.0
	bonus_lifesteal = 0.0
	bonus_range = 0.0
	bonus_mp = 0.0
	bonus_mp_regen = 0.0


func clone() -> Stats:
	var s := Stats.new()
	s.level = level
	s.strength = strength
	s.dexterity = dexterity
	s.intelligence = intelligence
	s.vitality = vitality
	s.stat_points = stat_points
	s.hp_scale = hp_scale
	return s


# --- Türetilmiş değerler ---
# Hepsi fonksiyon, çünkü ham stat veya eşya değişince anında güncellenmeli.

## Ham statların getirisi ARTANDIR: VIT 10'ken bir puan 25 can verir,
## VIT 60'ken çok daha fazlasını. Böylece puan yatırmak geç seviyede de
## anlamlı kalır.
func max_hp() -> int:
	var vit := float(vitality)
	var taban := 200.0 + float(level) * 55.0 + vit * 25.0 + vit * vit * 0.25
	return int(round(taban * hp_scale)) + bonus_hp


func max_mp() -> int:
	var i := float(intelligence)
	return int(round(120.0 + float(level) * 22.0 + i * 18.0 + i * i * 0.2)) + int(bonus_mp)


## Saniyede yenilenen mana.
func mp_regen() -> float:
	return (2.0 + float(intelligence) * 0.35) * (1.0 + bonus_mp_regen)


## Can çalma oranı — verdiğin hasarın bu kadarı cana döner.
func lifesteal() -> float:
	return clampf(bonus_lifesteal, 0.0, 0.60)


## Saldırı gücü.
func attack_power() -> int:
	var st := float(strength)
	return int(round(float(level) * 2.0 + st * 4.0 + st * st * 0.02)) + bonus_attack


## Zırh (savunma). Arayüzde "Zırh" olarak gösterilir.
## VIT katkısı bilerek düşük tutuldu: hasar formülü çıkarma olduğu için
## yüksek zırh, canavar vuruşlarını tamamen 1'e indirip savaşı anlamsız
## kılıyordu. Dayanıklılık büyük ölçüde candan gelsin.
func defense_value() -> int:
	var vit := float(vitality)
	return int(round(float(level) + vit + vit * vit * 0.008)) + bonus_defense


## Zırhın hasarı yüzde kaç emdiği.
##
## Hasar eskiden "saldırı - zırh" idi; doğrusal olduğu için geç
## seviyede zırh bütün vuruşları 1'e indiriyor, savaş anlamsızlaşıyordu.
## Artık zırh YÜZDESEL azaltma yapar ve seviyeyle birlikte ölçeklenir:
## aynı zırh değeri üst seviyelerde daha az işe yarar, yani gelişmek
## zorunludur. Tavan %80 — hiçbir hedef dokunulmaz olamaz.
func damage_reduction() -> float:
	var d := float(maxi(0, defense_value()))
	if d <= 0.0:
		return 0.0
	return clampf(d / (d + 100.0 + float(level) * 12.0), 0.0, 0.80)


## İsabet — savunanın kaçınmasına karşı yarışır.
func accuracy() -> int:
	return 60 + level * 2 + dexterity * 3


func evasion() -> int:
	return 20 + level * 2 + dexterity * 2


## Kritik vuruş şansı: hasarı ikiye katlar.
func crit_chance() -> float:
	var dx := float(dexterity)
	return minf(0.02 + dx * 0.002 + dx * dx * 0.00002 + bonus_crit, 0.60)


## Kritik vuruşun hasar çarpanı. Taban iki kat; ustalık ve beceriler
## bunun üstüne ekler.
func crit_multiplier() -> float:
	return 2.0 + bonus_crit_damage


## Delici vuruş şansı: Metin2'nin imzası — hedefin zırhını YOK SAYAR.
func pierce_chance() -> float:
	return minf(0.01 + float(dexterity) * 0.0015 + bonus_pierce, 0.50)


## Seviye atlarken çağrılır.
func level_up() -> void:
	level += 1
	stat_points += 1


## Oyuncu karakteri kurulumu. Canavarlardan belirgin güçlü başlar:
## kahraman, sürüyle dövüşebilmeli.
static func for_player() -> Stats:
	var s := Stats.new()
	s.level = 1
	s.strength = 6
	s.dexterity = 6
	s.intelligence = 4
	s.vitality = 8
	return s


## Saldırı hızı çarpanı: vuruş hazırlık ve toparlanma tick'leri buna bölünür.
func attack_speed_scale() -> float:
	return 1.0 / (1.0 + maxf(0.0, bonus_attack_speed))


## Canavarlar için hızlı kurulum: seviyeye göre makul ham statlar.
static func for_monster(monster_level: int, toughness: float = 1.0) -> Stats:
	var s := Stats.new()
	s.level = monster_level
	# Canavarlar oyuncunun gelişim eğrisine yakın ölçeklenir; yoksa
	# birkaç rütbe sonra hepsi birer çuval oluyor.
	s.strength = int(round((3.0 + float(monster_level) * 0.85) * toughness))
	s.dexterity = int(round((2.0 + float(monster_level) * 1.0) * toughness))
	s.intelligence = 2
	s.vitality = int(round((2.0 + float(monster_level) * 1.25) * toughness))
	s.hp_scale = 1.15
	return s
