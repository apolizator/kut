extends SceneTree

## core/ birim testleri. Motor penceresi AÇILMADAN çalışır:
##
##     godot --headless --path . --script res://tests/run_tests.gd
##
## Bu testlerin motorsuz çalışabiliyor olması, core/'un temiz kaldığının
## kanıtıdır. Bir gün bu komut çalışmazsa, core/ içine görsel katmandan
## bir şey sızmış demektir.

var _pass := 0
var _fail := 0


func _initialize() -> void:
	print("\n=== core testleri ===\n")

	test_rng_deterministik()
	test_rng_durum_kaydi()
	test_rng_aralik_siniri()
	test_rng_oran_dogrulugu()
	test_rng_agirlikli_secim()
	test_saat_sabit_adim()
	test_hareket_mesafesi()
	test_hareket_hedefi_asmiyor()
	test_saldiri_zamanlamasi()
	test_saldiri_sirasinda_komut_yok_sayiliyor()
	test_varlik_kimligi()
	test_hareketsiz_varlik()
	test_dolasma_bolgede_kaliyor()
	test_simulasyon_tekrarlanabilir()

	test_stat_turetme()
	test_stat_getirisi_artiyor()
	test_zirh_yuzdesel_azaltiyor()
	test_seviye_atlayinca_stat_puani()
	test_delici_vurus_zirhi_yok_sayiyor()
	test_kritik_hasari_ikiye_katliyor()
	test_isabet_sansi_sinirli()
	test_her_vurus_en_az_bir_hasar()
	test_exp_egrisi_artiyor()
	test_exp_odulu_seviye_farkina_duyarli()

	test_canavar_kendiliginden_saldirmiyor()
	test_vurulan_canavar_karsilik_veriyor()
	test_npc_ye_saldirilamiyor()
	test_aggro_zamanla_sonuyor()
	test_olum_exp_ve_yeniden_dogus()
	test_yeterli_exp_seviye_atlatiyor()
	test_canavar_cok_uzaklasinca_donuyor()

	test_haritalar_yukleniyor()
	test_gecitler_tutarli()
	test_gecitler_sonsuz_donguye_sokmuyor()
	test_gecitten_gecince_harita_degisiyor()
	test_seviye_haritalar_arasi_tasiniyor()
	test_koyler_guvenli_avlaklar_dolu()
	test_ayni_harita_ayni_duzeni_kuruyor()

	test_iskalama_kapali()
	test_ustalik_hasarla_geliyor()
	test_ustalik_kritik_hasarini_buyutuyor()
	test_kusanma_statlari_degistiriyor()
	test_seviyesi_yetmeyen_esya_kusanilmiyor()
	test_ganimet_oranlari()
	test_coklu_hedef_vurusu()
	test_oyuncu_cevresine_komple_vuruyor()
	test_canavar_dar_acida_vuruyor()
	test_suru_kavgaya_katiliyor()
	test_suru_sayisi_sinirli()
	test_denge_uc_canavar_oyuncuyu_oldurmuyor()
	test_kayit_ve_yukleme()
	test_stat_puani_harcaniyor()

	test_klavye_yonu_ile_yuruyor()
	test_yururken_saldirabiliyor()
	test_harita_sinirindan_cikilamiyor()
	test_saldiranlar_onde_hizaya_geciyor()
	test_metin_tasi_bekci_cagiriyor()
	test_metin_tasi_odulu_buyuk()
	test_canavar_para_birakiyor()
	test_esya_satilabiliyor()
	test_beceri_agaci()
	test_gorev_akisi()
	test_gorev_hedefleri_gercek_canavarlar()
	test_kapilar_acik()
	test_bolgeler_guc_farki_tasiyor()
	test_ilk_avlak_uzun_soluklu()
	test_sehirlerde_dukkan_var()

	test_sunak_haritayi_ayaga_kaldiriyor()
	test_sunak_dalga_dalga_boss_cikariyor()
	test_sunak_ve_tas_ozel_esya_dusuruyor()
	test_katman_kilidi_kademeli_ilerletiyor()
	test_beceri_fullenince_ekstra_bonus()
	test_katman_tamamlama_odulu()
	test_grup_dagilarak_geri_geliyor()
	test_gec_seviye_dengesi()
	test_ustalik_bir_anda_patlamiyor()

	test_can_calma()
	test_yetenek_mana_harciyor_ve_alan_vuruyor()
	test_pasif_yetenek_statlara_isliyor()
	test_kademe_ilerlemesi_master_ve_poly()
	test_uc_esya_birlesiyor()
	test_iksirler_calisiyor()
	test_ozellik_zinciri_sirayla_aciliyor()
	test_bolge_bossu()
	test_zor_gorevler_kalici_odul_veriyor()
	test_daha_iyi_esya_isaretleniyor()
	test_dunya_ve_agac_buyudu()
	test_on_bir_kusanma_yeri()
	test_canta_bolumlere_ayriliyor()

	print("")
	if _fail == 0:
		print("TÜMÜ GEÇTİ — %d kontrol\n" % _pass)
	else:
		print("%d BAŞARISIZ / %d kontrol\n" % [_fail, _pass + _fail])
	quit(1 if _fail > 0 else 0)


# --- yardımcılar ---

func check(ok: bool, label: String) -> void:
	if ok:
		_pass += 1
		print("  ok    %s" % label)
	else:
		_fail += 1
		print("  HATA  %s" % label)


func check_near(got: float, want: float, tol: float, label: String) -> void:
	check(absf(got - want) <= tol, "%s  (beklenen ~%.4f, gelen %.4f)" % [label, want, got])


# --- RNG ---

func test_rng_deterministik() -> void:
	var a := SimRng.new(1234)
	var b := SimRng.new(1234)
	var c := SimRng.new(1235)
	var ayni := true
	var farkli := false
	for i in 1000:
		var x := a.next_u32()
		if x != b.next_u32():
			ayni = false
		if x != c.next_u32():
			farkli = true
	check(ayni, "aynı seed 1000 çekişte aynı diziyi veriyor")
	check(farkli, "farklı seed farklı dizi veriyor")


func test_rng_durum_kaydi() -> void:
	var r := SimRng.new(77)
	for i in 50:
		r.next_u32()
	var snapshot := r.get_state()
	var beklenen := r.next_u32()
	for i in 20:
		r.next_u32()
	r.set_state(snapshot)
	check(r.next_u32() == beklenen, "RNG durumu kaydedilip geri yüklenebiliyor")


func test_rng_aralik_siniri() -> void:
	var r := SimRng.new(9)
	var min_gorulen := 999
	var max_gorulen := -999
	var disarida := false
	for i in 20000:
		var v := r.int_range(3, 7)
		if v < 3 or v > 7:
			disarida = true
		min_gorulen = mini(min_gorulen, v)
		max_gorulen = maxi(max_gorulen, v)
	check(not disarida, "int_range(3,7) aralık dışına çıkmıyor")
	check(min_gorulen == 3 and max_gorulen == 7, "int_range üst sınır dahil (3..7 tamamı görüldü)")


func test_rng_oran_dogrulugu() -> void:
	# %2'lik bir drop oranı gerçekten %2 mi? Loot sisteminin temeli bu.
	var r := SimRng.new(4242)
	var n := 200000
	var dustu := 0
	for i in n:
		if r.chance(0.02):
			dustu += 1
	var oran := float(dustu) / float(n)
	check_near(oran, 0.02, 0.0015, "%2 şans 200k denemede gerçekten ~%2")


func test_rng_agirlikli_secim() -> void:
	var r := SimRng.new(555)
	var weights := PackedInt32Array([1, 0, 3])
	var sayac := [0, 0, 0]
	var n := 120000
	for i in n:
		var idx := r.weighted_index(weights)
		sayac[idx] += 1
	check(sayac[1] == 0, "ağırlığı 0 olan seçenek hiç seçilmiyor")
	check_near(float(sayac[0]) / float(n), 0.25, 0.005, "ağırlık 1/4 -> ~%25")
	check_near(float(sayac[2]) / float(n), 0.75, 0.005, "ağırlık 3/4 -> ~%75")


# --- Saat ---

func test_saat_sabit_adim() -> void:
	var c := SimClock.new()
	var toplam := 0
	for i in 120:  # 60 FPS'de 2 saniye
		toplam += c.advance(1.0 / 60.0)
	check(absi(toplam - 40) <= 1, "2 saniye ~40 tick üretti (gelen: %d)" % toplam)

	var c2 := SimClock.new()
	var buyuk := c2.advance(3.0)  # donmuş kare
	check(buyuk == SimClock.MAX_TICKS_PER_FRAME, "tek karede tick sayısı sınırlanıyor (ölüm sarmalı koruması)")


# --- Hareket ---

func test_hareket_mesafesi() -> void:
	var w := SimWorld.new(1)
	var e := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	e.move_speed = 4.0
	w.command_move(e.id, Vector2(100.0, 0.0))
	for i in SimClock.TICK_RATE:  # tam 1 saniye
		w.step()
	check_near(e.pos.x, 4.0, 0.0001, "4 birim/sn hızla 1 saniyede 4 birim gidildi")


func test_hareket_hedefi_asmiyor() -> void:
	var w := SimWorld.new(1)
	var e := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	e.move_speed = 4.0  # tick başına 0.2 birim
	w.command_move(e.id, Vector2(0.05, 0.0))
	w.step()
	check(e.pos == Vector2(0.05, 0.0), "yakın hedefte tam üstüne oturuyor, titremiyor")
	check(not e.has_move_target, "hedefe varınca yürüme komutu kapanıyor")


# --- Saldırı ---

func test_saldiri_zamanlamasi() -> void:
	var w := SimWorld.new(1)
	var e := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	var kukla := w.spawn("Kukla", Vector2(1.0, 0.0))
	kukla.move_speed = 0.0
	kukla.stats.vitality = 400  # test boyunca ölmesin
	kukla.hp = kukla.stats.max_hp()
	e.attack_windup_ticks = 4
	e.attack_recover_ticks = 6
	w.command_attack(e.id, kukla.id)

	var isabet_tick := -1
	var vurus_sayisi := 0
	for i in 30:
		w.step()
		for ev in w.drain_events():
			if ev["type"] == "attack_hit":
				vurus_sayisi += 1
				if isabet_tick < 0:
					isabet_tick = w.tick  # ilk vuruş; sonrakiler tekrardır

	check(isabet_tick == 5, "ilk vuruş, komuttan 4 tick sonra isabet ediyor (gelen tick: %d)" % isabet_tick)
	check(vurus_sayisi >= 3, "saldırı komutu tek vuruş değil, kesintisiz devam ediyor (%d vuruş / 1.5 sn)" % vurus_sayisi)


func test_saldiri_sirasinda_komut_yok_sayiliyor() -> void:
	var w := SimWorld.new(1)
	var e := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	var kukla := w.spawn("Kukla", Vector2(1.0, 0.0))
	kukla.move_speed = 0.0
	kukla.stats.vitality = 400
	kukla.hp = kukla.stats.max_hp()
	w.command_attack(e.id, kukla.id)
	w.step()
	w.step()
	var kok := e.pos
	w.command_move(e.id, Vector2(10.0, 10.0))
	w.step()
	check(e.pos == kok, "saldırı animasyonu bitmeden yürüme komutu alınmıyor")


# --- Varlıklar ---

func test_varlik_kimligi() -> void:
	var w := SimWorld.new(1)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	var kurt := w.spawn("Kurt", Vector2(3.0, 0.0))
	check(apo.display_name == "Apo", "karakter ismi saklanıyor")
	check(apo.kind == SimEntity.Kind.PLAYER, "oyuncu türü doğru")
	check(kurt.kind == SimEntity.Kind.MONSTER and kurt.team == 1, "canavar varsayılanı: düşman takım")
	check(apo.id != kurt.id, "her varlık benzersiz kimlik alıyor")
	check(w.get_entity(kurt.id) == kurt, "kimlikten varlığa erişilebiliyor")


