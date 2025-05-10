extends  EntityBase
class_name Player

var ray: RayCast3D
var focous #: Vector3i
var fnorm
var camera: Camera3D 

var crossair: TextureRect
var debugText: RichTextLabel


#Set these to settings.
var sensitivity = 0.002
var tiltMax = deg_to_rad(95)
var tiltMin = deg_to_rad(-85)

var godMode = true
var paused = true



func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(1.5,1.5,2.5)
	add_child(camera)
	
	
	debugText = RichTextLabel.new()
	debugText.scroll_active = false
	debugText.fit_content = true
	#theme. 
	
	ray = RayCast3D.new()
	crossair = TextureRect.new()
	crossair.custom_minimum_size = Vector2(64,64)
	crossair.pivot_offset = Vector2(32,32)
	crossair.set_anchors_preset(Control.PRESET_CENTER)
	crossair.position = Vector2(-32,-32)
	
	crossair.texture = load("res://assets/crosshair161.png")
	camera.add_child(debugText)
	camera.add_child(ray)
	camera.add_child(crossair)
	
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && !paused:
		self.rotation.y = self.rotation.y - event.relative.x * sensitivity
		camera.rotation.x = clamp(camera.rotation.x - event.relative.y * sensitivity,tiltMin,tiltMax)
		

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
		godMode = !godMode
		
	debugText.clear()
	debugText.add_text(str(position)+"\n"+str(Engine.get_frames_per_second()))
	
	#custom
	ray_cast()
	
	super._physics_process(delta)

func ray_cast()-> void:
	if ray.is_colliding():
		crossair.rotation = deg_to_rad(45)
		var norm = ray.get_collision_normal()
		var pos = ray.get_collision_point()
		
		#if world != null:
			#world_clicks(pos,norm)
	else:
		crossair.rotation = 0
		if focous != null: # we can only get a focous if the world was set, see below.
			region.unHilightBlock(focous)
			focous = null

func world_clicks(pos,norm):
	var wCord = region.getPosFromRayCol(pos,norm)
	var blk = region.get_block(wCord)
	if blk != 0: #make sure we are looking at a block
		if focous != wCord || fnorm != norm:
			if focous != null:
				region.unHilightBlock(focous)
			focous = wCord
			fnorm = norm
			region.hilight_block(focous, norm)
		var temp = region.getTemp(wCord)
		debugText.add_text("\n\nLooking at "+str(focous)+": Type ="+str(blk&0x03ff)+" Var ="+str((blk&0x07c00)>>10)+", Temp ="+str(temp))
		if Input.is_action_just_pressed("leftMouse"):
			region.break_block(focous)
		if Input.is_action_just_pressed("rightMouse"):
			region.place_block(focous+Vector3i(norm),3)
	

func grvity(delta: float) -> void:
	if godMode:
		return
	# Add the gravity.
	super.grvity(delta)

func jump() -> void:
	# Handle jump.
	if godMode:
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY*3
		elif Input.is_action_pressed("crouch"):
			velocity.y = JUMP_VELOCITY*-3
		else:
			velocity.y = 0
	else:
		super.jump()

func walk() -> void:
	var speed = SPEED
	if Input.is_action_pressed("sprint"):
		speed*=2
	if godMode:
		speed*=1#0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (self.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
