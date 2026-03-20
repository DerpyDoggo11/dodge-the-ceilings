extends Control

const MAIN_SCENE = "res://scenes/main/main.tscn"

@onready var spinner = $SpinnerIcon 

func _ready():
	# Start loading the main scene in the background
	ResourceLoader.load_threaded_request(MAIN_SCENE)

func _process(delta):
	# Rotate the spinner
	spinner.rotation += delta * 3.0

	# Check if loading is done
	var status = ResourceLoader.load_threaded_get_status(MAIN_SCENE)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene = ResourceLoader.load_threaded_get(MAIN_SCENE)
		get_tree().change_scene_to_packed(scene)
