@tool
extends Node
class_name Region

var sections: Dictionary
var entities: Array[EntityBase]
#var player: Player

@export var worldSize: Vector3i = Vector3i(4,4,4)
@export var loasQueueSize = 5
@export var worldY: int 
@export var worldSeed: int = 42
@export var simDist = 1
@export var globalAmp = 1

@export var sectionSize: Vector3i = Vector3i(8,8,8)
@export var blockSize: float = 1
@export var blockLib: BlockLib
@export var noSimThreads: int = 8
@export var simClockTime: int = 1000

var simThreads: Array[Thread]
var masterSimThread: int
var simQueue: Array
var simQueueMutex: Mutex

var meshThread: Thread

@onready var player = $"../Player"

var run: bool

var noise_y_small: FastNoiseLite = FastNoiseLite.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sections = {}
	prep()
	run = true
	meshThread = Thread.new()
	meshThread.start(_mesh)
	
	
	var px = 0
	var pz = 0
	var py = getHeight(px,pz)+4
	player.position = Vector3(px, py, pz)
	
	simQueueMutex = Mutex.new()
	for i in noSimThreads:
		var t = Thread.new()
		t.start(_sim)
		simThreads.append(t)
	
func _exit_tree() -> void:
	run = false
	if meshThread.is_started():
		meshThread.wait_to_finish()
	for t in simThreads:
		if t.is_started():
			t.wait_to_finish()

func _enter_tree() -> void:
	pass
	#run = true
	#if meshThread.is_started():
		#meshThread.start(_mesh)
	#for t in simThreads:
		#if !t.is_started():
			#t.start(_sim)

func _mesh():
	while run:
		for sec: Section in sections.values():
			if sec.updated:
				sec.genMesh()

func _sim():
	simQueueMutex.lock()
	if masterSimThread == 0:
		masterSimThread = OS.get_thread_caller_id()
	simQueueMutex.unlock()
	while run:
		if OS.get_thread_caller_id() == masterSimThread:
			var start =  Time.get_ticks_msec()
			simQueueMutex.lock()
			simQueue = sections.keys().duplicate()
			simQueueMutex.unlock()
			
			digestSimQueue()
			
			
			var end =  Time.get_ticks_msec()
			var dir = end-start
			print(dir)
			OS.delay_msec(max(simClockTime-dir,0))
		else:
			digestSimQueue()

func digestSimQueue():
	while simQueue.size()>0:
		if(simQueueMutex.try_lock()):
			if simQueue.size()>0:
				var pos = simQueue.pop_front()
				
				var start =  Time.get_ticks_msec()
				var section : Section = sections[pos]
				if section.updated == false:#lets wait for the section to be updated first.
					section.findAction()
				var end =  Time.get_ticks_msec()
				var dir = end-start
				#print(str(OS.get_thread_caller_id())+" Tested "+str(pos)+ ", took "+ str(dir) +" ms to complete")
			#else:
				#print(str(OS.get_thread_caller_id())+" Tested  could not find a section in queue")
			simQueueMutex.unlock()
	#print(str(OS.get_thread_caller_id())+" finished for this cycle ")




func prep():
	for x in worldSize.x:
		for z in worldSize.z:
			var pos = Vector2i(-(worldSize.x/2)+x,-(worldSize.z/2)+z)
			col(pos)
	for s : Section in sections.values():
		add_child(s)
#util
func getHeight(x,z) -> int:
	var frequency = Vector2i(1,1)
	var offset = 60
	var amplitude = 20 * globalAmp
	var grad = noise_y_small.get_noise_2d(x*frequency.x,z*frequency.y)
	return offset + (grad*amplitude)
	
func getWaterLine() -> int:
	return 60
	

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
func addAt(cord: Vector3i, val: int, mass: int) -> void:
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
			var height = 60#getHeight(wCord.x,wCord.z) ---------------------------------------------------------------
			var sh = height/sectionSize.y
			var sec = Vector3i(pos.x,sh,pos.y)
			if !sections.has(sec):
				sections.merge({sec:Section.new(sec,sectionSize,blockSize, self, blockLib)})
			var wh = 60/sectionSize.y
			for i in (wh - sh)+1:
				sec = Vector3i(pos.x,sh+i,pos.y)
				if !sections.has(sec):
					sections.merge({sec:Section.new(sec,sectionSize,blockSize, self, blockLib)})
