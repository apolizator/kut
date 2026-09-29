class_name SimClock
extends RefCounted

## Sabit adımlı simülasyon saati.
##
## Simülasyon asla kare hızına (delta) bağlı ilerlemez; saniyede tam olarak
## TICK_RATE kez ilerler. Ekran 144 Hz de olsa 30 Hz de olsa aynı sayıda
## tick işlenir -> aynı girdi aynı sonucu verir.
##
## Faz 4'te authoritative server tam olarak bu saati çalıştıracak.
## Şimdi kurmazsak savaş sistemi o zaman baştan yazılır.

const TICK_RATE := 20
const TICK_DELTA := 1.0 / float(TICK_RATE)

## Kare çok gecikirse (pencere sürüklendi, uyku modu) simülasyonun
## yüzlerce tick'i yakalamaya çalışıp daha da gecikmesini engeller.
const MAX_TICKS_PER_FRAME := 5

var tick_count: int = 0

var _accumulator: float = 0.0


## Gerçek zamanı ilerletir, işlenmesi gereken tick sayısını döndürür.
func advance(real_delta: float) -> int:
	_accumulator += real_delta
	var ticks := 0
	while _accumulator >= TICK_DELTA and ticks < MAX_TICKS_PER_FRAME:
		_accumulator -= TICK_DELTA
		ticks += 1
	if ticks >= MAX_TICKS_PER_FRAME:
		_accumulator = 0.0  # birikmiş borcu sil, ölüm sarmalına girme
	tick_count += ticks
	return ticks


## İki tick arasındaki ilerleme oranı [0,1). Sadece ÇİZİM için:
## görüntünün 20 Hz'de takılı görünmemesi için ara değer hesaplanır.
## Simülasyon bu değeri asla kullanmaz.
func alpha() -> float:
	return clampf(_accumulator / TICK_DELTA, 0.0, 1.0)


func reset() -> void:
	_accumulator = 0.0
	tick_count = 0
