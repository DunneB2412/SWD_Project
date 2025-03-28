extends Resource
class_name BlockTextureMap



@export var top: Vector2
@export var bottom: Vector2
@export var left: Vector2
@export var right: Vector2
@export var front: Vector2
@export var back: Vector2
@export_range(0,1) var aplha: float = 1

func getTextures() -> Dictionary:
	return {
		Global.DIR.UP:top,Global.DIR.DOWN:bottom,
		Global.DIR.WEST:left,Global.DIR.EAST:right,
		Global.DIR.SOUTH:front,Global.DIR.NORTH:back,
		"alpha": aplha
	}
