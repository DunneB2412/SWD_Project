@tool
extends StaticBody3D
class_name Chunk
#masks for world encoding.
#all 32 bits accounted for 
const encoder = {
	"airAbove": 		{"mask":0x0000000080000000,"max":1      , "offset": 31}, # 1000 0000 0000 0000 0000 0000 0000 0000
	"airBelow":   	{"mask":0x0000000040000000,"max":1      , "offset": 30}, # 0100 0000 0000 0000 0000 0000 0000 0000
	"clickable":  	{"mask":0x0000000020000000,"max":1      , "offset": 29}, # 0010 0000 0000 0000 0000 0000 0000 0000
	"opaque":		{"mask":0x0000000010000000,"max":1      , "offset": 28}, # 0001 0000 0000 0000 0000 0000 0000 0000
	"visable":		{"mask":0x0000000008000000,"max":1      , "offset": 27}, # 0000 1000 0000 0000 0000 0000 0000 0000
	"solid":			{"mask":0x0000000004000000,"max":1      , "offset": 26}, # 0000 0100 0000 0000 0000 0000 0000 0000
	"blocktype":		{"mask":0x00000000000003ff,"max":0x03ff , "offset": 00}, # 0000 0000 0000 0000 0000 0011 1111 1111
	"blocktvar":		{"mask":0x0000000000007c00,"max":0x001f , "offset": 10}, # 0000 0000 0000 0000 0111 1100 0000 0000
	"norm":			{"mask":0x0000000000038000,"max":0x0007 , "offset": 15}, # 0000 0000 0000 0011 1000 0000 0000 0000
	"rotation": 		{"mask":0x00000000000c0000,"max":0x0003 , "offset": 17}, # 0000 0000 0000 1100 0000 0000 0000 0000
	"strain":		{"mask":0x0000000000f00000,"max":0x000f , "offset": 20}, # 0000 0000 1111 0000 0000 0000 0000 0000
	"permuable": 	{"mask":0x0000000001000000,"max":0x0001 , "offset": 24},  # 0000 0011 0000 0000 0000 0000 0000 0000
	"spare1"	:		{"mask":0x0000000002000000,"max":0x0001 , "offset": 24},
	"mass":			{"mask":0x03ffffff00000000,"max":0x03ffffff, "offset":32},
	"phase":			{"mask":0x0c00000000000000,"max":0x0003 , "offset":58},
	"pcounter":		{"mask":0x3000000000000000,"max":0x0003 , "offset":60},
	"spare2"	:		{"mask":0x4000000000000000,"max":0x0001 , "offset": 24},
	#"spare3"	:		{"mask":0x8000000000000000,"max":0x0001 , "offset": 24} apparently this dosent fit in 64 bits guess sine is reserved.
}

# 2  bits for phase, solid, liquid, gass. i will use the last to encode paste. this is half solid, half liquid.
#airAbove, Air Below, visable. this is 3
#take away, focous, sky and simulate, this is -3
#densist material is osmium at 40,700 kg per m3 according to below article
#https://www.nuclear-power.com/nuclear-engineering/thermodynamics/thermodynamic-properties/what-is-density-physics/densest-materials-on-the-earth/
# it may be best to use gram as smallest mass unit and 26 bits, this allows up to 66 ton, even allowing for fictional more dence materials.
# we have 4 remaining bits...
# if we give 2 to block var we can have 4k types. 
# 2 for emergancy. 

const commonflags = 0x14000000

# corner transforms
const vertices = [
	Vector3(-0.5,-0.5,-0.5), #0 bottom back left. 1,2,5
	Vector3(0.5,-0.5,-0.5), #1 bottom fromt left  1,5,3
	Vector3(-0.5,0.5,-0.5), #2 top back left      
	Vector3(0.5,0.5,-0.5), #3 top front left
	Vector3(-0.5,-0.5,0.5), #4 bottom back right
	Vector3(0.5,-0.5,0.5), #5 bottom front right
	Vector3(-0.5,0.5,0.5), #6 top back right
	Vector3(0.5,0.5,0.5)  #7 top front right
]
const ind = [
	2,6,
	6,7,
	3,7,
	2,3,
	2,0,
	6,4,
	7,5,
	3,1,
	0,4,
	0,1,
	1,5,
	4,5
	]
