extends Resource
class_name Block

const encoder = {
	"focus": 	{"mask":0x80000000,"max":1      , "offset": 31}, # 1000 0000 0000 0000 0000 0000 0000 0000
	"sky":   	{"mask":0x40000000,"max":1      , "offset": 30}, # 0100 0000 0000 0000 0000 0000 0000 0000
	"clickable":{"mask":0x20000000,"max":1      , "offset": 29}, # 0010 0000 0000 0000 0000 0000 0000 0000
	"opaque":	{"mask":0x10000000,"max":1      , "offset": 28}, # 0001 0000 0000 0000 0000 0000 0000 0000
	"simulate":	{"mask":0x08000000,"max":1      , "offset": 27}, # 0000 1000 0000 0000 0000 0000 0000 0000
	"solid":		{"mask":0x04000000,"max":1      , "offset": 26}, # 0000 0100 0000 0000 0000 0000 0000 0000
	"blocktype":	{"mask":0x000003ff,"max":0x03ff , "offset": 00}, # 0000 0000 0000 0000 0000 0011 1111 1111
	"blocktvar":	{"mask":0x00007c00,"max":0x001f , "offset": 10}, # 0000 0000 0000 0000 0111 1100 0000 0000
	"botomnorm":	{"mask":0x00038000,"max":0x0007 , "offset": 15}, # 0000 0000 0000 0011 1000 0000 0000 0000
	"rotation": 	{"mask":0x000c0000,"max":0x0003 , "offset": 17}, # 0000 0000 0000 1100 0000 0000 0000 0000
	"strain":	{"mask":0x00f00000,"max":0x000f , "offset": 20}, # 0000 0000 1111 0000 0000 0000 0000 0000
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

const FACES: Dictionary = {
	"top":[[6,2,7,3], Vector3i(0,1,0),Blocks.TOP],
	"bottom":[[1,0,5,4],Vector3i(0,-1,0),Blocks.BOTTOM],
	"right":[[5,4,7,6],Vector3i(0,0,1),Blocks.RIGHT],
	"left":[[0,1,2,3],Vector3i(0,0,-1),Blocks.LEFT],
	"front":[[1,5,3,7],Vector3i(1,0,0),Blocks.FRONT],
	"back":[[4,0,6,2],Vector3i(-1,0,0),Blocks.BACK]
}

static func setMeta(val: int, property: String, meta: int) -> int:
	if meta <= encoder[property]["max"] && meta >= 0:
		return val | (meta<<encoder[property]["offset"])
	return val
static func readMeta(val:int, property: String) -> int :
	return (val & encoder[property]["mask"])>>encoder[property]["offset"]
	

#func genArrayMesh(value: int, size:float, pos:Vector3) -> bool:
	#if value ==0:# if the vxl is empty.
		#return false
		#
	##var hilighted = (value & encoder["focus"]["mask"])>0 handle this elsewhere
	#
	##TODO handle the norm and rotation on the faces
	#var blockT = readMeta(value,"blocktype")
	#var blockV = readMeta(value,"blocktvar")
	#var norm = readMeta(value,"norm")
	#var bockTextures = Blocks.blocks[Blocks.index[blockT]]["textures"][blockV]
	#
	#for f in FACES.values():
		##checkPair(cCord,f[1])
		##if !getVal(cCord+f[1])&encoder["opaque"]["mask"]:
			#createFace(f[0],pos,bockTextures[f[2]])
		##if hilighted:
			##var color = Color.DARK_MAGENTA
			##color.a8 = 100
			##createFace(f[0],cCord,Vector2(4,2),false ,1.01, color)
	#return true
	#
#
#func createFace(face,cCord : Vector3, faceT: Vector2, rScale: float = 1, ):
	#var a = (vertices[face[0]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	#var b = (vertices[face[1]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	#var c = (vertices[face[2]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	#var d = (vertices[face[3]]*(cellSize*rScale)) + (cCord * cellSize) + reset
	#
	#
	#var uv_offset = faceT / Blocks.TEXTURE_ATLAS_SIZE2
	#var height = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.y
	#var width = 1.0 / Blocks.TEXTURE_ATLAS_SIZE2.x
	#
	#var uv_a = uv_offset + Vector2(0, 0)
	#var uv_b = uv_offset + Vector2(0, height)
	#var uv_c = uv_offset + Vector2(width, height)
	#var uv_d = uv_offset + Vector2(width, 0)
	#
	#if colidable:
		#collision_surface.add_triangle_fan(([a,b,c]),([uv_b,uv_c,uv_a]),([color,color,color]))
		#collision_surface.add_triangle_fan(([d,c,b]),([uv_d,uv_a,uv_c]),([color,color,color]))
	#else:
		#texture_surface.add_triangle_fan(([a,b,c]),([uv_b,uv_c,uv_a]),([color,color,color]))
		#texture_surface.add_triangle_fan(([d,c,b]),([uv_d,uv_a,uv_c]),([color,color,color]))
	
