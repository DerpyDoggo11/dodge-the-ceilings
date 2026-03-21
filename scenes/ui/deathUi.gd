extends Control

func _on_ready() -> void:
	var minutes = Globals.timeAlive / 60
	var seconds = Globals.timeAlive % 60
	$CanvasLayer/HBoxContainer/VBoxContainer/Label3.text = "you survived for " + ("%d:%02d minutes" % [minutes, seconds])
