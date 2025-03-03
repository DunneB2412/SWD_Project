@tool
extends StaticBody3D
class_name Chunk
#masks for world encoding.
#all 32 bits accounted for 
const encoder = {
	"focus": 		{"mask":0x80000000,"max":1      , "offset": 31}, # 1000 0000 0000 0000 0000 0000 0000 0000
	"sky":   		{"mask":0x40000000,"max":1      , "offset": 30}, # 0100 0000 0000 0000 0000 0000 0000 0000
	"clickable":  	{"mask":0x20000000,"max":1      , "offset": 29}, # 0010 0000 0000 0000 0000 0000 0000 0000
	"opaque":		{"mask":0x10000000,"max":1      , "offset": 28}, # 0001 0000 0000 0000 0000 0000 0000 0000
	"simulate":		{"mask":0x08000000,"max":1      , "offset": 27}, # 0000 1000 0000 0000 0000 0000 0000 0000
	"solid":		{"mask":0x04000000,"max":1      , "offset": 26}, # 0000 0100 0000 0000 0000 0000 0000 0000
	"blocktype":	{"mask":0x000003ff,"max":0x03ff , "offset": 00}, # 0000 0000 0000 0000 0000 0011 1111 1111
	"blocktvar":	{"mask":0x00007c00,"max":0x001f , "offset": 10}, # 0000 0000 0000 0000 0111 1100 0000 0000
	"botomnorm":	{"mask":0x00038000,"max":0x0007 , "offset": 15}, # 0000 0000 0000 0011 1000 0000 0000 0000
	"rotation": 	{"mask":0x000c0000,"max":0x0003 , "offset": 17}, # 0000 0000 0000 1100 0000 0000 0000 0000
	"strain":		{"mask":0x00f00000,"max":0x000f , "offset": 20}, # 0000 0000 1111 0000 0000 0000 0000 0000
	"pcounter": 	{"mask":0x03000000,"max":0x0003 , "offset": 24}  # 0000 0011 0000 0000 0000 0000 0000 0000
}
const commonflags = 0x14000000

# corner transforms
const vertices = [
	Vector3(-0.5,-0.5,-0.5), #0 bottom back left
	Vector3(0.5,-0.5,-0.5), #1 bottom fromt left
	Vector3(-0.5,0.5,-0.5), #2 top back left
	Vector3(0.5,0.5,-0.5), #3 top front left
	Vector3(-0.5,-0.5,0.5), #4 bottom back right
	Vector3(0.5,-0.5,0.5), #5 bottom front right
	Vector3(-0.5,0.5,0.5), #6 top back right
	Vector3(0.5,0.5,0.5)  #7 top front right
]
var reset = Vector3(0.5,0.5,0.5)
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
const OUTLINE = preload("res://materials/test/outline.png")
const MORE_ITEMS = preload("res://materials/test/moreItems.tres")
#Members
var vxls: Array = []
var visable: PackedVector3Array = PackedVector3Array()

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

var texture_surface = SurfaceTool.new()
var collision_surface = SurfaceTool.new()

var updateQueue: Dictionary = {}
@export var updateQueueSize = 16
var checkerThread: Thread = Thread.new()

var updated = false

func _ready() -> void:
	noise.seed = genSeed
	updateQueue = {}
	loadVxls()
	genMesh()

func _process(_delta: float) -> void:
	for pos in updateQueue:
		setVal(pos, updateQueue[pos])
		updateQueue.erase(pos)
	if updated:
		genMesh()

func startSim():
	pass
	#checkerThread.start(chunkThread)
	
func chunkThread():
	while true:
		find_actions()
		await get_tree().create_timer(0.5).timeout
func find_actions():
	#use offset grid idea.. this will still technically be 8 chose 2 
	#or 28 unique pars but there should be no duplicate checks. 
	#if we asume a standard chunk of 32*32*32 and check all the paris
	# then we have 917,504 checks to perform.
	# this will only consider extras in the positive directions. 
	# this gows to 1,006,236 when considering neighbour chunks. 
	# not sure i have a smart way to couver this search space.
	# the check can be done in read only (thread safe) and can enqueue them
	# the queued sim action needs to sote the affected pos, 
	#the co-operating pos and the strength/ priority
	
	#otherwise, we can be more carefull in how we design reaction maps and 
	#may be able to get away with 6 samples per block. totaling 196,608 checks.
	# maybe check the reaction map first to help cut this back.
	for x in chunk_size.x:
		for y in chunk_size.y:
			for z in chunk_size.z:
				pass
				
