extends AlchemicMap
class_name Sand

func process(section:Section, cord: Vector3i, val: int):
	var temp = section.getTemp(cord)
	var mass = SectionData.readMeta(val,SectionData.INC.MASS)
	var typ = SectionData.readMeta(val,SectionData.INC.BLOCK_TYPE)
	var offsets = [
		Global.REF_VEC3,
		Global.OFFSETS[Global.DIR.WEST],
		Global.OFFSETS[Global.DIR.EAST],
		Global.OFFSETS[Global.DIR.NORTH],
		Global.OFFSETS[Global.DIR.SOUTH]
	]
	
	var move = mass
	if mass>250:
		move = move >>1
	
	for offset in offsets:
		var altCord = cord+offset+Global.OFFSETS[Global.DIR.DOWN]
		var alt = section.getVal(altCord)
		var altP = SectionData.readMeta(alt[0],SectionData.INC.PHASE)
		var altT = SectionData.readMeta(alt[0],SectionData.INC.BLOCK_TYPE)
		var altM = SectionData.readMeta(alt[0],SectionData.INC.MASS)
		if (alt[0]>=0&&altP>0) || alt[0]==0 ||  (altT == typ && altM < (section.lib.blocks[typ].mineral.normalDendity-250) ):
			var rem = section.addAt(cord,val,-move,temp, Global.REF_VEC3)
			var add = section.addAt(altCord,val,-rem,temp)
			#if add < rem:
				#section.addAt(cord,val,add+rem,temp, Global.REF_VEC3)
			move += rem
			if move <=0:
				return
