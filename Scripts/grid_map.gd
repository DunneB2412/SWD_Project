extends GridMap
@onready var playerhilight: GridMap = $Playerhilight


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func destroyBlock(worldCoord):
	set_cell_item(local_to_map(worldCoord), -1)
	
func placeBlock(worldCoord, itemId):
	# should make a check if the player is present.
	
	set_cell_item(local_to_map(worldCoord), itemId)
	
func gridGetBlock(worldCoord):
	return local_to_map(worldCoord)
	
func gridHilightBlock(worldCoord):
	var gridco = local_to_map(worldCoord)
	if(get_cell_item(gridco)==-1):
		#mistake happend
		var e = 1
	else:
		playerhilight.set_cell_item(gridco,0)
	
func gridClearHilightBlock(mapCoord):
	playerhilight.set_cell_item(mapCoord,-1)
	
	
