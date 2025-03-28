extends CharacterBody3D

class_name Player

@onready var camera_3d: Camera3D = $Boddy/Camera3D
@onready var ray_cast_3d: RayCast3D = $Boddy/Camera3D/RayCast3D
@onready var crossair: TextureRect = $Boddy/Camera3D/crossair
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


@onready var boddy: Node3D = $Boddy

@onready var rich_text_label: RichTextLabel = $Boddy/Camera3D/RichTextLabel


#@onready var grid_map: GridMap = $"../GridMap"

const SPEED = 5.0
const JUMP_VELOCITY = 4.6
#Set these to settings.
var sensitivity = 0.002
var tiltMax = deg_to_rad(95)
var tiltMin = deg_to_rad(-85)

var supper = false
var paused = false

@export var world: Node3D
var focous
var fnorm

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && !paused:
		boddy.rotation.y = boddy.rotation.y - event.relative.x * sensitivity
		
		camera_3d.rotation.x = clamp(camera_3d.rotation.x - event.relative.y * sensitivity,tiltMin,tiltMax)
		

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("pause"):
		paused = !paused
		if paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if paused:
		return
		
	if Input.is_action_just_pressed("hyperSpeed"):
		supper = !supper
		collision_shape_3d.disabled = supper
		
	rich_text_label.clear()
	rich_text_label.add_text(str(position)+"\n"+str(Engine.get_frames_per_second()))
	
	#standard
	grvity(delta)
	jump()
	walk()
	
	#custom
	ray_cast()
	

	
	move_and_slide()

func ray_cast()-> void:
	if ray_cast_3d.is_colliding():
		crossair.rotation = deg_to_rad(45)
		var norm = ray_cast_3d.get_collision_normal()
		var pos = ray_cast_3d.get_collision_point()
		
		if world != null:
			world_clicks(pos,norm)
	else:
		crossair.rotation = 0
		if focous != null: # we can only get a focous if the world was set, see below.
			world.unHilightBlock(focous)
			focous = null

func world_clicks(pos,norm):
	var wCord = world.getPosFromRayCol(pos,norm)
	var blk = world.get_block(wCord)
	if blk != 0: #make sure we are looking at a block
		if focous != wCord || fnorm != norm:
			if focous != null:
				world.unHilightBlock(focous)
			focous = wCord
			fnorm = norm
			world.hilight_block(focous, norm)
		var temp = world.getTemp(wCord)
		rich_text_label.add_text("\n\nLooking at "+str(focous)+": Type ="+str(blk&0x03ff)+" Var ="+str((blk&0x07c00)>>10)+", Temp ="+str(temp))
		if Input.is_action_just_pressed("leftMouse"):
			world.break_block(focous)
		if Input.is_action_just_pressed("rightMouse"):
			world.place_block(focous+Vector3i(norm),3)
	

func grvity(delta: float) -> void:
	if supper:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

func jump() -> void:
	# Handle jump.
	if supper:
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY*3
		elif Input.is_action_pressed("crouch"):
			velocity.y = JUMP_VELOCITY*-3
		else:
			velocity.y = 0
	else:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

func walk() -> void:
	var speed = SPEED
	if Input.is_action_pressed("sprint"):
		speed*=2
	if supper:
		speed*=10
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (boddy.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
