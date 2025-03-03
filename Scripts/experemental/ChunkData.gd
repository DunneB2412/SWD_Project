extends Resource
class_name ChunkData

#ref https://www.youtube.com/watch?v=vzRZjM9MTGw
# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

var data:PackedInt32Array 
var size: Vector3i
var name: String


func _init(size: Vector3i, name: String) -> void:
	self.size = size
	self.name = name
	self.data = PackedInt32Array()
	self.data.resize(self.size.x*self.size.y*self.size.z)

func getVal(pos: Vector3i) -> int:
	return data[flattenCord(pos)]

func setVal(pos: Vector3i, val) -> void:
	data[flattenCord(pos)] = val
	
func flattenCord(pos: Vector3i) -> int:
	return (pos.x*size.y*size.z) + (pos.y*size.z) + pos.z

func save():
	ResourceSaver.save(self,"res://saves/"+name+".tres")
