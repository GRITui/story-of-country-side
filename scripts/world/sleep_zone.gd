extends Node2D
class_name SleepZone
## Interaction zone that lets the player skip to the next morning.
## Place in a world scene (e.g. FarmScene) near a "bed" visual.
## When the player is in the zone and presses the interact action,
## shows a confirmation dialog and, on confirm, advances the day.

signal sleep_initiated

## Set by player collision or directly in tests.
var is_player_in_zone: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_player_in_zone:
		sleep_initiated.emit()
		get_viewport().set_input_as_handled()

## Area2D collision hook -- wire body_entered/body_exited to these
## when a CharacterBody2D player exists.
func _on_body_entered(_body: Node2D) -> void:
	is_player_in_zone = true

func _on_body_exited(_body: Node2D) -> void:
	is_player_in_zone = false
