# KUT

Metin2 dinamiklerine sahip bir MMORPG'nin **matematiksel altyapısını** önce
izole bir 2D ortamda kusursuzlaştırma projesi. Grafik sonra gelir.

Motor: **Godot 4** · Ana geliştirme: **M5 MacBook** · Oyun hissi testleri: **Windows**

---

## Tek Kural

> `core/` klasöründeki hiçbir dosya motoru tanımaz.
> Sprite yok, node yok, tuş yok, piksel yok, ekran yok.

Faz 6'da 2D arayüz sökülüp yerine 3D dünya takılacak. O gün acısız olsun
diye bugün bu kurala uyuyoruz. Kuralın ihlal edilip edilmediğinin testi basit:
`core/` testleri motor penceresi açılmadan çalışıyorsa temizdir.

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Bu komut bir gün çalışmazsa, görsel katmandan beyne sızıntı olmuş demektir.

---

## Klasörler

| Klasör | İçerik | Faz 6'da |
| --- | --- | --- |
| `core/` | Saf matematik: statlar, hasar, EXP, eşya, çanta, ganimet, simülasyon, harita tanımları, kayıt biçimi | **Aynen kalır** |
| `shell/` | 2D çizim ve girdi | Sökülür, yerine 3D gelir |
| `server/` | `core/`'u headless çalıştıran otorite (Faz 4) | Aynen kalır |
| `data/` | JSON: itemler, canavarlar, drop tabloları, EXP eğrisi, haritalar | Aynen kalır |
| `tests/` | `core/` birim testleri | Aynen kalır |

---

## Baştan Doğru Kurulan 4 Şey

Bunlar sonradan eklenemeyen, eksikse her şeyi yeniden yazdıran kararlardır.

**1. Dünya birimi, piksel değil** — `core/units.gd`
Menzil `150 piksel` değil `1.5 birim`. 1 birim = 1 metre. 3D'ye geçişte
`core/` içindeki hiçbir sayı değişmez.

**2. Sabit tick (20 Hz)** — `core/sim_clock.gd`
Simülasyon kare hızına bağlı ilerlemez. 144 Hz'de de 30 Hz'de de aynı sayıda
tick işlenir. Faz 4'teki authoritative server tam olarak bu saati çalıştıracak.

**3. Seed'li deterministik RNG** — `core/rng.gd`
Motorun `randi()`'si değil, sabit bir xorshift32. Aynı seed her zaman aynı
diziyi verir; RNG durumu kaydedilip geri yüklenebilir. "%2'lik drop oranı
200.000 denemede gerçekten %2 mi" testi buna dayanır. Faz 4'te loot'u sunucu
belirleyecek, istemci doğrulayabilecek.

> **Yaşanmış tuzak.** Bu sınıfın metotları önce `randf()`, `randi_range()`,
> `randf_range()` diye adlandırılmıştı. Bunlar GDScript'in YERLEŞİK global
> fonksiyonlarıdır: sınıfın içinden niteliksiz yapılan `randf()` çağrısı
> sessizce motorun global rastgeleliğine gitti. Oran testleri geçiyordu
> (dağılım doğruydu), ama hiçbir şey tekrarlanabilir değildi — loot
> sisteminin altında saatli bomba. Metotlar bu yüzden `next_float()`,
> `int_range()`, `float_range()` diye adlandırıldı ve `project.godot`
> içinde global gölgeleme artık uyarı değil **derleme hatası**.
> Bunu yakalayan şey determinizm testiydi.

**4. Olay kuyruğu** — `SimWorld.events`
Simülasyon "ne oldu"yu bir listeye yazar, çizim katmanı okur. Faz 4'te aynı
liste ağ paketine dönüşecek.

---

## Çalıştırma

```bash
# Testler (pencere açılmaz)
godot --headless --path . --script res://tests/run_tests.gd

# Oyun
godot --path .
```

### Kontroller

