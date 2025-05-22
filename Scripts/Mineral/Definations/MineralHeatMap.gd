@tool
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

@export var condsolid: float = 0.25
@export var condPaste: float = 0.25
@export var condLiquid: float = 0.25
@export var condGass: float = 0.25
 
func getShp(phase:int):
	return [shpSolid,shpLiquid,shpGass,shpPaste][phase]
func getLhp(phase:int):
	return [lhpLiquid,lhpGass,lhpPaste][phase]
func getPCtemp(phase:int):
	return [pcLiquid,pcGass,pcPaste][phase]
	
func getCond(phase:int):
	return [condsolid,condLiquid,condGass,condPaste][phase]
