@tool
extends Resource
class_name MeshTemplate

@export var vertices: PackedVector3Array
@export var Faces: Array[Face]
@export var Reset: Vector3


func getFace(dir: Global.DIR) -> PackedInt32Array:
	for f in Faces:
		if f.dir == dir:
			return f.vers
	return []