| Tuş | İş |
| --- | --- |
| **WASD / yön tuşları** | yürü (basılı tut) — yürürken de vurabilirsin |
| **Sol tık** | boşluğa: yürü · birime: seç · panelde: stat artır |
| **Sağ tık** | birime: saldır |
| **Boşluk** | **basılı tut**: durmadan vur — hedefin ölürse en yakınına geçer |
| **1 - 6** | hızlı çubuk: 1-2 iksir, 3-6 yetenek |
| **F** | otomatik av — etraftaki canavarları biçer, canın düşünce iksirini içer |
| **G** | otomatik metin avı — taşları kırar |
| **B** | yetenek defteri |
| **Tab** | en yakın düşmanı seç |
| **I** | çanta (tıkla: kuşan / çıkar) |
| **K** | beceri ağacı (54 pasif) |
| **J** | görev defteri |
| **T** | istatistikler |
| **M** | dünya haritası — gezdiğin bölgeye tıkla, ışınlan |
| **Esc** | pencereyi kapat · açık pencere yoksa kaydet ve çık |

Yürümek ve vurmak artık birlikte olur: WASD'ye basarken Boşluk'a bas, menzile
girdiğin anda savurmaya başlarsın. Hedefin ölürse ve sana saldıran biri
varsa karakter **kendiliğinden ona döner** — olduğun yerde boşa dayak yemezsin.

## Birim türleri

| Tür | Renk | Davranış |
| --- | --- | --- |
| Oyuncu (**Apo**) | mavi kare | sen |
| NPC (Demirci Ustası, Şifacı Ayşe…) | yeşil kare | saldırılamaz, kıpırdamaz |
| Canavar (Kurt, Aç Kurt, Dağ Haydutu…) | kırmızı kare | bölgesinde dolaşır, **vurulursa** karşılık verir |
| Metin Taşı | mor elmas | sabit ve dayanıklı, kırılınca ganimet verecek |

Her birimin üstünde **seviyesi**, **adı** ve **can barı** durur. Tıklayınca
sağ üstte tam dökümü açılır: zırh, saldırı gücü, STR/DEX/INT/VIT ve komut
düğmeleri. Karşılık vermeye başlayan bir canavarın adının önünde **!** çıkar.

## Saldırganlık kuralı ve sürü savaşı

> Canavarlar kendiliğinden saldırmaz.

Bir canavar ancak **vurulduğunda** karşılık verir, saldırganın peşine düşer
ve bir süre sonra sakinleşip yuvasına döner. Yuvasından fazla uzaklaşırsa
kovalamayı bırakır. Yani harita, sen ilk vuruşu yapana kadar huzurludur.

Ama yalnız da gelmezler: bir canavara vurduğunda **yakınındaki en fazla iki
arkadaşı** kavgaya katılır. Buna karşılık senin her vuruşun **önündeki üç
düşmana birden** değer — arkanda kalana vuramazsın.

Senin savuruşun **tam çevreyi** kapsar — arkandaki de hasar alır. Saldıranlar
ayrıca çepeçevre kuşatmaz: aynı hedefe saldıran canavarlar önünde bir yay
üzerinde hizaya geçer.

## Metin taşları

Metin taşının **canı çok yüksek ama zırhı incedir**: uzun süren, sürekli
vurduğun bir kuşatma olsun diye. Canı azaldıkça **beş dalga** hâlinde ikişer
bekçi çağırır, her dalga bir öncekinden güçlü, sonuncuda **Metin Muhafızı**
çıkar. Kırınca kendine özel eşya bırakır.

## Sunaklar — haritanın boss cismi

Her avlakta bir **sunak** var: haritadaki en iri, altın renkli cisim.

> Ona dokunduğun anda **bölgedeki bütün canavarlar** üstüne gelir.

Bu uyarı **her dalgada tekrarlanır**, yani arada ölüp yeniden doğanlar da
kavgaya katılır. Sunak beş dalga **boss** çıkarır — Sunak Muhafızları, sonuncuda **Sunak
Efendisi**. Her dalga ciddi biçimde güçlenir ve bosslar sıradan canavarın
kat kat üstündedir. Canı devasa, zırhı ince; kırması oyunun en zor işi.

Karşılığı da o kadar: sıradan canavarın **yirmi beş katı deneyim**,
seviyesinin yüz elli katı altın ve **sunağa özel eşya**.

