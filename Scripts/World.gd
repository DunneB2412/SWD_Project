@tool
extends Node3D
class_name World

#Members
var chunks = {}
var updateQueue = []
var destroyQueue = []
var entities = []
@onready var player: CharacterBody3D = $Player
@onready var chunksNode: Node3D = $Chunks

#Generation paramiters
@export var worldSize: Vector3i = Vector3i(4,4,4)
@export var loasQueueSize = 5
@export var worldY: int 
@export var worldSeed: int = 42
@export var simDist = 1
@export var globalAmp = 1

@export var chunkSize: Vector3i = Vector3i(32,32,32)
@export var blockSize: float = 1
var noise_y_small: FastNoiseLite = FastNoiseLite.new()

var pPos: Vector3i

var loadThread: Thread = Thread.new()
@export var updateQueueLim = 0

func _ready() -> void:
	noise_y_small.seed = worldSeed
	chunks = {}
	updateQueue = []
	entities = [player]
	
	var px = 0
	var pz = 0
	var py = getHeight(px,pz)+4
	player.position = Vector3(px, py, pz)
	pPos = player.position
	
	loadChunks()


	#loadThread.start(_threadProcess)
	
func _process(_delta: float) -> void:
	pPos = player.position
	#print("Player at" + str(get_relatives(pPos)["chunk"]))
	
	#if updateQueue.size()>0:
		#updateChunks()
	#if destroyQueue.size()>0:
		#deleteChunks()
	checkChunks()
	
func _threadProcess():
	var oldPlayerChunk = get_relatives(pPos)["chunk"]
	if(true):
		var playerChunk: Vector3i  = get_relatives(pPos)["chunk"]
		if playerChunk != oldPlayerChunk || true:
			oldPlayerChunk = playerChunk
			for pos in chunks:
				var val = chunks[pos]
				val["life"]-=1
				if val["life"] <=0:
					if !destroyQueue.has(pos):
						destroyQueue.append(pos)
			
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
					var wx = (ox*chunkSize.x) + (chunkSize.x>>1) # sample thge midle
					var wz = (oz*chunkSize.z) + (chunkSize.z>>1)
					var wy = getHeight(wx,wz)
					var oy = floor(wy/chunkSize.y) + vec.y
					var cPos = Vector3i(ox,oy,oz)
					#TODO use gen queue, allow gen threads to work on the gen queue and sen them to update queue
					createChunk(cPos)
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
func loadChunks():
	var playerChunk = get_relatives(pPos)["chunk"]
	var preload_range = 2
	for i in preload_range:
		for j in preload_range:
			for k in preload_range*globalAmp:
				var x = playerChunk.x +(i -(preload_range>>1))
				var z = playerChunk.z + (j -(preload_range>>1))
				var wx = (x*chunkSize.x) + (chunkSize.x>>1) # sample thge midle
				var wz = (z*chunkSize.z) + (chunkSize.z>>1)
				var wy = getHeight(wx,wz)
				var y = floor(wy/chunkSize.y) + (k -((preload_range*globalAmp)>>1))
				
				var pos = Vector3i(x,y,z)
				createChunk(pos)
				
	while updateQueue.size()>0:
		updateChunks()

func createChunk(pos: Vector3i) -> bool:
	if !chunks.has(pos):
		if not(updateQueue.has(pos)):
			#var t = Thread.new()
			#t.start(createChunk.bind(cPos))
			#loaders.append(t)
			var chunk = Chunk.new(pos, worldSeed, self, chunkSize, blockSize)
			chunks.merge({pos:{"chunk":chunk,"life":20, "placed": false}})
			updateQueue.append(pos)
			return true
	else:
		chunks[pos]["life"] = 20 # reset time
	return false

func updateChunks() -> void:
	var pos = updateQueue.pop_front()
	var cd = chunks.get(pos)
	if cd != null:
		var c:Chunk = cd["chunk"]
		if c.visible: # if the chunk is ready to be used
			chunksNode.add_child(c)
			c.set_name("chunk:"+str(pos))
			cd["placed"] = true
			c.startSim()
		else:
			c.genMesh()
			updateQueue.append(pos)
			
func checkChunks() -> void:
	var playerChunk: Vector3i = get_relatives(pPos)["chunk"]
	for pos in chunks:
		var chunk = chunks[pos]
		if playerChunk.distance_to(pos) > 32:
			chunks.erase(pos)
			chunk["chunk"].queue_free()
		if !chunk["placed"]:
			if chunk["chunk"].visible:
				chunksNode.add_child(chunk["chunk"])
				chunk["chunk"].set_name("chunk:"+str(pos))
				chunk["placed"] = true
			else:
				chunk["chunk"].genMesh()
				return

