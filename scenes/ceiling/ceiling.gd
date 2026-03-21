extends CharacterBody3D

@export var settingsUI: PackedScene

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = 5
var jump_speed = 5
const FIRST_PERSON_LENGTH = 0.0
const THIRD_PERSON_LENGTH = 3.5
const ZOOM_SPEED = 10.0

const DASH_SPEED = 20.0
const DASH_DURATION = 0.25
const DASH_COOLDOWN = 1.0
const NORMAL_HEIGHT = 1.0
const DASH_HEIGHT = 0.5
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var is_dashing = false
var dash_direction = Vector3.ZERO

var camera_yaw = 0.0
var camera_pitch = 0.0

const JUMP_HOLD_FORCE = 3.0
const JUMP_HOLD_MAX = 0.5
var jump_hold_timer = 0.0
var timeAliveAccumulator = 0.0
var settingsOpen = false
var settingsCanvas: CanvasLayer = null

@onready var cameraPivot = $CameraPivot
@onready var springArm = $CameraPivot/SpringArm3D
@onready var camera = $CameraPivot/SpringArm3D/Camera3D
@onready var playerMesh = $Mesh
@onready var collider = $CollisionShape3D 

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_yaw = rotation.y

func _physics_process(delta):
	
	if Globals.started == false:
		return
		
	timeAliveAccumulator += delta
	if timeAliveAccumulator >= 1.0:
		timeAliveAccumulator -= 1.0
		Globals.timeAlive += 1
	
	if global_position.y < -10:
		die()
	
	velocity.y += -gravity * delta

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	var input = Input.get_vector("left", "right", "forward", "back")
	var cam_basis = cameraPivot.global_transform.basis
	var forward = Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
	var right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
	var movement_dir = (-forward * -input.y + right * input.x)
	
	if movement_dir.length() > 0.1:
		if $Flop.playing == false:
			$Flop.play()
	
	if is_dashing:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
	else:
		velocity.x = movement_dir.x * speed
		velocity.z = movement_dir.z * speed
		
	move_and_slide()
	
	if settingsOpen:
		return
		
	if velocity.length() > 0.1:
		var target_angle = atan2(velocity.x, velocity.z)
		playerMesh.rotation.y = lerp_angle(playerMesh.rotation.y, target_angle, delta * 10.0)
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
		jump_hold_timer = JUMP_HOLD_MAX
		$Jump.playing = true

	if jump_hold_timer > 0.0:
		if Input.is_action_pressed("jump"):
			velocity.y += JUMP_HOLD_FORCE * delta
			jump_hold_timer -= delta
		else:
			jump_hold_timer = 0.0
	
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		dash_direction = movement_dir if movement_dir.length() > 0.1 else -forward
		dash_direction = dash_direction.normalized()
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		$Dash.playing = true
		$DashFlop.playing = true
	
	var target_height = DASH_HEIGHT if is_dashing else NORMAL_HEIGHT
	var current_height = lerp(playerMesh.scale.y, target_height, delta * 15.0)
	playerMesh.scale.y = current_height

	if collider.shape is CapsuleShape3D:
		collider.shape.height = lerp(collider.shape.height, target_height * 2.0, delta * 15.0)
	
	
	var target_length = THIRD_PERSON_LENGTH if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else FIRST_PERSON_LENGTH
	springArm.spring_length = lerp(springArm.spring_length, target_length, delta * ZOOM_SPEED)

	var isThirdPerson = springArm.spring_length > 0.2
	playerMesh.visible = isThirdPerson


func _input(event):
	if Globals.started == false:
		return
		
	if event.is_action_pressed("exit"):
		
		if !settingsOpen:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			openSettings()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			closeSettings()
		return
	
	if settingsOpen:
		return


	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var isThirdPerson = springArm.spring_length > 0.2
		camera_yaw   -= event.relative.x * (Globals.sensitivity * 0.001)
		camera_pitch -= event.relative.y * (Globals.sensitivity * 0.001)
		camera_pitch  = clampf(camera_pitch, -deg_to_rad(80), deg_to_rad(80))

		if isThirdPerson:
			cameraPivot.rotation = Vector3(camera_pitch, camera_yaw - rotation.y, 0.0)
		else:
			rotation.y = camera_yaw
			cameraPivot.rotation = Vector3(camera_pitch, 0.0, 0.0)
			
			
func openSettings():
	settingsOpen = true
	if settingsCanvas != null:
		return

	settingsCanvas = CanvasLayer.new()
	settingsCanvas.layer = 64
	add_child(settingsCanvas)

	var instance = settingsUI.instantiate()
	instance.modulate.a = 0.0
	settingsCanvas.add_child(instance)

	var tween = settingsCanvas.create_tween()
	tween.tween_property(instance, "modulate:a", 1.0, 0.25)
	
func closeSettings():
	settingsOpen = false
	if settingsCanvas == null:
		return

	var instance = settingsCanvas.get_child(0)
	if not is_instance_valid(instance):
		settingsCanvas.queue_free()
		settingsCanvas = null
		return

	var tween = settingsCanvas.create_tween()
	tween.tween_property(instance, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		settingsCanvas.queue_free()
		settingsCanvas = null
	)
	
func die():
	if Globals.started == false:
		return
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tree = get_tree()
	Globals.started = false

	var canvas = CanvasLayer.new()
	canvas.layer = 128
	tree.root.add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	overlay.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func():
		overlay.size = get_viewport().get_visible_rect().size
	)
	canvas.add_child(overlay)

	var deathCanvas = CanvasLayer.new()
	deathCanvas.layer = 129
	tree.root.add_child(deathCanvas)

	var deathScene = preload("res://scenes/ui/deathUi.tscn").instantiate()
	deathScene.modulate.a = 0.0
	deathCanvas.add_child(deathScene)

	var tween = canvas.create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 2) 
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		deathCanvas.queue_free()   
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		tree.change_scene_to_file("res://scenes/ui/playUi.tscn")
	)
	tween.tween_interval(0.4) 
	tween.tween_property(overlay, "color:a", 0.0, 0.5) 
	tween.tween_callback(canvas.queue_free)
