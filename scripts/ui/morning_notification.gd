extends CanvasLayer
class_name MorningNotification
## Brief "Good morning!" HUD notification after a day-skip fades back in.
## Shows "Day [N], [Season]" for DISPLAY_SECONDS then fades out.

signal finished

const DISPLAY_SECONDS := 2.0
const FADE_SECONDS := 0.5

@onready var _label: Label = $Margin/Label

func _ready() -> void:
	_label.text = "Good morning!\nDay %d, %s" % [TimeManager.day_in_season, TimeManager.current_season()]
	var timer := get_tree().create_timer(DISPLAY_SECONDS)
	timer.timeout.connect(_fade_out)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(_on_faded)

func _on_faded() -> void:
	finished.emit()
	queue_free()