func checkPair(cCord, dir) -> void:
	var ta = getVal(cCord)&encoder["blocktype"]["mask"]
	var bCords = cCord+dir
	var tb = getVal(bCords,true)&encoder["blocktype"]["mask"]
	var pa = Blocks.blocks[Blocks.index[ta-1]]
	if !pa.has("alchemic"):# is there even an alchemic map defined
		return
	
	var varEnc = encoder["blocktvar"]
	var blkVariant = (ta&varEnc["mask"])>>varEnc["offset"]
	var alchemic = pa["alchemic"]
	if alchemic.size()<= blkVariant: # if there is o map defined for the variant
		return
	
	var varAlc = alchemic[blkVariant]
	if !varAlc.has(dir): # if nothing is defined for the direction
		return
	
	var alc = varAlc[dir]
	var p
	if alc.has(Blocks.index[tb-1]): # if there is no map for the other value
		p = alc[Blocks.index[tb-1]]
	elif  alc.has("any"): # also checks if we have a catch all.
		p = alc["any"]
	else:
		return
		
	var passesCons = true
	var logicMode = "or"
	#needs to handle the following possible conditions.
	# block type, block var, impact, heat. this is permitting 
	if p.has("conditions"): #checks any conditions that may exist
		passesCons = false
		for check in p["conditions"]:
			if check == "logic":
				logicMode = p["conditions"][check]
			elif check == "heat":
				pass
#				impliment heat check
			elif check == "impact":
				pass
#				impliment impact check
			else:
				var pos = cCord if check == "self" else bCords
				var conditions = p["conditions"][check]
				for c in conditions:
					if typeof(c)== TYPE_STRING and c == "logic":
						logicMode = conditions[c]
					else:
						for mc in conditions[c]:
							var res = readMeta(getVal(pos+c,true),mc) == conditions[c][mc]
							if logicMode == "and":
								passesCons = passesCons and res
							else:
								passesCons = passesCons or res
	
	if passesCons && p.has("other") and !updateQueue.has(bCords) and updateQueue.size()<updateQueueSize:
		updateQueue.merge({bCords:p["other"]})
		var t = getVal(bCords,true)
	if passesCons && p.has("self") and !updateQueue.has(bCords) and updateQueue.size()<updateQueueSize:
		updateQueue.merge({cCord:p["self"]})

func genMesh() -> void:
	
	
	#remove all children
	for c in self.get_children():
		c.queue_free()
	# prepare texture mesh
	var texture_mesh= ArrayMesh.new()
	var texture_meshInstance = MeshInstance3D.new()
	texture_surface.clear()
	texture_surface.begin(texture_mesh.PRIMITIVE_TRIANGLES)
	texture_surface.set_smooth_group(-1)
	texture_surface.set_material(TESTMATERIAL)
	
	#prep collision mesh
	var collision_mesh= ArrayMesh.new()
	var collision_meshInstance = MeshInstance3D.new()
	collision_surface.clear()
	collision_surface.begin(texture_mesh.PRIMITIVE_TRIANGLES)
	collision_surface.set_smooth_group(-1)
	collision_surface.set_material(TESTMATERIAL)
	
	# TODO get air first and get visable faces then.
	var empty = true
	for x in chunk_size.x:
		for y in chunk_size.y:
			for z in chunk_size.z:
				empty = !createBlock(Vector3i(x,y,z)) and empty
	
	if empty:
		return
	
	texture_surface.generate_normals(false)
	texture_surface.commit(texture_mesh)
	texture_surface.set_material(TESTMATERIAL)
	texture_meshInstance.set_mesh(texture_mesh)
	add_child(texture_meshInstance)
	
	collision_surface.generate_normals(false)
	collision_surface.commit(collision_mesh)
	collision_meshInstance.set_mesh(collision_mesh)
	add_child(collision_meshInstance)
	collision_meshInstance.create_trimesh_collision()
	self.visible = true
	updated = false


