extends Control

const MAIN_SCENE = "res://main.tscn"
const LOADING_SCENE = "res://loading.tscn"
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
	#GameState.difficulty = difficulty

	if LOADING_SCENE != "":
		get_tree().change_scene_to_file(LOADING_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_SCENE)


func _on_difficulty_1_pressed() -> void:
	_load_game(1)

func _on_difficulty_2_pressed() -> void:
	_load_game(2)

func _on_difficulty_3_pressed() -> void:
	_load_game(3)


func _on_difficulty_3_mouse_entered() -> void:
	pass # Replace with function body.
