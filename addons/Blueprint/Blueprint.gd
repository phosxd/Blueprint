class_name Blueprint
## Class for holding a dictionary blueprint.

const TYPE_BLUEPRINT_POINTER:int = TYPE_MAX+1

## Blueprint error codes.
enum error {
	BP_OK,
	BP_FAILED,
	ERR_BP_PARAMSET_NOT_DICTIONARY,
	ERR_BP_PARAMSET_MISSING_TYPE,
	ERR_BP_PARAMSET_INVALID_TYPE_PARAM,
	ERR_BP_PARAMSET_INVALID_OPTIONAL_PARAM,
	ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM,
	ERR_BP_PARAMSET_INVALID_RANGE_PARAM,
	ERR_BP_PARAMSET_INVALID_STEP_PARAM,
	ERR_BP_PARAMSET_INVALID_ENUM_PARAM,
	ERR_BP_PARAMSET_INVALID_PREFIX_PARAM,
	ERR_BP_PARAMSET_INVALID_SUFFIX_PARAM,
	ERR_BP_PARAMSET_INVALID_REGEX_PARAM,
	ERR_BP_PARAMSET_INVALID_ELEMENT_TYPES_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_PREFIX_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_SUFFIX_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_REGEX_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_ELEMENT_TYPES_PARAM,
	ERR_BP_DATA_INVALID_TYPE,
	MATCH_OK,
	MATCH_FAILED,
	ERR_MATCH_INVALID,
	ERR_MATCH_FAILED_TYPE,
	ERR_MATCH_FAILED_ENUM,
	ERR_MATCH_FAILED_RANGE,
	ERR_MATCH_FAILED_STEP,
	ERR_MATCH_FAILED_PREFIX,
	ERR_MATCH_FAILED_SUFFIX,
	ERR_MATCH_FAILED_REGEX,
	ERR_MATCH_FAILED_FORMAT,
}

## Blueprint errors as explanatory strings.
const error_strings:Array[String] = [
	'Blueprint validated with no errors.',
	'Blueprint validation failed unexpectedly.',
	'Blueprint parameter set must be of type `Dictionary`.',
	'Blueprint parameter set must contain a "type" parameter.',
	'Blueprint parameter set\'s "type" parameter must be of type `String` & match one of the following values: "string", "bool", "int", "float", "array", "dict", ">{blueprint_name}".',
	'Blueprint parameter set\'s "optional" parameter must be of type `bool`.',
	'Blueprint parameter set\'s "default" parameter value type must match the `type` parameter & is always required except when `type` is not a blueprint pointer.',
	'Blueprint parameter set\'s "range" parameter must be of type `Array` & have 2 elements of type `int`, or `float` if "type" parameter is "float".',
	'Blueprint parameter set\'s "step" parameter must be of type `int` or `float`.',
	'Blueprint parameter set\'s "enum" parameter must be of type `Array` & have elements of value type that matches `type` parameter.',
	'Blueprint parameter set\'s "prefix" parameter must be of type `String`.',
	'Blueprint parameter set\'s "suffix" parameter must be of type `String`.',
	'Blueprint parameter set\'s "regex" parameter must be of type `String`.',
	'Blueprint parameter set\'s "element_types" parameter must be of type `Array`.',
	'Blueprint parameter set\'s "prefix" parameter is only expected when the parameter set\'s "type" parameter is "string".',
	'Blueprint parameter set\'s "suffix" parameter is only expected when the parameter set\'s "type" parameter is "string".',
	'Blueprint parameter set\'s "regex" parameter is only expected when the parameter set\'s "type" parameter is "string".',
	'Blueprint parameter set\'s "element_types" parameter is only expected when the parameter set\'s "type" parameter is "array".',
	'Blueprint data should only be of type `Dictionary`.',
	'Matched with no errors.',
	'Match failed unexpectedly.',
	'Cannot match with an invalid Blueprint.',
	'Match failed "type": invalid value type.',
	'Mtach failed "enum": value is not equal to any of the allowed values.',
	'Match failed "range": value does not fall into the specified range.',
	'Match failed "step": value is not a multiple of the sepcified step.',
	'Match Failed "prefix": value does not have specified prefix.',
	'Match Failed "suffix": value does not have specified suffix.',
	'Match Failed "regex": value doesn\'t match to the specified RegEx pattern.',
	'Match Failed "format": value doesn\'t follow the specified format.',
]