func deleteChunks() -> void:
	var pos = destroyQueue.pop_front()
	if chunks.has(pos):
		var cVals = chunks[pos]
		if cVals["life"] <=0:
			var c = cVals["chunk"]
			#chunksNode.remove_child(c)
			chunks.erase(pos)
			c.queue_free()
			#safely delete the rest.
				

func get_block(wCord: Vector3i) -> int:
	var relative = get_relatives(wCord)
	var chunk = get_Chunk(relative["chunk"])
	if chunk == null:
		return 0
	return chunk.getVal(relative["block"])

func getTemp(wCord: Vector3i) -> float:
	var relative = get_relatives(wCord)
	var chunk = get_Chunk(relative["chunk"])
	if chunk == null:
		return 0
	return chunk.getTemp(relative["block"])

func setTemp(wCord: Vector3i, val:float):
	var relative = get_relatives(wCord)
	var chunk = get_Chunk(relative["chunk"])
	if chunk == null:
		return
	chunk.setTemp(relative["block"],val)
	#chunk.updated = true

func getHeight(x,z) -> int:
	var frequency = Vector2i(1,1)
	var offset = 60
	var amplitude = 20 * globalAmp
	var grad = noise_y_small.get_noise_2d(x*frequency.x,z*frequency.y)
	return offset + (grad*amplitude)

func place_block(wCord: Vector3i, id: int) -> void:
	if checkPresence(wCord) && id !=0:
		return
	var relative = get_relatives(scenePosToWorld(wCord))
	var chunk = get_Chunk(relative["chunk"])
	if chunk == null:
		createChunk(relative["chunk"])
		return
	chunk.setVal(relative["block"],id)

func break_block(wCord: Vector3i) -> void:
	place_block(wCord,0)
	
func updateChunk(cPos: Vector3i) -> void:
	var chunk = get_Chunk(cPos)
	if chunk != null:
		chunk.updated = true
	
func get_relatives(worldPos) -> Dictionary:
	var chunk = Vector3i(0,0,0)
	
	#use compliment, this will turn -1 to 0, ect thid deals wit hthe no -0. take the sign and put it back
	for i in 3:
		if worldPos[i]<0: 
			chunk[i] = ~((~worldPos[i])/chunkSize[i])
		else:
			chunk[i] = worldPos[i]/chunkSize[i]
	
	var block = Vector3i(posmod(worldPos.x,chunkSize.x),posmod(worldPos.y,chunkSize.y),posmod(worldPos.z,chunkSize.z))
	
	# put the sign back
	return {"chunk":chunk,"block":block}

func scenePosToWorld(globalPos: Vector3) -> Vector3i:
	return floor(globalPos*blockSize)
		
func getPosFromRayCol(pos, norm):
	return scenePosToWorld(pos-(norm*(blockSize/2)))

func hilight_block(wCord: Vector3i, norm: Vector3i) -> void:
	var relative = get_relatives(scenePosToWorld(wCord))
	var chunk = get_Chunk(relative["chunk"])# protect out of bounds
	if chunk == null:
		return
	chunk.hilightBlock(relative["block"], norm)
	
func unHilightBlock(wCord: Vector3i) -> void:
	var relative = get_relatives(scenePosToWorld(wCord))
	var chunk = get_Chunk(relative["chunk"])# protect out of bounds
	if chunk == null:
		return
	chunk.unHilightBlock()
	
	
func get_Chunk(cPos: Vector3i): #use a table and actually load the chunk on the request.
	if chunks.has(cPos):
		return chunks[cPos]["chunk"]
	return null

#ref https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection
func checkPresence(wPos: Vector3i)->bool:
	if get_block(wPos) != 0:
		return true
	for e:CharacterBody3D in entities:
		var pos = e.position
		var inx = (pos.x-0.18 <=((wPos.x+1)/blockSize)) && (pos.x+0.19 >= ((wPos.x)/blockSize))
		var iny = (pos.y-0.8 <=((wPos.y+1)/blockSize)) && (pos.y+0.8 >= ((wPos.y)/blockSize))
		var inz = (pos.z-0.18 <=((wPos.z+1)/blockSize)) && (pos.z+0.18 >= ((wPos.z)/blockSize))
		if inx && iny && inz:
			return true
	return false
