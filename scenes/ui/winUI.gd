extends Control

const NORMAL_SCALE_X = 130.0
const HOVER_SCALE_X = 150.0
const LERP_SPEED = 12.0


func _process(delta):
	var target_x = HOVER_SCALE_X if $CanvasLayer/HBoxContainer/VBoxContainer/playAgain.is_hovered() else NORMAL_SCALE_X
	$CanvasLayer/HBoxContainer/VBoxContainer/playAgain.custom_minimum_size.x = lerp($CanvasLayer/HBoxContainer/VBoxContainer/playAgain.custom_minimum_size.x, target_x, delta * LERP_SPEED)

func _on_play_again_pressed() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	get_tree().root.add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	overlay.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func():
		overlay.size = get_viewport().get_visible_rect().size
	)
	
	canvas.add_child(overlay)
	var tween = canvas.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 2) 
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/playUi.tscn")
	)
	tween.tween_interval(0.4) 
	tween.tween_property(overlay, "color:a", 0.0, 0.5) 
	tween.tween_callback(canvas.queue_free)
