extends MeshInstance3D

var data:SectionData
var cords: Vector3i
var size: Vector3i
var cellSize: float

var visable: PackedInt64Array 
# encoding into a 64 bit int 3x 20 bit numbers. with 4 bits left
const flag = 0x0fffff
const offser = 20

func _init(cords,size,cellSize) -> void:
	self.cords = cords
	self.size = size
	self.cellSize = cellSize
	data = SectionData.new(size,str(cords))
	# prepare/load data
	# prepare load mesh
	
	self.visable = PackedInt64Array() 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
