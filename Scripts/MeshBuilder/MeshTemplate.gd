@tool
extends Resource
class_name MeshTemplate

@export var vertices: PackedVector3Array
@export var Faces: Array[Face]
@export var Reset: Vector3

#func createFaceOnSurface(surface: SurfaceTool, lib: BlockLib, facei: int, rot: int, rotNorm: int, blkNorm: int, scale: float, offset: Vector3):#(face: PackedInt32Array, vert:PackedVector3Array, reset: Vector3, surface: SurfaceTool ,cCord : Vector3, faceT: Vector2,rot: int = 0, rScale: float = 1):
	#var face = Faces[facei].vers
	#var a = (vertices[face[0]]*(scale)) + offset + Reset
	#var b = (vertices[face[1]]*(scale)) + offset + Reset
	#var c = (vertices[face[2]]*(scale)) + offset + Reset
	#var d = (vertices[face[3]]*(scale)) + offset + Reset
	#
	#
	#var uv_offset = faceT / lib.size
	#var height = 1.0 / lib.size.y
	#var width = 1.0 / lib.size.x
	#
	#var uvs = [uv_offset + Vector2(0, 0),
		#uv_offset + Vector2(0, height),
		#uv_offset + Vector2(width, height),
		#uv_offset + Vector2(width, 0)
	#]
	#surface.add_triangle_fan(([a,b,c]) ,([uvs[(1+rot)%4],uvs[(2+rot)%4],uvs[(0+rot)%4]]))
	#surface.add_triangle_fan(([d,c,b]) ,([uvs[(3+rot)%4],uvs[(0+rot)%4],uvs[(2+rot)%4]]))
	