@export var reset = Vector3(0.5,0.5,0.5)
const FACES: Dictionary = {
	"top":[[6,2,7,3], Vector3i(0,1,0),Blocks.TOP],
	"bottom":[[1,0,5,4],Vector3i(0,-1,0),Blocks.BOTTOM],
	"right":[[5,4,7,6],Vector3i(0,0,1),Blocks.RIGHT],
	"left":[[0,1,2,3],Vector3i(0,0,-1),Blocks.LEFT],
	"front":[[1,5,3,7],Vector3i(1,0,0),Blocks.FRONT],
	"back":[[4,0,6,2],Vector3i(-1,0,0),Blocks.BACK]
}
# this was really annoying to figure out. at the end of it i found out that the midle ones need to be oposite. after that osition 0 and 3 may be swapped to change the direction of the face.

const TESTMATERIAL = preload("res://materials/test/testmaterial.tres")
const MORE_ITEMS = preload("res://materials/test/moreItems.tres")
#Members
var vxls: Array = []
var temp: Array = []
var visable: PackedVector3Array = PackedVector3Array()
var focous
var f_norm: Vector3i



#GenParamiters
var noise: FastNoiseLite = FastNoiseLite.new()
@export var chunk_size: Vector3i = Vector3i(32,32,32)
@export var genSeed: int = 100
@export var dirtDept: int = 3
@export var dirtVar: int = 2
@export var minY: int = 20

#Cell parms
@export var cellSize: float = 1

var worldPos: Vector3i = Vector3i(0,0,0) 
var world

var texture_surface: SurfaceTool = SurfaceTool.new()
var collision_surface: SurfaceTool = SurfaceTool.new()
var linesTool: SurfaceTool = SurfaceTool.new()

var updateQueue: Dictionary = {}
var mutex: Mutex
@export var updateQueueSize = 16

var updated = false

func _init(pos: Vector3i, genseed: int, world: Node, chunk_size: Vector3i, cell_size: float) -> void:
	self.visible = false
	reset = reset*cellSize
	FACES.make_read_only()
	self.worldPos = pos
	position = pos*chunk_size*cell_size
	self.genSeed = genseed
	noise.seed = genSeed
	self.world = world
	self.chunk_size = chunk_size
	self.cellSize = cell_size
	self.reset = Vector3(0.5,0.5,0.5)*cell_size
	mutex = Mutex.new()
	loadVxls()

func _process(_delta: float) -> void:
	mutex.lock()
	for pos in updateQueue:
		setVal(pos, updateQueue[pos])
		updateQueue.erase(pos)
	if updated:
		genMesh()
	mutex.unlock()
	
	# use a lock on queue while processing the changes. use local queue in find action.
	
func find_actions():
	var checkOffsets = [Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(-1,0,0),Vector3i(0,1,0),Vector3i(0,-1,0),Vector3i(0,0,1),Vector3i(0,0,-1)]
	# use search exploration aproach and do pair check when new pos is found.
	mutex.lock()
	var pendingUpdates = updateQueue.size()>0
	mutex.unlock()
	if updated || pendingUpdates:
		return # don't process if tghere have been un handled updates
		
	var noFacesChecked = 0
	var effects = {}
	var cstart =  Time.get_ticks_msec()
	
	#var cellsQueue = [Vector3i(0,0,0)]
	#var visited = []
	#var test: Vector3i
	#while cellsQueue.size()>0:
		#var cell = cellsQueue.pop_front()
		#visited.append(cell)
		#mutex.lock()
		#var val = getVal(cell)
		#mutex.unlock()
		#for offset in checkOffsets:
				#test = cell + offset
				#if !(cellsQueue.has(test) || visited.has(test)):
					#if(getOverflow(test)== checkOffsets[0]):
						#cellsQueue.append(test)
					#if val&encoder["blocktype"]["mask"] !=0:
						#noFacesChecked += 1
						#mutex.lock()
						#effects.merge(checkPair(cell,offset))
						#mutex.unlock()
						#tempSpread(cell,offset)
					
	for x in chunk_size.x:
		for y in chunk_size.y:
			for z in chunk_size.z:
				var pos = Vector3i(x,y,z)
				if getVal(pos)&encoder["blocktype"]["mask"] !=0:
					for offset in checkOffsets:
						noFacesChecked += 1
						mutex.lock()
						effects.merge(checkPair(pos,offset))
						mutex.unlock()
						tempSpread(pos,offset)
	
	print(str(OS.get_thread_caller_id())+": Finding actions for " + str(worldPos)+ "Checked "+ str(noFacesChecked) + " took " + str( Time.get_ticks_msec() - cstart ) +"ms to process" )
	mutex.lock()
	updateQueue = effects
	mutex.unlock()
	
				
