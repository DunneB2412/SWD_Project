@tool
extends Node
class_name Region

var sections: Dictionary
var entities: Array[EntityBase]
var player: Player

@export var worldSize: Vector3i = Vector3i(4,4,4)
@export var loasQueueSize = 5
@export var worldY: int 
@export var worldSeed: int = 42
@export var simDist = 1
@export var globalAmp = 1

@export var sectionSize: Vector3i = Vector3i(8,8,8)
@export var blockSize: float = 1
@export var blockLib: BlockLib
var noise_y_small: FastNoiseLite = FastNoiseLite.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sections = {}
	prep()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func prep():
	for x in worldSize.x:
		for z in worldSize.z:
			var pos = Vector2i(-(worldSize.x/2)+x,-(worldSize.z/2)+z)
			col(pos)
	for s : Section in sections.values():
		s.genMesh()
		add_child(s)
#util
func getHeight(x,z) -> int:
	var frequency = Vector2i(1,1)
	var offset = 60
	var amplitude = 20 * globalAmp
	var grad = noise_y_small.get_noise_2d(x*frequency.x,z*frequency.y)
	return offset + (grad*amplitude)
	
	
	

func get_relatives(worldPos) -> Dictionary:
	var sec = Vector3i(0,0,0)
	#use compliment, this will turn -1 to 0, ect thid deals wit hthe no -0. take the sign and put it back
	for i in 3:
		if worldPos[i]<0: 
			sec[i] = ~((~worldPos[i])/sectionSize[i])
		else:
			sec[i] = worldPos[i]/sectionSize[i]
	
	var block = Vector3i(posmod(worldPos.x,sectionSize.x),posmod(worldPos.y,sectionSize.y),posmod(worldPos.z,sectionSize.z))
	
	# put the sign back
	return {"sec":sec,"block":block}

	
func getSec(pos:Vector3i) -> Section:
	if sections.has(pos):
		return sections[pos]
	return null

#util functions
#mater handelers
func getVal(cord: Vector3i) -> PackedInt64Array:
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return [0]
	return sec.getVal(relative["block"])
func changeAt(cord: Vector3i, val: int, mass: int) -> void:
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	return sec.addAt(relative["block"],val, mass)
	
	
#temprature handelers
func setTemp(cord: Vector3i, val:float):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	return sec.setTemp(relative["block"],val)
func getTemp(cord: Vector3i) -> float:
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return 0
	return sec.getTemp(relative["block"])
func addHeatAt(cord: Vector3i, heat: int):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	return sec.addHeatAt(relative["block"],heat)

#ref https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection
func checkPresence(wPos: Vector3i)->bool:
	if getVal(wPos)[0] != 0:
		return true
	for e:CharacterBody3D in entities:
		var pos = e.position
		var inx = (pos.x-0.18 <=((wPos.x+1)/blockSize)) && (pos.x+0.19 >= ((wPos.x)/blockSize))
		var iny = (pos.y-0.8 <=((wPos.y+1)/blockSize)) && (pos.y+0.8 >= ((wPos.y)/blockSize))
		var inz = (pos.z-0.18 <=((wPos.z+1)/blockSize)) && (pos.z+0.18 >= ((wPos.z)/blockSize))
		if inx && iny && inz:
			return true
	return false


func col(pos:Vector2i) -> void:
	for x in sectionSize.x:  #load all surface sections. 
		for z in sectionSize.z:
			var wCord = Vector3i(x,0,z) + (Vector3i(pos.x,0,pos.y)*sectionSize)
			var height = getHeight(wCord.x,wCord.z)
			var sec = Vector3i(pos.x,height/sectionSize.y,pos.y)
			if !sections.has(sec):
				sections.merge({sec:Section.new(sec,sectionSize,blockSize, self, blockLib)})