## RegEx patterns available for all Blueprints. When adding to or modifiying this, make sure to update `regex_patterns_compiled` accordingly.
# Validated & tested with "regex101.com".
static var regex_patterns:Dictionary[String,String] = {
	'digits': r'[0-9]+',
	'integer': r'\-?[0-9]+',
	'float': r'\-?[0-9]+(\.[0-9]+)?',
	'letters': r'[[:alpha:]]+',
	'uppercase': r'[[:upper:]]+',
	'lowercase': r'[[:lower:]]+',
	'ascii': r'[[:ascii:]]+',
	'hexadecimal': r'[[:xdigit:]]+',
	'date_yyyy_mm_dd': r"(?(DEFINE)(?'sep'\/|\-| ))[0-9]{4}(?&sep)([1-9](?&sep)|10(?&sep)|11(?&sep)|12(?&sep))([0-9]$|[0-2][0-9]|3[0-1])",
	'date_mm_dd_yyyy': r"(?(DEFINE)(?'sep'\/|\-| ))([1-9](?&sep)|10(?&sep)|11(?&sep)|12(?&sep))([0-9]|[0-2][0-9]|3[0-1])(?&sep)[0-9]{4}",
	'time_12_hour': r'([1-9]|10|11|12):[0-5][0-9]',
	'time_12_hour_signed': r'([1-9]|10|11|12):[0-5][0-9] ?(A|P)M',
	'time_24_hour': r'([0-9]|1[0-9]|2[0-3]):[0-5][0-9]',
	'email': r'(([[:alnum:]_-])|((?<!\.|^)\.))+@(?1)+', # Not perfect: doesn't enforce top-level domain name, allows "." at the beginning of the domain name & at the end of username & top-level domain name.
	'url': r'/https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#()?&\/=]*)',
}
static var regex_patterns_compiled:Dictionary[String,RegEx] = {}

## Blueprint data. Should only be of type `Dictionary` or `Array`. If modified (which is not recommended), `_validate` needs to be called immediately after.
var data
## Whether or not this Blueprint is valid for use.
var valid:bool



## Initializes the `Blueprint` & registers in the `BlueprintManager`. "data" parameter should be a `Dictionary`.
func _init(name:String, data:Dictionary) -> void:
	# Compile RegEx patterns, if not already.
	if regex_patterns_compiled == {}:
		for key in regex_patterns:
			regex_patterns_compiled[key] = RegEx.new()
			var err = regex_patterns_compiled[key].compile(regex_patterns[key])
	# If invalid Blueprint, print error & return.
	var validation_error:error = _validate(data)
	if validation_error: 
		valid = false
		push_error(error_strings[validation_error])
		return
	# Otherwise, set up Blueprint.
	valid = true
	self.data = data
	BlueprintManager.add_blueprint(name, self)