func checkPair(cCord, dir) -> Dictionary:
	
	var ta = getVal(cCord)&encoder["blocktype"]["mask"]
	if ta == 0:
		return {}
	var bCords = cCord+dir
	var tb = getVal(bCords,true)&encoder["blocktype"]["mask"]
	var pa = Blocks.blocks[Blocks.index[ta]]
	if !pa.has("alchemic"):# is there even an alchemic map defined
		return {} 
	
	var blkVariant = readMeta(getVal(cCord),"blocktvar")
	var alchemic = pa["alchemic"] 
	if alchemic.size()<= blkVariant: # if there is o map defined for the variant
		return {}
	
	var varAlc = alchemic[blkVariant]
	if !varAlc.has(dir): # if nothing is defined for the direction
		return {}
	
	var index = Blocks.index[tb]
	var alc = varAlc[dir]
	var pair_actions: Array
	if alc.has(index): # if there is no map for the other value
		pair_actions = alc[index]
	elif  alc.has("any"): # also checks if we have a catch all.
		pair_actions = alc["any"]
		 
	else:
		return {}
		
	
	#needs to handle the following possible conditions.
	# block type, block var, impact, heat. this is permitting 
	var effects = {}
	for i in pair_actions.size():
		var passesCons = true
		var logicMode = "or"
		var action = pair_actions[i]
		if action.has("conditions"): #checks any conditions that may exist
			passesCons = false
			for check in action["conditions"]:
				if check == "logic":
					logicMode = action["conditions"][check]
				elif check == "heat":
					passesCons = true
					if action["conditions"][check].has("low"):
						passesCons = passesCons && temp[cCord.x][cCord.z][cCord.y] > action["conditions"][check]["low"]
					if action["conditions"][check].has("high"):
						passesCons = passesCons && temp[cCord.x][cCord.z][cCord.y] < action["conditions"][check]["high"]
				elif check == "impact":
					pass
	#				impliment impact check
				else:
					var pos = cCord if check == "self" else bCords
					var conditions = action["conditions"][check]
					for c in conditions:
						if typeof(c)== TYPE_STRING and c == "logic":
							logicMode = conditions[c]
						else:
							var passRow = true
							for mc in conditions[c]:
								var res = readMeta(getVal(pos+c,true),mc) == conditions[c][mc]
								passRow = passRow and res
							if logicMode == "and":
								passesCons = passesCons and passRow
							else:
								passesCons = passesCons or passRow
		if passesCons:
			#Handle enqueue actions
			if !updateQueue.has(bCords):# and updateQueue.size()<updateQueueSize:
				if action.has("other"):
					effects.merge({bCords:action["other"]})
				if action.has("self"):
					effects.merge({cCord:action["self"]})
				if action.has("heat"):
					temp[cCord.x][cCord.z][cCord.y] += action["heat"]
	return effects
		
func tempSpread(cCord, dir) -> void:
	var tempa = getTemp(cCord, true)
	var tempb = getTemp(cCord+dir, true)
	var transfer = (tempa-tempb)/4 #TODO use conductivity as a multiplier. using 2 by default
	setTemp(cCord, tempa-transfer)
	setTemp(cCord+dir, tempb+transfer)
	#TODO should conider all faces at the same time. heat is inclined to travle in a spacific direction as is

func genMesh() -> void:
	#remove all children
	for c in self.get_children():
		c.queue_free()
		
	prepareST(texture_surface)
	prepareST(collision_surface)
	linesTool.clear()
	linesTool.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		var nv = (v+Vector3(0.5,0.5,0.5))*cellSize*Vector3(chunk_size.x,chunk_size.y, chunk_size.z)
		linesTool.set_color(Color.CRIMSON)
		linesTool.add_vertex(nv)
	for i in ind:
		linesTool.add_index(i)
	
	
	var empty = true
	for x in chunk_size.x:
		for y in chunk_size.y:
			for z in chunk_size.z:
				if createBlock(Vector3i(x,y,z)):
					empty = false
	
	if ! empty:
		commitMesh(texture_surface)
		commitMesh(collision_surface, true)
	
	commitMesh(linesTool,false, false)
	
	self.visible = true
	updated = false

