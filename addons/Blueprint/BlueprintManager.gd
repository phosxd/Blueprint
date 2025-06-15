class_name BlueprintManager

static var registered_blueprints:Dictionary[String,Blueprint] = {}


## Registers the JSONBlueprint. Does nothing if the given name is already in use.
##
## This function is automatically called when a new `JSONBlueprint` is created.
static func add_blueprint(name:String, blueprint:Blueprint) -> void:
	if registered_blueprints.get(name): return
	registered_blueprints[name] = blueprint


static func remove_blueprint(name:String) -> void: ## Removes the JSONBlueprint by it's registered name. Does nothing if it doesn't exist.
	registered_blueprints.erase(name)


static func get_blueprint(name:String): ## Returns the JSONBlueprint by it's registered name. Returns `null` if it doesn't exist.
	return registered_blueprints.get(name, null)


static func add_blueprint_from_file(name:String, filepath:String): ## Registers a JSONBlueprint from a JSON file. Does nothing if error occurs.
	var file := FileAccess.open(filepath, FileAccess.READ)
	var file_text:String = file.get_as_text()
	var json_data = JSON.parse_string(file_text)
	if not json_data: return # Return if failed to parse file text as JSON.
	Blueprint.new(name, json_data)
