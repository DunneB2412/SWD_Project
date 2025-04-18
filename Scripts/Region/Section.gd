@tool
extends MeshInstance3D
class_name Section

#temp for debug
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


var data:SectionData
var pos: Vector3i
@export var size: Vector3i
@export var cellSize: float
var root: Node

@export var lib: BlockLib
var debugMode = false
var debugContainer: Node3D = Node3D.new()


func _init(posIn: Vector3i,sizeIn: Vector3i,cellSizeIn: float, rootIn: Node, libIn: BlockLib) -> void:
	self.pos = posIn
	self.size = sizeIn
	self.cellSize = cellSizeIn
	self.root = rootIn
	
	self.lib = libIn
	self.name = "section"+str(pos)
	self.position = pos*size*cellSize
	
	loadSection()
	add_child(debugContainer)


func loadSection() -> void:
	#self.data = load("res://saves/"+str(cords)+".tres")
	#try to load the resorce.
	data = SectionData.new(size,str(pos)) #create a new one
	for x in size.x:
		for z in size.z:
			
			var wCord = Vector3i(x,0,z)+(pos*size)
			var height = size.y
			if root != null:
				height = root.getHeight(wCord.x,wCord.z) - (size.y*pos.y)
			var waterHeight = 60 - (size.y*pos.y) #parent root should own water height.
			var soil = 2
			if height - 3 < waterHeight:
				soil = 8
			
			var dd = 3
			for y in size.y: 
				var b = 0
				if y <= waterHeight && y > height:
					b = 7
				if y <= height:
					b = soil 
				if y <height - dd:
					b = 1
				if b>0:
					var v = b | lib.blocks[b].commonMask
					if b == 7:
						v = SectionData.setMeta(v,SectionData.INC.PHASE, 1)
						v = SectionData.setMeta(v,SectionData.INC.OPAQUE, 0)
					v = SectionData.setMeta(v, SectionData.INC.ROTATION, randi_range(0,SectionData.metaLim(SectionData.INC.ROTATION)))
					#b = SectionData.setMeta(b, SectionData.INC.NORM, randi_range(0,SectionData.metaLim(SectionData.INC.NORM)))
					initWith(Vector3i(x,y,z),v)
					if y == height && b == 2:
						addAt(Vector3i(x,y,z),3,5)
					if y <= height && randi_range(0,10)>=8:
						addAt(Vector3i(x,y,z),5,1000)
					setTemp(Vector3i(x,y,z),120- ((size.y*pos.y)+y))

func getOverflow(cord) -> Vector3i:
	var res = Vector3i(0,0,0)
	for i in 3:
		if cord[i] < 0:
			res[i] = -1
		if cord[i] >= size[i]:
			res[i] = 1
	return res


func genMesh() -> void:
	#remove all children
	for c in self.get_children():
		c.queue_free()
	if debugMode:
		DebugOutline()
	var cells = data.get_filled_cells()
	if cells.size()==0:
		return
	
	var ts = prepareST()
	for c in cells:
		createBlock(c,ts)
	
	ts.generate_normals(false)
	self.mesh = ts.commit()

	self.visible = true
		
func DebugOutline():
	var lt = SurfaceTool.new()
	lt.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		var nv = (v+Vector3(0.5,0.5,0.5))*cellSize*Vector3(size.x,size.y, size.z)
		lt.set_color(Color.CRIMSON)
		lt.add_vertex(nv)
	for i in ind:
		lt.add_index(i)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.set_mesh(lt.commit())
	mesh_instance.cast_shadow = false
	mesh_instance.name = "outline"
	add_child(mesh_instance)

func prepareST():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	st.set_material(lib.material)
	return st