## Checks if the data is a valid Blueprint.
## Returns Blueprint error code.
static func _validate(data:Dictionary) -> error:
	var typeof_data:Variant.Type = typeof(data)
	if typeof_data not in [TYPE_DICTIONARY]: return error.ERR_BP_DATA_INVALID_TYPE
	for key in data:
		var value
		if typeof_data == TYPE_DICTIONARY: value = data[key]
		else: value = key
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
				'bool': type_param_literal_type = TYPE_BOOL
				'int': type_param_literal_type = TYPE_INT
				'float': type_param_literal_type = TYPE_FLOAT
				'array': type_param_literal_type = TYPE_ARRAY
				'dict': type_param_literal_type = TYPE_DICTIONARY
				_:
					if not type_param.begins_with('>'): return error.ERR_BP_PARAMSET_INVALID_TYPE_PARAM
					type_param_literal_type = TYPE_BLUEPRINT_POINTER

		# Validate "optional" parameter.
		var optional_param = value.get('optional', false)
		if typeof(optional_param) != TYPE_BOOL: return error.ERR_BP_PARAMSET_INVALID_OPTIONAL_PARAM

		# Validate "default" parameter.
		var default_param = value.get('default')
		if default_param == null:
			if type_param_literal_type != TYPE_BLUEPRINT_POINTER: return error.ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM
		var typeof_default_param := typeof(default_param)
		# Set typeof_default_param to `int` if holds no floating value.
		if typeof_default_param == TYPE_FLOAT:
			if round(default_param) == default_param: typeof_default_param = TYPE_INT
		# Return error if "default" is of a different type than "type".
		if type_param_literal_type in [TYPE_BLUEPRINT_POINTER, TYPE_NIL]: pass
		elif typeof_default_param == TYPE_INT && type_param_literal_type == TYPE_FLOAT: pass
		elif typeof_default_param != type_param_literal_type: return error.ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM

		# Validate "range" parameter.
		var range_param = value.get('range')
		if range_param != null:
			if typeof(range_param) != TYPE_ARRAY: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM
			var count:int = 0
			for item in range_param:
				if typeof(item) not in [TYPE_INT, TYPE_FLOAT]: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM
				# Return error if using a `float` value when the "type" parameter is not also `float`.
				if type_param_literal_type != TYPE_FLOAT:
					if round(item) != item: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM
				count += 1
			if count != 2: return error.ERR_BP_PARAMSET_INVALID_RANGE_PARAM

		# Validate "step" parameter.
		var step_param = value.get('step')
		if step_param != null:
			if typeof(step_param) not in [TYPE_INT, TYPE_FLOAT]: return error.ERR_BP_PARAMSET_INVALID_STEP_PARAM
			if step_param == 0: return error.ERR_BP_PARAMSET_INVALID_STEP_PARAM

		# Validate "enum" parameter.
		var enum_param = value.get('enum')
		if enum_param != null:
			if typeof(enum_param) != TYPE_ARRAY: return error.ERR_BP_PARAMSET_INVALID_ENUM_PARAM
			for item in enum_param:
				if typeof(item) != type_param_literal_type: return error.ERR_BP_PARAMSET_INVALID_ENUM_PARAM

		# Validate "prefix" parameter.
		var prefix_param = value.get('prefix')
		if prefix_param != null:
			if type_param_literal_type != TYPE_STRING: return error.ERR_BP_PARAMSET_UNEXPECTED_PREFIX_PARAM
			if typeof(prefix_param) != TYPE_STRING: return error.ERR_BP_PARAMSET_INVALID_PREFIX_PARAM

		# Validate "suffix" parameter.
		var suffix_param = value.get('suffix')
		if suffix_param != null:
			if type_param_literal_type != TYPE_STRING: return error.ERR_BP_PARAMSET_UNEXPECTED_SUFFIX_PARAM
			if typeof(suffix_param) != TYPE_STRING: return error.ERR_BP_PARAMSET_INVALID_SUFFIX_PARAM

		# Validate "regex" parameter.
		var regex_param = value.get('regex')
		if regex_param != null:
			if type_param_literal_type != TYPE_STRING: return error.ERR_BP_PARAMSET_UNEXPECTED_REGEX_PARAM
			if typeof(regex_param) != TYPE_STRING: return error.ERR_BP_PARAMSET_INVALID_REGEX_PARAM

		# Validate "element_types" parameter.
		var element_types_param = value.get('element_types')
		if element_types_param != null:
			if type_param_literal_type != TYPE_ARRAY: return error.ERR_BP_PARAMSET_UNEXPECTED_ELEMENT_TYPES_PARAM
			if typeof(element_types_param) != TYPE_ARRAY: return error.ERR_BP_PARAMSET_INVALID_ELEMENT_TYPES_PARAM

	return error.BP_OK