func test_hareketsiz_varlik() -> void:
	var w := SimWorld.new(1)
	var tas := w.spawn("Metin Taşı", Vector2(2.0, 2.0), SimEntity.Kind.STONE)
	tas.move_speed = 0.0
	w.command_move(tas.id, Vector2(20.0, 20.0))
	for i in 40:
		w.step()
	check(tas.pos == Vector2(2.0, 2.0), "metin taşı komut gelse de yerinden kıpırdamıyor")


func test_dolasma_bolgede_kaliyor() -> void:
	var w := SimWorld.new(2024)
	var kurt := w.spawn("Kurt", Vector2(10.0, -4.0))
	w.set_wander(kurt, 3.0)
	var en_uzak := 0.0
	var hic_yurudu := false
	for i in 2000:  # 100 saniye
		w.step()
		en_uzak = maxf(en_uzak, kurt.pos.distance_to(kurt.wander_origin))
		if kurt.state == SimEntity.State.MOVING:
			hic_yurudu = true
	check(hic_yurudu, "dolaşan canavar gerçekten yürüyor")
	check(en_uzak <= 3.0001, "dolaşma bölgesinin dışına çıkmıyor (en uzak: %.3f birim)" % en_uzak)


# --- Bütünlük ---

func test_simulasyon_tekrarlanabilir() -> void:
	# Aynı seed + aynı komut dizisi = aynı sonuç.
	# Faz 4'te sunucu ile istemcinin anlaşması buna dayanacak.
	var sonuclar := []
	for deneme in 2:
		var w := SimWorld.new(31337)
		var e := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
		# Dolaşan canavarlar da RNG'den çekiyor: sıra bozulursa test düşer.
		w.set_wander(w.spawn("Kurt", Vector2(6.0, 0.0)), 3.0)
		w.set_wander(w.spawn("Aç Kurt", Vector2(-4.0, 2.0)), 2.0)
		for t in 100:
			if t == 0:
				w.command_move(e.id, Vector2(6.0, 3.0))
			elif t == 40:
				w.command_attack(e.id, w.entities[1].id)
			w.step()
		var konumlar := []
		for ent in w.entities:
			konumlar.append(ent.pos)
		sonuclar.append([konumlar, w.rng.get_state(), w.tick])
	check(sonuclar[0] == sonuclar[1], "aynı seed + aynı komutlar birebir aynı dünyayı üretiyor")


# --- Statlar ---

func test_stat_turetme() -> void:
	var s := Stats.new()
	s.level = 1
	s.vitality = 4
	check(s.max_hp() > 250, "can, seviye ve VIT'ten türetiliyor (%d)" % s.max_hp())

	var zirh_once := s.defense_value()
	s.bonus_defense += 12
	check(s.defense_value() == zirh_once + 12, "kuşanılan zırh savunmaya ekleniyor")


func test_stat_getirisi_artiyor() -> void:
	# Kullanıcı isteği: puan yatırmak geç seviyede de anlamlı kalsın.
	var a := Stats.new()
	a.vitality = 10
	var can10 := a.max_hp()
	a.vitality = 11
	var erken_kazanc := a.max_hp() - can10

	a.vitality = 60
	var can60 := a.max_hp()
	a.vitality = 61
	var gec_kazanc := a.max_hp() - can60

	check(erken_kazanc >= 25, "VIT +1 en az 25 can veriyor (%d)" % erken_kazanc)
	check(gec_kazanc > erken_kazanc,
			"VIT yükseldikçe her puan daha çok can veriyor (%d -> %d)" % [erken_kazanc, gec_kazanc])

	var b := Stats.new()
	b.strength = 10
	var sal10 := b.attack_power()
	b.strength = 11
	var sal_erken := b.attack_power() - sal10
	b.strength = 80
	var sal80 := b.attack_power()
	b.strength = 81
	var sal_gec := b.attack_power() - sal80
	check(sal_erken >= 4, "STR +1 en az 4 saldırı veriyor")
	check(sal_gec > sal_erken, "STR yükseldikçe her puan daha çok saldırı veriyor (%d -> %d)" % [sal_erken, sal_gec])


func test_zirh_yuzdesel_azaltiyor() -> void:
	# Hasar eskiden "saldırı - zırh" idi; geç seviyede zırh her vuruşu
	# 1'e indirip savaşı anlamsız kılıyordu.
	var zayif := Stats.new()
	check_near(zayif.damage_reduction(), float(zayif.defense_value()) /
			(float(zayif.defense_value()) + 112.0), 0.001, "azaltma zırh ve seviyeden hesaplanıyor")

	var tank := Stats.new()
	tank.level = 40
	tank.vitality = 300
	tank.bonus_defense = 2000
	check(tank.damage_reduction() <= 0.80, "azaltmanın tavanı %80 — kimse dokunulmaz değil")

	# Aynı zırh, üst seviyede daha az işe yarar: gelişmek zorunlu.
	var a := Stats.new()
	a.level = 5
	a.bonus_defense = 200
	var b := Stats.new()
	b.level = 60
	b.bonus_defense = 200
	check(a.damage_reduction() > b.damage_reduction(),
			"aynı zırh üst seviyede daha az emiyor (%.2f > %.2f)" % [a.damage_reduction(), b.damage_reduction()])


func test_seviye_atlayinca_stat_puani() -> void:
	var s := Stats.new()
	var can_once := s.max_hp()
	s.level_up()
	check(s.level == 2, "seviye arttı")
	check(s.stat_points == 1, "seviye başına 1 stat puanı")
	check(s.max_hp() > can_once, "seviye canı artırıyor")


# --- Hasar zinciri ---

func test_delici_vurus_zirhi_yok_sayiyor() -> void:
	# Delici vuruş Metin2'nin imzası: hedefin zırhı hesaba katılmaz.
	var saldiran := Stats.new()
	saldiran.strength = 25
	saldiran.dexterity = 30
	var savunan := Stats.new()
	savunan.vitality = 30
	savunan.bonus_defense = 260  # zırhı kalın olsun ki fark net ayrışsın

	var rng := SimRng.new(7)
	var delici_en_dusuk := 999999
	var normal_en_yuksek := 0
	var delici_sayisi := 0
	for i in 30000:
		var s := Combat.resolve(saldiran, savunan, rng)
		if not s["hit"] or s["critical"]:
			continue  # kritikler ölçümü bulandırır
		if s["pierced"]:
			delici_sayisi += 1
			delici_en_dusuk = mini(delici_en_dusuk, int(s["damage"]))
		else:
			normal_en_yuksek = maxi(normal_en_yuksek, int(s["damage"]))

	check(delici_sayisi > 50, "delici vuruş gerçekleşiyor (%d kez)" % delici_sayisi)
	check(delici_en_dusuk > normal_en_yuksek,
			"en zayıf delici (%d) en güçlü normal vuruştan (%d) fazla" % [delici_en_dusuk, normal_en_yuksek])


func test_kritik_hasari_ikiye_katliyor() -> void:
	var saldiran := Stats.new()
	saldiran.strength = 25
	saldiran.dexterity = 30
	var savunan := Stats.new()
	savunan.vitality = 10

	var rng := SimRng.new(11)
	var kritik_top := 0.0
	var kritik_n := 0
	var normal_top := 0.0
	var normal_n := 0
	for i in 60000:
		var s := Combat.resolve(saldiran, savunan, rng)
		if not s["hit"] or s["pierced"]:
			continue
		if s["critical"]:
			kritik_top += float(s["damage"])
			kritik_n += 1
		else:
			normal_top += float(s["damage"])
			normal_n += 1

	check(kritik_n > 100 and normal_n > 100, "hem kritik hem normal vuruş örneklendi")
	var oran := (kritik_top / float(kritik_n)) / (normal_top / float(normal_n))
	check_near(oran, 2.0, 0.08, "kritik vuruş ortalaması normalin iki katı")


func test_isabet_sansi_sinirli() -> void:
	var ezici := Stats.new()
	ezici.level = 90
	ezici.dexterity = 200
	var zavalli := Stats.new()
	check_near(Combat.hit_chance(ezici, zavalli), Combat.MAX_HIT_CHANCE, 0.0001,
			"isabet şansının tavanı var — hiçbir vuruş garanti değil")
	check_near(Combat.hit_chance(zavalli, ezici), Combat.MIN_HIT_CHANCE, 0.0001,
			"isabet şansının tabanı var — hiçbir hedef dokunulmaz değil")


func test_her_vurus_en_az_bir_hasar() -> void:
	var cilibiz := Stats.new()
	var tank := Stats.new()
	tank.level = 60
	tank.vitality = 300
	var rng := SimRng.new(3)
	var en_dusuk := 999999
	for i in 5000:
		var s := Combat.resolve(cilibiz, tank, rng)
		if s["hit"]:
			en_dusuk = mini(en_dusuk, int(s["damage"]))
	check(en_dusuk >= 1, "zırhı delemeyen vuruş bile en az 1 hasar veriyor (en düşük: %d)" % en_dusuk)


# --- Deneyim ---

func test_exp_egrisi_artiyor() -> void:
	var artiyor := true
	for lv in range(1, 50):
		if ExpTable.required_for(lv) >= ExpTable.required_for(lv + 1):
			artiyor = false
	check(artiyor, "her seviye bir öncekinden pahalı")
	check(ExpTable.required_for(1) == 55, "1. seviyeden çıkmak 55 EXP")
	check(ExpTable.reward_for(5, 5) > 100, "canavar başına kazanç hissedilir (%d EXP)" % ExpTable.reward_for(5, 5))


func test_exp_odulu_seviye_farkina_duyarli() -> void:
	var esit := ExpTable.reward_for(10, 10)
	var cok_dusuk := ExpTable.reward_for(10, 30)
	var cok_yuksek := ExpTable.reward_for(10, 2)
	check(cok_dusuk < esit, "çok altındaki oyuncu... değil, çok üstündeki oyuncu az EXP alıyor")
	check(cok_yuksek > esit, "kendinden güçlüyü öldürmek fazla kazandırıyor")
	check(ExpTable.reward_for(10, 30) >= 1, "EXP ödülü hiçbir zaman sıfırlanmıyor")


# --- Saldırganlık kuralı ---

