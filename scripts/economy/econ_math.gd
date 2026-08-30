class_name EconMath
extends RefCounted
## Pure, stateless economic math — no autoload access, no signals.
## Everything is a static function of its explicit inputs, so the same
## formula can run headless (tests, balancing sims, server preview) and
## in-game. All tuned constants live here; managers consume the results.
##
## @balance-sheet 2026 — canonical constants:
##   stamina budget    100/day (full restore on sleep)
##   day               06:00-24:00, 1 real sec = 1 in-game min
##   quality           1.0 / 1.25 / 1.5  (normal / silver / gold)
##   iron tools        ~600g, gold tools ~2200g
##   house expansion   10000g (optimal-path day ~17, casual ~day 22)

# ----------------------------------------------------------------------
# Leveling / curve multipliers
# ----------------------------------------------------------------------

## XP required to advance FROM `level` (1-based) to level+1.
## Growth 1.5 = gentle super-linear: L1->2 = 100, L4->5 = 800, L9->10 ~2617.
static func xp_to_next(level: int, base_xp: int = 100, growth: float = 1.5) -> int:
	return ceili(float(base_xp) * pow(float(maxi(level, 1)), growth))

## Generic normalized ease curve for tuning knobs.
## t in [0,1] -> [0,1]; e.g. curve_mult(0.5, 0.0, 2.0) -> 0.25.
static func curve_mult(t: float, min_out: float, exponent: float, max_out: float = 1.0) -> float:
	var n := clampf(t, 0.0, 1.0)
	return clampf(min_out + (max_out - min_out) * pow(n, exponent), min_out, max_out)

## Relationship: 1 heart = 50 friendship points (max 10 hearts).
const POINTS_PER_HEART := 50
const MAX_HEARTS := 10

static func hearts_from_points(points: int) -> int:
	return clampi(points / POINTS_PER_HEART, 0, MAX_HEARTS)

static func heart_progress(points: int) -> float:
	## 0.0..1.0 progress toward the *next* heart (or 1.0 at max hearts).
	if hearts_from_points(points) >= MAX_HEARTS:
		return 1.0
	return float(points % POINTS_PER_HEART) / float(POINTS_PER_HEART)

# ----------------------------------------------------------------------
# Stamina economy
# ----------------------------------------------------------------------

## Tool stamina cost per action with tier decay:
## cost(t) = max(min_cost, round(base - t * decay))
##   hoe       base 3, decay 0.6, min 2  -> 3 / 2 / 2
##   water     base 2, decay 0.5, min 1  -> 2 / 2 / 1
##   axe       base 5, decay 1.0, min 3  -> 5 / 4 / 3
##   pickaxe   base 5, decay 1.0, min 3  -> 5 / 4 / 3
##   scythe    base 2, decay 0.6, min 1  -> 2 / 1 / 1
##   sow (flat)                          -> 1
static func tool_stamina_cost(tier: int, base: int, decay: float, min_cost: int) -> int:
	return maxi(min_cost, roundi(float(base) - float(tier) * decay))

## Tiles covered per action at tier, optional cap (mining/chopping cap at 3
## so AOE never outscales farming tools).
static func aoe_tiles(tier: int, step: int, cap: int = 0) -> int:
	var tiles := 1 + step * maxi(tier, 0)
	return mini(tiles, cap) if cap > 0 else tiles

## Stamina consumed per *tile* (cost / coverage) — the number that actually
## matters for farm-sizing math.
static func stamina_per_tile(tier: int, base: int, decay: float, min_cost: int, step: int, cap: int = 0) -> float:
	var per_action := float(tool_stamina_cost(tier, base, decay, min_cost))
	var coverage := float(aoe_tiles(tier, step, cap))
	return per_action / coverage

## Gold opportunity value of one stamina point. Tuned so early staples sit at
## ~2.5-3 g/st and the house expansion lands ~day 17 optimal-path.
const STAMINA_GOLD_RATE := 2.0

# ----------------------------------------------------------------------
# Crop growth & profit
# ----------------------------------------------------------------------

