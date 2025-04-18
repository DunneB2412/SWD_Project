extends Resource
class_name SectionData

enum INC{
	BLOCK_TYPE,
	BLOCK_VAR,
	NORM,
	ROTATION,
	STRAIN,
	AIRABOVE,
	AIRBELOW,
	CLICKABLE,
	OPAQUE,
	VISABLE,
	SOLID,
	SPARE1,
	PERMUABLE,
	MASS,
	PHASE,
	PCOUNTER,
	SPARE2
}

const encoder = {
	INC.AIRABOVE: 		{"mask":0x0000000080000000,"max":1      , "offset": 31}, # 0000 0000 0000 0000 0000 0000 0000 0000 1000 0000 0000 0000 0000 0000 0000 0000
	INC.AIRBELOW:   	{"mask":0x0000000040000000,"max":1      , "offset": 30}, # 0000 0000 0000 0000 0000 0000 0000 0000 0100 0000 0000 0000 0000 0000 0000 0000
	INC.CLICKABLE:  	{"mask":0x0000000020000000,"max":1      , "offset": 29}, # 0000 0000 0000 0000 0000 0000 0000 0000 0010 0000 0000 0000 0000 0000 0000 0000
	INC.OPAQUE:		{"mask":0x0000000010000000,"max":1      , "offset": 28}, # 0000 0000 0000 0000 0000 0000 0000 0000 0001 0000 0000 0000 0000 0000 0000 0000
	INC.VISABLE:		{"mask":0x0000000008000000,"max":1      , "offset": 27}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 1000 0000 0000 0000 0000 0000 0000
	INC.SOLID:			{"mask":0x0000000004000000,"max":1      , "offset": 26}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0100 0000 0000 0000 0000 0000 0000
	INC.SPARE1	:		{"mask":0x0000000002000000,"max":0x0001 , "offset": 25}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0010 0000 0000 0000 0000 0000 0000
	INC.PERMUABLE: 	{"mask":0x0000000001000000,"max":0x0001 , "offset": 24}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0001 0000 0000 0000 0000 0000 0000
	INC.BLOCK_TYPE:		{"mask":0x00000000000003ff,"max":0x03ff , "offset": 00}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0011 1111 1111
	INC.BLOCK_VAR:		{"mask":0x0000000000007c00,"max":0x001f , "offset": 10}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0111 1100 0000 0000
	INC.NORM:			{"mask":0x0000000000038000,"max":0x0005 , "offset": 15}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0011 1000 0000 0000 0000
	INC.ROTATION: 		{"mask":0x00000000000c0000,"max":0x0003 , "offset": 18}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 1100 0000 0000 0000 0000
	INC.STRAIN:		{"mask":0x0000000000f00000,"max":0x000f , "offset": 20}, # 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 1111 0000 0000 0000 0000 0000
	INC.MASS:			{"mask":0x03ffffff00000000,"max":0x03ffffff, "offset":32},#0000 0011 1111 1111 1111 1111 1111 1111 0000 0000 0000 0000 0000 0000 0000 0000
	INC.PHASE:			{"mask":0x0c00000000000000,"max":0x0003 , "offset": 58}, # 0000 1100 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
	INC.PCOUNTER:		{"mask":0x3000000000000000,"max":0x0003 , "offset": 60}, # 0011 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
	INC.SPARE2	:		{"mask":0x4000000000000000,"max":0x0001 , "offset": 62}, # 0100 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
	# cant use this, see issue https://github.com/godotengine/godot/issues/36387 "spare3"	:		{"mask":0x8000000000000000,"max":0x0001 , "offset": 63}, # 1000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
}

static func metaLim(property: INC) -> int:
	return encoder[property]["max"]

static func setMeta(val: int, property: INC, meta: int) -> int:
	if meta <= encoder[property]["max"] && meta >= 0:
		return (val & ~  encoder[property]["mask"]) | (meta<<encoder[property]["offset"])
	return val
static func readMeta(val:int, property: INC) -> int :
	return (val & encoder[property]["mask"])>>encoder[property]["offset"]