func prepareST(st:SurfaceTool):
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	st.set_material(MORE_ITEMS)

func commitMesh(st:SurfaceTool, colision: bool = false, shadow: bool = true):
	if(st.get_primitive_type()==Mesh.PRIMITIVE_TRIANGLES):
		st.generate_normals(false)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.set_mesh(st.commit())
	mesh_instance.cast_shadow = shadow
	add_child(mesh_instance)
	if colision:
		mesh_instance.create_trimesh_collision()

func createBlock(cCord : Vector3i) -> bool:
	var cell = getVal(cCord)
	if cell ==0:# if the vxl is empty.
		return false
	
	if(OS.get_thread_caller_id()>1):
		print("Something spooky is happening.")
		
	#TODO handle the norm and rotation on the faces
	var blockT = readMeta(cell,"blocktype")
	var blockV = readMeta(cell,"blocktvar")
	var norm = readMeta(cell,"norm")
	var facing = readMeta(cell,"rotation")
	var bockTextures = Blocks.blocks[Blocks.index[blockT]]["textures"][blockV]
	var hilighted = focous == cCord
	var res = false
	for f in FACES.values():
		if !getVal(cCord+f[1], true )&encoder["opaque"]["mask"]:
			if f[1].abs() == unPackNorm(norm).abs():
				createFace(f[0],cCord,bockTextures[f[2]],facing)
				res = true
			createFace(f[0],cCord,bockTextures[f[2]])
		if hilighted:
			createFace(f[0],cCord,Vector2(4,2),0,false ,1.02)
			if f[1] == f_norm:
				createFace(f[0],cCord,Vector2(5,2),0,false ,1.02)
	return res


