extends Node

var started = false
var difficulty 
var sensitivity = 2

func _ready():
	resetVars()

func resetVars():
	started = false