## Matches the `object` to this Blueprint, mismatched values will be fixed.
## Returns a `BlueprintMatch` with the fixed "object" & an unordered list of matching errors.
func match(object:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new(object.duplicate(true), {})
	# Return if Blueprint is invalid.
	if not self.valid:
		result.errors['_pre_match-1'] = error.ERR_MATCH_INVALID
		return result

	# Iterate through every key in the Blueprint.
	for key in self.data:
		var blueprint_params
		var object_value
		blueprint_params = self.data[key]
		object_value = result.matched.get(key)
		# If value missing & is optional, skip.
		if not object_value && blueprint_params.get('optional') == true:
			continue
		# If value missing, use default.
		if not object_value:
			if blueprint_params.type:
				if blueprint_params.type.begins_with('>'):
					result.matched.set(key, _handle_blueprint_match({}, blueprint_params))
					continue
			result.matched.set(key, blueprint_params.default)
			continue
		# If value does not match enum (if defined), use default.
		if object_value not in blueprint_params.get('enum',[object_value]):
			result.matched.set(key, blueprint_params.default)
			continue

		# Match.
		var handled:bool = false
		for item:Array in [
			['string',_handle_string_match],
			['bool',_handle_bool_match],
			['int',_handle_int_match],
			['float',_handle_float_match],
			['array',_handle_array_match],
			['dict',_handle_dict_match],
		]:
			if item[0] == blueprint_params.type:
				var match_result = item[1].call(object_value, blueprint_params)
				result.errors[key] = match_result.errors['main']
				result.matched.set(key, match_result.matched)
			handled = true
		if not handled:
			if blueprint_params.type == null:
				result.matched.set(key, object_value)
			if blueprint_params.type.begins_with('>'):
				result.matched.set(key, _handle_blueprint_match(object_value, blueprint_params))
			else:
				assert(false, 'Invalid Blueprint parameters type "%s".' % blueprint_params.type)

	return result


## Adds the RegEx pattern to the list of available formats for all Blueprints.
static func add_format(name:String, regex_pattern:String) -> void:
	regex_patterns[name] = regex_pattern
	var new_regex := RegEx.new()
	new_regex.compile(regex_pattern)
	regex_patterns_compiled[name] = new_regex




static func _handle_string_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new(value, {'main':error.MATCH_OK})
	# Validate value type.
	if typeof(value) != TYPE_STRING:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	# Validate string length.
	var range = parameters.get('range')
	var value_length:int = value.length()
	if range:
		if value_length > range[1] || value_length < range[0]:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_RANGE
			return result
	# Validate stepped string length.
	var step = parameters.get('step')
	if step:
		if value_length%step != 0:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_STEP
			return result
	# Validate prefix.
	var prefix = parameters.get('prefix')
	if prefix:
		if not value.begins_with(prefix):
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_PREFIX
			return result
	# Validate suffix.
	var suffix = parameters.get('suffix')
	if suffix:
		if not value.ends_with(prefix):
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_SUFFIX
			return result
	# Validate regex match.
	var regex_pattern = parameters.get('regex')
	if regex_pattern:
		var regex := RegEx.new()
		regex.compile(regex_pattern, false)
		var regex_result = regex.search(value)
		if not regex_result:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_REGEX
			return result
		var matched:bool = false
		for string:String in regex_result.strings:
			if string == value: matched = true
		if not matched:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_REGEX
			return result
	# Validate format.
	var format = parameters.get('format')
	if format:
		var format_regex = regex_patterns_compiled.get(format)
		if not format_regex: assert(false, 'Cannot match non-existent format "%s".' % format)
		var regex_result = format_regex.search(value)
		if not regex_result:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_FORMAT
			return result
		var matched:bool = false
		for string:String in regex_result.strings:
			if string == value: matched = true
		if not matched:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_FORMAT
			return result
	
	return result


static func _handle_bool_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new(value, {'main':error.MATCH_OK})
	# Validate value type.
	if typeof(value) != TYPE_BOOL:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
	return result


static func _handle_int_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new(value, {'main':error.MATCH_OK})
	# Validate value type.
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	if round(value) != value:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	# Validate min/max value.
	var range = parameters.get('range')
	if range:
		if value > range[1] || value < range[0]:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_RANGE
	# Validate stepped value.
	var step = parameters.get('step')
	if step:
		if fmod(value,step) != 0:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_STEP
			return result

	return result


static func _handle_float_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new(value, {'main':error.MATCH_OK})
	# Validate value type.
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	var range = parameters.get('range')
	# Validate min/max value.
	if range:
		if value > range[1] || value < range[0]:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_RANGE
	# Validate stepped value.
	var step = parameters.get('step')
	if step:
		if fmod(value,step) != 0:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_STEP
			return result

	return result


static func _handle_array_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new([], {'main':error.MATCH_OK})
	# Validate value type.
	if typeof(value) != TYPE_ARRAY:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	# Validate array size.
	var range = parameters.get('range')
	var value_size:int = value.size()
	if range:
		if value_size > range[1] || value_size < range[0]:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_RANGE
			return result
	# Validate stepped array size.
	var step = parameters.get('step')
	if step:
		if fmod(value_size,step) != 0:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_STEP
			return result
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
							item = _handle_blueprint_match(item, {'type':expected_type, 'default':{}}).matched
					# If unexpected type, skip.
					else: create_element = false
			# Put item into new array, if valid.
			if create_element:
				result.matched.append(item)
			index += 1

	return result


static func _handle_dict_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new(value, {'main':error.MATCH_OK})
	# Validate value type.
	if typeof(value) != TYPE_DICTIONARY:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	# Validate dictionary size.
	var range = parameters.get('range')
	var value_size:int = value.size()
	if range:
		if value_size > range[1] || value_size < range[0]:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_RANGE
	# Validate stepped dictionary size.
	var step = parameters.get('step')
	if step:
		if fmod(value_size,step) != 0:
			result.matched = parameters.default
			result.errors['main'] = error.ERR_MATCH_FAILED_STEP
			return result

	return result


static func _handle_blueprint_match(value, parameters:Dictionary) -> BlueprintMatch:
	var result := BlueprintMatch.new({}, {'main':error.MATCH_OK})
	var blueprint_name:String = parameters.type.trim_prefix('>')
	var blueprint = BlueprintManager.get_blueprint(blueprint_name)
	# Validate the Blueprint before use.
	var assert_error:bool = false
	if not blueprint: assert_error = true
	if not blueprint.valid: assert_error = true
	if assert_error:
		assert(false, 'Cannot match against non-existent Blueprint "%s".' % blueprint_name)
	# Validate value type.
	if typeof(value) != TYPE_DICTIONARY:
		result.matched = parameters.default
		result.errors['main'] = error.ERR_MATCH_FAILED_TYPE
		return result
	# Match.
	result.matched = blueprint.match(value).matched

	return result
