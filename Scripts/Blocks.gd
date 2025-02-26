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




const Blocks = {
	"stone":{
		"textures":[
			{
				TOP:Vector2(0, 1), BOTTOM:Vector2(0, 1), LEFT:Vector2(0, 1),
				RIGHT:Vector2(0, 1), FRONT:Vector2(0, 1), BACK:Vector2(0, 1)
			}
		]
	},
	"dirt":{
		"textures":[
			{
				TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(2, 0),
				RIGHT:Vector2(2,0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0)
			}
		]
	},
	"grass":{
		"textures":[
			{
				TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
				RIGHT:Vector2(1,0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0)
			}
		],
		"alchemic":{
			"dirt":{
				"other":"grass"
			}
		}
	}
}
