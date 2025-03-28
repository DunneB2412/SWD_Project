extends Object

enum DIR{
	UP,
	DOWN,
	WEST,
	EAST,
	SOUTH,
	NORTH
}
const  OFFSETS = {
	DIR.SOUTH: Vector3i(1,0,0),
	DIR.NORTH: Vector3i(-1,0,0),
	DIR.UP:Vector3i(0,1,0),
	DIR.DOWN:Vector3i(0,-1,0),
	DIR.EAST:Vector3i(0,0,1),
	DIR.WEST:Vector3i(0,0,-1)
}
