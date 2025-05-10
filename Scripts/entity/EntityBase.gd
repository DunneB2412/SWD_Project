extends CharacterBody3D
class_name EntityBase

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var envNode: Node3D
var visualShape : Array[Section]
var region: Region
var lastPos: Vector3i
var entityId: int

var size: Vector3

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
	
func _exit_tree() -> void:
	envNode.queue_free()
	

func _physics_process(delta: float) -> void:
	for c in envNode.get_children():
		c.queue_free()
		
	var pos = region.scenePosToWorld(self.position)
	#standard
	grvity(delta)
	jump()
	walk()

	moveNslide(delta)
	#move_and_slide()


func grvity(delta: float) -> void:
	var res = checkGround()
	velocity = (velocity+get_gravity() * delta) *(1-res)

func jump() -> void:
	var res = checkGround()
	if Input.is_action_pressed("jump") && res !=0:
		velocity.y = max((velocity.y*(1-res))+JUMP_VELOCITY*res, JUMP_VELOCITY)

func walk() -> void:
	var speed = SPEED
	if Input.is_action_pressed("sprint"):
		speed*=2
	#if godMode:
		#speed*=1#0
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


func checkGround() -> float:
	var res = 0
	var cord = region.scenePosToWorld(self.position - size/2)
	var t = ceil(size)
	for x in t.x+1:
		for z in t.z+1:
			if region.entityTouching(self, cord + Vector3i(x,0,z)):
				#createColisionAt(cord + Vector3i(x,0,z))
				var val = region.getVal(cord + Vector3i(x,0,z))
				if SectionData.readMeta(val[0], SectionData.INC.BLOCK_TYPE) == 7:
					res = max(res, 0.1)
				else:
					res = 1
	
	return res
	
	
func checkDir(dir: Vector3i) -> Vector3:
	var res = Vector3(0,0,0)
	var t = ceil(size)
	for i in 3: #cycle over vector
		var d = dir[i]+ceil(size[i]/2)
		
		
		for a in t[(i+1)%3]:
			for b in t[(i+2)%3]:
				var cellPos = Vector3i(0,0,0)
				if dir[i] >0:
					cellPos[i]=d-dir[i]
				else:
					cellPos[i]=d-ceil(size[i]/2)-dir[i]
				cellPos[(i+1)%3]=a-ceil(size[(i+1)%3]/2)
				cellPos[(i+2)%3]=b-ceil(size[(i+2)%3]/2)
	return res

func moveNslide(delta):
	var change = velocity*delta
	
	if change != Vector3(Global.REF_VEC3):
		print("Mobing entity by "+str(change)+ " this tick.")
		
		var ref = Vector3(Global.REF_VEC3)
		
		while change != ref:
			#find least.
			var minI = 0
			var minDis = INF
			var dir = 0
			for i in 3:
				var rsd = fmod(position[i],1.0)
				if change[i] >0 && 1-rsd < minDis:
					minDis = 1-rsd
					minI = i
					dir = 1
				elif change[i] < 0 && rsd<minDis:
					minDis = rsd
					minI = i
					dir = -1
			var blkCheck = Vector3i(0,0,0)
			blkCheck[minI] = dir
			var step = min(change[minI],minDis)
			change[minI] -= step
			var val = region.getVal(region.scenePosToWorld(self.position)+blkCheck)
			if val[0] != 0:
				createColisionAt(region.scenePosToWorld(self.position)+blkCheck)
				step = 0
			
			var next = Vector3(0,0,0)
			next[minI] = step
			
			
			position = position+next
			var pPos = region.scenePosToWorld(self.position+((size/2)*dir))
			if region.entityTouching(self, pPos):
				print("hit wall at "+str(pPos))
				
				#block further moobment.

func createColisionAt(cell:Vector3i):
	var box = BoxMesh.new()
	box.size = Vector3(1.01,1.01,1.01)* region.blockSize
	var visual = MeshInstance3D.new()
	visual.mesh = box
	visual.position = (cell*region.blockSize)+Vector3(0.505,0.505,0.505) 
	envNode.add_child(visual)
	
