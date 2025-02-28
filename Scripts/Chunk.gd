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
#Members
var vxls = []
var ents = []

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
	
	for x in chunk_size.x:
		for y in chunk_size.y:
			for z in chunk_size.z:
				pass
					
func checkPair(posa, posb) -> void:
	var ta = getVal(posa)&encoder["blocktype"]["mask"]
	var tb = getVal(posb)&encoder["blocktype"]["mask"]
	var pa = Blocks.blocks[Blocks.index[ta-1]]
	if pa.has("alchemic"):
		var alc = pa["alchemic"]
		if alc.has(Blocks.index[tb-1]):
			var p = alc[Blocks.index[tb-1]]
			var passesCons = true
			if p.has("conditions"):
				var conditions = p["conditions"]["other"]
				for c in conditions:
					passesCons = getVal(posb+c) == conditions[c]
			if passesCons && p.has("other") and !updateQueue.has(posb) and updateQueue.size()<updateQueueSize:
				updateQueue.merge({posb:p["other"]})
	
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
		var o = getVal(cCord+f[1],true)
		checkPair(cCord, cCord+f[1])
		if !o&encoder["opaque"]["mask"]:
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
	genMesh()

func cCordToWCord(cCord: Vector3i) -> Vector3i:
	return cCord+(worldPos*chunk_size)
	
	
func getVal(cCords: Vector3i, considerWorld: bool = false) -> int:
	var bind: Vector3i = cCords % chunk_size
	var overflow: Vector3i = getOverflow(cCords)
	if overflow == Vector3i(0,0,0):
		return vxls[cCords.x][cCords.z][cCords.y]
	if considerWorld and world != null:
		return world.get_block((overflow*chunk_size)+bind)
	return 0
	
func setVal(cCords: Vector3i, val: int, flags: int = commonflags) -> void:
	var bind: Vector3i = cCords % chunk_size
	#var overflow: Vector3i = getOverflow(cCords)
	if bind != cCords:
		return
	if val > 0: # manage other flags including surface flag.
		val = val | commonflags
	vxls[cCords.x][cCords.z][cCords.y] = val
	updated = true
	
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
	
