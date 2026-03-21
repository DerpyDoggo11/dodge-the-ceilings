extends Control

func _ready() -> void:
	$CanvasLayer/HBoxContainer/VBoxContainer/HSlider.value = Globals.sensitivity
	
func _on_h_slider_value_changed(value: float) -> void:
	Globals.sensitivity = value
	
