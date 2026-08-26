extends CanvasLayer
class_name FadeTransition
## Full-screen black fade used by SleepSystem for the sleep transition.
## Call fade_in() then advance day, then fade_out().

signal faded_in
signal faded_out

func _ready() -> void:
	_color_rect.modulate.a = 0.0

@onready var _color_rect: ColorRect = $ColorRect

func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 1.0, 0.5)
	tween.tween_callback(faded_in.emit)

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(faded_out.emit)
