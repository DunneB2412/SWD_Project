extends Resource
class_name Mineral

static func check():
	pass

@export var name: String
@export var texture: MineralTexture
@export var uses_paste_phase: bool
@export var color: Color
@export var parentid: int = 0 #default is stone
@export var varId: int
@export var heatCapacity: MineralHeatMap
@export var normalDendity: float

@export var hardness: int #energy required to consume one levle of strain
@export var meshTemplate: MeshTemplate
@export var clicable: bool
@export var clickAction: Callable

@export var alchemic: AlchemicMap
