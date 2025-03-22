extends Node


const TEXTURE_ATLAS_SIZE = Vector2(3,2)
const TEXTURE_ATLAS_SIZE2 = Vector2(8,4)
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
	STONE,
	SAND,
	LOG,
	PLANK,
	LEAF,
	BRICK,
	CACTUS,
	ASH,
	SMOKE,
	FIRE
}


const index = [
	AIR,
	STONE, #1
	DIRT, #2
	GRASS, #3
	SAND, #4
	LOG,
	PLANK,
	LEAF,
	BRICK,
	CACTUS,
	ASH,
	SMOKE,
	FIRE
]

static func  predOr(a:bool, b:bool):
	return a or b
static func predAnd(a:bool, b:bool):
	return a and b

const blocks = {
	STONE:{
		"textures":[
			{
				TOP:Vector2(0, 0), BOTTOM:Vector2(0, 0), LEFT:Vector2(0, 0),
				RIGHT:Vector2(0, 0), FRONT:Vector2(0, 0), BACK:Vector2(0, 0)
			}
		]
	},
	DIRT:{
		"textures":[
			{
				TOP:Vector2(1, 0), BOTTOM:Vector2(1, 0), LEFT:Vector2(1, 0),
				RIGHT:Vector2(1,0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0)
			}
		],
		"alchemic":[
			{
				Vector3i(0,0,0):{ #allow checking it's self
					DIRT:[
							{
							"conditions":{
								"heat":{
									"low": 120
								}
							},
							"self": 4
						}
					]
					
				},
				Vector3i(0,1,0):{
					AIR:[
						{
							"conditions":{
								"other":{
									"logic" : "or",
									Vector3i(1,0,0): {"blocktype": 3,"blocktvar": 0},
									Vector3i(-1,0,0): {"blocktype": 3,"blocktvar": 0},
									Vector3i(0,0,1): {"blocktype": 3,"blocktvar": 0},
									Vector3i(0,0,-1): {"blocktype": 3,"blocktvar": 0}
								}
							},
							"self":3
						}
					]
				},
				Vector3i(0,-1,0):{
					"any":[
						{
							"conditions":{
								"other":{
									"logic" : "or",
									Vector3i(1,0,0): {"blocktype": 3,"blocktvar": 0},
									Vector3i(-1,0,0): {"blocktype": 3,"blocktvar": 0},
									Vector3i(0,0,1): {"blocktype": 3,"blocktvar": 0},
									Vector3i(0,0,-1): {"blocktype": 3,"blocktvar": 0}
								},
								"logic": "and",
								"self":{
									Vector3i(0,1,0): {"blocktype": 0}, # make sure it is not smothered.
								}
							},
							"self":3
						},
						{
							"conditions":{
								"other":{
									Vector3i(0,0,0):{"opaque": 1}
								}
							},
							"impact": 3
						}
					]
				}
			}
		]
	},
	GRASS:{
		"textures":[
			{
				TOP:Vector2(1, 1), BOTTOM:Vector2(1, 0), LEFT:Vector2(0, 1),
				RIGHT:Vector2(0,1), FRONT:Vector2(0, 1), BACK:Vector2(0, 1)
			},
			{
				TOP:Vector2(1, 2), BOTTOM:Vector2(1, 0), LEFT:Vector2(0, 2),
				RIGHT:Vector2(0,2), FRONT:Vector2(0, 2), BACK:Vector2(0, 2)
			}
		],
		"alchemic":[
			{
				Vector3i(0,0,0):{ #allow checking it's self
					GRASS:[
							{ # we still need to make sure we are looking at grass because the rest of the system.
							"conditions":{
								"heat":{
									"low":120
								}
							},
							"self": 4
						},
						{
							"conditions":{
								"heat":{
									"high":-1
								},
								"logic": "and",
								"self":{
									Vector3i(0,0,0):{"blocktvar": 0}
								}
							},
							"self": 3 | (1<<10) # encode the block variant. frossen grass
						}
					]
					
				},
				Vector3i(0,1,0):{
					"any":[
						{ #should smuther grass if it is couvered by anything solid. 
							"conditions":{
								"other":{
									Vector3i(0,0,0):{"opaque": 1}
								}
							},
							"self":2
						}
					]
				},
				Vector3i(0,-1,0):{
					AIR:[{"impact": 3}]
					
				},
				Vector3i(1,0,0):{
					DIRT:[
						{
							"conditions":{
								"other":{
									Vector3i(0,1,0): {"blocktype": 0}
								}
							},
							"other":3
						}
					]
				},
				Vector3i(-1,0,0):{
					DIRT:[
						{
							"conditions":{
								"other":{
									Vector3i(0,1,0): {"blocktype": 0}
								}
							},
							"other":3
						}
					]
				},
				Vector3i(0,0,1):{
					DIRT:[
						{
							"conditions":{
								"other":{
									Vector3i(0,1,0): {"blocktype": 0}
								}
							},
							"other":3
						}
					]
				},
				Vector3i(0,0,-1):{
					DIRT:[
						{
							"conditions":{
								"other":{
									Vector3i(0,1,0): {"blocktype": 0}
								}
							},
							"other":3
						}
					]
				}
			},
			{
				Vector3i(0,0,0):{ 
					GRASS:[
						{
							"conditions":{ #let the grass taw back out.
								"heat":{
									"low":1
								},
								"logic": "and",
								"self":{
									Vector3i(0,0,0):{"blocktvar": 1}
								}
								
							},
							"self": 3
						}
					]
				},
				Vector3i(0,1,0):{
					"any":[
						{ #should smuther grass if it is couvered by anything solid. 
							"conditions":{
								"other":{
									Vector3i(0,0,0):{"opaque": 1}
								}
							},
							"self":2
						}
					]
				},
			}
		]
	},
	SAND:{
		"textures":[
			{
				TOP:Vector2(2, 2), BOTTOM:Vector2(2, 2), LEFT:Vector2(2, 2),
				RIGHT:Vector2(2, 2), FRONT:Vector2(2, 2), BACK:Vector2(2, 2)
			}
		],
		"alchemic":[
			{
				Vector3i(0,0,0):{ 
					SAND:[
						{
							"conditions":{
								"heat":{ # test constant temp increase
									"low":200
								}
								
							},
							"self": 0
						},
						{
							"conditions":{
								"heat":{ # test constant temp increase
									"low":1
								}
								
							},
							"heat": 3
						}
					]
				}
			}
		]
	},
	LOG:{
		"textures":[
			{
				TOP:Vector2(3, 0), BOTTOM:Vector2(3, 0), LEFT:Vector2(2, 0),
				RIGHT:Vector2(2, 0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0)
			}
		]
	},
	PLANK:{
		"textures":[
			{
				TOP:Vector2(4, 0), BOTTOM:Vector2(4, 0), LEFT:Vector2(4, 0),
				RIGHT:Vector2(4, 0), FRONT:Vector2(4, 0), BACK:Vector2(4, 0)
			}
		]
	},
	LEAF:{
		"textures":[
			{
				TOP:Vector2(3, 1), BOTTOM:Vector2(3, 1), LEFT:Vector2(3, 1),
				RIGHT:Vector2(3, 1), FRONT:Vector2(3, 1), BACK:Vector2(3, 1)
			}
		]
	},
	BRICK:{
		"textures":[
			{
				TOP:Vector2(4, 1), BOTTOM:Vector2(4, 1), LEFT:Vector2(4, 1),
				RIGHT:Vector2(4, 1), FRONT:Vector2(4, 1), BACK:Vector2(4, 1)
			}
		]
	},
	CACTUS:{
		"textures":[
			{
				TOP:Vector2(3,2),BOTTOM:Vector2(3,2),LEFT:Vector2(3,2),
				RIGHT:Vector2(3,2),FRONT:Vector2(3,2),BACK:Vector2(3,2),
			}
		]
	},
	ASH:{
		"textures":[
			{
				TOP:Vector2(3,3),BOTTOM:Vector2(3,3),LEFT:Vector2(3,3),
				RIGHT:Vector2(3,3),FRONT:Vector2(3,3),BACK:Vector2(3,3),
			}
		]
	},
	SMOKE:{
		"textures":[
			{
				TOP:Vector2(4,3),BOTTOM:Vector2(4,3),LEFT:Vector2(4,3),
				RIGHT:Vector2(4,3),FRONT:Vector2(4,3),BACK:Vector2(4,3),
			}
		]
	},
	FIRE:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	},
	IRON:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	},
	COPPER:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	},
	TIN:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	},
	BRONZ:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	},
	CARBON:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	},
	STEEL:{
		"textures":[
			{
				TOP:Vector2(5,0),BOTTOM:Vector2(5,0),LEFT:Vector2(5,0),
				RIGHT:Vector2(5,0),FRONT:Vector2(5,0),BACK:Vector2(5,0),
			}
		]
	}
}