Karşılığında ödülü büyüktür: sıradan bir canavarın **altı katı deneyim**
ve seviyesinin otuz katı altın.

**Denge bir testle kilitli.** 1. seviye Apo, üç canavarın ortasında
hayatta kalmalı, üçünü de öldürmeli ve canının en az %15'i kalmalı.
Formülleri değiştiren biri bu testi düşürürse oyunun oynanabilirliğini
bozmuş demektir.

Iskalama şu an **kapalı** — her vuruş isabet eder. Hesap zinciri
(`Combat.hit_chance`) yerinde duruyor; `Combat.MISS_ENABLED` sabitini
true yapmak isabet sistemini olduğu gibi geri getirir.

## Haritalar

```
Umurca Köyü  ──  Umurca Ovası  ──  Kırklareli Geçidi  ──  Lüleburgaz  ──  Lüleburgaz Ormanı
  güvenli          Sv. 1-4            Sv. 5-8            güvenli           Sv. 9-14
```

Haritalar `data/maps/*.json` içinde tanımlı: sınırlar, doğuş noktası,
NPC'ler, canavar grupları ve geçitler. Geçidin üstüne yürüyünce harita
değişir; seviyen, statların ve EXP'in seninle gelir. **M** tuşu dünya
haritasını açar — gitmediğin bölgeler "? ? ?" olarak kapalı durur.

Yeni harita eklemek kod değil, veri işidir: bir JSON dosyası yazıp
`index.json` listesine adını eklemek yeter.

## Üç ayrı gelişme hattı

| Hat | Nasıl gelir | Nerede görünür |
| --- | --- | --- |
| **Stat puanı** | seviye başına 1 puan, sen dağıtırsın | sol üst panel, **+** düğmeleri |
| **Ustalık** | dövüştükçe kendiliğinden (R1–R30) | sol üst panel |
| **Beceriler** | altınla satın alınır (54 pasif) | **K** |
| **Dönüm noktaları** | sadece oynayarak | **T** |

## Mana, can çalma ve yetenekler

Karakterin artık **manası** var. Altı yetenek:

| Yetenek | Tür | Ne yapar |
| --- | --- | --- |
| Güç Kalkanı | pasif | saldırı gücü ve kritik |
| Savaş Temposu | pasif | saldırı ve hareket hızı |
| Kan Emme | pasif | **can çalma** ve can |
| Kasırga | alan | çevrendeki herkese ağır savuruş |
| Ok Yağmuru | uzak | uzaktaki hedefe ve çevresine |
| Savaş Narası | güçlenme | kısa süre saldırı ve hız fırlar |

**Can çalma** verdiğin hasarın bir kısmını cana çevirir — vuruşun üstünde yeşil bir sayı belirir.

### Kademeler — Metin2 mantığı

```
Seviye 1-20  →  her karakter seviyesinde kazanılan BECERİ PUANI
M1 - M10     →  metin taşlarından düşen KİTAPLAR
Poly         →  sunaklardan çıkan TAŞLAR
```

Her kademe güçte sıçrama yapar: normal seviyenin tavanı ×1.2, M10 ×3.8, **Poly ×7.5**. Poly'ye ulaşmak yaklaşık 85 kitap ve 10 sunak taşı ister — oyunun uzun vadeli hedefi.

Hızlı çubuğun **1-2 numaraları iksirlere ayrılmıştır** (çantandaki en güçlüsü kendiliğinden oraya konur), **3-6** yeteneklerine. İksirler şehirdeki ustalarda ucuz.

## Görünüm

Oyun artık düz karelerden ibaret değil:

- **Her bölgenin kendi rengi var** — Umurca Ovası yeşil bir kır, Ateş Çölü
  turuncu bir kum denizi, Buz Geçidi soğuk mavi bir yayla, Kıyamet Diyarı
  kızıl bir cehennem. Zemin gradyanlı ve dünyaya sabitlenmiş doku
  lekeleriyle kaplı, yürürken akıyormuş gibi görünüyor.
- **Karakterlerin gölgesi, gövdesi ve kafası var**; yürürken hafifçe
  sekiyorlar, baktıkları yöne ince bir kama uzanıyor.
