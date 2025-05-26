extends AlchemicMap
class_name Burning

func process(section:Section, cord: Vector3i, val: int):
	var p = SectionData.readMeta(val, Section.INC.PHASE)
	var temp = section.getTemp(cord)
	if temp > SectionData.celToKel(300):
		#return{Global.REF_VEC3: {}}
		section.addAt(cord,val,-100,temp, Global.REF_VEC3)
		var alt = SectionData.setMeta(val, SectionData.INC.BLOCK_TYPE,10 )
		section.addAt(cord,alt,100,temp,Global.REF_VEC3)
