class_name SimRng
extends RefCounted

## Deterministik sözde-rastgele üreteç (xorshift32).
##
## Neden Godot'un randi()'si değil:
##   1. Aynı seed her zaman aynı diziyi verir -> "bu seed'le 10.000 canavar
##      öldür, kılıç düşme oranı gerçekten %2 mi" testi yazılabilir.
##   2. Faz 4'te loot'u SUNUCU belirler; istemcinin aynı sonucu üretmesi
##      motor sürümüne değil, buradaki sabit algoritmaya bağlıdır.
##   3. Bir karakterin RNG durumu kaydedilip geri yüklenebilir.
##
## Bu dosya bilinçli olarak hiçbir motor API'si kullanmaz.
##
## İSİMLENDİRME UYARISI — pahalıya patlayan bir tuzak:
## GDScript'te randf(), randi_range(), randf_range() motorun YERLEŞİK
## global fonksiyonlarıdır. Bu sınıfın metotlarına o isimleri verirsek,
## sınıfın içinden niteliksiz yapılan çağrılar sessizce motorun global
## rastgeleliğine gider — oranlar doğru görünür, ama hiçbir şey
## tekrarlanabilir olmaz. Bu yüzden metotlar bilerek farklı adlandırıldı.

const _MASK32 := 0xFFFFFFFF

var _state: int = 0


func _init(seed_value: int = 20260920) -> void:
	set_seed(seed_value)


func set_seed(seed_value: int) -> void:
	var s := seed_value & _MASK32
	if s == 0:
		s = 0x9E3779B9  # xorshift sıfır durumunda kilitlenir
	_state = s


## Kaydet/yükle için: akışın tam durumu.
func get_state() -> int:
	return _state


func set_state(state_value: int) -> void:
	_state = state_value & _MASK32


func next_u32() -> int:
	var x := _state
	x ^= (x << 13) & _MASK32
	x ^= x >> 17
	x ^= (x << 5) & _MASK32
	x &= _MASK32
	_state = x
	return x


## [0.0, 1.0) aralığında ondalık.
func next_float() -> float:
	return float(next_u32()) / 4294967296.0


func float_range(low: float, high: float) -> float:
	return low + (high - low) * next_float()


## [low, high] aralığında tam sayı — ÜST SINIR DAHİL.
##
## Doğrudan "% span" yapmak küçük sayıları sistematik olarak fazla üretir
## (modulo bias). %0.5'lik bir drop oranının gerçekten %0.5 olması için
## aşan aralığı reddedip yeniden çekiyoruz.
func int_range(low: int, high: int) -> int:
	if high <= low:
		return low
	var span := high - low + 1
	var limit := _MASK32 - ((_MASK32 + 1) % span)
	var r := next_u32()
	while r > limit:
		r = next_u32()
	return low + (r % span)


## probability 0.0 .. 1.0 (0.02 = %2)
func chance(probability: float) -> bool:
	if probability <= 0.0:
		return false
	if probability >= 1.0:
		return true
	return next_float() < probability


## Ağırlıklı seçim: drop tablolarının temeli.
## Döndürülen değer weights dizisindeki indekstir, hiçbiri seçilemezse -1.
func weighted_index(weights: PackedInt32Array) -> int:
	var total := 0
	for w in weights:
		if w > 0:
			total += w
	if total <= 0:
		return -1
	var roll := int_range(1, total)
	var acc := 0
	for i in weights.size():
		if weights[i] <= 0:
			continue
		acc += weights[i]
		if roll <= acc:
			return i
	return -1
