extends  EntityBase
class_name Player

var ray: RayCast3D
var focous #: Vector3i
var fnorm
var focousNode: Node3D
var camera: Camera3D 

var crossair: TextureRect
var debugText: RichTextLabel

var Hotbar: ItemList
var item: = 3

const meshTemplate = preload("res://Scripts/Blocks/fullBlockMechTemplate.tres")

#Set these to settings.
var sensitivity = 0.002
var tiltMax = deg_to_rad(95)
var tiltMin = deg_to_rad(-85)

var godMode = true
var paused = true



func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0,size.y/4,0)
	add_child(camera)
	
	
	
	debugText = RichTextLabel.new()
	debugText.scroll_active = false
	debugText.fit_content = true
	debugText.theme = Theme.new()
	debugText.theme.default_font_size = 20
	debugText.size = Vector2(500,500)
	debugText.visible = true
	debugText.position = Vector2(30,30)
	
	ray = RayCast3D.new()
	ray.target_position = Vector3i(0,0,-5)
	
	crossair = TextureRect.new()
	crossair.custom_minimum_size = Vector2(64,64)
	crossair.pivot_offset = Vector2(32,32)
	crossair.set_anchors_preset(Control.PRESET_CENTER)
	crossair.z_index = -1
	crossair.y_sort_enabled = true
	crossair.position = Vector2(-32,-32)
	
	crossair.texture = load("res://assets/crosshair161.png")
	crossair.material = load("res://assets/crossairShader.tres")
	camera.add_child(debugText)
	camera.add_child(ray)
	camera.add_child(crossair)
	
	Hotbar = ItemList.new()
	var test = DisplayServer.screen_get_size()
	Hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	Hotbar.size = Vector2(300,30)
	Hotbar.scale = Vector2(2,2)
	Hotbar.position = Vector2(-300,-80)
	Hotbar.max_columns = 10
	var size = Vector2(16,16)
	for i in region.blockLib.blocks.size()-1:
		var mineral = region.blockLib.blocks[i+1].mineral
		var texture = AtlasTexture.new()
		texture.atlas= region.blockLib.material.albedo_texture
		texture.region = Rect2((mineral.prim_texture.getPhase(0).front)*size,size)
		#texture.co
		Hotbar.add_icon_item(texture)
	camera.add_child(Hotbar)
	
	

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
	debugText.add_text(str(snapped(position,Vector3(0.001,0.001,0.001)))+"\n"+str(Engine.get_frames_per_second()))
	
	#custom
	ray_cast()
	numbSellect()
	
	if Input.is_action_just_pressed("scrClk"):
		region.queue_free()
	
	super._physics_process(delta)

func ray_cast()-> void:
	if ray.is_colliding():
		crossair.rotation = deg_to_rad(45)
		var norm = ray.get_collision_normal()
		var pos = ray.get_collision_point()
		
		if region != null:
			world_clicks(pos,norm)
	else:
		crossair.rotation = 0
		if focous != null: # we can only get a focous if the world was set, see below.
			clearFocous()
			focous = null

func world_clicks(pos,norm):
	var wCord = region.getPosFromRayCol(pos,norm)
	var blk = region.getVal(wCord)
	if blk[0] != 0: #make sure we are looking at a block
		if focous != wCord || fnorm != norm:
			focous = wCord
			fnorm = snapped(norm,Vector3(1,1,1))
			setFocous(focous,fnorm)
		var temp = region.getTemp(wCord)
		debugText.add_text("\n\nLooking at "+str(focous)+":\n" + region.info(focous))
		if Input.is_action_just_pressed("leftMouse"):
			region.break_block(focous)
			region.ForceUpdate(focous)
		if Input.is_action_just_pressed("rightMouse"):
			if Input.is_action_pressed("Alt"):
				region.addAt(focous,item,1000,SectionData.celToKel(30))
			else:
				region.addAt(focous+Vector3i(fnorm),item,1000,SectionData.celToKel(30),true)
			region.ForceUpdate(focous)
	

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
func checkDir(dir: Vector3i) -> PackedVector2Array:
	if godMode:
		var ref = Vector2(0,0)
		return [ref,ref,ref]
	return super.checkDir(dir)

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


func setFocous(cord: Vector3i, norm: Vector3i):
	clearFocous()
	var st = SurfaceTool.new()
	st.set_material(region.blockLib.material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for f in meshTemplate.Faces:
		var a = (meshTemplate.vertices[f.vers[0]]*(region.blockSize*1.01)) + (cord * region.blockSize) + meshTemplate.Reset
		var b = (meshTemplate.vertices[f.vers[1]]*(region.blockSize*1.01)) + (cord * region.blockSize) + meshTemplate.Reset
		var c = (meshTemplate.vertices[f.vers[2]]*(region.blockSize*1.01)) + (cord * region.blockSize) + meshTemplate.Reset
		var d = (meshTemplate.vertices[f.vers[3]]*(region.blockSize*1.01)) + (cord * region.blockSize) + meshTemplate.Reset
		
		var t = Vector2(4,1)
		if Global.OFFSETS[f.dir]==norm:
			t.x=5
		var rot = 0
		var color = Color.WHITE
		
		var uv_offset = t / region.blockLib.size
		var height = 1.0 / region.blockLib.size.y
		var width = 1.0 / region.blockLib.size.x
		
		var uvs = [uv_offset + Vector2(0, 0),
			uv_offset + Vector2(0, height),
			uv_offset + Vector2(width, height),
			uv_offset + Vector2(width, 0)
		]
		st.add_triangle_fan(([a,b,c]) ,([uvs[(1+rot)%4],uvs[(2+rot)%4],uvs[(0+rot)%4]]),([color,color,color]))
		st.add_triangle_fan(([d,c,b]) ,([uvs[(3+rot)%4],uvs[(0+rot)%4],uvs[(2+rot)%4]]),([color,color,color]))
	focousNode = Node3D.new()
	var meshIns = MeshInstance3D.new()
	meshIns.mesh = st.commit()
	focousNode.add_child(meshIns)
	region.add_child(focousNode)
		
func clearFocous():
	if focousNode != null:
		focousNode.queue_free()
		focousNode = null

func numbSellect():
	for i in 10:
		var e = str((i+1)%10)
		if Input.is_action_just_pressed(e):
			item = i+1
			Hotbar.select(i)
