extends Node3D

@export var tileInstance: PackedScene
@export var mapSize = 5
@export var spacing = 2

@onready var bottomTiles = $BottomTiles 

func _ready() -> void:
	spawnTileGrid(0, 0, bottomTiles) # base map

func spawnTileGrid(yLevel: int, emptySlots: int, parent: Node3D):
	var offset = (mapSize - 1) * spacing * 0.5
	for row in range(mapSize):
		for column in range (mapSize):
			var instance = tileInstance.instantiate()
			parent.add_child(instance)
			instance.position = Vector3(mapSize * spacing - offset, 0.0, mapSize * spacing - offset)

func removeTiles(parent: Node3D):
	for child in bottomTiles.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	pass
