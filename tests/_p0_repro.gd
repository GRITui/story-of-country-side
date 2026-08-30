extends Node
## TEMP P0 repro: drives the real TitleScreen New Game flow and observes
## whether Main boots, whether start_game() ever runs, and whether the
## Farm HUD appears. DELETE AFTER USE.

func _d(tag: String, val: Variant) -> void:
	print("[P0] %-28s => %s" % [tag, str(val)])

func _ready() -> void:
	SaveManager.delete_save_file()
	print("############ P0 REPRO ############")
	_d("root class", get_tree().get_root().get_class())
	_d("root has_method(start_game)", get_tree().get_root().has_method("start_game"))
	_d("root name", get_tree().get_root().name)

	var title: Node = load("res://scenes/ui/TitleScreen.tscn").instantiate()
	add_child(title)
	get_tree().current_scene = title
	print("=== title _ready ran; continue button ready. current_scene=", _s(get_tree().current_scene))
	_d("TimeManager frozen reasons", TimeManager._freeze_reasons)

	# Exactly what the NewGameButton.pressed handler does:
	title.call("_on_new_game_pressed")
	_d("after _on_new_game_pressed current_scene", _s(get_tree().current_scene))

	# change_scene_to_file is deferred to end of current frame
	await get_tree().process_frame
	await get_tree().process_frame
	_d("after 2 process frames current_scene", _s(get_tree().current_scene))
	var mc: Node = get_tree().current_scene
	if is_instance_valid(mc):
		_d("mc class", mc.get_class())
		_d("mc has_method(start_game)", mc.has_method("start_game"))
	_d("root has_method(start_game) now", get_tree().get_root().has_method("start_game"))
	_d("TimeManager frozen reasons", TimeManager._freeze_reasons)

	# Wait past the 0.1s timer (repeat is 0.1s forever)
	await get_tree().create_timer(0.4).timeout
	_d("after 0.4s (past timer) Main children", mc.get_children() if is_instance_valid(mc) else "INVALID")
	for c: Node in (mc.get_children() if is_instance_valid(mc) else []):
		if c.has_method("is_finished"):
			_d("intro present? finished", c.is_finished())
			if c.has_method("current_line"):
				_d("intro current_line", c.current_line())
	print("############ P0 REPRO DONE ############")
	get_tree().quit()

func _s(n: Node) -> String:
	return n.name + " (" + n.get_class() + ")" if is_instance_valid(n) else "INVALID"