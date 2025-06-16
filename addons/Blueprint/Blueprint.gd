class_name Blueprint
## Class for holding a dictionary blueprint.

## Blueprint error codes.
enum error {
	OK,
	FAILED,
	ERR_BP_PARAMSET_NOT_DICTIONARY,
	ERR_BP_PARAMSET_MISSING_TYPE,
	ERR_BP_PARAMSET_INVALID_TYPE_PARAM,
}
## Blueprint errors as explanatory strings.
const error_strings:Array[String] = [
	'OK.',
	'Unexpected failure.',
	'Blueprint parameter set must be of type `Dictionary`.',
	'Blueprint parameter set must contain a "type" parameter.',
	'Blueprint parameter set\'s "type" parameter must be of type `String` & match one of the following values: "string", "int", "float", "array", "dict", ">{blueprint_name}".',
]
## Blueprint data.
var data:Dictionary
## Whether or not this Blueprint is valid for use.
var valid:bool



## Initializes the Blueprint.
func _init(name:String, data:Dictionary) -> void:
	self.data = data
	var validation:error = _validate(data)
	if validation != error.OK: 
		valid = false
		push_error(error_strings[validation])
		return
	valid = true
	BlueprintManager.add_blueprint(name, self)


## Checks if the data is a valid Blueprint. Returns Blueprint error code.
static func _validate(data:Dictionary) -> error:
	for key in data:
		var value = data[key]
		if typeof(value) != TYPE_DICTIONARY: return error.ERR_BP_PARAMSET_NOT_DICTIONARY
		# Get type.
		var type_param = value.get('type')
		if type_param == null: return error.ERR_BP_PARAMSET_MISSING_TYPE
		if typeof(type_param) != TYPE_STRING: return error.ERR_BP_PARAMSET_INVALID_TYPE_PARAM
		match type_param:
			'string': pass
			'int': pass
			'float': pass
			'array': pass
			'dict': pass
			_:
				if not type_param.begins_with('>'): return error.ERR_BP_PARAMSET_INVALID_TYPE_PARAM
	return error.OK


## Matches the `object` to this Blueprint, mismatched values will be fixed. Returns fixed `object`. Returns `null` if Blueprint is invalid.
func match(object:Dictionary):
	if not self.valid: return # Return if Blueprint is invalid.
	for key in self.data:
		var blueprint_params = self.data[key]
		var object_value = object.get(key)
		# If value missing, use default.
		if not object_value && not blueprint_params.get('optional'):
			if blueprint_params.type.begins_with('>'):
				object.set(key, _handle_blueprint_match({}, blueprint_params))
			else:
				object.set(key, blueprint_params.default)
			continue
		# If value does not match enum (if defined), use default.
		if object_value not in blueprint_params.get('enum',[object_value]):
			object.set(key, blueprint_params.default)
			continue
		# Match.
		match blueprint_params.type:
			'string': object.set(key, _handle_string_match(object_value, blueprint_params))
			'int': object.set(key, _handle_int_match(object_value, blueprint_params))
			'float': object.set(key, _handle_float_match(object_value, blueprint_params))
			'array': object.set(key, _handle_array_match(object_value, blueprint_params))
			'dict': object.set(key, _handle_dict_match(object_value, blueprint_params))
			_:
				if blueprint_params.type.begins_with('>'):
					object.set(key, _handle_blueprint_match(object_value, blueprint_params))
				else:
					assert(false, 'Invalid Blueprint parameters type "%s".' % blueprint_params.type)

	return object




static func _handle_string_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_STRING: return parameters.default # Validate value type.
	# Validate string length.
	var range = parameters.get('range')
	var value_length:int = value.length()
	if range:
		if value_length > range[1] || value_length < range[0]: return parameters.default
	# Validate prefix.
	var prefix = parameters.get('prefix')
	if prefix:
		if not value.begins_with(prefix): return parameters.default
	# Validate suffix.
	var suffix = parameters.get('suffix')
	if prefix:
		if not value.ends_with(prefix): return parameters.default
	# Validate regex match.
	var regex_pattern = parameters.get('regex')
	if regex_pattern:
		var regex := RegEx.new()
		regex.compile(regex_pattern, false)
		var result = regex.search(value)
		if not result: return parameters.default
		result = ''.join(result.strings)
		print(result)
		if result == '' || value != result: return parameters.default
		
	
	return value


static func _handle_int_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_INT: return parameters.default # Validate value type.
	var range = parameters.get('range')
	# Validate min/max.
	if range:
		if value > range[1] || value < range[0]: return parameters.default
	return value


static func _handle_float_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_FLOAT: return parameters.default # Validate value type.
	var range = parameters.get('range')
	# Validate min/max.
	if range:
		if value > range[1] || value < range[0]: return parameters.default
	return value


static func _handle_array_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_ARRAY: return parameters.default # Validate value type.
	var new_value:Array = value.duplicate(true)
	var range = parameters.get('range')
	var value_size:int = value.size()
	# Validate array size.
	if range:
		if value_size > range[1] || value_size < range[0]: return parameters.default
	# Validate type of each element in array.
	var element_types = parameters.get('element_types')
	if element_types:
		var element_types_size:int = element_types.size()
		var index:int = 0
		for item in value:
			var item_type:Variant.Type = typeof(item)
			var expected_type:String
			if element_types_size == 1: expected_type = element_types[0]
			else: expected_type = element_types[index]
			match expected_type:
				'string': if item_type != TYPE_STRING: return parameters.default
				'int': if item_type != TYPE_INT: return parameters.default
				'float': if item_type != TYPE_FLOAT: return parameters.default
				'array': if item_type != TYPE_ARRAY: return parameters.default
				'dict': if item_type != TYPE_DICTIONARY: return parameters.default
				_:
					if expected_type.begins_with('>'): assert(false, 'Not currently supporting array element type of "blueprint pointer".')
					else: assert(false, 'Invalid Blueprint parameters array element type "%s".' % expected_type)
			index += 1
	return new_value


static func _handle_dict_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_DICTIONARY: return parameters.default # Validate value type.
	var range = parameters.get('range')
	var value_size:int = value.size()
	# Validate dictionary size.
	if range:
		if value_size > range[1] || value_size < range[0]: return parameters.default
	return value


static func _handle_blueprint_match(value, parameters:Dictionary):
	var blueprint_name:String = parameters.type.trim_prefix('>')
	var blueprint = BlueprintManager.get_blueprint(blueprint_name)
	var empty_matched:Dictionary = blueprint.match({})
	if typeof(value) != TYPE_DICTIONARY: return empty_matched # Validate value type.
	var matched:Dictionary = blueprint.match(value)
	return matched
