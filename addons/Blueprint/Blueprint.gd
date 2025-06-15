class_name Blueprint
## Class for interacting with data templates.

## All blueprint value operators & their callables.
static var _operators:Dictionary[String,Callable] = {
	'~>': _operator_match_blueprint, ## Determines the JSONBlueprint to match the value with.
	'~[': _operator_match_array ## Used only in the first element of an array. Determines array size. "-1" means unlimited.
}

var data:Dictionary


func _init(name:String, data:Dictionary) -> void: ## Initializes the JSONBlueprint.
	self.data = data
	BlueprintManager.add_blueprint(name, self)


func match(object:Dictionary) -> Dictionary[String,Variant]: ## Tests if the object matches this JSONBlueprint. Any mismatched values of the object will be set to the JSONBlueprint's default.
	var different:bool = false

	for key in self.data:
		var blueprint_value = self.data[key]
		var object_value = object.get(key)
		# If missing a value, replicate from the blueprint.
		if not object_value:
			different = true
			object.set(key, blueprint_value)
		
		match typeof(blueprint_value):
			# If is a string, execute operators (if possible).
			TYPE_STRING:
				for operator in _operators:
					if not blueprint_value.begins_with(operator): continue # Skip if doesn't match operator.
					object.set(key, _operators[operator].call(
						blueprint_value.trim_prefix(operator),
						blueprint_value,
						object_value
					)) # Assign new value to key.
			# If other type, match type.
			_:
				_operator_match_type(blueprint_value, object_value)

	return {
		'different': different,
		'object': object,
	}


static func _operator_match_type(blueprint_value, object_value): ## Returns `object_value` if the type matches `blueprint_value`, otherwise returns `blueprint_value`. If `blueprint_value` is null, returns `object_value`.
	if typeof(blueprint_value) == typeof(object_value) || typeof(blueprint_value) == TYPE_NIL: return object_value
	else: return blueprint_value


static func _operator_match_blueprint(blueprint_value_no_op:String, blueprint_value:String, object_value): ## Matches `object_value` to the JSONBlueprint provided in `blueprint_value_no_op`. Returns matched value.
	var object_to_match:Dictionary = {}
	if typeof(object_value) == TYPE_DICTIONARY: object_to_match = object_value
	var blueprint = BlueprintManager.get_blueprint(blueprint_value_no_op) # Get the blueprint.
	assert(blueprint != null, 'JSONBlueprint "%s" is not registered, cannot match value.' % blueprint_value_no_op) # Throw error if blueprint doesn't exist.
	var matched = blueprint.match(object_to_match) # Match dictionary using blueprint.
	return matched.object


static func _operator_match_array(blueprint_value:String, object_value):
	pass
