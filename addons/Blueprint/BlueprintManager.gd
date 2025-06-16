class_name BlueprintManager

static var registered_blueprints:Dictionary[String,Blueprint] = {}


## Registers the Blueprint. Does nothing if the given name is already in use.
##
## This function is automatically called when a new Blueprint is created.
static func add_blueprint(name:String, blueprint:Blueprint) -> void:
	if registered_blueprints.get(name): return
	registered_blueprints[name] = blueprint


## Removes the Blueprint by it's registered name. Does nothing if it doesn't exist.
static func remove_blueprint(name:String) -> void:
	registered_blueprints.erase(name)


## Returns the Blueprint by it's registered name. Returns `null` if it doesn't exist.
static func get_blueprint(name:String):
	return registered_blueprints.get(name, null)


## Registers a Blueprint from a JSON file. Does nothing if error occurs.
static func add_blueprint_from_file(name:String, filepath:String) -> void:
	var file := FileAccess.open(filepath, FileAccess.READ)
	var file_text:String = file.get_as_text()
	var json_data = JSON.parse_string(file_text)
	if not json_data: return # Return if failed to parse file text as JSON.
	Blueprint.new(name, json_data)
