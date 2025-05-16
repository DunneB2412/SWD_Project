@tool
extends Node2D

const lib = preload("res://Scripts/Blocks/Libery.tres")

@export var itemId:int = 1

var mesh: ArrayMesh
var meshinstance: MeshInstance2D
var st: SurfaceTool = SurfaceTool.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	mesh = ArrayMesh.new()
	#mesh.surface_set_material(1,MORE_ITEMS)
	meshinstance = MeshInstance2D.new()
	meshinstance.texture = lib.material.albedo_texture
	meshinstance.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	st.set_material(lib.material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	
	var faceT = Vector2(3,0)
	var uv_offset = faceT / lib.size
	var height = 1.0 /  lib.size.y
	var width = 1.0 /  lib.size.x
	
	var a = uv_offset + Vector2(0, 0)
	var b = uv_offset + Vector2(0, height)
	var c = uv_offset + Vector2(width, height)
	var d = uv_offset + Vector2(width, 0)
	
	var co = Color.BLUE_VIOLET
	
	st.add_triangle_fan(([Vector3(16,16,0),Vector3(0,0,0),Vector3(16,0,0)]),([c,a,d]),([co,co,co]))
	st.add_triangle_fan(([Vector3(16,16,0),Vector3(0,16,0),Vector3(0,0,0)]),([c,b,a]),([co,co,co]))
	
	
	st.generate_normals(false)
	st.commit(mesh)
	meshinstance.set_mesh(mesh)
	#add_child(meshinstance)
	
	var test = MeshTexture.new()
	test.mesh = mesh
	test.base_texture = lib.material.albedo_texture
	test.image_size = Vector2(16,16)
	var test2 = TextureRect.new()
	test2.texture = test
	add_child(test2)
	
	
	
	var debugText = RichTextLabel.new()
	debugText.scroll_active = false
	debugText.fit_content = true
	debugText.theme = Theme.new()
	debugText.theme.default_font_size = 20
	debugText.visible = true
	debugText.size = Vector2(500,100)
	debugText.text = "Test"
	
	
	add_child(debugText)
	
