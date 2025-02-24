class_name _ObjectParser

const REQUIRED_OBJECT_SUFFIX="_r"
const COMPACT_VAR_SUFFIX="_c"

const WHITELIST_VAR_NAME = "whitelist"

static func to_dict(obj:Object,compact:bool,skip_whitelist:bool=false) ->Dictionary:
	if obj == null:
		return {}
	if !skip_whitelist:
		return _get_dict_with_list(obj,obj.get_property_list(),compact)

	var output:Dictionary = {}
	if WHITELIST_VAR_NAME in obj and obj[WHITELIST_VAR_NAME].size() > 0:
		return _get_dict_with_list(obj,obj[WHITELIST_VAR_NAME],false)

	return output


static func _get_dict_with_list(obj:Object,property_list:Array,compact:bool) ->Dictionary:
	var output:Dictionary = {}
	for property in property_list:
		var name = ""
		if typeof(property) != TYPE_STRING && "name" in property:
			name = str(property.name)
		else:
			name = property
		if name.begins_with("_"):
			continue
		if compact and !_ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
			continue
		if !name in obj:
			continue
		var data_type = typeof(obj[name])
		var value = obj[name]
		match data_type:
			TYPE_NIL:
				continue
			TYPE_OBJECT:
				if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
					#var t = Thread.new()
					#var lamda = func():
					output[name] = to_dict(value,compact)

			TYPE_ARRAY: # todo
				continue
			TYPE_DICTIONARY: # todo
				var processsed_dictionary = {}
				for key in Dictionary(value):
					var key_type = typeof(value[key])
					var key_value = value[key]
					match key_type:
						TYPE_OBJECT:
							if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
								processsed_dictionary[name] = to_dict(key_value,compact)
						TYPE_ARRAY:
							continue
						_:
							processsed_dictionary[key] = key_value
				output[name] = processsed_dictionary
			_:
				output[name] = value
	return output

static func _ends_with(v:String,list:Array) -> bool:
	for s in list:
		if v.ends_with(s):
			return true
	return false