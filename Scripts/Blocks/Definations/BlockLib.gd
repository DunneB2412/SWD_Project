@tool
extends Resource
class_name BlockLib

@export var blocks: Array[Block]
@export var material: StandardMaterial3D
@export var size: Vector2


const AlchemitPlaceholder = {
	
	2:{
		"alchemic":[
			{
				Vector3i(0,0,0):{ #allow checking it's self
					2:[
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
					0:[
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
	3:{
		"alchemic":[
			{
				Vector3i(0,0,0):{ #allow checking it's self
					3:[
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
					0:[{"impact": 3}]
					
				},
				Vector3i(1,0,0):{
					2:[
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
					2:[
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
					2:[
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
					2:[
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
					3:[
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
	}
	
}
