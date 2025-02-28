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

const index = [STONE,DIRT,GRASS]




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
		]
	},
	GRASS:{
		"textures":[
			{
				TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
				RIGHT:Vector2(1,0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0)
			}
		],
		"alchemic":{
			DIRT:{
				"conditions":{
					"other":{
						Vector3i(0,1,0): 0
					}
				},
				"other":3
			}
		}
	}
}
