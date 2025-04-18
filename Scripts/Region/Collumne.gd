@tool
extends Node3D
class_name Collumne

var sections: Dictionary #[int,Section]

@export var pos: Vector2i
@export var root: Node
@export var colSize: int
@export var cellSize: float
@export var lib: BlockLib

var mutex: Mutex


func _init(posIn: Vector2i, world: Node, colSizeIn: int, cellSizeIn: float, libIn : BlockLib) -> void:
	self.visible = false
	self.pos = posIn
	position.x = posIn.x*colSizeIn*cellSizeIn
	position.y = 0
	position.z = posIn.y*colSizeIn*cellSizeIn
	self.root = world
	self.colSize = colSizeIn
	self.cellSize = cellSizeIn
	self.lib = libIn
	
	self.name = "Col"+str(pos)
	
	mutex = Mutex.new()
	#loadSurface()
#
	#
	#
#func loadSurface() -> void:
	#sections = {}
	#for x in colSize:  #load all surface sections. 
		#for z in colSize:
			#var height = 0
			#var wCord = cCordToWCord(Vector3i(x,0,z))
			#if root != null and root.has_method("getHeight"):
				#height = root.getHeight(wCord.x,wCord.z)
			#var sec = height/colSize
			#if !sections.has(sec):
				#sections.merge({sec:Section.new(Vector3i(0,sec,0),Vector3i(colSize,colSize,colSize),cellSize, self, lib)})
				#
	#for s : Section in sections.values():
		#s.genMesh()
		#add_child(s)
	#self.visible=true
#
#
#func cCordToWCord(cCord: Vector3i) -> Vector3i:
	#return cCord+(Vector3i(pos.x,0,pos.y)*colSize)
	#
#func getHeight( x,  z)-> int:
	#var wcord = cCordToWCord(Vector3i(x,0,z))
	#return root.getHeight(wcord.x,wcord.z)
#
#
#func getOverflow(cord) -> Vector2i:
	#var res = Vector3i(0,0,0)
	#for i in 3:
		#if cord[i] < 0:
			#res[i] = -1
		#if cord[i] >= colSize:
			#res[i] = 1
	#return res
	#
#func getSection(y: int) -> Section:
	#var sy = floor(y/colSize)
	#if sections.has(sy):
		#return sections[sy]
	#return null
#
##util functions
##mater handelers
#func getVal(cord: Vector3i) -> PackedInt64Array:
	#if(checkBounds(cord)):
		#var sec = getSection(cord.y)
		#if sec != null:
			#return sec.getVal(cord%colSize)
		#return [0]
	#elif root != null && root.has_method("getVal"):
		#return root.getVal(cCordToWCord(cord))
	#return [0]
#func addAt(cord: Vector3i, val: int, mass: int) -> void:
	#if(checkBounds(cord)):
		#var sec = getSection(cord.y)
		#if sec != null:
			#sec.addAt(cord%colSize,val,mass)
			#if(root != null && root.has_method("updateChunk")):
				#for d in Global.DIR:
					#if(checkBounds(cord+d)):
						#root.updateChunk(cCordToWCord(cord))
			#return
	#elif root != null && root.has_method("addAt"):
		#root.addAt(cCordToWCord(cord),val,mass)
#func initWith(cord:Vector3i, val: int):
	#addAt(cord,val, lib.blocks[SectionData.readMeta(val,SectionData.INC.BLOCK_TYPE)].mineral.normalDendity)
	#
##temprature handelers
#func setTemp(cord: Vector3i, val:float):
	#if(checkBounds(cord)):
		#var sec = getSection(cord.y)
		#if sec != null:
			#sec.setTemp(cord%colSize,val)
	#elif root != null && root.has_method("setTemp"):
		#root.setTemp(cCordToWCord(cord),val)
#func getTemp(cord: Vector3i) -> float:
	#if(checkBounds(cord)):
		#var sec = getSection(cord.y)
		#if sec != null:
			#return sec.getTemp(cord%colSize)
	#elif root != null && root.has_method("getTemp"):
		#return root.getTemp(cCordToWCord(cord))
	#return 0
#func addHeatAt(cord: Vector3i, heat: int):
	#if(checkBounds(cord)):
		#var sec = getSection(cord.y)
		#if sec != null:
			#sec.addHeatAt(cord%colSize, heat)
	#elif root != null && root.has_method("addHeatAt"):
		#root.addHeatAt(cCordToWCord(cord),heat)