- **Vuruşlar kıvılcım saçıyor.** Kritik vuruşta kamera sarsılıyor ve turuncu
  bir halka patlıyor; delici vuruş mavi, can çalma yeşil kıvılcım veriyor.
- **Metin taşları nabız gibi atıyor**, sunakların çevresinde ters yönde dönen
  iki halka var, portallar dönen yaylarla nefes alıyor.
- **Can barları** türüne göre renkleniyor (oyuncu yeşil, canavar kırmızı,
  boss turuncu, sunak altın) ve boss/sunak barları daha geniş.
- Seviye atlama, ölüm, yetenek ve sunak dalgaları kendi halkalarını çiziyor.

Bütün bu görsellik `shell/` içinde: `zone_theme.gd` renkleri, `effects.gd`
kıvılcım ve sarsıntıyı tutuyor. `core/` bunların hiçbirini bilmiyor.

## Zırh nasıl çalışır

Hasar eskiden `saldırı − zırh` idi. Doğrusal olduğu için geç seviyede zırh
bütün vuruşları 1'e indiriyor, savaş anlamsızlaşıyordu. Artık zırh
**yüzdesel** azaltma yapar ve seviyeyle ölçeklenir:

```
azaltma = zırh / (zırh + 100 + seviye × 12)     tavan %80
```

Aynı zırh değeri üst seviyelerde daha az işe yarar — yani gelişmek zorunludur.
**Delici vuruş** bu azaltmayı tamamen yok sayar.

Ham statların getirisi de **artandır**: VIT 10'ken bir puan 25 can verir,
VIT 60'ken çok daha fazlasını. Puan yatırmak geç seviyede de anlamlı kalır.

## Ustalık — dövüştükçe gelen kalıcı pasifler

Metin2'de eşyayı demirciye götürür, para ve taş verir, tutmasını umarsın.
**Burada gelişen eşya değil, karakterin kendisi.**

- Verdiğin hasar **Silah Ustalığını**, yediğin hasar **Zırh Ustalığını** besler
- Eşik dolunca bir **rütbe** atlarsın (tavan **R30**)
- Her rütbe kalıcı bir pasif açar: saldırı gücü, kritik şansı, **kritik hasarı**,
  delici vuruş, zırh, can, can yenilenme
- Rütbeler **kalıcıdır** — silahını değiştirsen de, ölsen de kaybolmaz

Sol üstteki panelde iki ustalık hattının rütbesi, ilerleme çubuğu ve bir
sonraki rütbenin ne vereceği yazar. Rütbe tablosu `core/mastery.gd` içinde.

## Dönüm noktaları — sadece oynayarak gelen pasifler

**T** tuşundaki istatistik ekranı yalnız sayı göstermiyor; o sayılar
kalıcı bonus da veriyor:

| Hat | Sayaç | Eşik geçince |
| --- | --- | --- |
| Avcı | kesilen canavar | Saldırı gücü +6 |
| Savaşçı | yapılan vuruş | Saldırı hızı +%2 |
| Yolcu | yürünen mesafe | Hareket hızı +0.07 |
| Dayanıklı | yenilen hasar | Zırh +5 |
| Nişancı | kritik vuruş | Kritik hasarı +%4 |

Aynı ekranda toplam verilen/yenilen hasar, ölüm sayısı, kırılan metin taşı,
kazanılan altın ve deneyim, oynama süresi gibi on dokuz sayaç duruyor.

## Beceri ağacı ve para

Canavar kesince ve çantandaki gereksiz eşyayı satınca **altın** kazanırsın.
Altını **K** tuşundaki beceri ağacında harcarsın.

Ustalıktan farkı: ustalık dövüştükçe kendiliğinden gelir, beceriler ise
satın alınır — yani neye yatırım yapacağına sen karar verirsin. Ağaç
önkoşullu: üst dallar ancak alttakini öğrenince açılır, her seviye bir
öncekinden pahalıdır. Beceri listesi `data/skills.json` içinde.

## Eşyalar — beş kuşanma yeri, kademeli

Silah, Zırh, Kask, Kalkan, Ayakkabı. Her slotun bonus **türü sabittir** —
"bunu mu alsam şunu mu" ikilemi yok, tek fark kademe gücü:

| Slot | Verdiği |
| --- | --- |
| Silah | saldırı gücü |
| Zırh / Kask / Kalkan | zırh ve can |
| Ayakkabı | zırh ve hareket hızı |

**Altı kademe** (Sv.1 / 8 / 16 / 26 / 38 / 52). **Aynı eşyadan üç tanesini**
şehirdeki ustaya götürünce bir üst kademeye dönüşür — ganimet hiç boşa
gitmez. Metin taşları ve sunaklar kendilerine özel parçalar bırakır.

Çanta **72 göz**, slot türüne göre bölümlü ve güçlüden zayıfa sıralı.
Kuşandığından güçlü ama henüz takmadığın bir parça varsa satırı **yeşil
yanar ve ▲ ile işaretlenir**. Kısaltılmış her yazının üstüne fareyi
götürünce tamamı bir ipucu kutusunda görünür.

## Şehirdeki ustalar

Bir NPC'yi seçip **Konuş** dediğinde dört iş birden yapılır:

- **İksir al** — can ve mana iksirleri, ucuz
- **Fazlalığı sat** — tek tek ya da "kuşanılmayanları sat"
- **Birleştir** — üç aynı eşya bir üst kademe
- **Özellik öğren** — parayla alınan **24 kalıcı özellik**, zincirleme
  açılır; sıradakini almadan bir sonrakine geçemezsin

## Görevler

**Sol tarafta hep açık bir görev takipçisi var.** Süren görevler ilerleme
çubuğuyla, seviyene uygun yeni görevler **altın çerçeveyle yanıp sönerek**
listelenir — üstüne tıklayınca görev başlar. Bir görev tamamlandığında
ekranın üstünde **"GÖREV TAMAMLANDI"** şeridi belirir ve takipçideki satır
yeşile döner; tıklayınca ödülü alırsın.

**J** tuşu tam defteri açar — NPC'ye gitmeye gerek yok, nerede olursan ol
görev alır, ilerlemeni görür, ödülünü toplarsın. Solda sürenler (ilerleme
çubuklu), sağda alınabilirler. **48 görev**, Sv.1'den Sv.150'ye. Bazıları çok zor ve tamamlandığında
**kalıcı stat bonusu** verir — sunak avcılığı, boss zincirleri, beş yüz
bekçi temizlemek gibi.

Görevler `data/quests.json` içinde. Bir test, her görevin hedefinin
haritalarda gerçekten var olan bir canavar olduğunu doğruluyor — yoksa
asla tamamlanamayan bir görev yazmak çok kolay.

## Stat dağıtımı

Her seviyede **1 stat puanı** kazanırsın ve nereye yatıracağına sen karar
verirsin. Sol üstteki panelde STR / DEX / INT / VIT yanındaki **+**
düğmelerine tıkla. VIT'e yatırdığında kazanılan can anında canına eklenir.

## Kayıt

Oyun kendiliğinden kaydeder: harita değiştiğinde, seviye atladığında,
eşya geliştiğinde, çanta değiştiğinde, her 30 saniyede bir ve **Esc** ile
çıkarken. Oyunu tekrar açtığında kaldığın yerden devam edersin.

Kayıt dosyası (macOS):
`~/Library/Application Support/Godot/app_userdata/Kut/kayit.json`

Baştan başlamak istersen bu dosyayı sil.

> **Geçit tuzağı.** A'dan B'ye geçerken B'deki varış noktası, B'nin geri
> dönüş geçidinin üstüne denk gelirse oyuncu iki harita arasında sonsuza
> kadar savrulur. Bunu elle kontrol etmek yerine bir test yazıldı:
> her varış noktasının her geçitten yeterince uzak olduğunu doğruluyor.

## Telefon

`core/` motor tanımadığı ve bütün mesafeler pikselle değil dünya birimiyle
tutulduğu için mobil desteğin mimari maliyeti **sıfır**. Godot tek projeden
Android ve iOS çıktısı verir. Yapılacak iş tamamen `shell/` içindedir:
dokunmatik saldırı düğmesi ve ekran boyutuna göre ölçeklenen arayüz.
Tıkla-yürü şu an bile telefonda çalışır (Godot dokunuşu fare tıklaması
olarak iletir). Sırası Faz 5, Windows çıktısıyla birlikte.

