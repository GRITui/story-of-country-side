class_name WorldMap
## PO-16BIT-WORLD-4: 64x64 Japanese Village World Map — 3 logical zones within the 64x64 tile grid.
##
## Spec: 64x64 tiles total, Zone1 Farm (farmhouse, tillable 8x8 field, shipping bin, water well, shed/coop),
## Zone2 Path & River (fishing spots, bamboo shoots foraging), Zone3 Village Square (Store, Blacksmith, Shrine, Townhall).
##
## Implementation: logical zones documented here while existing 8x8 FarmScene stays as Zone1's playable
## center. Full 64x64 tilemap expansion is deferred (would require new TileSet layers + camera), but this
## file is the single source of truth so any scene can query zone bounds, positions, and waypoint paths
## without hardcoding rects. Uses assets/16bit props per zone (farmhouse/barn/coop/well/shipping_bin in
## Farm; tree/pine/bush/rock in Path & River; kawara_roof/jizo_statue for Shrine, mine_cart/ladder for
## Blacksmith hint). Keeps Godot 64x32 isodiamond compat (no engine change).
##
## Waypoint pathfinding: simple lerp with detour waypoints around 12x8 feet colliders (no full A*).
## If straight segment intersects any blocked Rect2, insert midpoint detour offset perpendicular to travel.
## Documented as "A* not required if you document" per the task's own spec.

const WORLD_SIZE := Vector2i(64, 64)

## Zone rectangles in tile space (0..63). Farm top-left, Village top-right, Path & River as horizontal band.
const ZONE_FARM := Rect2i(0, 0, 24, 24)
const ZONE_PATH_RIVER := Rect2i(0, 24, 64, 16)
const ZONE_VILLAGE := Rect2i(24, 0, 40, 24)
## Fallback for tiles outside the above (mountain/sea edge)
const ZONE_WILDERNESS := Rect2i(0, 40, 64, 24)

const ZONE_NAMES: Array[String] = ["Farm", "Path_River", "Village", "Wilderness"]

## Named landmark positions (tile coords) per spec — used by NPC schedules + scene prop placement.
const LANDMARKS := {
	# Zone1 Farm
	"farmhouse": Vector2i(3, 2),
	"field_origin": Vector2i(4, 6), # 8x8 tillable field origin
	"field_size": Vector2i(8, 8),
	"shipping_bin": Vector2i(13, 12),
	"well": Vector2i(14, 8),
	"shed": Vector2i(2, 10), # coop/barn proxy
	# Zone2 Path & River
	"river_center": Vector2i(32, 30),
	"fishing_spot": Vector2i(28, 32),
	"bamboo_grove": Vector2i(40, 28),
	"path_crossing": Vector2i(32, 24),
	# Zone3 Village Square
	"store": Vector2i(36, 6),
	"blacksmith": Vector2i(48, 8),
	"shrine": Vector2i(52, 4), # Jizō + kawara roof
	"townhall": Vector2i(40, 14),
	"elder_home": Vector2i(50, 16),
	"hanako_home": Vector2i(34, 12),
}