#ref https://www.youtube.com/watch?v=vzRZjM9MTGw
# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

var data: Dictionary
var heatE: Dictionary
var size: Vector3i
var name: String

## encoding into a 64 bit int 3x 20 bit numbers. with 4 bits left perhaps use this to flaten. safer aswell.
#const flag = 0x0fffff
#const offser = 20


func _init(sizeIn: Vector3i, nameIn: String) -> void:
	self.size = sizeIn
	self.name = nameIn

func get_filled_cells() -> Array:
	var flats = data.keys()
	var vects = []
	for f in flats:
		vects.append(popCord(f))
	return vects

func getVal(pos: Vector3i) -> PackedInt64Array:
	var flat = flattenCord(pos)
	if data.has(flat):
		return data[flattenCord(pos)]
	return [0]

func addAt(pos: Vector3i, val: int, mass: int) -> void:
	var v = setMeta(val,INC.MASS,mass)
	#Handle when there is a new primary material.
	var flat = flattenCord(pos)
	if data.has(flat):
		var cell: PackedInt64Array = data[flat]
		for i in cell.size():
			var mi = readMeta(cell[i],INC.MASS)
			if mass>mi:
				cell.insert(i,v)
				return
		cell.append(v)
	else:
		data.merge({flat:PackedInt64Array([v])}) #create a new one
		
func clear(pos: Vector3i) -> void:
	var flat = flattenCord(pos)
	data.erase(flat)
	heatE.erase(flat)
	
		
func consume(pos: Vector3i, part: int, mass: int) -> int :
	var flat = flattenCord(pos)
	if !data.has(flat):
		return 0
	
	var cell: PackedInt64Array = data[flat]
	for i in cell.size():
		if readMeta(cell[i],INC.BLOCK_TYPE) == part:
			var v = cell[i]
			var m = readMeta(v, INC.MASS)
			cell.remove_at(i)
			if m > mass:
				m = m-mass
				addAt(pos,v,m)
				return mass
			else:
				if cell.size()==0:
					clear(pos) #if all minerals are consumed, clear
				return m
	return 0

func setTemp(pos:Vector3i, temp: float) -> void:
	var flat = flattenCord(pos)
	if !data.has(flat):
		return #can't have temprature in a vaccume
	var cell: PackedInt64Array = data[flat]
	var avg  = avgHeatCapAt(cell)
	
	if heatE.has(flat):
		heatE = temp*avg
	else:
		heatE.merge({flat: temp*avg})
		
func getTemp(pos:Vector3i) -> float :
	var flat = flattenCord(pos)
	if !(data.has(flat) && heatE.has(flat)):
		return 0.0#no temprature in a vaccume
	var cell: PackedInt64Array = data[flat]
	var avg  = avgHeatCapAt(cell)
	
	return heatE[flat]/avg

func addHeatAt(pos:Vector3i,j:int) -> void:
	var flat = flattenCord(pos)
	if !(data.has(flat) && heatE.has(flat)):
		return #no temprature in a vaccume
	heatE[flat] += j
	
func flattenCord(pos: Vector3i) -> int:
	return (pos.x*size.y*size.z) + (pos.y*size.z) + pos.z
	
func popCord(pos: int) -> Vector3i:
	var x = pos/(size.y*size.z)
	var r = pos % (size.y*size.z)
	var y = r / size.z
	var z = r%size.z
	return Vector3i(x,y,z)

func save():
	ResourceSaver.save(self,"res://saves/"+name+".tres")

func avgHeatCapAt(cell: PackedInt64Array) -> float:
	var sum = 0
	for d in cell:
		sum += readMeta(d,INC.MASS)
	return sum/cell.size()
	
func info(pos: Vector3i) -> String :
	var st = "temp " + str(getTemp(pos)) +"\n"
	var vals = getVal(pos)
	st = st + "Has "+ str(vals.size()) +" mineral present\n"
	var sum = 0
	for v in vals:
		sum += readMeta(v, INC.MASS)
	if sum == 0:
		print("ooh ")
	st = st + "containing " + str(sum) + "g of material"
	return st
