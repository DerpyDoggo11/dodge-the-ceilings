extends Node3D

@export var overlayTimeLeftBar: PackedScene
@export var winScreenInstance: PackedScene
@export var spikeyTileInstance: PackedScene
@export var mapTileInstance: PackedScene
@export var mapSize = 20
@export var spacing = 2
@export var fallSpeed = 3.0
@export var spawnHeight = 30.0
@export var emptySlotCount = 40

# duration seconds, fall speed, spawn interval, empty slots
@export var easyLevels = [
	[20.0, 3.0, 5.0, 40],
	[15.0, 4.5, 4.5, 32],
	[15.0, 6.0, 3.0, 24],
]
@export var mediumlevels = [
	[20.0, 4.5, 3.5, 40],
	[15.0, 4.5, 3, 32],
	[15.0, 6.0, 2.0, 24],
	[15.0, 8.0, 1.5, 16],
	[15.0, 11.0, 1, 8],
]
@export var hardlevels = [
	[20.0, 4.5, 2.5, 40],
	[15.0, 4.5, 1.5, 32],
	[15.0, 6.0, 1.0, 24],
	[15.0, 8.0, 1.0, 16],
	[15.0, 11.0, 1.0, 8],
]


@onready var bottomTiles = $BottomTiles

var fallingGrids = []
var spawnTimer = 0.0
var levelTimer = 0.0
var currentLevel = 0
var overlay
var overlayLabel
var overlayBar
var allLevels = []
var levels = []

# TODO: Make tilemap size shrink every few seconds (remove edges from main tilemap), Make sideway/angled tiles moving to the opposite side
func _ready() -> void:
	allLevels = [easyLevels, mediumlevels, hardlevels]
	levels = allLevels[Globals.difficulty - 1]
	overlay = overlayTimeLeftBar.instantiate()
	get_tree().root.add_child(overlay)
	var vbox = overlay.get_node("CanvasLayer/HBoxContainer/VBoxContainer")
	overlayLabel = vbox.get_node("Label")
	overlayBar = vbox.get_node("ProgressBar")
	
	applyLevel(currentLevel, )
	spawnTileGrid(0, 0, bottomTiles, mapTileInstance)

func applyLevel(index: int):
	var cfg = levels[index]
	var duration = cfg[0] as float
	var spawnInterval = cfg[2] as float
	spawnTimer = 0.0
	levelTimer = 0.0
	
	if overlayLabel:
		overlayLabel.text = "Level %d" % (index + 1)
	if overlayBar:
		overlayBar.max_value = duration
		overlayBar.value = duration
		
		
func currentCFG() -> Array:
	return levels[currentLevel]

func shrinkMap() -> void:
	var offset = (mapSize - 1) * spacing * 0.5
	for child in bottomTiles.get_children():
		var row = roundi((child.position.x + offset) / spacing)
		var col = roundi((child.position.z + offset) / spacing)
		if row == 0 or row == mapSize - 1 or col == 0 or col == mapSize - 1:
			child.queue_free()
	mapSize -= 2
 
func advanceLevel() -> void:
	currentLevel += 1
	if currentLevel >= levels.size():
		win()
		return
	else:
		spawnFallingGrid()
	shrinkMap()
	applyLevel(currentLevel)
	
func win() -> void:
	Globals.started = false
	
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
		get_tree().change_scene_to_file("res://scenes/ui/winUi.tscn")
	)
	tween.tween_interval(0.4) 
	tween.tween_property(overlay, "color:a", 0.0, 0.5) 
	tween.tween_callback(canvas.queue_free)
	
func spawnTileGrid(yLevel: int, emptySlots: int, parent: Node3D, tileInstance: PackedScene):
	var offset = (mapSize - 1) * spacing * 0.5
	
	var allPositions = []
	for row in range(mapSize):
		for column in range(mapSize):
			allPositions.append(Vector2i(row, column))
	allPositions.shuffle()
	var emptySet = {}
	for i in range(min(emptySlots, allPositions.size())):
		emptySet[allPositions[i]] = true

	for row in range(mapSize):
		for column in range(mapSize):
			if emptySet.get(Vector2i(row, column), false):
				continue
			var instance = tileInstance.instantiate()
			parent.add_child(instance)
			instance.position = Vector3(row * spacing - offset, yLevel, column * spacing - offset)

func spawnFallingGrid():
	var cfg = currentCFG()
	var emptySlots = cfg[3] as int
	var fallingParent = Node3D.new()
	add_child(fallingParent)
	fallingParent.position.y = spawnHeight
	spawnTileGrid(0, emptySlots, fallingParent, spikeyTileInstance)
	fallingGrids.append(fallingParent)

func removeTiles(parent: Node3D):
	for child in parent.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	if Globals.started == false:
		return
	
	var cfg = currentCFG()
	var duration = cfg[0] as float
	var fallSpeed = cfg[1] as float
	var spawnInterval = cfg[2] as float
	
	levelTimer += delta
	var timeLeft = maxf(duration - levelTimer, 0.0)
	
	if overlayLabel:
		overlayLabel.text = "Level %d  —  %ds" % [currentLevel + 1, ceili(timeLeft)]
	if overlayBar:
		overlayBar.value = timeLeft
		
	if levelTimer >= duration:
		advanceLevel()
		return
	
	spawnTimer += delta
	if spawnTimer >= spawnInterval:
		spawnTimer = 0.0
		spawnFallingGrid()

	for grid in fallingGrids.duplicate():
		grid.position.y -= fallSpeed * delta
		if grid.position.y <= 0.0:
			grid.position.y = 0.0
			grid.queue_free()
			fallingGrids.erase(grid)

func _exit_tree() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
