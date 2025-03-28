extends Resource
class_name MineralHeatMap

@export var shpSolid: float
@export var shpPaste: float
@export var shpLiquid: float
@export var shpGass: float

@export var lhpPaste: float
@export var lhpLiquid: float
@export var lhpGass: float

@export var pcPaste: float
@export var pcLiquid: float
@export var pcGass: float

func getTemp(grams: int, energy: int) -> float :
	return 0;
	
func phaseChange(grams: int, energy: int):
	pass
