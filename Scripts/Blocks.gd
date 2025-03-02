extends Node


const TEXTURE_ATLAS_SIZE = Vector2(3,2)

enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK
}

enum{
	AIR,
	DIRT,
	GRASS,
	STONE
}



const types = {
	DIRT:{
		TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(2, 0),
		RIGHT:Vector2(2,0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0)
	},
	GRASS:{
		TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
		RIGHT:Vector2(1,0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0)
	},
	STONE:{
		TOP:Vector2(0, 1), BOTTOM:Vector2(0, 1), LEFT:Vector2(0, 1),
		RIGHT:Vector2(0, 1), FRONT:Vector2(0, 1), BACK:Vector2(0, 1)
	}
}


const alchemic = {
	DIRT:{
	},
	GRASS:{
		DIRT:{
			"seld":GRASS,
			"other":GRASS
		}
	},
	STONE:{
		TOP:Vector2(0, 1), BOTTOM:Vector2(0, 1), LEFT:Vector2(0, 1),
		RIGHT:Vector2(0, 1), FRONT:Vector2(0, 1), BACK:Vector2(0, 1)
	}
}

const index = [STONE,DIRT,GRASS,AIR]

static func  predOr(a:bool, b:bool):
	return a or b
static func predAnd(a:bool, b:bool):
	return a and b

const blocks = {
	STONE:{
		"textures":[
			{
				TOP:Vector2(0, 1), BOTTOM:Vector2(0, 1), LEFT:Vector2(0, 1),
				RIGHT:Vector2(0, 1), FRONT:Vector2(0, 1), BACK:Vector2(0, 1)
			}
		]
	},
	DIRT:{
		"textures":[
			{
				TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(2, 0),
				RIGHT:Vector2(2,0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0)
			}
		],
		"alchemic":[
			{
				Vector3i(0,1,0):{
					AIR:{
						"conditions":{
							"other":{
								"logic" : "or",
								Vector3i(1,0,0): {"blocktype": 3},
								Vector3i(-1,0,0): {"blocktype": 3},
								Vector3i(0,0,1): {"blocktype": 3},
								Vector3i(0,0,-1): {"blocktype": 3}
							}
						},
						"self":3
					}
				},
				Vector3i(0,-1,0):{
					AIR:{
						"impact": 3
					},
					"any":{
						"conditions":{
							"other":{
								"logic" : "or",
								Vector3i(1,0,0): {"blocktype": 3},
								Vector3i(-1,0,0): {"blocktype": 3},
								Vector3i(0,0,1): {"blocktype": 3},
								Vector3i(0,0,-1): {"blocktype": 3}
							},
							"logic": "and",
							"self":{
								Vector3i(0,1,0): {"blocktype": 0}, # make sure it is not smothered.
							}
						},
						"self":3
					}
				}
			}
		]
	},
	GRASS:{
		"textures":[
			{
				TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
				RIGHT:Vector2(1,0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0)
			}
		],
		"alchemic":[
			{
				Vector3i(0,1,0):{
					"any":{ #should smuther grass if it is couvered by anything solid. 
						"conditions":{
							"other":{
								Vector3i(0,1,0):{"opaque": 1}
							}
						},
						#"self":2
					}
				},
				Vector3i(0,-1,0):{
					AIR:{"impact": 3}
					
				},
				Vector3i(1,0,0):{
					DIRT:{
						"conditions":{
							"other":{
								Vector3i(0,1,0): {"blocktype": 0}
							}
						},
						"other":3
					}
				},
				Vector3i(-1,0,0):{
					DIRT:{
						"conditions":{
							"other":{
								Vector3i(0,1,0): {"blocktype": 0}
							}
						},
						"other":3
					}
				},
				Vector3i(0,0,1):{
					DIRT:{
						"conditions":{
							"other":{
								Vector3i(0,1,0): {"blocktype": 0}
							}
						},
						"other":3
					}
				},
				Vector3i(0,0,-1):{
					DIRT:{
						"conditions":{
							"other":{
								Vector3i(0,1,0): {"blocktype": 0}
							}
						},
						"other":3
					}
				}
			}
		]
	}
}
