extends Resource
class_name SectionData

#ref https://www.youtube.com/watch?v=vzRZjM9MTGw
# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

var data: Dictionary
var size: Vector3i
var name: String


func _init(size: Vector3i, name: String) -> void:
	self.size = size
	self.name = name
	self.data = {}

func getVal(pos: Vector3i) -> PackedInt64Array:
	return data[flattenCord(pos)]

func addAt(pos: Vector3i, val) -> void:
	var flat = flattenCord(pos)
	if data.has(flat):
		data[flattenCord(pos)].append(val)
	else:
		data.merge({flat:PackedInt64Array(val)}) #create a new one
		
func clear(pos: Vector3i) -> void:
	data.erase(flattenCord(pos))
	
func flattenCord(pos: Vector3i) -> int:
	return (pos.x*size.y*size.z) + (pos.y*size.z) + pos.z

func save():
	ResourceSaver.save(self,"res://saves/"+name+".tres")
