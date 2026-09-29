class_name ZoneTheme
extends RefCounted

## Her bölgenin kendi rengi var. Aynı kareler ve çizgiler, ama Umurca
## Ovası yeşil bir kır, Ateş Çölü turuncu bir kum denizi, Buz Geçidi
## soğuk mavi bir yayla gibi görünsün diye.

const DEFAULT := {
	"bg": Color(0.07, 0.085, 0.10),
	"bg2": Color(0.10, 0.12, 0.14),
	"grid": Color(1.0, 1.0, 1.0, 0.045),
	"accent": Color(0.55, 0.70, 0.85),
	"ground": Color(0.13, 0.17, 0.14),
	"detail": Color(0.30, 0.42, 0.30, 0.55),
}

const THEMES := {
	"umurca_koyu": {"bg": Color(0.08, 0.11, 0.09), "bg2": Color(0.12, 0.16, 0.12),
		"accent": Color(0.55, 0.85, 0.55), "ground": Color(0.14, 0.20, 0.14),
		"detail": Color(0.35, 0.55, 0.35, 0.5)},
	"umurca_ovasi": {"bg": Color(0.07, 0.11, 0.08), "bg2": Color(0.11, 0.17, 0.11),
		"accent": Color(0.50, 0.82, 0.48), "ground": Color(0.13, 0.21, 0.13),
		"detail": Color(0.32, 0.58, 0.30, 0.5)},
	"kirklareli_gecidi": {"bg": Color(0.10, 0.09, 0.07), "bg2": Color(0.15, 0.13, 0.10),
		"accent": Color(0.82, 0.68, 0.45), "ground": Color(0.19, 0.16, 0.12),
		"detail": Color(0.48, 0.40, 0.28, 0.5)},
	"luleburgaz": {"bg": Color(0.09, 0.10, 0.12), "bg2": Color(0.13, 0.15, 0.18),
		"accent": Color(0.65, 0.75, 0.90), "ground": Color(0.16, 0.18, 0.21),
		"detail": Color(0.38, 0.44, 0.52, 0.5)},
	"luleburgaz_ormani": {"bg": Color(0.05, 0.09, 0.07), "bg2": Color(0.08, 0.14, 0.10),
		"accent": Color(0.40, 0.78, 0.50), "ground": Color(0.09, 0.17, 0.11),
		"detail": Color(0.22, 0.48, 0.28, 0.6)},
	"vize_kalesi": {"bg": Color(0.10, 0.10, 0.11), "bg2": Color(0.15, 0.15, 0.17),
		"accent": Color(0.75, 0.75, 0.80), "ground": Color(0.18, 0.18, 0.20),
		"detail": Color(0.42, 0.42, 0.46, 0.5)},
	"vize_harabeleri": {"bg": Color(0.09, 0.08, 0.11), "bg2": Color(0.14, 0.12, 0.17),
		"accent": Color(0.72, 0.58, 0.88), "ground": Color(0.16, 0.14, 0.20),
		"detail": Color(0.40, 0.33, 0.50, 0.5)},
	"ejder_vadisi": {"bg": Color(0.12, 0.07, 0.06), "bg2": Color(0.18, 0.10, 0.08),
		"accent": Color(0.92, 0.48, 0.35), "ground": Color(0.22, 0.12, 0.10),
		"detail": Color(0.55, 0.28, 0.22, 0.5)},
	"ates_kalesi": {"bg": Color(0.13, 0.08, 0.05), "bg2": Color(0.19, 0.12, 0.07),
		"accent": Color(0.98, 0.62, 0.30), "ground": Color(0.24, 0.15, 0.09),
		"detail": Color(0.60, 0.36, 0.18, 0.5)},
	"ates_colu": {"bg": Color(0.14, 0.10, 0.05), "bg2": Color(0.21, 0.15, 0.08),
		"accent": Color(1.00, 0.72, 0.35), "ground": Color(0.27, 0.19, 0.10),
		"detail": Color(0.66, 0.46, 0.22, 0.5)},
	"buz_gecidi": {"bg": Color(0.06, 0.09, 0.13), "bg2": Color(0.09, 0.14, 0.20),
		"accent": Color(0.55, 0.82, 1.00), "ground": Color(0.11, 0.17, 0.24),
		"detail": Color(0.32, 0.52, 0.70, 0.5)},
	"kuzey_kalesi": {"bg": Color(0.07, 0.10, 0.13), "bg2": Color(0.11, 0.15, 0.20),
		"accent": Color(0.70, 0.88, 1.00), "ground": Color(0.13, 0.19, 0.25),
		"detail": Color(0.38, 0.56, 0.72, 0.5)},
	"buz_magarasi": {"bg": Color(0.05, 0.08, 0.12), "bg2": Color(0.08, 0.12, 0.19),
		"accent": Color(0.62, 0.90, 1.00), "ground": Color(0.10, 0.15, 0.23),
		"detail": Color(0.28, 0.48, 0.68, 0.55)},
	"golge_vadisi": {"bg": Color(0.07, 0.05, 0.10), "bg2": Color(0.11, 0.08, 0.16),
		"accent": Color(0.70, 0.50, 0.95), "ground": Color(0.13, 0.10, 0.19),
		"detail": Color(0.36, 0.26, 0.52, 0.55)},
	"kadim_sehir": {"bg": Color(0.09, 0.08, 0.10), "bg2": Color(0.14, 0.12, 0.16),
		"accent": Color(0.90, 0.80, 0.55), "ground": Color(0.17, 0.15, 0.19),
		"detail": Color(0.46, 0.40, 0.30, 0.5)},
	"kiyamet_diyari": {"bg": Color(0.11, 0.04, 0.05), "bg2": Color(0.17, 0.07, 0.07),
		"accent": Color(1.00, 0.35, 0.30), "ground": Color(0.20, 0.09, 0.09),
		"detail": Color(0.52, 0.20, 0.18, 0.55)},
}


static func of(map_id: String) -> Dictionary:
	var t := DEFAULT.duplicate()
	if THEMES.has(map_id):
		for k in (THEMES[map_id] as Dictionary).keys():
			t[k] = (THEMES[map_id] as Dictionary)[k]
	return t
