class_name ExpTable
extends RefCounted

## Seviye eğrisi.
##
## Metin2 sabit bir tablo kullanır (formül değil), çünkü denge ayarı
## seviye seviye elle yapılır. Biz de tabloyla çalışıyoruz; tablo
## başlangıçta bu formülden üretiliyor ve istendiği an data/exp.json
## ile değiştirilebilecek.
##
## Not: sınıf adı "Exp" olamaz — exp() GDScript'in yerleşik fonksiyonu.

const MAX_LEVEL := 120


## level seviyesinden bir üste çıkmak için gereken toplam EXP.
static func required_for(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return int(round(55.0 * pow(float(level), 1.92)))


## Bir canavarı öldürünce kazanılan EXP.
## Seviye farkı büyüdükçe kazanç düşer: 10 seviye altındaki canavarı
## öldürmek oyuncuyu ilerletmesin diye.
static func reward_for(monster_level: int, killer_level: int) -> int:
	var taban := monster_level * 22 + 18
	var fark := killer_level - monster_level
	var carpan := 1.0
	if fark > 5:
		carpan = maxf(0.10, 1.0 - float(fark - 5) * 0.08)
	elif fark < -3:
		# Kendinden çok güçlüyü öldürmek fazladan kazandırır.
		carpan = minf(2.0, 1.0 + float(-fark - 3) * 0.10)
	return maxi(1, int(round(float(taban) * carpan)))