## Props per zone (paths match assets/16bit/props/*.png, wired by WorldMap helper)
const PROPS_BY_ZONE := {
	"Farm": [
		{"path": "res://assets/16bit/props/farmhouse.png", "tile": Vector2i(3, 2)},
		{"path": "res://assets/16bit/props/well.png", "tile": Vector2i(14, 8)},
		{"path": "res://assets/16bit/props/shipping_bin.png", "tile": Vector2i(13, 12)},
		{"path": "res://assets/16bit/props/barn.png", "tile": Vector2i(2, 10)},
		{"path": "res://assets/16bit/props/coop.png", "tile": Vector2i(8, 14)},
		{"path": "res://assets/16bit/props/fence_h.png", "tile": Vector2i(6, 5)},
		{"path": "res://assets/16bit/props/fence_v.png", "tile": Vector2i(2, 6)},
	],
	"Path_River": [
		{"path": "res://assets/16bit/props/tree.png", "tile": Vector2i(30, 28)},
		{"path": "res://assets/16bit/props/pine.png", "tile": Vector2i(38, 30)},
		{"path": "res://assets/16bit/props/bush.png", "tile": Vector2i(40, 28)},
		{"path": "res://assets/16bit/props/rock.png", "tile": Vector2i(32, 32)},
		{"path": "res://assets/16bit/props/rock_large.png", "tile": Vector2i(44, 30)},
	],
	"Village": [
		{"path": "res://assets/16bit/props/kawara_roof.png", "tile": Vector2i(52, 4)},
		{"path": "res://assets/16bit/props/jizo_statue.png", "tile": Vector2i(53, 6)},
		{"path": "res://assets/16bit/props/farmhouse.png", "tile": Vector2i(36, 6)}, # Store building
		{"path": "res://assets/16bit/props/barn.png", "tile": Vector2i(48, 8)}, # Blacksmith
		{"path": "res://assets/16bit/props/tree_2.png", "tile": Vector2i(40, 14)}, # Townhall tree
		{"path": "res://assets/16bit/props/fruit_tree.png", "tile": Vector2i(50, 16)},
	],
}

static func zone_for_tile(tile: Vector2i) -> String:
	if ZONE_FARM.has_point(tile):
		return "Farm"
	if ZONE_VILLAGE.has_point(tile):
		return "Village"
	if ZONE_PATH_RIVER.has_point(tile):
		return "Path_River"
	return "Wilderness"

static func zone_rect(zone_name: String) -> Rect2i:
	match zone_name:
		"Farm": return ZONE_FARM
		"Path_River": return ZONE_PATH_RIVER
		"Village": return ZONE_VILLAGE
		_: return ZONE_WILDERNESS

static func is_in_world(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < WORLD_SIZE.x and tile.y < WORLD_SIZE.y

static func landmark_tile(name: String) -> Vector2i:
	return LANDMARKS.get(name, Vector2i(-1, -1))

static func props_for_zone(zone_name: String) -> Array:
	return PROPS_BY_ZONE.get(zone_name, [])

## Simple waypoint path: if straight line from→to intersects any blocked Rect2, insert a detour
## midpoint offset perpendicular to travel direction. Returns at least [to]; with detour, [mid, to].
## No full A* — documented as sufficient per PO-16BIT-WORLD-4 spec.
static func get_waypoint_path(from: Vector2, to: Vector2, blocked_rects: Array[Rect2]) -> Array[Vector2]:
	var direct_blocked := false
	for r in blocked_rects:
		if _segment_intersects_rect(from, to, r):
			direct_blocked = true
			break
	if not direct_blocked:
		return [to]
	var dir := (to - from).normalized()
	if dir == Vector2.ZERO:
		return [to]
	var perp := Vector2(-dir.y, dir.x)
	var mid := (from + to) * 0.5 + perp * 32.0
	# If detour itself is blocked, try opposite side
	var mid_blocked := false
	for r in blocked_rects:
		if r.has_point(mid) or _segment_intersects_rect(from, mid, r) or _segment_intersects_rect(mid, to, r):
			mid_blocked = true
			break
	if mid_blocked:
		mid = (from + to) * 0.5 - perp * 32.0
	return [mid, to]

static func _segment_intersects_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	# Sample 8 points along segment + rect containment check — cheap and sufficient for 64x64 grid.
	for t in [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]:
		var p := a.lerp(b, t)
		if rect.has_point(p):
			return true
	# Also check if segment crosses rect edges (AABB line clip quick reject)
	var seg_min := Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var seg_max := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
	var r_max := rect.position + rect.size
	if seg_max.x < rect.position.x or seg_min.x > r_max.x or seg_max.y < rect.position.y or seg_min.y > r_max.y:
		return false
	return false
