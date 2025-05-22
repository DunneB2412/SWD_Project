extends Resource
class_name Mineral

static func check():
	pass

@export var name: String
@export var prim_texture: MineralTexture
@export var aux_texture: MineralTexture
@export var uses_paste_phase: bool
@export var color: Color
@export var heatCapacity: MineralHeatMap
@export var normalDendity: float

@export var hardness: int #energy required to consume one levle of strain
@export var clicable: bool
@export var clickAction: Callable

@export var alchemic: AlchemicMap






#have a primary and seccondary texture.
#all blocks will have a primary, where the majority of the material is one mineral.
# water will have a primary with the standard liquid and a secondary of darkening when liquid ans brightening when solid.
# items should be able to contain the same posible combination of minerals as in world blocks