---

## Yol Haritası

- [x] **Faz 1 — Çekirdek motor.** Proje iskeleti, sabit tick, deterministik RNG,
      tıkla-yürü, saldırı zamanlaması (hazırlık → isabet → toparlanma).
- [x] **Faz 1.5 — Kimlik ve sahne.** Karakter isimleri, varlık türleri
      (oyuncu / NPC / canavar / metin taşı), oyuncuyu takip eden kamera,
      canavarların bölgelerinde dolaşması.
- [x] **Faz 2 — RPG matematiği.** STR/DEX/INT/VIT ve türetilmiş statlar,
      can barları, hasar zinciri (isabet → delici → salınım → kritik),
      EXP eğrisi, seviye atlama, ölüm ve yeniden doğuş, karşılık verme
      yapay zekâsı, hedef seçimi ve komut arayüzü.
- [x] **Faz 2.5 — Haritalar.** Beş bölge, geçitler, bölgeler arası
      geçişte taşınan karakter, dünya haritası ekranı.
- [x] **Faz 3 — Eşya, çanta ve kayıt.** Silah ve zırh, ganimet, 24 gözlü
      çanta, stat dağıtımı, sürü savaşı ve çoklu vuruş, otomatik
      kayıt/yükleme.
- [x] **Faz 3.5 — İlerleme sistemleri.** WASD hareketi, ustalık rütbeleri,
      beceri ağacı ve para, görevler ve dükkân, metin taşı bekçileri,
      seviye kapıları, hizaya geçen düşman grupları.
- [x] **Faz 4 — Derinlik.** WASD ile yürürken vuruş, tam çevre savuruş,
      kendiliğinden hedef değiştirme, 30 rütbelik ustalık, 54 pasif
      beceri, dönüm noktası pasifleri ve istatistik ekranı, on bir
      kuşanma yeri ve 66 eşya, bölümlü envanter, 24 görevlik defter,
      on dalgalı metin taşları, sekiz bölge, grup hâlinde yeniden doğuş.
- [x] **Faz 4.5 — Denge ve derinlik.** Yüzdesel zırh, artan stat getirisi,
      geç seviye denge testi, beş katmanlı kademeli beceri ağacı (full ve
      katman tamamlama ödülleriyle), harita sunakları ve boss dalgaları,
      dağılarak gelen grup doğuşu, haritadan ışınlanma, basılı tutulan
      saldırı.
- [x] **Faz 5 — Yetenekler ve derinlik.** Mana, can çalma, altı yetenek ve
      M/Poly kademeleri, hızlı çubuk, otomatik avlanma, beş slotluk
      kademeli eşya + birleştirme, 60 düğümlük ağaç, 24 zincirleme
      özellik, 48 görev, 16 bölge, bölge bossları, ipucu kutuları.
- [x] **Faz 5.5 — Görsel katman.** Bölge renk temaları, dokulu zemin,
      gölgeli ve animasyonlu karakterler, kıvılcım/halka efektleri,
      kamera sarsıntısı, sol tarafta hep açık görev takipçisi ve
      tamamlandı şeridi.
- [ ] **Faz 6 — Derinleşme.** Eşya bonus roll'u (Metin2'nin rastgele
      bonusları), iksirler ve yığınlanabilir eşyalar, aktif beceriler,
      isabet sisteminin geri açılması, ikinci karakter sınıfı.
- [ ] **Faz 4 — Ağ temeli.** Headless authoritative server, komut/olay protokolü.
- [ ] **Faz 5 — Windows çıktısı.** `.exe` derleme, gerçek oyuncu ortamı testi.
- [ ] **Faz 6 — 3D entegrasyonu.** `shell/` sökülür, `core/` yerinde kalır.

### Faz 5'ten önce konuşulmayacaklar
Veritabanı, hesap/login, chat, lonca, ticaret, binek, kuşatma, ses, animasyon,
sanat. Faz 1'de karakter bir kare, düşman bir kare — bu normaldir.
