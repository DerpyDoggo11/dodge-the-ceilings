extends Control

func _on_ready() -> void:
	var t = Globals.timeAlive
	var timeText: String
	if t > 59:
		var minutes = int(t) / 60
		var seconds = int(t) % 60
		timeText = "%d:%02d minutes" % [minutes, seconds]
	else:
		timeText = "%d seconds" % int(t)
	$CanvasLayer/HBoxContainer/VBoxContainer/Label3.text = "you survived for " + timeText
