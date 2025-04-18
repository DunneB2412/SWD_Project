extends Resource
class_name Block

const FULL_BLOCK = preload("res://Scripts/Blocks/fullBlockMechTemplate.tres")
const defMask = 0x14000000

@export var name: String
@export var shape: MeshTemplate = FULL_BLOCK
@export var commonMask: int = defMask
@export var mineral: Mineral
