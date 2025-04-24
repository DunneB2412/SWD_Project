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

const INC = SectionData.INC

var data:SectionData
var dataMutex: Mutex
var pos: Vector3i
@export var size: Vector3i
@export var cellSize: float
var root: Node
@export var lib: BlockLib

var debugMode = false
var debugContainer: Node3D
var updated = false
var nextMesh: Mesh
var meshMutex: Mutex


func _init(posIn: Vector3i,sizeIn: Vector3i,cellSizeIn: float, rootIn: Node, libIn: BlockLib) -> void:
	self.pos = posIn
	self.size = sizeIn
	self.cellSize = cellSizeIn
	self.root = rootIn
	
	self.lib = libIn
	self.name = "section"+str(pos)
	self.position = pos*size*cellSize
	
	
	
	dataMutex = Mutex.new()
	meshMutex = Mutex.new()
	loadSection()
	
func _process(_delta: float) -> void:
	
	
	if nextMesh!= null:
		#print(str(OS.get_thread_caller_id())+" locking "+ str(pos) +" data at proess ")
		if(meshMutex.try_lock()):
			self.mesh = nextMesh
			nextMesh = null
			if debugContainer != null:
				for c in self.get_children():#remove any children if any.
					c.queue_free()
				add_child(debugContainer)
				debugContainer = null
			meshMutex.unlock()


func loadSection() -> void:
	#self.data = load("res://saves/"+str(cords)+".tres")
	#try to load the resorce.
	data = SectionData.new(size,str(pos)) #create a new one
	for x in size.x:
		for z in size.z:
			
			var wCord = Vector3i(x,0,z)+(pos*size)
			var height = size.y
			var waterHeight = 0
			if root != null:
				height = root.getHeight(wCord.x,wCord.z) - (size.y*pos.y)
				waterHeight = root.getWaterLine() - (size.y*pos.y)
				height = waterHeight
			if wCord.x ==4 and wCord.z == 4:
				waterHeight = waterHeight+4
			
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
						v = SectionData.setMeta(v,INC.PHASE, 1)
						v = SectionData.setMeta(v,INC.OPAQUE, 0)
					v = SectionData.setMeta(v, INC.ROTATION, randi_range(0,SectionData.metaLim(INC.ROTATION)))
					#b = SectionData.setMeta(b,INC.NORM, randi_range(0,SectionData.metaLim(INC.NORM)))
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
	var ts = SurfaceTool.new()
	ts.begin(Mesh.PRIMITIVE_TRIANGLES)
	ts.set_smooth_group(-1)
	ts.set_material(lib.material)
	
	#print(str(OS.get_thread_caller_id())+" locking "+ str(pos) +" data at gen mesh ")
	var con = Node3D.new()
	if debugMode:
		DebugOutline(con)
	dataMutex.lock()
	var cells = data.get_filled_cells().duplicate()
	dataMutex.unlock()
	if cells.size()>0:
		
		for c in cells:
			createBlock(c,ts,con,[])
		
	ts.generate_normals(false)
	meshMutex.lock()
	nextMesh = ts.commit()
	debugContainer = con
	meshMutex.unlock()
	updated = false
		
func DebugOutline(con: Node3D):
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
	con.add_child(mesh_instance)

