extends Node3D

@export var spikeyTileInstance: PackedScene
@export var mapTileInstance: PackedScene
@export var mapSize = 20
@export var spacing = 2
@export var fallSpeed = 3.0
@export var spawnHeight = 10.0
@export var emptySlotCount = 40

@onready var bottomTiles = $BottomTiles

var fallingGrids = []
var timer = 0.0
# TODO: Make tilemap size shrink every few seconds (remove edges from main tilemap), Make sideway/angled tiles moving to the opposite side
func _ready() -> void:
	spawnTileGrid(0, 0, bottomTiles, mapTileInstance)

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
	var fallingParent = Node3D.new()
	add_child(fallingParent)
	fallingParent.position.y = spawnHeight
	spawnTileGrid(0, emptySlotCount, fallingParent, spikeyTileInstance)
	fallingGrids.append(fallingParent)

func removeTiles(parent: Node3D):
	for child in parent.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	timer += delta
	if timer >= 5.0:
		timer = 0.0
		spawnFallingGrid()

	for grid in fallingGrids.duplicate():
		grid.position.y -= fallSpeed * delta
		if grid.position.y <= 0.0:
			grid.position.y = 0.0
			grid.queue_free()
			fallingGrids.erase(grid)
