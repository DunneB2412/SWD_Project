extends AlchemicMap
class_name Dirt

func process(section:Section, cord: Vector3i, val: int):
	var temp = section.getTemp(cord)
	if temp > SectionData.celToKel(125):
		#return{Global.REF_VEC3: {}} #TODO, adres the fact that there may not be 100 t0 tale
		var rem = section.addAt(cord,val,-100,temp, Global.REF_VEC3)
		var alt = SectionData.setMeta(val, SectionData.INC.BLOCK_TYPE,8 )
		var add = section.addAt(cord,alt,-rem,temp,Global.REF_VEC3)
		if add < rem:
			section.addAt(cord,val,add+rem,temp, Global.REF_VEC3)
