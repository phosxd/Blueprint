class_name Blueprint
## Class for holding a dictionary blueprint.

const TYPE_BLUEPRINT_POINTER:int = TYPE_MAX+1

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
	ERR_BP_PARAMSET_INVALID_ENUM_PARAM,
	ERR_BP_PARAMSET_INVALID_PREFIX_PARAM,
	ERR_BP_PARAMSET_INVALID_SUFFIX_PARAM,
	ERR_BP_PARAMSET_INVALID_REGEX_PARAM,
	ERR_BP_PARAMSET_INVALID_ELEMENT_TYPES_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_PREFIX_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_SUFFIX_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_REGEX_PARAM,
	ERR_BP_PARAMSET_UNEXPECTED_ELEMENT_TYPES_PARAM,
}

## Blueprint errors as explanatory strings.
const error_strings:Array[String] = [
	'OK.',
	'Unexpected failure.',
	'Blueprint parameter set must be of type `Dictionary`.',
	'Blueprint parameter set must contain a "type" parameter.',
	'Blueprint parameter set\'s "type" parameter must be of type `String` & match one of the following values: "string", "int", "float", "array", "dict", ">{blueprint_name}".',
	'Blueprint parameter set\'s "optional" parameter must be of type `bool`.',
	'Blueprint parameter set\'s "default" parameter value type must match the `type` parameter & is always required except when `type` is not a blueprint pointer.',
	'Blueprint parameter set\'s "range" parameter must be of type `Array` & have 2 elements of type `int`.',
	'Blueprint parameter set\'s "enum" parameter must be of type `Array` & have elements of value type that matches `type` parameter.',
	'Blueprint parameter set\'s "prefix" parameter must be of type `String`.',
	'Blueprint parameter set\'s "suffix" parameter must be of type `String`.',
	'Blueprint parameter set\'s "regex" parameter must be of type `String`.',
	'Blueprint parameter set\'s "element_types" parameter must be of type `Array`.',
	'Blueprint parameter set\'s "prefix" parameter is only expected when the parameter set\'s "type" parameter is "string".',
	'Blueprint parameter set\'s "suffix" parameter is only expected when the parameter set\'s "type" parameter is "string".',
	'Blueprint parameter set\'s "regex" parameter is only expected when the parameter set\'s "type" parameter is "string".',
	'Blueprint parameter set\'s "element_types" parameter is only expected when the parameter set\'s "type" parameter is "array".',
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

## Blueprint data. If modified, `_validate` needs to be called immediately after.
var data:Dictionary
## Whether or not this Blueprint is valid for use.
var valid:bool


## Initializes the Blueprint.
func _init(name:String, data:Dictionary) -> void:
	# Compile RegEx patterns, if not already.
	if regex_patterns_compiled == {}:
		for key in regex_patterns:
			regex_patterns_compiled[key] = RegEx.new()
			var err = regex_patterns_compiled[key].compile(regex_patterns[key])
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
		if type_param_literal_type in [TYPE_BLUEPRINT_POINTER, TYPE_NIL]: pass
		elif typeof_default_param != type_param_literal_type: return error.ERR_BP_PARAMSET_INVALID_DEFAULT_PARAM

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

	return error.OK




## Matches the `object` to this Blueprint, mismatched values will be fixed. Returns fixed `object`. Returns `null` if Blueprint is invalid.
func match(object:Dictionary):
	if not self.valid: return # Return if Blueprint is invalid.
	for key in self.data:
		var blueprint_params = self.data[key]
		var object_value = object.get(key)
		# If value missing, use default.
		if not object_value && not blueprint_params.get('optional'):
			if blueprint_params.type:
				if blueprint_params.type.begins_with('>'):
					object.set(key, _handle_blueprint_match({}, blueprint_params))
					continue
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
			null: object.set(key, object_value)
			_:
				if blueprint_params.type.begins_with('>'):
					object.set(key, _handle_blueprint_match(object_value, blueprint_params))
				else:
					assert(false, 'Invalid Blueprint parameters type "%s".' % blueprint_params.type)

	return object




## Adds the RegEx pattern to the list of available formats for all Blueprints.
static func add_format(name:String, regex_pattern:String) -> void:
	regex_patterns[name] = regex_pattern
	var new_regex := RegEx.new()
	new_regex.compile(regex_pattern)
	regex_patterns_compiled[name] = new_regex




static func _handle_string_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_STRING: return parameters.default # Validate value type.
	# Validate with string length.
	var range = parameters.get('range')
	var value_length:int = value.length()
	if range:
		if value_length > range[1] || value_length < range[0]: return parameters.default
	# Validate with prefix.
	var prefix = parameters.get('prefix')
	if prefix:
		if not value.begins_with(prefix): return parameters.default
	# Validate with suffix.
	var suffix = parameters.get('suffix')
	if prefix:
		if not value.ends_with(prefix): return parameters.default
	# Validate with regex match.
	var regex_pattern = parameters.get('regex')
	if regex_pattern:
		var regex := RegEx.new()
		regex.compile(regex_pattern, false)
		var result = regex.search(value)
		if not result: return parameters.default
		var matched:bool = false
		for string:String in result.strings:
			if string == value: matched = true
		if not matched: return parameters.default
	# Validate with format.
	var format = parameters.get('format')
	if format:
		var format_regex = regex_patterns_compiled.get(format)
		if not format_regex: assert(false, 'Cannot match non-existent format "%s".' % format)
		var result = format_regex.search(value)
		if not result: return parameters.default
		var matched:bool = false
		for string:String in result.strings:
			if string == value: matched = true
		if not matched: return parameters.default
	
	return value


static func _handle_int_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_INT: return parameters.default # Validate value type.
	var range = parameters.get('range')
	# Validate with min/max.
	if range:
		if value > range[1] || value < range[0]: return parameters.default
	return value


static func _handle_float_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_FLOAT: return parameters.default # Validate value type.
	var range = parameters.get('range')
	# Validate with min/max.
	if range:
		if value > range[1] || value < range[0]: return parameters.default
	return value


static func _handle_array_match(value, parameters:Dictionary):
	if typeof(value) != TYPE_ARRAY: return parameters.default # Validate value type.
	var new_value:Array = []
	var range = parameters.get('range')
	var value_size:int = value.size()
	# Validate with array size.
	if range:
		if value_size > range[1] || value_size < range[0]: return parameters.default
	# Validate with type of each element in array.
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
	# Validate with dictionary size.
	if range:
		if value_size > range[1] || value_size < range[0]: return parameters.default
	return value


static func _handle_blueprint_match(value, parameters:Dictionary):
	var blueprint_name:String = parameters.type.trim_prefix('>')
	var blueprint = BlueprintManager.get_blueprint(blueprint_name)
	if not blueprint: assert(false, 'Cannot match against non-existent Blueprint "%s".' % blueprint_name)
	var empty_matched:Dictionary = blueprint.match({})
	if typeof(value) != TYPE_DICTIONARY: return empty_matched # Validate value type.
	var matched:Dictionary = blueprint.match(value)
	return matched