func createBlock(cord : Vector3i, surface: SurfaceTool, debcon: Node3D, visited: Array[Vector3i]):
	var cell = data.getVal(cord).duplicate() #we are only considering one atm
	
	#there are a bunch of flags that we do not need to encode in each min, only in cell.
	#may not use var as mineral model dose nto require it.
	#record on textuure if it should be notm aligned, world aligned or rotatable
	var rot
	var norm = 0
	
	for i in min(cell.size(),5):
		var min = cell[i]
		var blockT = SectionData.readMeta(min,INC.BLOCK_TYPE)
		var phase = SectionData.readMeta(min,INC.PHASE)
		
		var bockTextures
		if i ==0:
			#norm = SectionData.readMeta(min,SectionData.INC.NORM)
			rot= SectionData.readMeta(min,INC.ROTATION)
			bockTextures = lib.blocks[blockT].mineral.prim_texture.getPhase(phase).getTextures()
		else:
			bockTextures = lib.blocks[blockT].mineral.aux_texture.getPhase(phase).getTextures()
		
		var color = lib.blocks[blockT].mineral.color
		color.a = (1.0/(i+1)) # * min(lib.blocks[blockT].mineral.normalDendity/ data.readMeta(min,INC.MASS),1)
		var template = lib.blocks[blockT].FULL_BLOCK
		
		
		for f: Face in template.Faces:
			var offset = Global.OFFSETS[f.dir]
			var n = getVal(cord+offset)[0]
			var t = SectionData.readMeta(n,INC.BLOCK_TYPE)
			var opaque = SectionData.readMeta(n,INC.OPAQUE)
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
					debcon.add_child(test)
			#else:TODO use a recursion for here. 
				#createBlock()


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
		
		dataMutex.lock()
		var cell = data.getVal(cord).duplicate()
		dataMutex.unlock()
		return cell
	elif root != null && root.has_method("getVal"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		return root.getVal(((overflow+pos)*size)+bind)
	return [0]
func addAt(cord: Vector3i, val: int, mass: int) -> void:
	var overflow = getOverflow(cord)
	if overflow == Global.REF_VEC3:
		#print(str(OS.get_thread_caller_id())+" locking "+ str(pos) +" data at 'add at'")
		dataMutex.lock()
		data.updateMassFor(cord,val,mass)
		dataMutex.unlock()
		updated = true
		#if(root != null && root.has_method("updateChunk")):
			#for d in Global.OFFSETS.values():
				#if(checkBounds(cord+d)):
					#root.updateChunk(cCordToWCord(cord))
	elif root != null && root.has_method("addAt"):
		var bind: Vector3i = Vector3i(posmod(cord.x, size.x),posmod(cord.y, size.y),posmod(cord.z, size.z))
		root.addAt((((overflow+pos)*size)+bind),val,mass)
func initWith(cord:Vector3i, val: int):
	addAt(cord,val, lib.blocks[SectionData.readMeta(val,INC.BLOCK_TYPE)].mineral.normalDendity - 500)# (randi_range(-150,150)))
	
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

	
#Simuylation
func findAction():
	# perhaps the fluid sim would work better using momentom vectors and impact.
	
	var vis: Array[Vector3i] = []
	var cells: Array = data.get_filled_cells()
	for i in cells.size():
		var pos = cells[i]
		var cell = data.getVal(pos)
		
		for j in cell.size():
			var m = cell[j]
			if SectionData.readMeta(m,INC.PHASE) >0 && j <= 4:
				fluidAct(pos,m)
			for dir in Global.OFFSETS.values():
				var alt = pos+dir
				if !vis.has(alt):
					pass
			
		
	

func fluidAct(cord:Vector3i, m: int):
	var t = SectionData.readMeta(m,INC.BLOCK_TYPE)
	var den = lib.blocks[t].mineral.normalDendity
	var mas = SectionData.readMeta(m,INC.MASS)


	#try down 
	var altdata = data.getVal(cord+Global.OFFSETS[Global.DIR.DOWN])[0] #we will only consider the primary
	var altp = SectionData.readMeta(altdata,INC.PHASE)
	if altdata == 0 || altp > 0:
		var altT = SectionData.readMeta(altdata, INC.BLOCK_TYPE)
		if altT == t:
			var altM = SectionData.readMeta(altdata, INC.MASS)
			var avg = altM+mas/2
			if avg > den:
				addAt(cord,m,avg-mas)
				addAt(cord+Global.OFFSETS[Global.DIR.DOWN],m,avg-altM)
				mas = avg
			else:
				var dif = min(den -altM, mas) # at most current mass
				addAt(cord,m,-dif)
				mas = mas - dif
				addAt(cord+Global.OFFSETS[Global.DIR.DOWN],m,dif)
				if  mas == 0:
					return
		else:			
			var altd = lib.blocks[altT].mineral.normalDendity
			if altd < den:
				var dif = min(den, mas) #send as much as naturally permited.
				addAt(cord,m,-dif)
				mas = mas - dif
				addAt(cord+Global.OFFSETS[Global.DIR.DOWN],m,dif)
				if mas == 0:
					return
	else:
		#permuable ?
		pass

	if mas<20: #don't split if there is not enough TODO should depend on viscosity of liquid. 
		return
	#can't fall or float, try flow.
	var dirs = [
		Global.OFFSETS[Global.DIR.SOUTH],Global.OFFSETS[Global.DIR.NORTH],
		Global.OFFSETS[Global.DIR.EAST],Global.OFFSETS[Global.DIR.WEST]
	]
	var suitable = [[Vector3i(0,0,0),mas,1]]
	var sumM = mas
	for dir in dirs:
		altdata = data.getVal(cord+dir)[0] #we will only consider the primary
		altp = SectionData.readMeta(altdata,INC.PHASE)
		if altdata == 0 || altp > 0:
			var altT = SectionData.readMeta(altdata, INC.BLOCK_TYPE)
			var altd = lib.blocks[SectionData.readMeta(altdata, INC.BLOCK_TYPE)].mineral.normalDendity
			if altd < den:
				suitable.append([dir,0,1])
			elif altT == t:
				var altM = SectionData.readMeta(altdata, INC.MASS)
				suitable.append([dir,altM,1])
				sumM += altM
		else:
			pass #solid permit
	
	var avgm = sumM / suitable.size()
	for o in suitable:
		var e = cord+o[0]
		var dif = (avgm-o[1])*o[2]
		addAt(e,m,dif)
