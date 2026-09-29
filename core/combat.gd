class_name Combat
extends RefCounted

## Hasar zinciri. Metin2'nin vuruş mantığının sadeleştirilmiş hâli:
##
##   1. İsabet mi? — ŞİMDİLİK KAPALI (aşağıdaki MISS_ENABLED'a bak)
##   2. Delici vuruş mu? (evetse hedefin ZIRHI YOK SAYILIR)
##   3. Ham hasar = saldırı gücü, zırhın emdiği yüzde düşülür, ±%15 salınım
##   4. Kritik mi? (evetse hasar iki katı)
##   5. En az 1 hasar — hiçbir vuruş boşa gitmez
##
## Bütün rastgelelik dışarıdan verilen SimRng'den gelir; bu yüzden
## savaş tamamen tekrarlanabilirdir ve sunucu tarafından doğrulanabilir.

## Iskalama şu an KAPALI: her vuruş isabet eder.
## Sebep: erken denemede "ıskaladı" yazısı oyunu okunmaz kılıyordu.
## Hesap zinciri (hit_chance) yerinde duruyor; bu sabiti true yapmak
## isabet sistemini olduğu gibi geri getirir.
const MISS_ENABLED := false

const MIN_HIT_CHANCE := 0.20
const MAX_HIT_CHANCE := 0.95
const DAMAGE_SPREAD := 0.15

## Taban kritik çarpanı. Ustalık ve beceriler bunu Stats üzerinden
## yükseltir, o yüzden hesapta Stats.crit_multiplier() kullanılır.
const CRIT_MULTIPLIER := 2.0


static func hit_chance(attacker: Stats, defender: Stats) -> float:
	var fark := float(attacker.accuracy() - defender.evasion())
	return clampf(0.45 + fark * 0.01, MIN_HIT_CHANCE, MAX_HIT_CHANCE)


## Tek bir vuruşu çözer. Sonuç sözlüğü doğrudan olay kuyruğuna girer,
## Faz 4'te de aynı sözlük ağ üzerinden istemciye gider.
static func resolve(attacker: Stats, defender: Stats, rng: SimRng) -> Dictionary:
	if MISS_ENABLED and not rng.chance(hit_chance(attacker, defender)):
		return {"hit": false, "damage": 0, "critical": false, "pierced": false}

	var pierced := rng.chance(attacker.pierce_chance())
	var critical := rng.chance(attacker.crit_chance())

	var raw := float(attacker.attack_power())
	if not pierced:
		raw *= 1.0 - defender.damage_reduction()

	# Salınım: aynı vuruş her seferinde aynı sayıyı vermesin.
	raw *= rng.float_range(1.0 - DAMAGE_SPREAD, 1.0 + DAMAGE_SPREAD)

	if critical:
		raw *= attacker.crit_multiplier()

	return {
		"hit": true,
		"damage": maxi(1, int(round(raw))),
		"critical": critical,
		"pierced": pierced,
	}
