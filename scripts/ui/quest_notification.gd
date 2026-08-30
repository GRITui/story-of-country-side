extends CanvasLayer
class_name QuestNotification
## Polished HUD notification for quest completion.
## Fades in, displays title + reward, then fades out.

signal finished

const DISPLAY_SECONDS := 3.0
const FADE_SECONDS := 0.5

@onready var _label: Label = $Margin/Label

func _ready() -> void:
	_label.modulate.a = 0.0
	_fade_in()

func show_quest(title: String, reward: String) -> void:
	_label.text = "Quest Completed!\n%s\n\nReward: %s" % [title, reward]

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(_on_faded)

func _on_faded() -> void:
	finished.emit()
	queue_free()

func start_timer() -> void:
	var timer := get_tree().create_timer(DISPLAY_SECONDS)
	timer.timeout.connect(_fade_out)
