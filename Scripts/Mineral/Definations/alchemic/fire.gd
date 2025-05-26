extends AlchemicMap
class_name Fire

const flamable = [9]

func process(section:Section, cord: Vector3i, val: int):
	var temp = section.getTemp(cord)
	var mass = SectionData.readMeta(val, Section.INC.MASS)
	if mass > 2000:
		var dif = mass - 2000
		section.addAt(cord,val,-dif,temp, Global.REF_VEC3)
	section.addHeatAt(cord,100*mass)
	
	section.addAt(cord,val,-500,temp, Global.REF_VEC3)
	if temp < 50:
		section.addAt(cord,val,-1000,temp, Global.REF_VEC3)
		return
	var offsets = [
		Global.REF_VEC3,
		Global.OFFSETS[Global.DIR.WEST],
		Global.OFFSETS[Global.DIR.EAST],
		Global.OFFSETS[Global.DIR.NORTH],
		Global.OFFSETS[Global.DIR.SOUTH],
		Global.OFFSETS[Global.DIR.NORTH]+Global.OFFSETS[Global.DIR.EAST],
		Global.OFFSETS[Global.DIR.SOUTH]+Global.OFFSETS[Global.DIR.EAST],
		Global.OFFSETS[Global.DIR.NORTH]+Global.OFFSETS[Global.DIR.WEST],
		Global.OFFSETS[Global.DIR.SOUTH]+Global.OFFSETS[Global.DIR.WEST],
	]
	var extra = [
		Global.OFFSETS[Global.DIR.UP],
		Global.REF_VEC3,
		Global.OFFSETS[Global.DIR.DOWN]
	]
	for dirA in offsets:
		for dirB in extra:
			var offset = dirB+dirA
			var alt = section.getVal(cord+offset)
			for v in alt:
				var t = SectionData.readMeta(v,SectionData.INC.BLOCK_TYPE)
				if t in flamable:
					section.addAt(cord+offset,val,+550,temp, Global.REF_VEC3)
					section.addAt(cord+offset,v,-1,temp, Global.REF_VEC3)