func createBlock(cCord : Vector3i) -> bool:
	var cell = getVal(cCord)
	if cell ==0:# if the vxl is empty.
		return false
	var t = Blocks.index[(cell&encoder["blocktype"]["mask"])-1]
	var block_info = Blocks.types[Blocks.index[(cell&encoder["blocktype"]["mask"])-1]]
	var hilighted = (cell & encoder["focus"]["mask"])>0
	
	#TODO handle the norm and rotation on the faces
	for f in FACES.values():
		checkPair(cCord,f[1])
		if !getVal(cCord+f[1])&encoder["opaque"]["mask"]:
			createFace(f[0],cCord,block_info[f[2]])
		if hilighted:
			var color = Color.DARK_MAGENTA
			color.a8 = 100
			createFace(f[0],cCord,Vector2(1,1),false ,1.01, color)
	return true


func createFace(face,cCord : Vector3, faceT: Vector2,colidable: bool = true, rScale: float = 1, color: Color = Color.WHITE):
	var a = (vertices[face[0]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var b = (vertices[face[1]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var c = (vertices[face[2]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var d = (vertices[face[3]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	
	
	var uv_offset = faceT / Blocks.TEXTURE_ATLAS_SIZE
	var height = 1.0 / Blocks.TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / Blocks.TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, height)
	var uv_c = uv_offset + Vector2(width, height)
	var uv_d = uv_offset + Vector2(width, 0)
	
	if colidable:
		collision_surface.add_triangle_fan(([a,b,c]),([uv_b,uv_c,uv_a]),([color,color,color]))
		collision_surface.add_triangle_fan(([d,c,b]),([uv_d,uv_a,uv_c]),([color,color,color]))
	else:
		texture_surface.add_triangle_fan(([a,b,c]),([uv_b,uv_c,uv_a]),([color,color,color]))
		texture_surface.add_triangle_fan(([d,c,b]),([uv_d,uv_a,uv_c]),([color,color,color]))

func loadVxls() -> void:
	vxls = []
	vxls.resize(chunk_size.x)
	for x in chunk_size.x:
		vxls[x] = []
		vxls[x].resize(chunk_size.z)
		for z in chunk_size.z:
			vxls[x][z] = []
			vxls[x][z].resize(chunk_size.y)
			
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
					b = 3 | encoder["sky"]["mask"] | commonflags
				if y < height:
					b = 2 | commonflags
				if y <height - dd:
					b = 1 | commonflags
				vxls[x][z][y] = b

	
func setGenParms(pos: Vector3i, genseed: int, world: World, chunk_size: Vector3i, cell_size: float) -> void:
	self.visible = false
	worldPos = pos
	position = pos*chunk_size*cellSize
	noise.seed = genseed
	self.world = world
	self.chunk_size = chunk_size
	self.cellSize = cell_size
	self.reset = Vector3(0.5,0.5,0.5)*cellSize
	loadVxls()

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
			val = val | commonflags
		vxls[cCords.x][cCords.z][cCords.y] = val
		updated = true #only updated if block is placed here.
		return
	if world != null:
		world.place_block(((overflow+worldPos)*chunk_size)+bind, val)
	
func getOverflow(cCords) -> Vector3i:
	var res = Vector3i(0,0,0)
	for i in 3:
		if cCords[i] < 0:
			res[i] = -1
		if cCords[i] >= chunk_size[i]:
			res[i] = 1
	return res

func unHilightBlock(cCord):
	var val = getVal(cCord)
	setVal(cCord, val & ~(encoder["focus"]["mask"]),0)
	

func hilightBlock(cCord):
	var val = vxls[cCord.x][cCord.z][cCord.y]
	setVal(cCord, val | encoder["focus"]["mask"],0)

func setMeta(val: int, property: String, meta: int) -> int:
	if meta <= encoder[property]["max"] && meta >= 0:
		return val | (meta<<encoder[property]["offset"])
	return val
func readMeta(val:int, property: String) -> int :
	return (val & encoder[property]["mask"])>>encoder[property]["offset"]
