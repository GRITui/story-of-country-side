extends Node
class_name SleepSystem
## Orchestrates the sleep/day-skip flow: confirmation overlay → fade-out
## → advance day → fade-in → morning notification.  Instantiated by
## MainController and connected to a SleepZone's sleep_initiated signal.

var _fade_transition: FadeTransition
var _morning_notification: MorningNotification

func start_sleep() -> void:
	var overlay: SleepOverlay = load("res://scenes/ui/SleepOverlay.tscn").instantiate()
	get_tree().current_scene.add_child(overlay)
	overlay.closed.connect(_on_overlay_closed)

func _on_overlay_closed(sleep_confirmed: bool) -> void:
	if not sleep_confirmed:
		return
	_show_fade_transition()

func _show_fade_transition() -> void:
	_fade_transition = load("res://scenes/ui/FadeTransition.tscn").instantiate()
	get_tree().current_scene.add_child(_fade_transition)
	_fade_transition.faded_in.connect(_on_faded_in)
	_fade_transition.fade_in()

func _on_faded_in() -> void:
	TimeManager.advance_day()
	_fade_transition.fade_out()
	_fade_transition.faded_out.connect(_on_faded_out)

func _on_faded_out() -> void:
	_show_morning_notification()

func _show_morning_notification() -> void:
	_morning_notification = load("res://scenes/ui/MorningNotification.tscn").instantiate()
	# #110: advance_day() already fired day_started, so RelationshipManager has
	# derived today's birthday (if any) by the time the banner shows.
	_morning_notification.birthday_npc = RelationshipManager.get_birthday_npc_today()
	get_tree().current_scene.add_child(_morning_notification)
	_morning_notification.finished.connect(_on_morning_notification_finished)

func _on_morning_notification_finished() -> void:
	_morning_notification = null
