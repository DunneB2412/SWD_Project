extends RayCast3D


func testRay(range: int):
	#test z,y (2,1)
	#then x,y (0,1)
	#then x,z (0,2)
	var tests = [Vector2i(2,1),Vector2i(0,1),Vector2i(0,2)]
	for t in tests:
		pass
		
func testDir(test: Vector2i):
	var dof
