extends Node

var started = false
var difficulty 
var sensitivity = 2
var timeAlive

func _ready():
	resetVars()

func resetVars():
	started = false
	timeAlive = 0
