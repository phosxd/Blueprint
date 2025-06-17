class_name Blueprint
## Class for holding a dictionary blueprint.

## Blueprint error codes.
enum error {
	OK,
	FAILED,
	ERR_BP_PARAMSET_NOT_DICTIONARY,
	ERR_BP_PARAMSET_MISSING_TYPE,
	ERR_BP_PARAMSET_INVALID_TYPE_PARAM,
	ERR_BP_PARAMSET_INVALID_OPTIONAL_PARAM,
	ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM,
	ERR_BP_PARAMSET_INVALID_RANGE_PARAM,
	ERR_BP_PARAMSET_INVALID_ENUM_PARAM
}
## Blueprint errors as explanatory strings.
const error_strings:Array[String] = [
	'OK.',
	'Unexpected failure.',
	'Blueprint parameter set must be of type `Dictionary`.',
	'Blueprint parameter set must contain a "type" parameter.',
	'Blueprint parameter set\'s "type" parameter must be of type `String` & match one of the following values: "string", "int", "float", "array", "dict", ">{blueprint_name}".',
	'Blueprint parameter set\'s "optional" parameter must be of type `bool`.',
	'Blueprint parameter set\'s "default" parameter value type must match the `type` parameter & is required when `optional` parameter is false or undefined, or when `type` is not a blueprint.',
	'Blueprint parameter set\'s "range" parameter must be of type `Array` & have 2 elements of type `int`.',
	'Blueprint parameter set\'s "enum" parameter must be of type `Array` & have elements of value type that matches `type` parameter.',
]
## Blueprint data.
var data:Dictionary
## Whether or not this Blueprint is valid for use.
var valid:bool



## Initializes the Blueprint.
func _init(name:String, data:Dictionary) -> void:
	# If invalid Blueprint, do nothing.
	var validation_error:error = _validate(data)
	if validation_error: 
		valid = false
		push_error(error_strings[validation_error])
		return
	valid = true
	# Otherwise, set up Blueprint.
	self.data = data
	BlueprintManager.add_blueprint(name, self)


## Checks if the data is a valid Blueprint. Returns Blueprint error code.
static func _validate(data:Dictionary) -> error:
	for key in data:
		var value = data[key]
		if typeof(value) != TYPE_DICTIONARY: return error.ERR_BP_PARAMSET_NOT_DICTIONARY

		# Validate "type" parameter.
		var type_param = value.get('type')
		var type_param_literal_type # Track the type, for use in other checks.
		if type_param == null:
			type_param_literal_type = TYPE_NIL
		else:
			if typeof(type_param) != TYPE_STRING: return error.ERR_BP_PARAMSET_INVALID_TYPE_PARAM
			match type_param:
				'string': type_param_literal_type = TYPE_STRING
				'int': type_param_literal_type = TYPE_INT
				'float': type_param_literal_type = TYPE_FLOAT
				'array': type_param_literal_type = TYPE_ARRAY
				'dict': type_param_literal_type = TYPE_DICTIONARY
				_:
					if not type_param.begins_with('>'): return error.ERR_BP_PARAMSET_INVALID_TYPE_PARAM
					type_param_literal_type = '>'

		# Validate "optional" parameter.
		var optional_param = value.get('optional', false)
		if typeof(optional_param) != TYPE_BOOL: return error.ERR_BP_PARAMSET_INVALID_OPTIONAL_PARAM

		# Validate "default" parameter.
		var default_param = value.get('default')
		if default_param == null:
			if not optional_param: return error.ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM
			if type_param_literal_type != '>': return error.ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM
		var typeof_default_param := typeof(default_param)
		# Set typeof_default_param to `int` if holds no floating value.
		if typeof_default_param == TYPE_FLOAT:
			if round(default_param) == default_param: typeof_default_param = TYPE_INT
		if typeof_default_param != type_param_literal_type: return error.ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM

		# Validate "range" parameter.
		var range_param = value.get('range')
		if range_param != null:
			if typeof(range_param) != TYPE_ARRAY: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM
			var count:int = 0
			for item in range_param:
				if typeof(item) not in [TYPE_INT, TYPE_FLOAT]: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM
				if round(item) != item: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM
				count += 1
			if count != 2: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM

		# Validate "enum" parameter.
		var enum_param = value.get('enum')
		if enum_param != null:
			if typeof(enum_param) != TYPE_ARRAY: return error.ERR_BP_PARAMSET_INVALID_ENUM_PARAM
			for item in enum_param:
				if typeof(item) != type_param_literal_type: return error.ERR_BP_PARAMSET_INVALID_ENUM_PARAM

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
	var new_value:Array = []
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
			var create_element:bool = true
			var item_type:Variant.Type = typeof(item)
			var expected_type:String
			if element_types_size == 1: expected_type = element_types[0]
			else: expected_type = element_types[index]
			# Check if item matches expected type.
			match expected_type:
				'string': if item_type != TYPE_STRING: create_element = false
				'int': if item_type != TYPE_INT: create_element = false
				'float': if item_type != TYPE_FLOAT: create_element = false
				'array': if item_type != TYPE_ARRAY: create_element = false
				'dict': if item_type != TYPE_DICTIONARY: create_element = false
				_:
					# If expecting blueprint, match item to the expected blueprint.
					if expected_type.begins_with('>'):
						if item_type != TYPE_DICTIONARY: create_element = false
						else:
							item = _handle_blueprint_match(item, {'type':expected_type, 'default':{}})
					# If unexpected type, skip.
					else: create_element = false
			# Put item into new array, if valid.
			if create_element:
				new_value.append(item)
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
