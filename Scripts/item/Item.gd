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
	#meshinstance.texture = TEXTURE_ATLASNEW
	add_child(meshinstance)