func createFace(face,cCord : Vector3, faceT: Vector2,rot: int = 0, colidable: bool = true, rScale: float = 1):
	var flocal =  FACES
	var a = (vertices[face[0]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var b = (vertices[face[1]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var c = (vertices[face[2]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var d = (vertices[face[3]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	
	
	var uv_offset = faceT / Blocks.TEXTURE_ATLAS_SIZE2
	var height = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.y
	var width = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.x
	
	var uvs = [uv_offset + Vector2(0, 0),
		uv_offset + Vector2(0, height),
		uv_offset + Vector2(width, height),
		uv_offset + Vector2(width, 0)
	]
	
	if colidable:
		collision_surface.add_triangle_fan(([a,b,c]),([uvs[(1+rot)%4],uvs[(2+rot)%4],uvs[(0+rot)%4]]))
		collision_surface.add_triangle_fan(([d,c,b]),([uvs[(3+rot)%4],uvs[(0+rot)%4],uvs[(2+rot)%4]]))
	else:
		texture_surface.add_triangle_fan(([a,b,c]),([uvs[(1+rot)%4],uvs[(2+rot)%4],uvs[(0+rot)%4]]))
		texture_surface.add_triangle_fan(([d,c,b]),([uvs[(3+rot)%4],uvs[(0+rot)%4],uvs[(2+rot)%4]]))

func loadVxls() -> void:
	vxls = []
	temp = []
	temp. resize(chunk_size.x)
	vxls.resize(chunk_size.x)
	for x in chunk_size.x:
		vxls[x] = []
		temp[x] = []
		temp[x].resize(chunk_size.z)
		vxls[x].resize(chunk_size.z)
		for z in chunk_size.z:
			vxls[x][z] = []
			vxls[x][z].resize(chunk_size.y)
			temp[x][z] = []
			temp[x][z].resize(chunk_size.y)
			
			var dn = noise.get_noise_2d(z,x)
			var wCord = cCordToWCord(Vector3i(x,0,z))
			var height = 0
			if world != null:
				height = world.getHeight(wCord.x,wCord.z) - (chunk_size.y*worldPos.y)
			else:
				var hn = noise.get_noise_2d(wCord.x,wCord.z)
				height = (minY + (hn*60)) - (chunk_size.y*worldPos.y)
			var dd = dirtDept + dn*dirtVar 
			for y in chunk_size.y: 
				var b = 0
				if y == height:
					b = 3 | encoder["visable"]["mask"] | commonflags
				if y < height:
					b = 2 | encoder["visable"]["mask"] | commonflags
				if y <height - dd:
					b = 1 | encoder["visable"]["mask"] | commonflags
				vxls[x][z][y] = setMeta(b, "rotation", randi_range(0,encoder["rotation"]["max"]))
				temp[x][z][y] = 120- ((chunk_size.y*worldPos.y)+y)

func cCordToWCord(cCord: Vector3i) -> Vector3i:
	return cCord+(worldPos*chunk_size)
	
	
func getVal(cCords: Vector3i, considerWorld: bool = false) -> int:
	var bind: Vector3i = Vector3i(posmod(cCords.x, chunk_size.x),posmod(cCords.y, chunk_size.y),posmod(cCords.z, chunk_size.z))
	var overflow: Vector3i = getOverflow(cCords)
	if overflow == Vector3i(0,0,0):
		return vxls[cCords.x][cCords.z][cCords.y]
	if considerWorld and world != null:
		return world.get_block(((overflow+worldPos)*chunk_size)+bind)
	return 0
	
func setVal(cCords: Vector3i, val: int, flags: int = commonflags) -> void:
	var bind: Vector3i = Vector3i(posmod(cCords.x, chunk_size.x),posmod(cCords.y, chunk_size.y),posmod(cCords.z, chunk_size.z))
	var overflow: Vector3i = getOverflow(cCords)
	if overflow == Vector3i(0,0,0):
		if val > 0: # manage other flags including surface flag.
			val = val | flags
		vxls[cCords.x][cCords.z][cCords.y] = val
		updated = true #only updated if block is placed here.
		for f in FACES.values():
			overflow = getOverflow(cCords+f[1])
			if overflow != Vector3i(0,0,0):
				world.updateChunk(worldPos+overflow)
		return
	if world != null:
		world.place_block(((overflow+worldPos)*chunk_size)+bind, val)
		
func setTemp(cCords: Vector3i, val:float):
	var bind: Vector3i = Vector3i(posmod(cCords.x, chunk_size.x),posmod(cCords.y, chunk_size.y),posmod(cCords.z, chunk_size.z))
	var overflow: Vector3i = getOverflow(cCords)
	if overflow == Vector3i(0,0,0):
		temp[cCords.x][cCords.z][cCords.y] = val
		return
	if world != null:
		world.setTemp(((overflow+worldPos)*chunk_size)+bind, val)

func getTemp(cCords: Vector3i, considerWorld: bool = false) -> float:
	var bind: Vector3i = Vector3i(posmod(cCords.x, chunk_size.x),posmod(cCords.y, chunk_size.y),posmod(cCords.z, chunk_size.z))
	var overflow: Vector3i = getOverflow(cCords)
	if overflow == Vector3i(0,0,0):
		return temp[cCords.x][cCords.z][cCords.y]
	if considerWorld and world != null:
		var res =  world.getTemp(((overflow+worldPos)*chunk_size)+bind)
		if res == 0:
			res = getTemp(bind)
		return res
	return getTemp(bind)
	
func getOverflow(cCords) -> Vector3i:
	var res = Vector3i(0,0,0)
	for i in 3:
		if cCords[i] < 0:
			res[i] = -1
		if cCords[i] >= chunk_size[i]:
			res[i] = 1
	return res

func unHilightBlock():
	focous = null
	updated = true

func hilightBlock(cCord, norm):
	focous = cCord
	f_norm = norm
	updated = true

func setMeta(val: int, property: String, meta: int) -> int:
	if meta <= encoder[property]["max"] && meta >= 0 && val >0:
		return val | (meta<<encoder[property]["offset"])
	return val
func readMeta(val:int, property: String) -> int :
	return (val & encoder[property]["mask"])>>encoder[property]["offset"]
	
func unPackNorm(pnorm: int) -> Vector3i :
	if pnorm == 0:
		return Vector3i(1,0,0)
	if pnorm == 1:
		return Vector3i(-1,0,0)
	if pnorm == 2:
		return Vector3i(0,1,0)
	if pnorm == 3:
		return Vector3i(0,-1,0)
	if pnorm == 4:
		return Vector3i(0,0,1)
	if pnorm == 5:
		return Vector3i(0,0,-1)
	return Vector3i(0,-1,0) #default down
