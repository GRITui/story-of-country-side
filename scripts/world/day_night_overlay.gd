extends CanvasLayer
class_name DayNightOverlay
## PO-16BIT-GFX-2 Day/Night LUT overlay — ColorRect + CanvasModulate driven by TimeManager.hour.
## 4 keys: 06 warm amber, 10 crisp, 17 vermilion, 20 indigo + lantern. Lerp per hour.
## Minimal, deterministic, no shader. Add as child of any world scene top layer (Canopy→Weather/DayNight).
##
## Layer order: Ground→Tilled/Watered Overlay→Y-sorted Entities (DynamicLayer)→Canopy→Weather/DayNight overlay (this).

const LUT := {
	6: {"mod": Color(1.10, 0.98, 0.84), "overlay": Color(1.0, 0.92, 0.60, 0.08)},
	10: {"mod": Color(1.0, 1.0, 1.0), "overlay": Color(1.0, 1.0, 1.0, 0.0)},
	17: {"mod": Color(1.12, 0.88, 0.62), "overlay": Color(1.0, 0.62, 0.32, 0.14)},
	20: {"mod": Color(0.72, 0.78, 1.10), "overlay": Color(0.32, 0.38, 0.68, 0.22)},
}

var _modulate: CanvasModulate
var _overlay: ColorRect

func _ready() -> void:
	layer = 10
	_modulate = CanvasModulate.new()
	_modulate.color = Color.WHITE
	add_child(_modulate)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fill viewport — anchored full rect
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_overlay)
	if TimeManager:
		TimeManager.minute_passed.connect(_on_minute)
		_apply_for_hour(TimeManager.hour)
	else:
		_apply_for_hour(10)

func _on_minute(hour: int, _minute: int) -> void:
	_apply_for_hour(hour)

func _apply_for_hour(hour: int) -> void:
	var c := _lut_for_hour(hour)
	_modulate.color = c["mod"]
	_overlay.color = c["overlay"]
	# Lantern points after 19h — slightly brighten modulate center via overlay alpha already; no extra nodes

func _lut_for_hour(hour: int) -> Dictionary:
	# Exact keys return directly; otherwise lerp between nearest keys circular 6→10→17→20→6(next day)
	var keys: Array = LUT.keys()
	keys.sort()
	if LUT.has(hour):
		return LUT[hour]
	# Find lower/upper
	var lower := keys[0]
	var upper := keys[0]
	for k in keys:
		if k <= hour:
			lower = k
		if k > hour:
			upper = k
			break
	else:
		# hour beyond last key (e.g. 22) -> wrap to first key next day
		upper = keys[0] + 24
	# Handle wrap where upper < lower (e.g. hour 0-5)
	if hour < keys[0]:
		lower = keys[keys.size() - 1] - 24
		upper = keys[0]
	var span := float(upper - lower)
	var t := 0.0 if span == 0 else float(hour - lower) / span
	var lo: Dictionary = LUT[lower if LUT.has(lower) else keys[0] if hour < keys[0] else lower]
	# When lower is wrapped negative, map back
	if not LUT.has(lower):
		# wrapped lower (e.g. 20-24 = -4) -> use last key
		lo = LUT[keys[keys.size() - 1]]
	var hi: Dictionary = LUT[upper if LUT.has(upper) else keys[0]]
	return {
		"mod": lo["mod"].lerp(hi["mod"], t),
		"overlay": lo["overlay"].lerp(hi["overlay"], t),
	}

## Public getter for tests / verification — returns current modulate color.
func get_modulate_color() -> Color:
	return _modulate.color if _modulate else Color.WHITE

func get_overlay_color() -> Color:
	return _overlay.color if _overlay else Color(0,0,0,0)

## Static helper for headless/deterministic tests without scene tree.
static func lut_for_hour_static(hour: int) -> Dictionary:
	var tmp := DayNightOverlay.new()
	var res := tmp._lut_for_hour(hour)
	tmp.free()
	return res
