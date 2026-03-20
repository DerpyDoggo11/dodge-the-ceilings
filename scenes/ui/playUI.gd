extends Node

const NORMAL_SCALE_X = 130.0
const HOVER_SCALE_X = 150.0
const LERP_SPEED = 12.0

@onready var difficulty1 = $CanvasLayer/HBoxContainer/VBoxContainer/VBoxContainer/difficulty1
@onready var difficulty2 = $CanvasLayer/HBoxContainer/VBoxContainer/VBoxContainer/difficulty2
@onready var difficulty3 = $CanvasLayer/HBoxContainer/VBoxContainer/VBoxContainer/difficulty3
var buttons = []
var is_loading = false

func _ready():
	buttons = [difficulty1, difficulty2, difficulty3]

func _process(delta):
	if is_loading:
		return
	for button in buttons:
		var target_x = HOVER_SCALE_X if button.is_hovered() else NORMAL_SCALE_X
		button.custom_minimum_size.x = lerp(button.custom_minimum_size.x, target_x, delta * LERP_SPEED)
func _load_game(difficulty: int):
	if is_loading:
		return
	is_loading = true
	Globals.difficulty = difficulty
 
	var vp_size = get_viewport().get_visible_rect().size
 
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.size = vp_size
	get_viewport().size_changed.connect(func():
		overlay.size = get_viewport().get_visible_rect().size
	)
 
	var spinner = TextureRect.new()
	if difficulty == 1:
		spinner.texture = preload("res://assets/ceiling.png")
	elif difficulty == 2:
		spinner.texture = preload("res://assets/angyCeiling.png")
	elif difficulty == 3:
		spinner.texture = preload("res://assets/SUPERangyCeiling.png")
	spinner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spinner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var spinner_size = Vector2(200, 200)
	spinner.custom_minimum_size = spinner_size
	spinner.size = spinner_size
	spinner.position = vp_size - spinner_size - Vector2(50, 50)
	spinner.pivot_offset = spinner_size / 2.0
	spinner.modulate.a = 0.0
	overlay.add_child(spinner)
 
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)
 
	var tween = canvas.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		spinner.modulate.a = 1.0
		var spin_tween = canvas.create_tween()
		spin_tween.set_loops()
		spin_tween.tween_property(spinner, "rotation", TAU, 2.5).from(0.0)

		Globals.started = true
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main.tscn")
 
		var fade_tween = canvas.create_tween()
		fade_tween.tween_interval(0.3)
		fade_tween.tween_property(overlay, "color:a", 0.0, 0.5)
		fade_tween.parallel().tween_property(spinner, "modulate:a", 0.0, 0.5)
		fade_tween.tween_callback(func():
			spin_tween.kill()
			canvas.queue_free()
		)
	)

func _on_difficulty_1_pressed() -> void:
	_load_game(1)
func _on_difficulty_2_pressed() -> void:
	_load_game(2)
func _on_difficulty_3_pressed() -> void:
	_load_game(3)
func _on_difficulty_3_mouse_entered() -> void:
	pass
