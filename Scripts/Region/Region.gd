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
@export var noSimThreads: int = 8
@export var simClockTime: int = 1000

var simThreads: Array[Thread]
var masterSimThread: int
var simQueue: Array
var simQueueMutex: Mutex
var simSemaphore: Semaphore
var simQueueSync: int
var meshThread: Thread

var newQueue: Array[Section]
var newQueueMutex: Mutex

var pPos: Vector3i
var run: bool

var noise_y_small: FastNoiseLite = FastNoiseLite.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sections = {}
	
	newQueue = []
	newQueueMutex = Mutex.new()
	
	prep()
	
	run = true
	meshThread = Thread.new()
	meshThread.start(_mesh)
	
	var px = 0
	var pz = 0
	var py = getHeight(px,pz)+4
	pPos =  Vector3(px, py, pz)
	player = Player.new(pPos,self)#,Vector3(0.8,0.8,0.8))
	
	simQueueMutex = Mutex.new()
	simSemaphore = Semaphore.new()
	for i in noSimThreads:
		var t = Thread.new()
		t.start(_sim)
		simThreads.append(t)
	print_tree_pretty()
	
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
			
func _process(_delta: float) -> void:
	pPos = player.position
	newQueueMutex.lock()
	var s = newQueue.size()
	newQueueMutex.unlock()
	while s > 0:
		newQueueMutex.lock()
		var sec = newQueue.pop_front()
		s = newQueue.size()
		newQueueMutex.unlock()
		add_child(sec)
		


func _mesh():
	while run:
		for sec: Section in sections.values():
			if sec.updated:
				#TimedExe(sec.genMesh, "genMesh on "+str(sec.name))
				sec.genMesh()

func _sim():
	simQueueMutex.lock()
	if masterSimThread == 0:
		masterSimThread = OS.get_thread_caller_id()
	simQueueMutex.unlock()
	while run:
		if OS.get_thread_caller_id() == masterSimThread:
			var start =  Time.get_ticks_msec()
			#TimedExe(newSimBatch,"NextSim")
			newSimBatch()
			OS.delay_msec(max(simClockTime- (Time.get_ticks_msec()-start),0))
		else:
			simSemaphore.wait()
			digestSimQueue()
func newSimBatch():
	simQueueMutex.lock()
	simQueueSync = 0
	simQueue = sections.keys().duplicate()
	simQueueMutex.unlock()
	if noSimThreads>1:
		simSemaphore.post(noSimThreads-1) # 
	digestSimQueue()
	simQueueMutex.lock()
	var count = simQueueSync
	simQueueMutex.unlock()
	while count < noSimThreads:
		simQueueMutex.lock()
		count = simQueueSync
		simQueueMutex.unlock()
	
	
#master (provider, ) is adding more to the queue quicker than the they are being processes, causing a number of sections to be simulating the exact same one and inducing a bunch of delay from the locks. 
func digestSimQueue():
	var pSec = get_relatives(pPos)["sec"]
	while simQueue.size()>0:
		if(simQueueMutex.try_lock()):
			if simQueue.size()>0:
				var pos: Vector3i = simQueue.pop_front()
				simQueueMutex.unlock()
				var section : Section = sections[pos]
				if section.updated == false && pSec.distance_to(pos) <4:#lets wait for the section to be updated first.
					#TimedExe(section.findAction, "finding actions for "+str(pos))
					section.findAction()
			else:
				simQueueMutex.unlock()
	
	simQueueMutex.lock()
	simQueueSync+=1
	simQueueMutex.unlock()

func TimedExe(callable: Callable, msg: String):
	var start =  Time.get_ticks_msec()
	callable.call()
	var dir = Time.get_ticks_msec()-start
	print(str(OS.get_thread_caller_id())+" "+ msg + ", took "+ str(dir) +" ms to complete")


func prep():
	for x in worldSize.x:
		for z in worldSize.z:
			var pos = Vector2i(-(worldSize.x/2)+x,-(worldSize.z/2)+z)
			col(pos)
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
	return sec.getVal(relative["block"], Global.REF_VEC3)
func addAt(cord: Vector3i, val: int, mass: int) -> void:
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		#sec = addSection(relative['sec'])
		return
	return sec.addAt(relative["block"],val, mass, Global.REF_VEC3)
func break_block(cord: Vector3i) -> PackedInt64Array:
	var val = getVal(cord)
	for v in val:
		var m = SectionData.readMeta(v,SectionData.INC.MASS)
		addAt(cord,v,-m)
	return val

func ForceUpdate(cord: Vector3i):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		#sec = addSection(relative['sec'])
		return
	sec.genMesh()

#temprature handelers
func setTemp(cord: Vector3i, val:float):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	return sec.setTemp(relative["block"],val, Global.REF_VEC3)
func getTemp(cord: Vector3i) -> float:
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return 0
	return sec.getTemp(relative["block"], Global.REF_VEC3)
func addHeatAt(cord: Vector3i, heat: int):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	return sec.addHeatAt(relative["block"],heat, Global.REF_VEC3)
func getHeatAt(cord: Vector3i):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	return sec.getHeatAt(relative["block"], Global.REF_VEC3)

func col(pos:Vector2i) -> void:
	for x in sectionSize.x:  #load all surface sections. 
		for z in sectionSize.z:
			var wCord = Vector3i(x,0,z) + (Vector3i(pos.x,0,pos.y)*sectionSize)
			var height = getHeight(wCord.x,wCord.z)
			var sh = height/sectionSize.y
			var sec = Vector3i(pos.x,sh,pos.y)
			addSection(sec)
			var wh = 60/sectionSize.y
			for i in (wh - sh)+1:
				sec = Vector3i(pos.x,sh+i,pos.y)
				addSection(sec)
					
func addSection(pos:Vector3i):
	if !sections.has(pos):
		var sec = Section.new(pos,sectionSize,blockSize, self, blockLib)
		sections.merge({pos:sec})
		newQueueMutex.lock()
		newQueue.append(sec)
		newQueueMutex.unlock()
		return sec
	return sections[pos]



func scenePosToWorld(globalPos: Vector3) -> Vector3i:
	return floor(globalPos*blockSize)
		
func getPosFromRayCol(pos, norm):
	return scenePosToWorld(pos-(norm*(blockSize/2)))
	#ref https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection
func checkPresence(cord: Vector3i)->bool:
	if getVal(cord)[0] != 0:
		return true
	for e:EntityBase in entities:
		if entityTouching(e,cord)[0]:
			return true
	return false

#custom colisiton code Use this going forward, the shuffeling collisions will not work.
func entityTouching(entity:EntityBase, cord: Vector3i) ->Array:
	var overlap = Vector3(0,0,0)
	if getVal(cord)[0] == 0:
		return [false]
	var pos = entity.position
	var scale = entity.size
	for i in 3:
		overlap[i] = max(
			(((cord[i])/blockSize)-(pos[i]+(scale[i]/2)))* int((pos[i]+(scale[i]/2)) >= ((cord[i])/blockSize)),
			((pos[i]-(scale[i]/2)) - ((cord[i]+1)/blockSize)) * int((pos[i]-(scale[i]/2) <=((cord[i]+1)/blockSize)))
		)
	if overlap.x !=0 && overlap.y !=0 && overlap.z !=0:
		return [true,overlap]
	return [false]

func info(cord: Vector3i) -> String :
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return ""
	return sec.info(cord)
