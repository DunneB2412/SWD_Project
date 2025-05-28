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
@export var simRange: int = 8

var simThreads: Array[Thread]
var masterSimThread: int
var simQueue: Array
var simQueueMutex: Mutex
var simSemaphore: Semaphore
var simQueueSync: int

var meshThread: Thread
var mesherMutex: Mutex

var newQueue: Array[Section]
var newQueueMutex: Mutex

var pPos: Vector3i
var run: bool

@export var watertest = true

var noise_y_small: FastNoiseLite = FastNoiseLite.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sections = {}
	
	newQueue = []
	newQueueMutex = Mutex.new()
	mesherMutex = Mutex.new()
	
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
	if noSimThreads>1:
		simSemaphore.post(noSimThreads-1) # 
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
		mesherMutex.lock()
		var secs = sections.keys()
		mesherMutex.unlock()
		for key in secs:
			mesherMutex.lock()
			var sec = sections[key]
			mesherMutex.unlock()
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
			TimedExe(newSimBatch,"NextSim")
			#newSimBatch()
			OS.delay_msec(max(simClockTime- (Time.get_ticks_msec()-start),0))
		else:
			simSemaphore.wait()
			digestSimQueue()
func newSimBatch():
	if run:
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
	#print(str(OS.get_thread_caller_id())+":: start")
	var pSec = get_relatives(pPos)["sec"]
	while simQueue.size()>0 && run:
		if(simQueueMutex.try_lock()):
			if simQueue.size()>0:
				var pos: Vector3i = simQueue.pop_front()
				simQueueMutex.unlock()
				var section : Section = sections[pos]
				if section.updated == false && pSec.distance_to(pos) <simRange:#lets wait for the section to be updated first.
					#TimedExe(section.findAction, "finding actions for "+str(pos))
					section.findAction()
			else:
				simQueueMutex.unlock()
	
	simQueueMutex.lock()
	simQueueSync+=1
	simQueueMutex.unlock()
	#print(str(OS.get_thread_caller_id())+":: end")

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
	if watertest:
		return 60
	var frequency = Vector2i(1,1)
	var offset = 60
	var amplitude = 20 * globalAmp
	var grad = noise_y_small.get_noise_2d(x*frequency.x,z*frequency.y)
	return offset + (grad*amplitude)
	
func getWaterLine(x,z) -> int: 
	if watertest && x==0 && z ==0:
		return 64
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
		return [-1]
	return sec.getVal(relative["block"], Global.REF_VEC3)
func addAt(cord: Vector3i, val: int, mass: int, temp: float, force:bool = false) -> int:
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		if !force:
			return 0
		sec = addSection(relative['sec'])
	return sec.addAt(relative["block"],val, mass, temp, Global.REF_VEC3)
func break_block(cord: Vector3i) -> PackedInt64Array:
	var val = getVal(cord)
	for v in val:
		var m = SectionData.readMeta(v,SectionData.INC.MASS)
		addAt(cord,v,-m,0)
	return val
	

func ForceUpdate(cord: Vector3i):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		#sec = addSection(relative['sec'])
		return
	sec.genMesh()
func updateChunk(cord: Vector3i):
	var relative = get_relatives(cord)
	var sec = getSec(relative['sec'])
	if sec == null:
		return
	sec.updated = true

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
	var miny = INF
	var maxy = getWaterLine(pos.x,pos.y)/sectionSize.y
	for x in sectionSize.x:  #load all surface sections. 
		for z in sectionSize.z:
			var wCord = Vector3i(x,0,z) + (Vector3i(pos.x,0,pos.y)*sectionSize)
			var height = getHeight(wCord.x,wCord.z)
			var sh = height/sectionSize.y
			if sh < miny:
				miny = sh
			elif sh > maxy:
				maxy = sh
		
	miny -= floor(worldSize.y/2.0)
	maxy += ceil(worldSize.y/2.0)
	for i in maxy-miny:
		var sec = Vector3i(pos.x,i + miny,pos.y)
		addSection(sec)
					
func addSection(pos:Vector3i):
	if !sections.has(pos):
		var sec = Section.new(pos,sectionSize,blockSize, self, blockLib)
		mesherMutex.lock()
		sections.merge({pos:sec})
		mesherMutex.unlock()
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
	return sec.info(relative["block"])
	
	
	
func _threadProcess():
	var oldPlayerChunk = get_relatives(pPos)["chunk"]
	if(true):
		var playerChunk: Vector3i  = get_relatives(pPos)["chunk"]
		if playerChunk != oldPlayerChunk || true:
			oldPlayerChunk = playerChunk
			#for pos in sections:
				#var val = sections[pos]
				#val["life"]-=1
				#if val["life"] <=0:
					#if !destroyQueue.has(pos):
						#destroyQueue.append(pos)
			
			#var loaders = []
			
			var queue = [Vector3i(0,0,0)]
			var visited = []
			while !queue.is_empty():
				var vec = queue.pop_front()
				playerChunk = get_relatives(pPos)["chunk"]
				#if the vector is within the render distance.
				if(playerChunk.distance_to(vec)<32):
					
					var ox = playerChunk.x + vec.x 
					var oz = playerChunk.z + vec.z
					var wx = (ox*sectionSize.x) + (sectionSize.x>>1) # sample thge midle
					var wz = (oz*sectionSize.z) + (sectionSize.z>>1)
					var wy = getHeight(wx,wz)
					var oy = floor(wy/sectionSize.y) + vec.y
					var cPos = Vector3i(ox,oy,oz)
					addSection(cPos)
					visited.append(vec)
					var next = [
						Vector3i(bounce(vec.x),vec.y,vec.z),
						Vector3i(vec.x,vec.y,bounce(vec.z)),
						Vector3i(bounce(vec.x),vec.y,bounce(vec.z)),
						Vector3i(vec.x,bounce(vec.y),vec.z)
					]
					for v in next:
						if !visited.has(v) && !queue.has(v):	
							queue.push_back(v)
					
		await get_tree().create_timer(0.01).timeout

func bounce(i: int) -> int:
	return ~i + int(i<0)