func createBlock(cord : Vector3i, surface: SurfaceTool):
	var cell = data.getVal(cord) #we are only considering one atm
	
	if(OS.get_thread_caller_id()>1):
		print("Something spooky is happening.") # we should considere adding the new mesh to a queue then transfering once ready.
	
	#there are a bunch of flags that we do not need to encode in each min, only in cell.
	#may not use var as mineral model dose nto require it.
	#record on textuure if it should be notm aligned, world aligned or rotatable
	var rot
	var norm = 0
	
	for i in min(cell.size(),5):
		var min = cell[i]
		var blockT = SectionData.readMeta(min,SectionData.INC.BLOCK_TYPE)
		var phase = SectionData.readMeta(min,SectionData.INC.PHASE)
		
		var bockTextures
		if i ==0:
			#norm = SectionData.readMeta(min,SectionData.INC.NORM)
			rot= SectionData.readMeta(min,SectionData.INC.ROTATION)
			bockTextures = lib.blocks[blockT].mineral.prim_texture.getPhase(phase).getTextures()
		else:
			bockTextures = lib.blocks[blockT].mineral.aux_texture.getPhase(phase).getTextures()
		
		var color = lib.blocks[blockT].mineral.color
		color.a = 1.0/(i+1)
		var template = lib.blocks[blockT].FULL_BLOCK
		
		
		for f: Face in template.Faces:
			var offset = Global.OFFSETS[f.dir]
			var n = getVal(cord+offset)[0]
			var t = SectionData.readMeta(n,SectionData.INC.BLOCK_TYPE)
			var opaque = SectionData.readMeta(n,SectionData.INC.OPAQUE)
			if !opaque && (t != blockT):
				if f.dir == Global.DIR.UP ||  f.dir == Global.DIR.DOWN:
					createFace(f.vers,template.vertices, template.Reset,surface,cord,bockTextures[(f.dir+norm)%6],color,rot)
				else:
					createFace(f.vers,template.vertices, template.Reset,surface,cord,bockTextures[(((f.dir-2)+rot)%4)+2],color,0)
				if debugMode && i==0:
					var test = Label3D.new()
					test.text = str(cord+(pos*size))+"\n"+data.info(cord)
					test.position = (cord * cellSize) + (Vector3(cellSize,cellSize,cellSize)/2) + (Global.OFFSETS[f.dir]*0.51)
					test.font_size = 12
					
					test.rotation = Vector3(deg_to_rad(-90)*offset.y,(deg_to_rad(90)*offset.x)+(deg_to_rad(180)*min(offset.z,0)),0)
					add_child(test)


func createFace(face: PackedInt32Array, vert:PackedVector3Array, reset: Vector3, surface: SurfaceTool ,cCord : Vector3, faceT: Vector2,color: Color, rot: int = 0, rScale: float = 1):
	var a = (vert[face[0]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var b = (vert[face[1]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var c = (vert[face[2]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	var d = (vert[face[3]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	
	
	var uv_offset = faceT / lib.size
	var height = 1.0 / lib.size.y
	var width = 1.0 / lib.size.x
	
	var uvs = [uv_offset + Vector2(0, 0),
		uv_offset + Vector2(0, height),
		uv_offset + Vector2(width, height),
		uv_offset + Vector2(width, 0)
	]
	surface.add_triangle_fan(([a,b,c]) ,([uvs[(1+rot)%4],uvs[(2+rot)%4],uvs[(0+rot)%4]]),([color,color,color]))
	surface.add_triangle_fan(([d,c,b]) ,([uvs[(3+rot)%4],uvs[(0+rot)%4],uvs[(2+rot)%4]]),([color,color,color]))
	
	
#util functions
#mater handelers
func getVal(cord: Vector3i) -> PackedInt64Array:
	var overflow = getOverflow(cord)
	if overflow == Global.REF_VEC3:
		return data.getVal(cord)
	elif root != null && root.has_method("getVal"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		return root.getVal(((overflow+pos)*size)+bind)
	return [0]
func addAt(cord: Vector3i, val: int, mass: int) -> void:
	var overflow = getOverflow(cord)
	if overflow == Global.REF_VEC3:
		if mass >=0:
			data.addAt(cord,val,mass)
		else:
			data.consume(cord,val,mass)
		#if(root != null && root.has_method("updateChunk")):
			#for d in Global.OFFSETS.values():
				#if(checkBounds(cord+d)):
					#root.updateChunk(cCordToWCord(cord))
	elif root != null && root.has_method("addAt"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		root.addAt((((overflow+pos)*size)+bind),val,mass)
func initWith(cord:Vector3i, val: int):
	addAt(cord,val, lib.blocks[SectionData.readMeta(val,SectionData.INC.BLOCK_TYPE)].mineral.normalDendity)
	
#temprature handelers
func setTemp(cord: Vector3i, val:float):
	var overflow = getOverflow(cord)
	if overflow == Global.REF_VEC3:
		data.setTemp(cord,val)
	elif root != null && root.has_method("setTemp"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		root.setTemp((((overflow+pos)*size)+bind),val)
func getTemp(cord: Vector3i) -> float:
	var overflow = getOverflow(cord)
	if overflow == Global.REF_VEC3:
		return data.getTemp(cord)
	elif root != null && root.has_method("getTemp"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		return root.getTemp((((overflow+pos)*size)+bind))
	return 0
func addHeatAt(cord: Vector3i, heat: int):
	var overflow = getOverflow(cord)
	if overflow == Global.REF_VEC3:
		data.addHeatAt(cord, heat)
	elif root != null && root.has_method("addHeatAt"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		root.addHeatAt((((overflow+pos)*size)+bind),heat)
	
