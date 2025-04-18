@tool
extends Resource
class_name MineralTexture

@export var solid: BlockTextureMap
@export var paste: BlockTextureMap
@export var liquid: BlockTextureMap
@export var gass: BlockTextureMap

func getPhase(p: int) -> BlockTextureMap:
	return [solid,liquid,gass,paste][p]
