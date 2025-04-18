@tool
extends Node2D

const MORE_ITEMS = preload("res://materials/test/moreItems.tres")

@export var itemId:int = 1

var mesh: ArrayMesh
var meshinstance: MeshInstance2D
var st: SurfaceTool = SurfaceTool.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	mesh = ArrayMesh.new()
	#mesh.surface_set_material(1,MORE_ITEMS)
	meshinstance = MeshInstance2D.new()
	st.set_material(MORE_ITEMS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	
	var blockinfo = Blocks.blocks[Blocks.index[itemId]]["textures"][0]
	var faceT = blockinfo[Blocks.FRONT]
	var uv_offset = faceT / Blocks.TEXTURE_ATLAS_SIZE2
	var height = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.y
	var width = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.x
	
	var a = uv_offset + Vector2(0, 0)
	var b = uv_offset + Vector2(0, height)
	var c = uv_offset + Vector2(width, height)
	var d = uv_offset + Vector2(width, 0)
	
	
	st.add_triangle_fan(([Vector3(100,100,0),Vector3(0,0,0),Vector3(100,0,0)]),([c,a,d]))
	st.add_triangle_fan(([Vector3(100,100,0),Vector3(0,100,0),Vector3(0,0,0)]),([c,b,a]))
	
	
	
	st.generate_normals(false)
	st.commit(mesh)
	meshinstance.set_mesh(mesh)
	add_child(meshinstance)



#extends SubViewport
#
#const vertices = [
	#Vector3(-0.5,-0.5,-0.5), #0 bottom back left. 1,2,5
	#Vector3(0.5,-0.5,-0.5), #1 bottom fromt left  1,5,3
	#Vector3(-0.5,0.5,-0.5), #2 top back left      
	#Vector3(0.5,0.5,-0.5), #3 top front left
	#Vector3(-0.5,-0.5,0.5), #4 bottom back right
	#Vector3(0.5,-0.5,0.5), #5 bottom front right
	#Vector3(-0.5,0.5,0.5), #6 top back right
	#Vector3(0.5,0.5,0.5)  #7 top front right
#]
#const ind = [
	#2,6,
	#6,7,
	#3,7,
	#2,3,
	#2,0,
	#6,4,
	#7,5,
	#3,1,
	#0,4,
	#0,1,
	#1,5,
	#4,5
	#]
#@export var reset = Vector3(0.5,0.5,0.5)
#const FACES: Dictionary = {
	#"top":[[6,2,7,3], Vector3i(0,1,0),Blocks.TOP],
	#"bottom":[[1,0,5,4],Vector3i(0,-1,0),Blocks.BOTTOM],
	#"right":[[5,4,7,6],Vector3i(0,0,1),Blocks.RIGHT],
	#"left":[[0,1,2,3],Vector3i(0,0,-1),Blocks.LEFT],
	#"front":[[1,5,3,7],Vector3i(1,0,0),Blocks.FRONT],
	#"back":[[4,0,6,2],Vector3i(-1,0,0),Blocks.BACK]
#}
#
#@export var id: int = 3
#
#const MORE_ITEMS = preload("res://materials/test/moreItems.tres")
#
#var surface : SurfaceTool = SurfaceTool.new()
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	#surface.set_smooth_group(-1)
	#surface.set_material(MORE_ITEMS)
	#
	#var bockTextures = Blocks.blocks[Blocks.index[id]]["textures"][0]
	#for f in FACES.values():
		#createFace(f[0],bockTextures[f[2]])
	#
	#surface.generate_normals(false)
	#var mesh_instance = MeshInstance3D.new()
	#mesh_instance.set_mesh(surface.commit())
	#add_child(mesh_instance) 
#
#
#func createFace(face, faceT: Vector2):
	#var flocal =  FACES
	#var a = (vertices[face[0]]) + reset
	#var b = (vertices[face[1]]) + reset
	#var c = (vertices[face[2]]) + reset
	#var d = (vertices[face[3]]) + reset
	#
	#
	#var uv_offset = faceT / Blocks.TEXTURE_ATLAS_SIZE2
	#var height = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.y
	#var width = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.x
	#
	#var uvs = [uv_offset + Vector2(0, 0),
		#uv_offset + Vector2(0, height),
		#uv_offset + Vector2(width, height),
		#uv_offset + Vector2(width, 0)
	#]
	#var rot = 0
	#surface.add_triangle_fan(([a,b,c]),([uvs[(1+rot)%4],uvs[(2+rot)%4],uvs[(0+rot)%4]]))
	#surface.add_triangle_fan(([d,c,b]),([uvs[(3+rot)%4],uvs[(0+rot)%4],uvs[(2+rot)%4]]))
