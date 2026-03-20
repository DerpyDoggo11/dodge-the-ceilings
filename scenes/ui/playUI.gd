extends Node

const NORMAL_SCALE_X = 130.0
const HOVER_SCALE_X = 150.0
const LERP_SPEED = 12.0

@onready var difficulty1 = $CanvasLayer/HBoxContainer/VBoxContainer/VBoxContainer/difficulty1
@onready var difficulty2 = $CanvasLayer/HBoxContainer/VBoxContainer/VBoxContainer/difficulty2
@onready var difficulty3 = $CanvasLayer/HBoxContainer/VBoxContainer/VBoxContainer/difficulty3

var buttons = []

func _ready():
	buttons = [difficulty1, difficulty2, difficulty3]

func _process(delta):
	for button in buttons:
		var is_hovered = button.is_hovered()
		var target_x = HOVER_SCALE_X if is_hovered else NORMAL_SCALE_X
		button.custom_minimum_size.x = lerp(button.custom_minimum_size.x, target_x, delta * LERP_SPEED)
		
func _load_game(difficulty: int):
	Globals.difficulty = difficulty
	
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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
	spinner.position = overlay.size - spinner_size - Vector2(50, 50)
	spinner.pivot_offset = spinner_size / 2.0
	spinner.modulate.a = 0.0
	
	
	overlay.add_child(spinner)

	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)

	var tween = get_tree().create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		spinner.modulate.a = 1.0

		var spin_tween = canvas.create_tween()
		spin_tween.set_loops()
		spin_tween.tween_property(spinner, "rotation", TAU, 2.5).from(0.0)

		ResourceLoader.load_threaded_request("res://scenes/Main/Main.tscn")

		var timer = Timer.new()
		canvas.add_child(timer)
		timer.wait_time = 0.05
		timer.timeout.connect(func():
			var status = ResourceLoader.load_threaded_get_status("res://scenes/Main/Main.tscn")
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				timer.stop()
				var scene = ResourceLoader.load_threaded_get("res://scenes/Main/Main.tscn")
				get_tree().call_deferred("change_scene_to_packed", scene)

				var state = { "elapsed": 0.0 }
				var fade_time = 0.5
				var dt = 1.0 / 60.0

				var fade_timer = Timer.new()
				canvas.add_child(fade_timer)
				fade_timer.wait_time = dt
				fade_timer.timeout.connect(func():
					state.elapsed += dt
					var t = clampf(state.elapsed / fade_time, 0.0, 1.0)
					overlay.color.a = 1.0 - t
					spinner.modulate.a = 1.0 - t
					spinner.rotation += TAU * dt / 2.5

					if t >= 1.0:
						fade_timer.stop()
						spin_tween.kill()
						canvas.queue_free()
				)
				fade_timer.start()
				Globals.started = true;
		)
		timer.start()
	)


func _on_difficulty_1_pressed() -> void:
	_load_game(1)

func _on_difficulty_2_pressed() -> void:
	_load_game(2)

func _on_difficulty_3_pressed() -> void:
	_load_game(3)


func _on_difficulty_3_mouse_entered() -> void:
	pass # Replace with function body.
