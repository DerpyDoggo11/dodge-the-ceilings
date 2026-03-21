extends Node3D

@export var overlayTimeLeftBar: PackedScene
@export var winScreenInstance: PackedScene
@export var wallTileInstance: PackedScene
@export var spikeyTileInstance: PackedScene
@export var mapTileInstance: PackedScene
@export var mapSize = 20
@export var spacing = 2
@export var fallSpeed = 3.0
@export var spawnHeight = 30.0
@export var emptySlotCount = 40

# duration seconds, fall speed, ceiling spawn interval, empty slots, wall spawn interval
@export var easyLevels = [
	[25.0, 2.5, 7.0, 48, 999.0],
	[20.0, 3.0, 6.0, 40, 12.0],
	[20.0, 4.0, 5.0, 32, 10.0],
]
@export var mediumlevels = [
	[25.0, 3.0, 6.0, 44, 999.0],
	[20.0, 3.5, 5.0, 36, 10.0],
	[20.0, 4.5, 4.0, 28, 8.0],
	[20.0, 6.0, 3.0, 20, 7.0],
	[15.0, 8.0, 2.0, 14, 6.0],
]
@export var hardlevels = [
	[20.0, 3.5, 4.5, 40, 10.0],
	[20.0, 4.5, 3.5, 32, 7.0],
	[15.0, 6.0, 2.5, 24, 6.0],
	[15.0, 8.0, 2.0, 16, 5.0],
	[15.0, 11.0, 1.5, 8,  4.0],
]


@onready var bottomTiles = $BottomTiles
@onready var movingCeilingSound = $MovingCeiling
@onready var movingWallSound = $MovingWall

var fallingGrids = []
var spawnTimer = 0.0
var levelTimer = 0.0
var currentLevel = 0
var wallSpawnTimer = 0.0
var overlay
var overlayLabel
var overlayBar
var allLevels = []
var levels = []
var movingWalls = []
var isUnlimited = false

func _ready() -> void:
	allLevels = [easyLevels, mediumlevels, hardlevels]
	if Globals.difficulty == 4:
		isUnlimited = true
		levels = []
		for i in range(8):
			levels.append(generateUnlimitedLevel(i))
	else:
		levels = allLevels[Globals.difficulty - 1]
		
	overlay = overlayTimeLeftBar.instantiate()
	get_tree().root.add_child(overlay)
	var vbox = overlay.get_node("CanvasLayer/HBoxContainer/VBoxContainer")
	overlayLabel = vbox.get_node("Label")
	overlayBar = vbox.get_node("ProgressBar")
	
	applyLevel(currentLevel, )
	spawnTileGrid(0, 0, bottomTiles, mapTileInstance)

func generateUnlimitedLevel(index: int) -> Array:
	var t = float(index)
	var duration = maxf(30.0 - t * 1.5, 12.0)
	var fallSpeed = minf(2.5  + t * 0.65, 15.0)
	var spawnInterval = maxf(7.0 - t * 0.4, 0.8)
	var emptySlots = maxi(48 - index * 3, 4)
	var wallInterval = 999.0 if index < 2 else maxf(12.0 - t * 0.6, 3.0)
	return [duration, fallSpeed, spawnInterval, emptySlots, wallInterval]

func applyLevel(index: int):
	var cfg = levels[index]
	var duration = cfg[0] as float
	spawnTimer = 0.0
	wallSpawnTimer = 0.0
	levelTimer = 0.0
	
	if overlayLabel:
		overlayLabel.text = "Level %d" % (index + 1)
	if overlayBar:
		overlayBar.max_value = duration
		overlayBar.value = duration
		
		
func currentCFG() -> Array:
	return levels[currentLevel]

func shrinkMap() -> void:
	if mapSize <= 8:
		return
	var offset = (mapSize - 1) * spacing * 0.5
	for child in bottomTiles.get_children():
		var row = roundi((child.position.x + offset) / spacing)
		var col = roundi((child.position.z + offset) / spacing)
		if row == 0 or row == mapSize - 1 or col == 0 or col == mapSize - 1:
			fadeOutAndFree(child, 0.6)
	mapSize -= 2
	
func fadeOutAndFree(node: Node3D, duration: float) -> void:
	var meshes: Array = []
	collectMeshes(node, meshes)
	if meshes.is_empty():
		node.queue_free()
		return

	var tween = create_tween()
	tween.set_parallel(true)
	for mesh in meshes:
		var mat: Material = mesh.material_override
		if mat == null:
			continue
		mat = mat.duplicate()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		tween.tween_property(mat, "albedo_color:a", 0.0, duration)

	var seq = create_tween()
	seq.tween_interval(duration)
	seq.tween_callback(node.queue_free)
 
func advanceLevel() -> void:
	currentLevel += 1
	if currentLevel >= levels.size():
		if isUnlimited:
			levels.append(generateUnlimitedLevel(currentLevel))
		else: 
			win()
			return
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
	
	var movingSound = movingCeilingSound.duplicate()
	fallingParent.add_child(movingSound)
	movingSound.play()
	
	spawnTileGrid(0, emptySlots, fallingParent, spikeyTileInstance)
	fallingGrids.append(fallingParent)
	fadeInGrid(fallingParent, 0.6)
	
func collectMeshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		collectMeshes(child, result)

func fadeInGrid(parent: Node3D, duration: float) -> void:
	var meshes: Array = []
	collectMeshes(parent, meshes)
	if meshes.is_empty():
		return
		
	var tween = create_tween()
	tween.set_parallel(true)
	for mesh in meshes:
		var mat: Material = mesh.material_override
		if mat == null:
			continue
		mat = mat.duplicate()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		var base: Color = mat.albedo_color
		var h = fmod(base.h + randf_range(-0.01, 0.01), 1.0)
		var s = clampf(base.s + randf_range(-0.01, 0.05), 0.0, 1.0)
		var v = clampf(base.v + randf_range(-0.05, 0.05), 0.0, 1.0)
		mat.albedo_color = Color.from_hsv(h, s, v, 0.0)

		mesh.material_override = mat
		tween.tween_property(mat, "albedo_color:a", 1.0, duration)
	
func removeTiles(parent: Node3D):
	for child in parent.get_children():
		child.queue_free()
		
func spawnWall() -> void:
	var side = randi() % 4
	var wallHeight = 5
	var offset = (mapSize - 1) * spacing * 0.5
	
	var cfg = currentCFG()
	var ceilingEmptySlots = cfg[3] as int
	var wallEmptySlots = ceilingEmptySlots
	
	var allPositions = []
	for i in range(mapSize):
		for y in range (wallHeight):
			allPositions.append(Vector2i(i, y))
	allPositions.shuffle()
	var emptySet = {}
	for k in range(min(wallEmptySlots, allPositions.size())):
		emptySet[allPositions[k]] = true
		
	var safeCol = randi() % mapSize
	for y in range(wallHeight):
		emptySet[Vector2i(safeCol, y)] = true
	
	
	var wallParent = Node3D.new()
	add_child(wallParent)
	
	var movingSound = movingWallSound.duplicate()
	wallParent.add_child(movingSound)
	movingSound.play()
	
	var direction: Vector3
	var tileRotation: float
	match side:
		0: direction = Vector3( 0, 0,  1); tileRotation = 0.0
		1: direction = Vector3( 0, 0, -1); tileRotation = PI
		2: direction = Vector3( 1, 0,  0); tileRotation = -PI * 0.5
		3: direction = Vector3(-1, 0,  0); tileRotation = PI * 0.5
		
	for i in range(mapSize):
		for y in range(wallHeight):
			if emptySet.get(Vector2i(i, y), false):
				continue
			var instance = wallTileInstance.instantiate()
			wallParent.add_child(instance)
			instance.rotation.y = tileRotation
			match side:
				0: instance.position = Vector3(i * spacing - offset, y * spacing + spacing * 0.5, -offset - spacing)
				1: instance.position = Vector3(i * spacing - offset, y * spacing + spacing * 0.5,  offset + spacing)
				2: instance.position = Vector3(-offset - spacing, y * spacing + spacing * 0.5, i * spacing - offset)
				3: instance.position = Vector3( offset + spacing, y * spacing + spacing * 0.5, i * spacing - offset)
		
	movingWalls.append({"node": wallParent, "dir": direction})
	fadeInGrid(wallParent, 0.6)
	
func _process(delta: float) -> void:
	if Globals.started == false:
		return
	
	var cfg = currentCFG()
	var duration = cfg[0] as float
	var fallSpeed = cfg[1] as float
	var spawnInterval = cfg[2] as float
	var wallInterval = cfg[4] as float
	
	levelTimer += delta
	var timeLeft = maxf(duration - levelTimer, 0.0)
	
	if overlayLabel:
		overlayLabel.text = "Level %d:  %ds" % [currentLevel + 1, ceili(timeLeft)]
	if overlayBar:
		overlayBar.value = timeLeft
		
	if levelTimer >= duration:
		advanceLevel()
		return
	
	spawnTimer += delta
	if spawnTimer >= spawnInterval:
		spawnTimer = 0.0
		spawnFallingGrid()
		
	wallSpawnTimer += delta
	if wallSpawnTimer >= wallInterval:
		wallSpawnTimer = 0.0
		spawnWall()

	for grid in fallingGrids.duplicate():
		grid.position.y -= fallSpeed * delta
		if grid.position.y <= 0.0:
			grid.position.y = 0.0
			grid.queue_free()
			fallingGrids.erase(grid)
	
	var wallSpeed = fallSpeed * 0.25
	for wall in movingWalls.duplicate():
		var w: Node3D = wall["node"]
		if not is_instance_valid(w):
			movingWalls.erase(wall)
			continue
		w.position += wall["dir"] * wallSpeed * delta
		var p = w.position
		var limit = (mapSize + 2) * spacing
		if abs(p.x) > limit or abs(p.z) > limit:
			w.queue_free()
			movingWalls.erase(wall)

func _exit_tree() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
