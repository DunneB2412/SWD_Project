extends CharacterBody3D
class_name EntityBase

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var envNode: Node3D
var visualShape : Array[Section]
var colisionShape: CollisionShape3D
var region: Region
var lastPos: Vector3i
var entityId: int

var size: Vector3
var colisions: Vector3i

func _init(pos: Vector3i, region_in: Region, scale_in: Vector3 = Vector3(0.9,1.8,0.9)) -> void:
	lastPos = pos
	region = region_in
	position = pos*region.blockSize
	
	envNode = Node3D.new()
	
	
	size = scale_in
	region.add_child(self)
	region.add_child(envNode)
	region.entities.append(self)
	
	
	
	var box = BoxMesh.new()
	box.size = scale_in
	var visual = MeshInstance3D.new()
	visual.mesh = box
	add_child(visual)
	
	colisionShape = CollisionShape3D.new()
	colisionShape.shape = box.create_convex_shape()
	add_child(colisionShape)
	
func _exit_tree() -> void:
	envNode.queue_free()
	

func _physics_process(delta: float) -> void:
	for c in envNode.get_children():
		c.queue_free()
		
	
	#standard
	grvity(delta)
	jump()
	walk()

	#moveNslide(1)
	move_and_slide()


func grvity(delta: float) -> void:
	if colisions.y != -1 || is_on_floor():
		velocity = velocity+get_gravity() * delta

func jump() -> void:
	if Input.is_action_pressed("jump") && (colisions.y == -1 || is_on_floor()):
		velocity.y = JUMP_VELOCITY

func walk() -> void:
	var speed = SPEED
	if Input.is_action_pressed("sprint"):
		speed*=2
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (self.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	
func checkDir(dir: Vector3i) -> PackedVector2Array:
	var res: PackedVector2Array = []
	res.resize(3)
	var t = ceil(size)
	var cord = region.scenePosToWorld(self.position)
	for i in 3: #cycle over vector
		if dir[i]!=0:
			var d = dir[i]*ceil(size[i]/2)
			res[i] = Vector2(0,0) #overlap in this direction. 
			for a in t[(i+1)%3]+2:
				for b in t[(i+2)%3]+2:
					var celloffset = Vector3i(0,0,0)
					celloffset[i]=d
					celloffset[(i+1)%3]=a-ceil(size[(i+1)%3]/2)
					celloffset[(i+2)%3]=b-ceil(size[(i+2)%3]/2)
					var test = cord + celloffset
					var c = Color.RED
					var val = region.getVal(test)
					var contact = region.entityTouching(self, test)
					if contact[0]:
						res[i].y = contact[1][i]
						c = Color.PURPLE
						var tolerance = region.blockSize/100
						var minComb = size[i]+region.blockSize
						for j in 2:
							minComb = min(abs(snapped(contact[1][(i+(j+1))%3], tolerance)),minComb)
						if tolerance < minComb: #only consider if over is within threshold
							if SectionData.readMeta(val[0], SectionData.INC.BLOCK_TYPE) == 7:
								res[i].x = max(res[i].x, 0.1)
								c = Color.MIDNIGHT_BLUE
							else:
								c = Color.AQUAMARINE
								res[i].x = 1
					createColisionAt(test, c)
					
	return res

func moveNslide(delta):
	var change = velocity*delta
	
	if change != Vector3(Global.REF_VEC3):
		#print("Mobing entity by "+str(change)+ " this tick.")
		var tedt = Vector3i(0,0,0)
		for i in 3:
			if change[i] != 0:
				if change[i] > 0:
					tedt[i] = 1
				else:
					tedt[i] = -1
		var resistance: PackedVector2Array = checkDir(tedt)
		for i in 3:
			change[i] = change[i]* (1-resistance[i].x)
			if resistance[i].x != 0:
				var reset = (resistance[i].y+region.blockSize/200) * tedt[i] #keep contact.
				change[i] +=  reset*resistance[i].x
				colisions[i] = tedt[i]
			else:
				colisions[i] = 0
			
		#position += change

func leastTransform(a:float,b:float) -> float:
	if a <0:
		return max(a,b)
	else:
		return min(a,b)

func createColisionAt(cell:Vector3i, color: Color = Color.WHITE):
	color.a = 0.5
	var box = BoxMesh.new()
	box.size = Vector3(1.01,1.01,1.01)* region.blockSize
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = mat
	var visual = MeshInstance3D.new()
	visual.mesh = box
	visual.position = (cell*region.blockSize)+Vector3(0.5025,0.5025,0.5025) 
	envNode.add_child(visual)
	