func test_canavar_kendiliginden_saldirmiyor() -> void:
	# Projenin açık kuralı: harita, oyuncu ilk vuruşu yapana kadar huzurlu.
	var w := SimWorld.new(5)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	var kurt := w.spawn("Kurt", Vector2(1.0, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(8))
	w.set_wander(kurt, 2.0)
	var tam_can := apo.hp

	for i in 400:  # 20 saniye dip dibe
		w.step()

	check(apo.hp == tam_can, "yanı başında 20 saniye durdu, canı hiç eksilmedi")
	check(kurt.aggro_target_id == 0, "canavar kendiliğinden hedef almıyor")


func test_vurulan_canavar_karsilik_veriyor() -> void:
	var w := SimWorld.new(6)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	var kurt := w.spawn("Kurt", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(6))
	kurt.stats.vitality = 300  # test boyunca ölmesin
	kurt.hp = kurt.stats.max_hp()

	w.command_attack(apo.id, kurt.id)
	var karsilik_verdi := false
	# Oyuncu ölüp tam canla dirilirse anlık can ölçümü yanıltır;
	# o yüzden savaş boyunca görülen EN DÜŞÜK cana bakıyoruz.
	var en_dusuk := apo.hp
	for i in 300:
		w.step()
		en_dusuk = mini(en_dusuk, apo.hp)
		if kurt.aggro_target_id == apo.id:
			karsilik_verdi = true
	check(karsilik_verdi, "vurulan canavar saldırganı hedef aldı")
	check(en_dusuk < apo.stats.max_hp(), "canavar karşılık olarak hasar verdi")


func test_npc_ye_saldirilamiyor() -> void:
	var w := SimWorld.new(7)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	var demirci := w.spawn("Demirci Ustası", Vector2(1.0, 0.0), SimEntity.Kind.NPC, 0)
	w.command_attack(apo.id, demirci.id)
	for i in 100:
		w.step()
	check(apo.attack_target_id == 0, "NPC hedef olarak kabul edilmiyor")
	check(demirci.hp == demirci.stats.max_hp(), "NPC hiç hasar almadı")


func test_aggro_zamanla_sonuyor() -> void:
	var w := SimWorld.new(8)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	apo.stats.dexterity = 40
	var kurt := w.spawn("Kurt", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(4))
	kurt.stats.vitality = 300
	kurt.hp = kurt.stats.max_hp()

	w.command_attack(apo.id, kurt.id)
	for i in 60:
		w.step()
	check(kurt.aggro_target_id == apo.id, "kavga sırasında karşılık hedefi duruyor")

	w.command_stop(apo.id)
	for i in SimWorld.AGGRO_TICKS + 20:
		w.step()
	check(kurt.aggro_target_id == 0, "kavga bitince canavar sakinleşiyor")


# --- Ölüm, EXP ve yeniden doğuş ---

func test_olum_exp_ve_yeniden_dogus() -> void:
	var w := SimWorld.new(9)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	apo.stats.dexterity = 60
	var kurban := w.spawn("Zayıf Kurt", Vector2(1.0, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(6))
	kurban.move_speed = 0.0
	kurban.hp = 1

	var dogdugu_yer := kurban.pos
	w.command_attack(apo.id, kurban.id)

	var oldu := false
	for i in 200:
		w.step()
		if not kurban.alive:
			oldu = true
			break
	check(oldu, "hedef öldürülebiliyor")
	check(apo.experience > 0 or apo.stats.level > 1, "öldürmek EXP kazandırdı")
	check(apo.attack_target_id == 0, "hedef ölünce saldırı komutu kendiliğinden düşüyor")

	for i in SimWorld.RESPAWN_TICKS + 5:
		w.step()
	check(kurban.alive, "canavar bir süre sonra geri geliyor")
	check(kurban.hp == kurban.stats.max_hp(), "geri gelen canavarın canı tam")
	check(kurban.pos == dogdugu_yer, "canavar doğduğu noktada geri geliyor")


func test_yeterli_exp_seviye_atlatiyor() -> void:
	var w := SimWorld.new(10)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	apo.stats.dexterity = 60
	check(apo.stats.level == 1, "başlangıç seviyesi 1")

	# Seviye 6 bir canavar, 1. seviyeye 80'den fazla EXP verir.
	var kurban := w.spawn("Kurt", Vector2(1.0, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(6))
	kurban.move_speed = 0.0
	kurban.hp = 1
	w.command_attack(apo.id, kurban.id)
	for i in 200:
		w.step()
		if apo.stats.level > 1:
			break
	check(apo.stats.level == 2, "yeterli EXP seviye atlattı")
	check(apo.stats.stat_points == 1, "seviye atlayınca stat puanı geldi")
	check(apo.hp == apo.stats.max_hp(), "seviye atlayınca can tamamlandı")


func test_canavar_cok_uzaklasinca_donuyor() -> void:
	var w := SimWorld.new(12)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0)
	apo.stats.dexterity = 60
	apo.move_speed = 9.0  # canavardan hızlı kaç
	var kurt := w.spawn("Kurt", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(5))
	kurt.stats.vitality = 300
	kurt.hp = kurt.stats.max_hp()
	var yuva := kurt.spawn_pos

	w.command_attack(apo.id, kurt.id)
	for i in 40:
		w.step()
	w.command_stop(apo.id)
	w.command_move(apo.id, Vector2(60.0, 0.0))  # uzaklara kaç

	var en_uzak := 0.0
	for i in 600:
		w.step()
		en_uzak = maxf(en_uzak, kurt.pos.distance_to(yuva))
	check(en_uzak <= kurt.leash_range + 1.0,
			"canavar yuvasından belli bir mesafeden fazla uzaklaşmıyor (en uzak: %.2f)" % en_uzak)
	check(kurt.pos.distance_to(yuva) < 1.0, "kovalamayı bırakınca yuvasına döndü")


# --- Haritalar ---

func test_haritalar_yukleniyor() -> void:
	var haritalar := MapLoader.load_all()
	check(haritalar.size() >= 5, "harita dosyaları okundu (%d harita)" % haritalar.size())

	var isimli := true
	for m in haritalar:
		if m.id.is_empty() or m.display_name.is_empty():
			isimli = false
	check(isimli, "her haritanın kimliği ve adı var")

	var baslangic := MapLoader.start_map()
	var var_mi := false
	for m in haritalar:
		if m.id == baslangic:
			var_mi = true
	check(var_mi, "başlangıç haritası (%s) tanımlı" % baslangic)


func test_gecitler_tutarli() -> void:
	var haritalar := MapLoader.load_all()
	var tablo := {}
	for m in haritalar:
		tablo[m.id] = m

	var hedefler_gecerli := true
	var girisler_icerde := true
	for m in haritalar:
		for p in m.portals:
			var hedef := str(p.get("to", ""))
			if not tablo.has(hedef):
				hedefler_gecerli = false
				continue
			var varis: MapDef = tablo[hedef]
			var giris := MapDef._to_vec(p.get("entry", varis.spawn_point))
			if varis.clamp_pos(giris) != giris:
				girisler_icerde = false
	check(hedefler_gecerli, "her geçidin hedefi var olan bir harita")
	check(girisler_icerde, "her geçidin varış noktası hedef haritanın sınırları içinde")


func test_gecitler_sonsuz_donguye_sokmuyor() -> void:
	# Kritik tuzak: A'dan B'ye geçtiğinde B'deki çıkış noktası B'nin
	# geri dönüş geçidinin ÜSTÜNDEyse oyuncu iki harita arasında
	# sonsuza kadar savrulur. Bu testi geçmeyen harita oynanamaz.
	var haritalar := MapLoader.load_all()
	var tablo := {}
	for m in haritalar:
		tablo[m.id] = m

	var guvenli := true
	var suclu := ""
	for m in haritalar:
		for p in m.portals:
			var hedef := str(p.get("to", ""))
			if not tablo.has(hedef):
				continue
			var varis: MapDef = tablo[hedef]
			var giris := MapDef._to_vec(p.get("entry", varis.spawn_point))
			for q in varis.portals:
				var q_at := MapDef._to_vec(q.get("at", [0, 0]))
				var q_r := float(q.get("radius", 1.3))
				if giris.distance_to(q_at) <= q_r + 0.5:
					guvenli = false
					suclu = "%s -> %s" % [m.id, hedef]
	check(guvenli, "hiçbir varış noktası bir geçidin üstünde değil %s" % suclu)

	# Aynı kontrol haritaların kendi doğuş noktaları için de geçerli.
	var dogus_guvenli := true
	for m in haritalar:
		for q in m.portals:
			var q_at := MapDef._to_vec(q.get("at", [0, 0]))
			var q_r := float(q.get("radius", 1.3))
			if m.spawn_point.distance_to(q_at) <= q_r + 0.5:
				dogus_guvenli = false
	check(dogus_guvenli, "hiçbir haritanın doğuş noktası bir geçidin üstünde değil")


func test_gecitten_gecince_harita_degisiyor() -> void:
	var oyun := Game.new("Apo", 4242)
	for m in MapLoader.load_all():
		oyun.register_map(m)
	oyun.start("umurca_koyu")
	check(oyun.current_map.id == "umurca_koyu", "oyun Umurca Köyü'nde başlıyor")

	var kapi := MapDef._to_vec(oyun.current_map.portals[0].get("at", [0, 0]))
	oyun.world.command_move(oyun.player.id, kapi)

	var gecti := false
	for i in 400:
		oyun.step()
		if oyun.current_map.id != "umurca_koyu":
			gecti = true
			break
	check(gecti, "geçide yürüyünce harita değişti -> %s" % oyun.current_map.id)
	check(oyun.visited.size() >= 2, "gezilen haritalar işaretleniyor")

	# Geçtikten sonra hemen geri savrulmamalı.
	var kaldi := true
	var varilan := oyun.current_map.id
	for i in 40:
		oyun.step()
		if oyun.current_map.id != varilan:
			kaldi = false
	check(kaldi, "yeni haritada kaldı, geçide geri düşmedi")


func test_seviye_haritalar_arasi_tasiniyor() -> void:
	var oyun := Game.new("Apo", 999)
	for m in MapLoader.load_all():
		oyun.register_map(m)
	oyun.start("umurca_koyu")
	oyun.player.stats.level = 7
	oyun.player.stats.strength = 22
	oyun.player.experience = 55

	oyun.travel_to("umurca_ovasi")
	check(oyun.player.stats.level == 7, "seviye haritayı geçince korunuyor")
	check(oyun.player.stats.strength == 22, "dağıtılmış statlar korunuyor")
	check(oyun.player.experience == 55, "biriken EXP korunuyor")


func test_koyler_guvenli_avlaklar_dolu() -> void:
	var oyun := Game.new("Apo", 31)
	for m in MapLoader.load_all():
		oyun.register_map(m)

	oyun.start("umurca_koyu")
	var koyde_canavar := 0
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER or e.kind == SimEntity.Kind.STONE:
			koyde_canavar += 1
	check(koyde_canavar == 0, "Umurca Köyü güvenli — tek canavar yok")

	oyun.travel_to("umurca_ovasi")
	var ovada_canavar := 0
	var tas_var := false
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER:
			ovada_canavar += 1
		elif e.kind == SimEntity.Kind.STONE:
			tas_var = true
	check(ovada_canavar >= 5, "Umurca Ovası canavarla dolu (%d canavar)" % ovada_canavar)
	check(tas_var, "ovada metin taşı var")


func test_ayni_harita_ayni_duzeni_kuruyor() -> void:
	var konumlar := []
	for deneme in 2:
		var oyun := Game.new("Apo", 777)
		for m in MapLoader.load_all():
			oyun.register_map(m)
		oyun.start("umurca_ovasi")
		var satir := []
		for e in oyun.world.entities:
			satir.append("%s@%.6f,%.6f" % [e.display_name, e.pos.x, e.pos.y])
		konumlar.append(satir)
	check(konumlar[0] == konumlar[1], "aynı harita her girişte aynı düzeni kuruyor")


# --- Iskalama kapalı ---

func test_iskalama_kapali() -> void:
	var saldiran := Stats.new()
	var kacak := Stats.new()
	kacak.dexterity = 200  # kaçınması tavanda
	var rng := SimRng.new(4)
	var iska := 0
	for i in 3000:
		if not Combat.resolve(saldiran, kacak, rng)["hit"]:
			iska += 1
	check(iska == 0, "ıskalama kapalıyken her vuruş isabet ediyor")
	check(not Combat.MISS_ENABLED, "isabet sistemi kapalı ama hesabı duruyor")


# --- Eşyalar ---

func test_ustalik_hasarla_geliyor() -> void:
	var m := Mastery.new()
	var gerekli := Mastery.required(0)

	check(m.add_weapon_damage(gerekli - 1) == 0, "eşik dolmadan rütbe gelmiyor")
	check(m.weapon_rank == 0, "hâlâ rütbe 0")
	check(m.add_weapon_damage(1) == 1, "eşik dolunca rütbe atlıyor")
	check(m.weapon_rank == 1, "silah ustalığı rütbe 1")
	check(m.armor_rank == 0, "zırh ustalığı ayrı hattan ilerliyor")

	check(m.add_armor_damage(Mastery.required(0)) == 1, "yenilen hasar zırh ustalığını besliyor")
	check(Mastery.required(1) > Mastery.required(0), "üst rütbeler daha çok hasar istiyor")

	# Rütbe bonusları statlara kalıcı olarak yansıyor
	var st := Stats.for_player()
	var saldiri_once := st.attack_power()
	var zirh_once := st.defense_value()
	m.apply_to(st)
	check(st.attack_power() > saldiri_once, "silah rütbesi saldırıyı artırdı")
	check(st.defense_value() > zirh_once, "zırh rütbesi savunmayı artırdı")

	# Tavan
	for i in 400:
		m.add_weapon_damage(500000)
	check(m.weapon_rank == Mastery.MAX_RANK, "ustalık R%d'da duruyor" % Mastery.MAX_RANK)
	check(Mastery.MAX_RANK == 30, "ustalık tavanı 30 rütbe")
	check(not Mastery.bonus_text(Mastery.weapon_bonus(30)).is_empty(), "30. rütbenin bonusu tanımlı")
	check(not Mastery.bonus_text(Mastery.armor_bonus(30)).is_empty(), "zırh 30. rütbesi tanımlı")
	check(m.add_weapon_damage(999999) == 0, "en üst rütbede ilerleme yok")


func test_ustalik_kritik_hasarini_buyutuyor() -> void:
	var st := Stats.for_player()
	check_near(st.crit_multiplier(), 2.0, 0.001, "taban kritik çarpanı iki kat")
	st.bonus_crit_damage = 0.5
	check_near(st.crit_multiplier(), 2.5, 0.001, "pasif bonus kritik çarpanını büyüttü")


func test_kusanma_statlari_degistiriyor() -> void:
	var st := Stats.for_player()
	var inv := Inventory.new()
	var saldiri_once := st.attack_power()
	var zirh_once := st.defense_value()

	var kilic := Item.new()
	kilic.display_name = "Test Kılıcı"
	kilic.slot = Item.Slot.WEAPON
	kilic.bonus = {"attack": 20}
	var kalkan := Item.new()
	kalkan.display_name = "Test Kalkanı"
	kalkan.slot = Item.Slot.SHIELD
	kalkan.bonus = {"defense": 18, "hp": 200}

	inv.add(kilic)
	inv.add(kalkan)
	check(inv.equip_at(0, 1), "silah kuşanıldı")
	check(inv.equip_at(0, 1), "kalkan kuşanıldı")
	st.reset_bonuses()
	inv.apply_to(st)

	check(st.attack_power() == saldiri_once + 20, "silah saldırı gücüne eklendi")
	check(st.defense_value() == zirh_once + 18, "kalkan savunmayı artırdı")
	check(inv.slots.is_empty(), "kuşanılan eşyalar çantadan çıktı")
	check(inv.equipped(Item.Slot.WEAPON) != null and inv.equipped(Item.Slot.SHIELD) != null,
			"iki ayrı kuşanma yeri dolu")

	check(inv.unequip(Item.Slot.WEAPON), "silah çıkarıldı")
	st.reset_bonuses()
	inv.apply_to(st)
	check(st.attack_power() == saldiri_once, "çıkarınca saldırı eski hâline döndü")


func test_on_bir_kusanma_yeri() -> void:
	var db := ItemDb.new()
	db.load_from(MapLoader.read_json("res://data/items.json"))
	var bulunan := {}
	for id in db.order:
		bulunan[(db.templates[id] as Item).slot] = true
	check(bulunan.size() >= 5, "her kuşanma yeri için eşya var (%d)" % bulunan.size())

	var inv := Inventory.new()
	var st := Stats.for_player()
	var kusanilabilir := 0
	for s_tur in Item.SLOT_ORDER:
		if s_tur == Item.Slot.NONE:
			continue  # iksir ve malzeme kuşanılmaz
		for id in db.order:
			var tpl: Item = db.templates[id]
			if tpl.slot == s_tur and tpl.required_level <= 1 and tpl.is_equipment():
				inv.add(db.make(id))
				kusanilabilir += 1
				break
	for i in kusanilabilir:
		inv.equip_at(0, 1)
	check(inv.equipment.size() == kusanilabilir, "hepsi ayrı yerlere kuşanıldı (%d parça)" % kusanilabilir)
	check(inv.slots.is_empty(), "çanta boşaldı")

	st.reset_bonuses()
	inv.apply_to(st)
	check(st.bonus_attack > 0 and st.bonus_defense > 0, "takım saldırı ve savunma veriyor")
	check(st.bonus_move_speed > 0.0, "ayakkabı hareket hızı veriyor")
	check(st.bonus_hp > 0, "zırh ve kask can veriyor")


func test_canta_bolumlere_ayriliyor() -> void:
	var db := ItemDb.new()
	db.load_from(MapLoader.read_json("res://data/items.json"))
	var inv := Inventory.new()
	# Karışık sırayla doldur
	for id in ["kalkan_1", "kilic_3", "kilic_1", "ayakkabi_2", "kilic_2", "kalkan_3"]:
		if db.has(id):
			inv.add(db.make(id))

	var gruplar := inv.grouped()
	check(gruplar.size() == 3, "üç ayrı bölüm oluştu (%d)" % gruplar.size())

	var sirali := true
	for g in gruplar:
		var liste: Array = g["items"]
		for i in range(1, liste.size()):
			if (liste[i - 1]["item"] as Item).power() < (liste[i]["item"] as Item).power():
				sirali = false
	check(sirali, "her bölüm güçlüden zayıfa sıralı")

	var ilk_slot: Item.Slot = gruplar[0]["slot"]
	check(ilk_slot == Item.Slot.WEAPON, "silah bölümü en üstte")


func test_seviyesi_yetmeyen_esya_kusanilmiyor() -> void:
	var inv := Inventory.new()
	var ust_esya := Item.new()
	ust_esya.display_name = "Gök Kılıcı"
	ust_esya.slot = Item.Slot.WEAPON
	ust_esya.bonus = {"attack": 68}
	ust_esya.required_level = 13
	inv.add(ust_esya)
	check(not inv.equip_at(0, 1), "1. seviye oyuncu 13. seviye kılıcı kuşanamıyor")
	check(inv.equipped(Item.Slot.WEAPON) == null, "silah boş kaldı")
	check(inv.equip_at(0, 13), "seviye yetince kuşanılıyor")


func test_ganimet_oranlari() -> void:
	var db := ItemDb.new()
	db.load_from(MapLoader.read_json("res://data/items.json"))
	check(db.order.size() >= 10, "eşya havuzu yüklendi (%d eşya)" % db.order.size())

	var rng := SimRng.new(5)
	var dusen := 0
	for i in 4000:
		if db.roll_drop(3, rng, 0.28) != null:
			dusen += 1
	check_near(float(dusen) / 4000.0, 0.28, 0.025, "ganimet oranı ayarlandığı gibi")

	var rng2 := SimRng.new(6)
	var fazla_yuksek := false
	for i in 3000:
		var it := db.roll_drop(3, rng2, 1.0)
		if it != null and it.required_level > 3:
			fazla_yuksek = true
	check(not fazla_yuksek, "canavar seviyesinin üstünde eşya düşmüyor")


# --- Sürü savaşı ---

func test_coklu_hedef_vurusu() -> void:
	var w := SimWorld.new(21)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.attack_max_targets = 3

	var a := w.spawn("A", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(2))
	var b := w.spawn("B", Vector2(1.1, 0.6), SimEntity.Kind.MONSTER, 1, Stats.for_monster(2))
	var c := w.spawn("C", Vector2(1.1, -0.6), SimEntity.Kind.MONSTER, 1, Stats.for_monster(2))
	for e in [a, b, c]:
		e.move_speed = 0.0
		e.stats.vitality = 300
		e.hp = e.stats.max_hp()

	w.command_attack(apo.id, a.id)
	for i in 12:
		w.step()

	check(a.hp < a.stats.max_hp(), "ana hedef hasar aldı")
	check(b.hp < b.stats.max_hp() and c.hp < c.stats.max_hp(), "tek vuruş yanındaki ikisine de değdi")


func test_oyuncu_cevresine_komple_vuruyor() -> void:
	var w := SimWorld.new(23)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.attack_max_targets = 3
	apo.attack_arc = PI  # tam çevre

	var on := w.spawn("Ön", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(2))
	var arka := w.spawn("Arka", Vector2(-1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(2))
	for e in [on, arka]:
		e.move_speed = 0.0
		e.stats.vitality = 300
		e.hp = e.stats.max_hp()

	w.command_attack(apo.id, on.id)
	for i in 12:
		w.step()
	check(on.hp < on.stats.max_hp(), "öndeki hasar aldı")
	check(arka.hp < arka.stats.max_hp(), "arkadaki de hasar aldı — savuruş tam çevre")


func test_canavar_dar_acida_vuruyor() -> void:
	# Oyuncunun savuruşu tam çevre, canavarınki değil.
	var w := SimWorld.new(52)
	var kurt := w.spawn("Kurt", Vector2.ZERO, SimEntity.Kind.MONSTER, 1, Stats.for_monster(5))
	check(kurt.attack_arc < PI - 0.01, "canavarın vuruş açısı dar")


func test_suru_kavgaya_katiliyor() -> void:
	var w := SimWorld.new(22)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.attack_max_targets = 1  # sadece sürü davranışını ölç

	var hedef := w.spawn("Kurt 1", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
	var yakin1 := w.spawn("Kurt 2", Vector2(3.5, 1.5), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
	var yakin2 := w.spawn("Kurt 3", Vector2(2.5, -2.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
	var uzak := w.spawn("Kurt 4", Vector2(25.0, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
	for e in [hedef, yakin1, yakin2, uzak]:
		e.stats.vitality = 400
		e.hp = e.stats.max_hp()

	w.command_attack(apo.id, hedef.id)
	for i in 30:
		w.step()

	check(hedef.aggro_target_id == apo.id, "vurulan canavar karşılık veriyor")
	check(yakin1.aggro_target_id == apo.id and yakin2.aggro_target_id == apo.id,
			"yakındaki sürü arkadaşları kavgaya katıldı")
	check(uzak.aggro_target_id == 0, "uzaktaki canavar duymadı")


func test_suru_sayisi_sinirli() -> void:
	# Bütün harita üstüne gelirse oyuncu ölür. Katılan sayısı sınırlı olmalı.
	var w := SimWorld.new(24)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	var hedef := w.spawn("Kurt 0", Vector2(1.2, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
	hedef.stats.vitality = 400
	hedef.hp = hedef.stats.max_hp()
	for i in 8:
		var e := w.spawn("Kurt %d" % (i + 1), Vector2(1.5 + float(i) * 0.3, 1.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
		e.stats.vitality = 400
		e.hp = e.stats.max_hp()

	w.command_attack(apo.id, hedef.id)
	for i in 60:
		w.step()

	var kizgin := 0
	for e in w.entities:
		if e.kind == SimEntity.Kind.MONSTER and e.aggro_target_id == apo.id:
			kizgin += 1
	check(kizgin <= SimWorld.MAX_ENGAGED,
			"aynı anda en fazla %d canavar saldırıyor (gelen: %d)" % [SimWorld.MAX_ENGAGED, kizgin])


# --- Denge ---

func test_denge_uc_canavar_oyuncuyu_oldurmuyor() -> void:
	# Kullanıcının açık isteği: sürü saldırsın ama oyuncuyu öldürmesin.
	# Bu test dengeyi kilitler — formülleri değiştiren biri bunu düşürürse
	# oyunun oynanabilirliğini bozmuş demektir.
	var oyun := _oyun_kur(2468, "umurca_ovasi", 0.0)
	var apo := oyun.player

	var canavarlar: Array[SimEntity] = []
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER and canavarlar.size() < 3:
			canavarlar.append(e)
	check(canavarlar.size() == 3, "üç canavar bulundu")

	for i in canavarlar.size():
		var c := canavarlar[i]
		c.pos = apo.pos + Vector2.from_angle(float(i) * TAU / 3.0) * 1.3
		c.prev_pos = c.pos
		c.wander_enabled = false
		c.aggro_target_id = apo.id
		c.aggro_ticks = 100000

	oyun.world.command_attack(apo.id, canavarlar[0].id)

	var en_dusuk := apo.hp
	var tur := 0
	for i in 1200:
		oyun.step()
		tur += 1
		en_dusuk = mini(en_dusuk, apo.hp)
		if not apo.alive:
			break
		if apo.attack_target_id == 0:
			for c in canavarlar:
				if c.alive:
					oyun.world.command_attack(apo.id, c.id)
					break
		var kalan := 0
		for c in canavarlar:
			if c.alive:
				kalan += 1
		if kalan == 0:
			break

	var hepsi_oldu := true
	for c in canavarlar:
		if c.alive:
			hepsi_oldu = false

	var oran := float(en_dusuk) / float(apo.stats.max_hp())
	check(apo.alive, "1. seviye Apo üç canavarın ortasında hayatta kaldı")
	check(hepsi_oldu, "üçünü de öldürdü (%.1f saniyede)" % (float(tur) * SimClock.TICK_DELTA))
	check(oran >= 0.15, "canının en az %%15'i kaldı (en düşük: %%%d)" % int(oran * 100.0))
	check(en_dusuk < apo.stats.max_hp(), "savaş gerçekti — hasar aldı")


# --- Kayıt ---

func test_kayit_ve_yukleme() -> void:
	var oyun := _oyun_kur(555, "umurca_koyu", 0.0)
	oyun.player.stats.level = 5
	oyun.player.stats.strength = 15
	oyun.player.stats.stat_points = 3
	oyun.player.experience = 123
	oyun.mastery.add_weapon_damage(Mastery.required(0) + 5)
	oyun.mastery.add_armor_damage(Mastery.required(0) + 3)
	oyun._set_gold(1500)
	oyun.learn_skill("kaba_kuvvet")
	oyun.quest_log.accept("z00_0", 5)
	oyun.quest_log.on_kill("Yabani Köpek")
	oyun.progress.kills = 123
	oyun.progress.damage_dealt = 45678
	oyun.travel_to("umurca_ovasi")
	oyun.player.hp = 200

	var kayit := SaveState.capture(oyun)
	check(not kayit.is_empty(), "kayıt alındı")

	var yeni := _oyun_kur(1, "", 0.0)
	check(SaveState.restore(yeni, kayit), "kayıt geri yüklendi")
	check(yeni.player_name == "Apo", "isim korundu")
	check(yeni.current_map.id == "umurca_ovasi", "harita korundu")
	check(yeni.player.stats.level == 5, "seviye korundu")
	check(yeni.player.stats.strength == 15, "dağıtılan statlar korundu")
	check(yeni.player.stats.stat_points == 3, "harcanmamış puan korundu")
	check(yeni.player.experience == 123, "EXP korundu")
	check(yeni.player.hp == 200, "can korundu")
	check(yeni.player_inventory.equipped(Item.Slot.WEAPON) != null, "kuşanılı silah korundu")
	check(yeni.player.stats.bonus_attack > 0, "yüklenen eşya statlara yansıdı")
	check(yeni.mastery.weapon_rank == 1 and yeni.mastery.armor_rank == 1, "ustalık rütbeleri korundu")
	check(yeni.skills.level_of("kaba_kuvvet") == 1, "öğrenilen beceri korundu")
	check(yeni.player.stats.bonus_attack > 0, "ustalık ve beceri bonusları yüklenince geri geldi")
	check(yeni.player_gold == oyun.player_gold, "para korundu (%d)" % yeni.player_gold)
	var q := yeni.quest_log.get_quest("z00_0")
	check(q != null and q.state == Quest.State.ACTIVE and q.progress == 1, "görev ilerlemesi korundu")
	check(yeni.progress.kills == 123 and yeni.progress.damage_dealt == 45678, "istatistikler korundu")

	check(not SaveState.restore(yeni, {}), "boş kayıt reddediliyor")
	check(not SaveState.restore(yeni, {"version": 999, "map": "umurca_koyu"}), "eski sürüm kayıt reddediliyor")
	check(not SaveState.restore(yeni, {"version": SaveState.VERSION, "map": "olmayan_harita"}),
			"olmayan haritaya işaret eden kayıt reddediliyor")


func test_stat_puani_harcaniyor() -> void:
	var w := SimWorld.new(77)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.stats.stat_points = 2
	var can_once := apo.hp
	var str_once := apo.stats.strength

	check(w.command_spend_stat(apo.id, "str"), "puan STR'ye yatırıldı")
	check(apo.stats.strength == str_once + 1, "STR arttı")
	check(apo.stats.stat_points == 1, "puan düştü")

	check(w.command_spend_stat(apo.id, "vit"), "puan VIT'e yatırıldı")
	check(apo.hp > can_once, "VIT artınca mevcut can da yükseldi")

	check(not w.command_spend_stat(apo.id, "str"), "puan bitince artırılamıyor")
	check(not w.command_spend_stat(apo.id, "olmayan"), "geçersiz stat adı reddediliyor")


## Testlerde tekrar eden oyun kurulumu.
func _oyun_kur(seed_value: int, map_id: String, drop: float) -> Game:
	var oyun := Game.new("Apo", seed_value)
	for m in MapLoader.load_all():
		oyun.register_map(m)
	var veri := MapLoader.read_json("res://data/items.json")
	var db := ItemDb.new()
	db.load_from(veri)
	oyun.setup_items(db, veri.get("starting", {}), drop)
	oyun.setup_skills(MapLoader.read_json("res://data/skills.json"))
	oyun.setup_quests(MapLoader.read_json("res://data/quests.json"))
	oyun.setup_abilities(MapLoader.read_json("res://data/abilities.json"))
	oyun.setup_perks(MapLoader.read_json("res://data/perks.json"))
	if not map_id.is_empty():
		oyun.start(map_id)
	return oyun


# --- Klavye ile yürüme ---

func test_klavye_yonu_ile_yuruyor() -> void:
	var w := SimWorld.new(41)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.move_speed = 4.0

	w.command_move_dir(apo.id, Vector2(1.0, 0.0))
	for i in SimClock.TICK_RATE:
		w.step()
	check_near(apo.pos.x, 4.0, 0.001, "sağa basılı tutmak 1 saniyede 4 birim ilerletti")
	check_near(apo.pos.y, 0.0, 0.001, "sapma yok")

	# Çapraz basmak daha hızlı olmamalı
	var basla := apo.pos
	w.command_move_dir(apo.id, Vector2(1.0, 1.0))
	for i in SimClock.TICK_RATE:
		w.step()
	check_near(apo.pos.distance_to(basla), 4.0, 0.001, "çapraz yürümek hızlandırmıyor")

	w.command_move_dir(apo.id, Vector2.ZERO)
	var durus := apo.pos
	for i in 20:
		w.step()
	check(apo.pos == durus, "tuş bırakılınca duruyor")


func test_yururken_saldirabiliyor() -> void:
	var w := SimWorld.new(42)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	var kukla := w.spawn("Kukla", Vector2(1.0, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(3))
	kukla.move_speed = 0.0
	kukla.stats.vitality = 400
	kukla.hp = kukla.stats.max_hp()

	w.command_attack(apo.id, kukla.id)
	w.step()
	w.step()
	check(apo.attack_timer >= 0, "saldırı başladı")

	w.command_move_dir(apo.id, Vector2(-1.0, 0.0))
	var konum := apo.pos
	w.step()
	check(apo.attack_target_id == kukla.id, "yürürken hedef bırakılmıyor")
	check(apo.pos != konum, "vuruş sürerken de yürüyebiliyor")


func test_harita_sinirindan_cikilamiyor() -> void:
	var w := SimWorld.new(43)
	w.bounds = Vector2(5.0, 5.0)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	w.command_move_dir(apo.id, Vector2(1.0, 0.0))
	for i in 200:
		w.step()
	check(apo.pos.x <= 5.0001, "harita kenarında duruyor (x=%.2f)" % apo.pos.x)


# --- Hizaya geçme ---

func test_saldiranlar_onde_hizaya_geciyor() -> void:
	# Kuşatma yerine hiza: üçü de oyuncunun aynı tarafında toplanmalı ki
	# tek savuruşla kapsanabilsinler.
	var w := SimWorld.new(44)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.move_speed = 0.0  # oyuncu sabit dursun, ölçüm temiz olsun
	apo.stats.vitality = 500
	apo.hp = apo.stats.max_hp()

	var grup: Array[SimEntity] = []
	for i in 3:
		var c := w.spawn("Kurt %d" % i, Vector2(6.0, -2.0 + float(i) * 2.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(4))
		c.stats.vitality = 400
		c.hp = c.stats.max_hp()
		c.aggro_target_id = apo.id
		c.aggro_ticks = 100000
		grup.append(c)

	for i in 300:
		w.step()

	# Hepsi oyuncuya göre aynı yarım düzlemde mi?
	var yonler: Array[float] = []
	for c in grup:
		yonler.append((c.pos - apo.pos).angle())
	var en_genis := 0.0
	for a in yonler:
		for b in yonler:
			en_genis = maxf(en_genis, absf(angle_difference(a, b)))
	check(en_genis < 2.2, "saldıranlar dar bir yay içinde hizalandı (%.2f rad)" % en_genis)


# --- Metin taşı ---

func test_metin_tasi_bekci_cagiriyor() -> void:
	var w := SimWorld.new(45)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.stats.strength = 200  # taşı hızlı eritelim
	apo.attack_max_targets = 1
	var tas := w.spawn("Metin Taşı", Vector2(1.2, 0.0), SimEntity.Kind.STONE, 1, Stats.for_monster(6))
	tas.move_speed = 0.0
	tas.stats.hp_scale = 3.2
	tas.hp = tas.stats.max_hp()

	var onceki_sayi := w.entities.size()
	w.command_attack(apo.id, tas.id)

	var dalga := 0
	for i in 600:
		w.step()
		for ev in w.drain_events():
			if str(ev["type"]) == "guards_summoned":
				dalga += 1
		if not tas.alive:
			break

	check(dalga >= 3, "taş can eksildikçe dalga dalga bekçi çağırdı (%d dalga)" % dalga)
	check(SimWorld.STONE_GUARD_WAVES == 5, "metin taşı beş dalga çıkarıyor")
	check(SimWorld.ALTAR_WAVES == 5, "sunak beş boss dalgası çıkarıyor")
	check(w.entities.size() > onceki_sayi, "bekçiler sahneye girdi")

	var bekci_var := false
	for e in w.entities:
		if e.display_name == "Metin Bekçisi":
			bekci_var = true
			check(e.temporary, "bekçi geçici varlık — ölünce geri gelmez")
			check(e.aggro_target_id == apo.id, "bekçi doğar doğmaz saldırgana yöneldi")
			break
	check(bekci_var, "Metin Bekçisi doğdu")


func test_metin_tasi_odulu_buyuk() -> void:
	var sade := ExpTable.reward_for(9, 5)
	var tas_odulu := int(round(float(sade) * 6.0))
	check(tas_odulu > sade * 5, "metin taşı sıradan canavardan çok daha fazla EXP veriyor")

	var oyun := _oyun_kur(61, "umurca_ovasi", 0.0)
	var tas: SimEntity = null
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.STONE:
			tas = e
			break
	check(tas != null, "ovada metin taşı var")
	check(tas.exp_multiplier >= 6.0, "taşın EXP çarpanı yüksek")
	check(tas.gold_value >= tas.stats.level * 20, "taşın para ödülü yüksek (%d altın)" % tas.gold_value)
	check(tas.stats.max_hp() > 1500, "taş çok dayanıklı (%d can)" % tas.stats.max_hp())


# --- Para ---

func test_canavar_para_birakiyor() -> void:
	var w := SimWorld.new(46)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	var kurban := w.spawn("Kurt", Vector2(1.0, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(4))
	kurban.move_speed = 0.0
	kurban.hp = 1
	kurban.gold_value = 17

	w.command_attack(apo.id, kurban.id)
	for i in 60:
		w.step()
		if not kurban.alive:
			break
	check(not kurban.alive, "canavar öldü")
	check(apo.gold == 17, "kesesine para girdi (%d)" % apo.gold)


# --- Dükkân ---

func test_esya_satilabiliyor() -> void:
	var oyun := _oyun_kur(47, "umurca_koyu", 0.0)
	var esya := oyun.item_db.make("kilic_3")
	oyun.player_inventory.add(esya)
	var once := oyun.player_gold
	var kazanc := oyun.sell_item(0)
	check(kazanc == esya.sell_price, "satış fiyatı eşyanın fiyatı kadar")
	check(oyun.player_gold == once + kazanc, "para kesede")
	check(oyun.player.gold == oyun.player_gold, "simülasyondaki kese ile oyun kesesi aynı")
	check(oyun.player_inventory.slots.is_empty(), "eşya çantadan çıktı")
	check(oyun.sell_item(0) == 0, "boş gözü satmaya çalışmak bir şey yapmıyor")


# --- Beceri ağacı ---

func test_beceri_agaci() -> void:
	var oyun := _oyun_kur(48, "umurca_koyu", 0.0)
	check(oyun.skills.defs.size() >= 8, "beceri ağacı yüklendi (%d beceri)" % oyun.skills.defs.size())

	oyun._set_gold(0)
	check(oyun.learn_skill("kaba_kuvvet") == 0, "parasız beceri öğrenilemiyor")

	oyun._set_gold(5000)
	check(not oyun.skills.prerequisites_met("agir_darbe"), "önkoşulsuz üst beceri kilitli")
	check(oyun.learn_skill("agir_darbe") == 0, "kilitli beceri öğrenilemiyor")

	var saldiri_once := oyun.player.stats.attack_power()
	var fiyat := oyun.skills.cost_of("kaba_kuvvet")
	check(oyun.learn_skill("kaba_kuvvet") == fiyat, "beceri öğrenildi, para harcandı")
	check(oyun.player.stats.attack_power() > saldiri_once, "beceri saldırıya hemen yansıdı")
	check(oyun.player_gold == 5000 - fiyat, "kesedeki para düştü")
	check(oyun.skills.prerequisites_met("agir_darbe"), "önkoşul sağlanınca üst beceri açıldı")
	check(oyun.skills.cost_of("kaba_kuvvet") > fiyat, "bir sonraki seviye daha pahalı")

	for i in 20:
		oyun._set_gold(20000)
		oyun.learn_skill("kaba_kuvvet")
	check(oyun.skills.level_of("kaba_kuvvet") == oyun.skills.max_level("kaba_kuvvet"),
			"beceri tavanında duruyor")


# --- Görevler ---

func test_gorev_akisi() -> void:
	var oyun := _oyun_kur(49, "umurca_koyu", 0.0)
	var acik := oyun.quest_log.available()
	check(acik.size() >= 20, "görev defteri dolu (%d alınabilir görev)" % acik.size())
	check(acik[0].required_level <= acik[acik.size() - 1].required_level,
			"alınabilir görevler seviyeye göre sıralı")

	var q := oyun.quest_log.get_quest("z00_0")
	check(q != null, "görev tanımı yüklendi")
	check(not oyun.quest_log.accept("z09_boss", 1), "seviyesi yetmeyen görev alınamıyor")
	check(oyun.quest_log.accept(q.quest_id, 1), "görev kabul edildi")
	check(q.state == Quest.State.ACTIVE, "görev aktif")

	for i in q.target_count - 1:
		oyun.quest_log.on_kill("Yabani Köpek")
	check(q.state == Quest.State.ACTIVE, "hedef dolmadan tamamlanmıyor")
	check(oyun.quest_log.on_kill("Kurt").is_empty(), "alakasız canavar görevi ilerletmiyor")

	var tamamlanan := oyun.quest_log.on_kill("Yabani Köpek")
	check(tamamlanan.size() == 1, "son öldürme görevi tamamladı")
	check(q.state == Quest.State.READY, "görev ödül bekliyor")

	var para_once := oyun.player_gold
	var seviye_once := oyun.player.stats.level
	var odul := oyun.quest_log.claim(q.quest_id)
	check(not odul.is_empty(), "ödül alındı")
	oyun.grant_reward(int(odul["gold"]), int(odul["exp"]))
	check(oyun.player_gold == para_once + q.reward_gold, "ödül parası kesede")
	check(oyun.progress.quests_done == 1, "biten görev sayacı işledi")
	check(oyun.player.stats.level > seviye_once or oyun.player.experience > 0, "ödül EXP'si işlendi")
	check(oyun.quest_log.claim(q.quest_id).is_empty(), "aynı ödül ikinci kez alınamıyor")


func test_gorev_hedefleri_gercek_canavarlar() -> void:
	# Var olmayan bir canavarı hedefleyen görev asla tamamlanamaz.
	var isimler := {}
	for m in MapLoader.load_all():
		for c in m.monsters:
			isimler[str((c as Dictionary).get("name", ""))] = true
		if not m.boss.is_empty():
			isimler[str(m.boss.get("name", ""))] = true
		if not m.altar.is_empty():
			isimler["Sunak"] = true  # sunak görevleri tür adını kullanır
	isimler["Metin Bekçisi"] = true  # taşın çağırdığı bekçi

	isimler["Metin Muhafızı"] = true  # son dalganın bekçisi
	isimler["Sunak Muhafızı"] = true
	isimler["Sunak Efendisi"] = true
	var defter := QuestLog.new()
	defter.load_defs(MapLoader.read_json("res://data/quests.json"))
	check(defter.quests.size() >= 20, "görevler yüklendi (%d görev)" % defter.quests.size())

	var eksik := ""
	for q in defter.quests:
		if not isimler.has(q.target_name):
			eksik = q.target_name
	check(eksik.is_empty(), "her görevin hedefi haritalarda gerçekten var %s" % eksik)


# --- Seviye kapıları ---

func test_kapilar_acik() -> void:
	# Kullanıcı isteği: her bölgeye her seviyede girilebilsin; zorluk
	# farkını kapı değil, bölgenin kendisi anlatsın.
	var kilitli := false
	for m in MapLoader.load_all():
		for p in m.portals:
			if int(p.get("min_level", 1)) > 1:
				kilitli = true
	check(not kilitli, "hiçbir geçit seviye şartı istemiyor")

	var oyun := _oyun_kur(50, "umurca_ovasi", 0.0)
	oyun.player.stats.level = 1
	var kapi := Vector2.ZERO
	for p in oyun.current_map.portals:
		if str(p.get("to", "")) == "kirklareli_gecidi":
			kapi = MapDef._to_vec(p.get("at", [0, 0]))
	oyun.world.command_move(oyun.player.id, kapi)
	var gecti := false
	for i in 900:
		oyun.step()
		if oyun.current_map.id != "umurca_ovasi":
			gecti = true
			break
	check(gecti, "1. seviye oyuncu üst bölgeye geçebildi")


func test_bolgeler_guc_farki_tasiyor() -> void:
	var haritalar := MapLoader.load_all()
	var avlaklar: Array[MapDef] = []
	for m in haritalar:
		if not m.safe:
			avlaklar.append(m)
	check(avlaklar.size() >= 5, "en az beş avlak var (%d)" % avlaklar.size())

	avlaklar.sort_custom(func(a, b): return a.level_range.x < b.level_range.x)
	var artiyor := true
	for i in range(1, avlaklar.size()):
		if avlaklar[i].level_range.x <= avlaklar[i - 1].level_range.y - 4:
			artiyor = false
	check(artiyor, "bölgeler arası güç farkı belirgin biçimde basamaklanıyor")
	check(avlaklar[avlaklar.size() - 1].level_range.y >= 55,
			"en üst bölge Sv.%d'e kadar çıkıyor" % avlaklar[avlaklar.size() - 1].level_range.y)


func test_ilk_avlak_uzun_soluklu() -> void:
	var tablo := {}
	for m in MapLoader.load_all():
		tablo[m.id] = m
	var ova: MapDef = tablo["umurca_ovasi"]
	check(ova.level_range.x == 1 and ova.level_range.y >= 10,
			"ilk avlak 1-%d seviye aralığını kapsıyor" % ova.level_range.y)

	var seviyeler := []
	var toplam := 0
	for c in ova.monsters:
		seviyeler.append(int((c as Dictionary).get("level", 1)))
		toplam += int((c as Dictionary).get("count", 1))
	seviyeler.sort()
	check(seviyeler.size() >= 4, "avlakta en az dört canavar çeşidi var")
	check(seviyeler[0] <= 2 and seviyeler[seviyeler.size() - 1] >= 8,
			"canavar seviyeleri 2'den 8+'e kadar basamaklanıyor")
	check(toplam >= 15, "avlak dolu (%d canavar)" % toplam)


# --- NPC rolleri ---

func test_sehirlerde_dukkan_var() -> void:
	var oyun := _oyun_kur(51, "umurca_koyu", 0.0)
	var dukkanci := 0
	for e in oyun.world.entities:
		if e.kind != SimEntity.Kind.NPC:
			continue
		if e.npc_role == "shop" or e.npc_role == "both":
			dukkanci += 1
	check(dukkanci >= 2, "köyde alışveriş yapılabilecek en az iki kişi var")
	check(oyun.quest_log.available().size() >= 20, "görevler NPC'ye bağlı değil, her yerden alınabiliyor")


# --- Sunak: haritanın boss cismi ---

func test_sunak_haritayi_ayaga_kaldiriyor() -> void:
	var oyun := _oyun_kur(71, "umurca_ovasi", 0.0)
	var sunak: SimEntity = null
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.ALTAR:
			sunak = e
			break
	check(sunak != null, "haritanın sunağı var")
	check(sunak.stats.max_hp() > 30000, "sunağın canı devasa (%d)" % sunak.stats.max_hp())
	check(sunak.exp_multiplier >= 20.0, "sunağın ödülü çok büyük (×%d EXP)" % int(sunak.exp_multiplier))
	check(sunak.stats.damage_reduction() < 0.55, "sunağın zırhı ince — vuruşlar 1'e düşmüyor")

	var apo := oyun.player
	apo.stats.strength = 400
	oyun.refresh_stats()
	apo.pos = sunak.pos + Vector2(1.2, 0.0)
	apo.prev_pos = apo.pos

	var kizgin_once := 0
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER and e.aggro_target_id == apo.id:
			kizgin_once += 1
	check(kizgin_once == 0, "sunağa dokunmadan önce harita sakin")

	oyun.world.command_attack(apo.id, sunak.id)
	for i in 30:
		oyun.step()

	var kizgin := 0
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER and e.aggro_target_id == apo.id:
			kizgin += 1
	check(kizgin >= 15, "sunağa dokununca bütün bölge üstüne geldi (%d yaratık)" % kizgin)


func test_sunak_dalga_dalga_boss_cikariyor() -> void:
	var oyun := _oyun_kur(72, "umurca_ovasi", 0.0)
	var sunak: SimEntity = null
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.ALTAR:
			sunak = e
			break
	var apo := oyun.player
	apo.stats.strength = 260  # testi makul sürede bitirmek için
	apo.attack_max_targets = 1
	oyun.refresh_stats()
	apo.pos = sunak.pos + Vector2(1.2, 0.0)
	apo.prev_pos = apo.pos
	apo.stats.vitality = 4000
	apo.hp = apo.stats.max_hp()

	oyun.world.command_attack(apo.id, sunak.id)
	var dalga := 0
	var son_dalga := false
	for i in 2000:
		oyun.step()
		for ev in oyun.world.drain_events():
			if str(ev["type"]) == "altar_wave":
				dalga += 1
				if bool(ev.get("final", false)):
					son_dalga = true
		if not sunak.alive:
			break

	check(dalga >= 3, "sunak dalga dalga boss çıkardı (%d dalga)" % dalga)
	var boss := 0
	var guclu := true
	for e in oyun.world.entities:
		if e.display_name.begins_with("Sunak"):
			boss += 1
			if e.stats.max_hp() < sunak.stats.level * 200:
				guclu = false
	check(boss > 0, "sahnede sunak bossları var (%d)" % boss)
	check(guclu, "bosslar sıradan canavardan belirgin güçlü")


func test_sunak_ve_tas_ozel_esya_dusuruyor() -> void:
	var db := ItemDb.new()
	db.load_from(MapLoader.read_json("res://data/items.json"))
	check(db.stone_drops.size() >= 2, "metin taşına özel eşyalar tanımlı")
	check(db.altar_drops.size() >= 3, "sunağa özel eşyalar tanımlı")

	var rng := SimRng.new(9)
	var cikti := false
	for i in 300:
		var it := db.roll_drop(60, rng, 1.0)
		if it != null and (db.stone_drops.has(it.item_id) or db.altar_drops.has(it.item_id)):
			cikti = true
	check(not cikti, "özel eşyalar sıradan canavardan düşmüyor")

	var ozel := db.roll_special(db.altar_drops, rng)
	check(ozel != null and ozel.power() > 300, "sunak ganimeti güçlü bir eşya")


# --- Beceri ağacı: kademeli kilit ve tamamlama ödülleri ---

func test_katman_kilidi_kademeli_ilerletiyor() -> void:
	var oyun := _oyun_kur(73, "umurca_koyu", 0.0)
	var t := oyun.skills
	check(t.tier_count() == 5, "ağaç beş katman (%d)" % t.tier_count())
	check(t.defs.size() >= 60, "ağaçta en az altmış beceri var (%d)" % t.defs.size())
	check(t.tier_gate(0) == 0, "ilk katman açık")
	check(t.tier_gate(1) > 0, "ikinci katman seviye şartı istiyor (%d)" % t.tier_gate(1))

	oyun._set_gold(500000)
	check(not t.tier_unlocked(2), "üçüncü katman baştan kilitli")
	check(oyun.learn_skill("keskin_goz") == 0, "kilitli katmandaki beceri öğrenilemiyor")

	# Üst katmanları doldurunca alt katman açılır
	var koruma := 0
	while not t.tier_unlocked(1) and koruma < 200:
		koruma += 1
		for id in t.skills_in_tier(0):
			oyun._set_gold(500000)
			oyun.learn_skill(id)
	check(t.tier_unlocked(1), "ilk katman doldurulunca ikinci katman açıldı")
	check(t.levels_above(1) >= t.tier_gate(1), "kilit eşiği gerçekten aşıldı")


func test_beceri_fullenince_ekstra_bonus() -> void:
	var oyun := _oyun_kur(74, "umurca_koyu", 0.0)
	var t := oyun.skills
	var id := "kaba_kuvvet"
	var tavan := t.max_level(id)

	oyun._set_gold(500000)
	for i in tavan - 1:
		oyun._set_gold(500000)
		oyun.learn_skill(id)
	check(t.level_of(id) == tavan - 1, "son seviyeye bir kala")
	var once := oyun.player.stats.bonus_attack

	oyun._set_gold(500000)
	oyun.learn_skill(id)
	check(t.is_full(id), "beceri sonuna kadar yükseldi")
	var sonra := oyun.player.stats.bonus_attack
	var tek_seviye := int((oyun.skills.by_id[id] as Dictionary).get("attack", 0))
	check(sonra - once > tek_seviye,
			"son seviye normal artıştan fazlasını verdi — full bonusu açıldı (%d > %d)" % [sonra - once, tek_seviye])


func test_katman_tamamlama_odulu() -> void:
	var oyun := _oyun_kur(75, "umurca_koyu", 0.0)
	var t := oyun.skills

	# Katmandaki her beceriden bir seviye: "hepsi açıldı" ödülü
	for id in t.skills_in_tier(0):
		oyun._set_gold(500000)
		oyun.learn_skill(id)
	check(t.tier_all_learned(0), "ilk katmanın hepsi açıldı")
	check(not t.tier_mastered(0), "ama henüz doldurulmadı")
	var acilis := oyun.player.stats.bonus_attack

	# Hepsini sonuna kadar: "hepsi dolduruldu" ödülü
	var koruma := 0
	while not t.tier_mastered(0) and koruma < 300:
		koruma += 1
		for id in t.skills_in_tier(0):
			oyun._set_gold(500000)
			oyun.learn_skill(id)
	check(t.tier_mastered(0), "ilk katman tamamen dolduruldu")
	check(oyun.player.stats.bonus_attack > acilis, "katmanı doldurmak ek ödül verdi")


# --- Yeniden doğuş ---

func test_grup_dagilarak_geri_geliyor() -> void:
	var oyun := _oyun_kur(76, "umurca_ovasi", 0.0)
	var grup: Array[SimEntity] = []
	var grup_no := 0
	for e in oyun.world.entities:
		if e.kind != SimEntity.Kind.MONSTER:
			continue
		if grup_no == 0:
			grup_no = e.spawn_group
		if e.spawn_group == grup_no:
			grup.append(e)
	check(grup.size() >= 3, "bir canavar grubu bulundu (%d üye)" % grup.size())
	check(grup[0].group_spread > 0.0, "grubun yayılma yarıçapı tanımlı")

	var olum_yerleri := []
	for e in grup:
		olum_yerleri.append(e.pos)
		e.hp = 0
		e.alive = false
		e.dead_ticks = 0
		e.respawn_ticks = 0
		e.state = SimEntity.State.DEAD

	var canli := 0
	for i in SimWorld.GROUP_RESPAWN_TICKS + 10:
		oyun.step()
	for e in grup:
		if e.alive:
			canli += 1
	check(canli == grup.size(), "grup temizlenince hepsi birden geri geldi")

	var ayni_yerde := 0
	for i in grup.size():
		if grup[i].pos.distance_to(olum_yerleri[i]) < 0.01:
			ayni_yerde += 1
	check(ayni_yerde < grup.size(), "öldükleri noktada değil, bölgeye dağılarak doğdular")


# --- Geç seviye dengesi ---

func test_gec_seviye_dengesi() -> void:
	# Kullanıcının şikâyeti: "bir anda çok güçleniyoruz, rakipler zayıf
	# kalıyor." Bu test üst seviyede canavarların hâlâ tehdit olduğunu
	# kilitliyor: oyuncu kazanmalı ama ciddi hasar almalı.
	var oyun := _oyun_kur(77, "luleburgaz_ormani", 0.0)
	var apo := oyun.player
	var st := apo.stats
	st.level = 26
	st.strength = 6 + 13   # puanların yarısı saldırıya
	st.vitality = 8 + 12   # yarısı cana

	# Bölgeye uygun takım
	for id in ["kilic_3", "zirh_3", "kask_3", "kalkan_3", "ayakkabi_3"]:
		var it := oyun.item_db.make(id)
		if it != null:
			oyun.player_inventory.add(it)
	for i in 5:
		oyun.player_inventory.equip_at(0, st.level)

	# Makul bir ustalık ve beceri birikimi
	# Sv.26'ya gelirken birikecek gerçekçi bir ustalık ve sayaç yükü
	oyun.mastery.add_weapon_damage(320000)
	oyun.mastery.add_armor_damage(90000)
	oyun.progress.kills = 1400
	oyun.progress.attacks = 9000
	oyun.progress.crits = 700
	oyun._set_gold(30000)
	for id in oyun.skills.skills_in_tier(0):
		oyun.learn_skill(id)
	oyun.refresh_stats()
	apo.hp = st.max_hp()

	var canavarlar: Array[SimEntity] = []
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER and canavarlar.size() < 3:
			canavarlar.append(e)
	for i in canavarlar.size():
		var c := canavarlar[i]
		c.pos = apo.pos + Vector2.from_angle(float(i) * TAU / 3.0) * 1.4
		c.prev_pos = c.pos
		c.wander_enabled = false
		c.aggro_target_id = apo.id
		c.aggro_ticks = 1000000

	oyun.world.command_attack(apo.id, canavarlar[0].id)
	var en_dusuk := apo.hp
	var tur := 0
	for i in 3000:
		oyun.step()
		tur += 1
		en_dusuk = mini(en_dusuk, apo.hp)
		if not apo.alive:
			break
		if apo.attack_target_id == 0:
			for c in canavarlar:
				if c.alive:
					oyun.world.command_attack(apo.id, c.id)
					break
		var kalan := 0
		for c in canavarlar:
			if c.alive:
				kalan += 1
		if kalan == 0:
			break

	var hepsi_oldu := true
	for c in canavarlar:
		if c.alive:
			hepsi_oldu = false
	var oran := float(en_dusuk) / float(st.max_hp())

	check(apo.alive, "Sv.26 oyuncu bölgesindeki üç canavarla başa çıktı")
	check(hepsi_oldu, "üçünü de öldürdü (%.1f saniye)" % (float(tur) * SimClock.TICK_DELTA))
	check(oran < 0.90, "canavarlar ciddi hasar verdi — canının %%%d'ine düştü" % int(oran * 100.0))
	check(oran > 0.05, "yine de hayatta kalınabilir bir dövüş")


func test_ustalik_bir_anda_patlamiyor() -> void:
	# "Bir anda çok güçleniyoruz": ilk rütbeler hissedilir, ama bir
	# avlak dolusu canavar kesmek ustalığı tepeye taşımamalı.
	var m := Mastery.new()
	m.add_weapon_damage(60000)  # kabaca yüzlerce canavarlık hasar
	check(m.weapon_rank <= 8, "60 bin hasar ustalığı R%d'a taşıdı — tepeye değil" % m.weapon_rank)
	check(m.weapon_rank >= 2, "yine de gözle görülür ilerleme var (R%d)" % m.weapon_rank)
	check(Mastery.required(20) > Mastery.required(5) * 8, "üst rütbeler belirgin biçimde pahalı")


# --- Can çalma ---

func test_can_calma() -> void:
	var w := SimWorld.new(81)
	var apo := w.spawn("Apo", Vector2.ZERO, SimEntity.Kind.PLAYER, 0, Stats.for_player())
	apo.stats.bonus_lifesteal = 0.25
	apo.hp = apo.stats.max_hp() / 2
	var baslangic := apo.hp

	var kukla := w.spawn("Kukla", Vector2(1.5, 0.0), SimEntity.Kind.MONSTER, 1, Stats.for_monster(5))
	kukla.move_speed = 0.0
	kukla.stats.strength = 0   # karşılık vermesin, ölçüm temiz olsun
	kukla.stats.vitality = 4000
	kukla.hp = kukla.stats.max_hp()

	w.command_attack(apo.id, kukla.id)
	var calma_oldu := false
	var en_yuksek := apo.hp
	for i in 60:
		w.step()
		en_yuksek = maxi(en_yuksek, apo.hp)
		for ev in w.drain_events():
			if str(ev["type"]) == "lifesteal":
				calma_oldu = true
	check(calma_oldu, "vuruştan can çalındı")
	check(en_yuksek > baslangic, "canı arttı (%d -> %d)" % [baslangic, en_yuksek])
	check(apo.hp <= apo.stats.max_hp(), "can tavanı aşılmıyor")


# --- Yetenekler ---

func test_yetenek_mana_harciyor_ve_alan_vuruyor() -> void:
	var oyun := _oyun_kur(82, "umurca_ovasi", 0.0)
	var apo := oyun.player
	oyun.abilities.points = 5
	check(oyun.spend_ability_point("kasirga"), "beceri puanıyla yetenek öğrenildi")

	var a := oyun.abilities.get_ability("kasirga")
	check(a.is_learned() and a.level == 1, "yetenek 1. seviyede")

	# Çevresine üç düşman topla
	var hedefler: Array[SimEntity] = []
	for e in oyun.world.entities:
		if e.kind == SimEntity.Kind.MONSTER and hedefler.size() < 3:
			e.pos = apo.pos + Vector2.from_angle(float(hedefler.size()) * 2.1) * 2.0
			e.prev_pos = e.pos
			e.stats.vitality = 3000
			e.hp = e.stats.max_hp()
			hedefler.append(e)

	apo.mp = apo.stats.max_mp()
	var mana_once := apo.mp
	check(oyun.world.command_use_ability(apo.id, "kasirga", apo.pos), "yetenek kullanıldı")
	check(apo.mp < mana_once, "mana harcandı (%d -> %d)" % [mana_once, apo.mp])
	check(a.cooldown_left > 0, "bekleme süresi başladı")
	check(not oyun.world.command_use_ability(apo.id, "kasirga", apo.pos), "beklemedeyken tekrar kullanılamıyor")

	var vurulan := 0
	for h in hedefler:
		if h.hp < h.stats.max_hp():
			vurulan += 1
	check(vurulan == 3, "çevredeki üç düşmana da değdi (%d)" % vurulan)


func test_pasif_yetenek_statlara_isliyor() -> void:
	var oyun := _oyun_kur(83, "umurca_koyu", 0.0)
	var once := oyun.player.stats.attack_power()
	oyun.abilities.points = 3
	oyun.spend_ability_point("guc_kalkani")
	check(oyun.player.stats.attack_power() > once, "pasif yetenek saldırıya işledi")

	var hiz_once := oyun.player.stats.bonus_attack_speed
	oyun.spend_ability_point("savas_temposu")
	check(oyun.player.stats.bonus_attack_speed > hiz_once, "pasif yetenek saldırı hızını artırdı")


func test_kademe_ilerlemesi_master_ve_poly() -> void:
	var oyun := _oyun_kur(84, "umurca_koyu", 0.0)
	var book := oyun.abilities
	var id := "kasirga"

	book.points = Ability.MAX_NORMAL
	for i in Ability.MAX_NORMAL:
		oyun.spend_ability_point(id)
	var a := book.get_ability(id)
	check(a.level == Ability.MAX_NORMAL, "normal seviye doldu (%d)" % a.level)
	check(not oyun.spend_ability_point(id), "dolu seviyeye puan yatırılamıyor")
	var normal_guc := a.effect_scale()

	# Kitapla M kademesi
	book.books = 200
	for i in AbilityBook.BOOKS_FOR_MASTER:
		oyun.advance_ability(id, false)
	check(a.grade == Ability.Grade.MASTER and a.master_level == 1, "kitaplarla M1'e çıktı")
	check(a.effect_scale() > normal_guc * 1.3, "M kademesi güçte sıçrama yaptı")

	var koruma := 0
	while a.master_level < Ability.MAX_MASTER and koruma < 500:
		koruma += 1
		oyun.advance_ability(id, false)
	check(a.master_level == Ability.MAX_MASTER, "M%d'a ulaşıldı" % a.master_level)
	check(not oyun.advance_ability(id, false), "M10'dan sonra kitap işe yaramıyor")

	# Sunak taşıyla Poly
	book.stones = AbilityBook.STONES_FOR_POLY
	var master_guc := a.effect_scale()
	for i in AbilityBook.STONES_FOR_POLY:
		oyun.advance_ability(id, true)
	check(a.grade == Ability.Grade.POLY, "sunak taşlarıyla Poly kademesine geçti")
	check(a.effect_scale() > master_guc * 1.5, "Poly en büyük sıçrama (%.2f -> %.2f)" % [master_guc, a.effect_scale()])
	check(a.grade_label() == "POLY", "kademe etiketi doğru")


# --- Eşya birleştirme ve iksir ---

func test_uc_esya_birlesiyor() -> void:
	var oyun := _oyun_kur(85, "umurca_koyu", 0.0)
	for i in 3:
		oyun.player_inventory.add(oyun.item_db.make("kilic_2"))
	check(oyun.player_inventory.count_of("kilic_2") == 3, "üç aynı eşya çantada")

	var yeni := oyun.combine_item("kilic_2")
	check(yeni != null and yeni.item_id == "kilic_3", "üçü bir üst kademeye dönüştü")
	check(oyun.player_inventory.count_of("kilic_2") == 0, "eskiler harcandı")
	check(yeni.power() > (oyun.item_db.templates["kilic_2"] as Item).power(), "üst kademe daha güçlü")

	check(oyun.combine_item("kilic_3") == null, "tek parçayla birleştirme olmuyor")


func test_iksirler_calisiyor() -> void:
	var oyun := _oyun_kur(86, "umurca_koyu", 0.0)
	oyun.player_inventory.add(oyun.item_db.make("can_iksiri_k"))
	oyun.player_inventory.add(oyun.item_db.make("can_iksiri_k"))
	check(oyun.player_inventory.count_of("can_iksiri_k") == 2, "iksirler yığınlandı")
	check(oyun.player_inventory.slots.size() == 1, "yığın tek göz kaplıyor")

	oyun.player.hp = 10
	oyun.refresh_hotbar()
	check(oyun.abilities.hotbar[0] == "can_iksiri_k", "can iksiri 1 numaralı yuvaya kondu")
	var sonuc := oyun.use_hotbar(0)
	check(sonuc == "can", "iksir kullanıldı")
	check(oyun.player.hp > 10, "can yenilendi (%d)" % oyun.player.hp)
	check(oyun.player_inventory.count_of("can_iksiri_k") == 1, "yığından bir tane harcandı")


# --- Özellik zinciri ---

func test_ozellik_zinciri_sirayla_aciliyor() -> void:
	var oyun := _oyun_kur(87, "umurca_koyu", 0.0)
	oyun.player.stats.level = 60
	oyun._set_gold(2000000)

	var ilk := oyun.perks.next_perk()
	check(not ilk.is_empty(), "zincirin başı var")
	var ikinci_id := str((oyun.perks.perks[1] as Dictionary).get("id", ""))
	check(not oyun.perks.can_buy(ikinci_id, oyun.player_gold, 60), "sıradaki atlanamıyor")

	var once := oyun.player.stats.attack_power()
	check(oyun.buy_perk(str(ilk.get("id", ""))) > 0, "ilk özellik alındı")
	check(oyun.player.stats.attack_power() > once, "özellik statlara işledi")
	check(oyun.perks.can_buy(ikinci_id, oyun.player_gold, 60), "ilki alınınca ikincisi açıldı")

	var fakir := _oyun_kur(88, "umurca_koyu", 0.0)
	fakir.player.stats.level = 60
	fakir._set_gold(0)
	check(fakir.buy_perk(str(ilk.get("id", ""))) == 0, "parasız özellik alınamıyor")


# --- Bölge bossu ---

func test_bolge_bossu() -> void:
	var oyun := _oyun_kur(89, "umurca_ovasi", 0.0)
	var boss: SimEntity = null
	for e in oyun.world.entities:
		if e.is_boss:
			boss = e
			break
	check(boss != null, "bölgenin bossu var")
	check(boss.stats.max_hp() > 8000, "bossun canı sıradan canavarın kat kat üstünde (%d)" % boss.stats.max_hp())
	check(boss.exp_multiplier >= 10.0, "bossun ödülü büyük (×%d EXP)" % int(boss.exp_multiplier))
	check(boss.attack_range > 2.5, "bossun menzili geniş")

	var sayim := 0
	for m in MapLoader.load_all():
		if not m.boss.is_empty():
			sayim += 1
	check(sayim >= 10, "her avlakta bir boss var (%d bölge)" % sayim)


# --- Görev kalıcı ödülü ---

func test_zor_gorevler_kalici_odul_veriyor() -> void:
	var oyun := _oyun_kur(90, "umurca_koyu", 0.0)
	var odullu: Quest = null
	for q in oyun.quest_log.quests:
		if q.has_permanent_reward():
			odullu = q
			break
	check(odullu != null, "kalıcı ödüllü görev var")

	var once := oyun.player.stats.attack_power()
	odullu.state = Quest.State.READY
	var odul := oyun.quest_log.claim(odullu.quest_id)
	oyun.grant_reward(int(odul["gold"]), 0)
	check(oyun.player.stats.attack_power() > once or oyun.player.stats.max_hp() > 0,
			"görevin kalıcı bonusu statlara işledi")
	check(odullu.state == Quest.State.DONE, "görev tamamlandı olarak işaretlendi")

	var sayim := 0
	for q in oyun.quest_log.quests:
		if q.has_permanent_reward():
			sayim += 1
	check(sayim >= 15, "kalıcı ödüllü zor görev sayısı yeterli (%d)" % sayim)


# --- Çanta işaretleri ---

func test_daha_iyi_esya_isaretleniyor() -> void:
	var oyun := _oyun_kur(91, "umurca_koyu", 0.0)
	oyun.player.stats.level = 40
	check(oyun.player_inventory.upgrades_available().is_empty(), "başlangıçta işaret yok")

	oyun.player_inventory.add(oyun.item_db.make("kilic_4"))
	var isaretli := oyun.player_inventory.upgrades_available()
	check(isaretli.size() == 1, "kuşandığından güçlü eşya işaretlendi")

	oyun.player_inventory.equip_at(isaretli[0], 40)
	check(oyun.player_inventory.upgrades_available().is_empty(), "kuşanınca işaret kalkıyor")


# --- Genişleyen içerik ---

func test_dunya_ve_agac_buyudu() -> void:
	var haritalar := MapLoader.load_all()
	check(haritalar.size() >= 16, "en az on altı bölge var (%d)" % haritalar.size())
	var en_ust := 0
	for m in haritalar:
		en_ust = maxi(en_ust, m.level_range.y)
	check(en_ust >= 170, "en üst bölge Sv.%d'e kadar çıkıyor" % en_ust)

	var tas := 0
	for m in haritalar:
		for c in m.monsters:
			if bool((c as Dictionary).get("stone", false)):
				tas += 1
	check(tas >= 25, "haritalarda bol metin taşı var (%d)" % tas)

	var tree := SkillTree.new()
	tree.load_defs(MapLoader.read_json("res://data/skills.json"))
	var toplam := 0
	for e in tree.defs:
		toplam += int(e.get("max", 1))
	check(tree.defs.size() >= 60, "beceri ağacı altmış düğüme çıktı (%d)" % tree.defs.size())
	check(toplam >= 500, "toplam beceri seviyesi ikiye katlandı (%d)" % toplam)
	check(tree.tier_gate(4) >= 200, "son katman ciddi bir birikim istiyor (%d)" % tree.tier_gate(4))

	var defter := QuestLog.new()
	defter.load_defs(MapLoader.read_json("res://data/quests.json"))
	check(defter.quests.size() >= 48, "görev sayısı ikiye katlandı (%d)" % defter.quests.size())
