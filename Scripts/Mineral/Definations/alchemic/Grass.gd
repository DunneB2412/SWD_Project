extends Burning
class_name Grass

const fertailSoil = [2]

func process(section:Section, cord: Vector3i, val: int):
	super.process(section,cord,val)
	var temp = section.getTemp(cord)
	var up = section.getVal(cord+Global.OFFSETS[Global.DIR.UP])
	var cell = section.getVal(cord)
	if up[0]>0 || !fertailSoil.has(SectionData.readMeta(cell[0],SectionData.INC.BLOCK_TYPE)):
		#return{Global.REF_VEC3: {}}
		section.addAt(cord,val,-50,temp, Global.REF_VEC3)
		var alt = SectionData.setMeta(val, SectionData.INC.BLOCK_TYPE,2 )
		section.addAt(cord,alt,50,temp,Global.REF_VEC3)
		return
		
	if temp < 0:
		return
	var mass = SectionData.readMeta(val, Section.INC.MASS)
	if mass <= 500:
		section.addAt(cord,val,50,temp, Global.REF_VEC3)
		if mass < 100:
			return
			
	
	
	var offsets = [
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
			var altT = SectionData.readMeta(alt[0],SectionData.INC.BLOCK_TYPE)
			var altTop = section.getVal(cord+offset+Global.OFFSETS[Global.DIR.UP])
			if altT == 2 && altTop[0] <=0:
				var hasGrass = false
				for v in alt:
					var vT = SectionData.readMeta(v,SectionData.INC.BLOCK_TYPE)
					if vT ==3:
						hasGrass = hasGrass || true
				if ! hasGrass:
					section.addAt(cord,val,-50,temp, Global.REF_VEC3)
					section.addAt(cord+offset,val,50,temp)
								