## Per-season growth modifier (Showa satoyama climate):
##   Spring 1.00, Summer 0.95 (warm, fastest), Fall 1.10, Winter 1.25.
static func season_growth_mult(season: String) -> float:
	match season:
		"Spring":
			return 1.00
		"Summer":
			return 0.95
		"Fall":
			return 1.10
		"Winter":
			return 1.25
		_:
			return 1.00

## Growth days: stages scaled by soil and season, +1 day per missed watering.
##   soil_mult: basic 1.0, fertilized 0.92, rich 0.85 (soil accelerates *stages*)
##   season_mult: see season_growth_mult()
##   water stalls: each missed watering adds 1 full day, never shortens.
static func growth_days(
	base_days: int, soil_mult: float, missed_water_days: int, season_mult: float = 1.0,
) -> int:
	var stages := float(base_days) * clampf(soil_mult, 0.5, 1.0) * clampf(season_mult, 0.5, 1.5)
	return ceili(stages) + maxi(missed_water_days, 0)

## Quality roll from a [0,1) uniform roll. Deterministic, so seeding with a
## tile hash gives stable per-tile harvest quality.
##   soil_grade: 0 basic / 1 fertilized / 2 rich
##   skill: Farming level 0-20, shifts silver->gold.
static func quality_from_roll(roll: float, soil_grade: int, skill_level: int) -> String:
	var gold_p := clampf(0.05 + 0.05 * soil_grade + 0.005 * skill_level, 0.0, 0.5)
	var silver_p := clampf(0.25 + 0.10 * soil_grade - 0.01 * skill_level, 0.0, 0.8)
	var normal_p := 1.0 - gold_p - silver_p
	if roll < normal_p:
		return "normal"
	if roll < normal_p + silver_p:
		return "silver"
	return "gold"

## Expected sell multiplier given soil grade + skill (before market swings).
static func expected_quality_mult(soil_grade: int, skill_level: int) -> float:
	var gold_p := clampf(0.05 + 0.05 * soil_grade + 0.005 * skill_level, 0.0, 0.5)
	var silver_p := clampf(0.25 + 0.10 * soil_grade - 0.01 * skill_level, 0.0, 0.8)
	return 1.0 + 0.25 * silver_p + 0.50 * gold_p

## Net profit for one tile, one cycle, with labor cost (stamina converted to
## gold at the opportunity rate) and quality + skill sell multipliers.
static func net_profit(
	base_price: int, quality_mult: float, skill_sell_mult: float, yield_per_tile: int,
	seed_cost: int, stamina_per_tile: float, stamina_gold_rate: float = STAMINA_GOLD_RATE,
) -> float:
	var revenue := float(base_price) * quality_mult * skill_sell_mult * float(yield_per_tile)
	return revenue - float(seed_cost) - stamina_per_tile * stamina_gold_rate

# ----------------------------------------------------------------------
# Market price fluctuation (deterministic per item+day, no RNG state)
# ----------------------------------------------------------------------

## Amplitude by category. Crops swing least (predictable staples); forage and
## fish swing most (encourage opportunistic selling).
static func _category_amplitude(category: String) -> float:
	match category:
		"crop": return 0.08
		"artisan": return 0.10
		"mineral": return 0.12
		"fish": return 0.15
		"forage": return 0.20
		_:
			return 0.08

static func _stable_rand(seed_a: int, seed_b: String) -> float:
	var h := absi(hash(seed_b)) ^ (seed_a * 2654435761)
	return float(h % 10000) / 10000.0

## Daily sell multiplier: smooth sine (12-day period, per-item phase) + small
## deterministic noise, clamped to [0.85, 1.25]. Same item+day always returns
## the same value, so saves and replays stay consistent.
static func market_price_mult(item_id: String, day: int, category: String = "crop") -> float:
	var amp := _category_amplitude(category)
	var phase := float(absi(hash(item_id)) % 360)
	var wave := sin((float(day) / 12.0 + phase / 360.0) * TAU)
	var noise := lerpf(-0.03, 0.03, _stable_rand(day, item_id))
	return clampf(1.0 + amp * wave + noise, 0.85, 1.25)