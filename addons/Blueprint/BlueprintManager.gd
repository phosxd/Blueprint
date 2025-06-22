class_name BlueprintManager
## Stores all active `Blueprint`s.

## All currently registered `Blueprint`s.
static var registered_blueprints:Dictionary[String,Blueprint] = {}


static func add_blueprint(name:String, blueprint:Blueprint) -> bool: ## Registers the `Blueprint`. Returns true if successfully added the `Blueprint`. Automatically called when a `Blueprint` is created.
	if registered_blueprints.get(name): return false
	registered_blueprints[name] = blueprint
	return true


static func remove_blueprint(name:String) -> void: ## Removes the `Blueprint` by it's registered name. Does nothing if it doesn't exist.
	registered_blueprints.erase(name)


static func get_blueprint(name:String): ## Returns the `Blueprint` by it's registered name. Returns `null` if it doesn't exist.
	return registered_blueprints.get(name, null)


static func add_blueprint_from_file(name:String, filepath:String) -> bool: ## Registers a `Blueprint` from a JSON file. Returns whether or not the `Blueprint` is valid.
	var file := FileAccess.open(filepath, FileAccess.READ)
	if not file: return false # Return if failed to open file.
	var file_text:String = file.get_as_text()
	var json_data = JSON.parse_string(file_text)
	if not json_data: return false # Return if failed to parse file text as JSON.
	var new_blueprint := Blueprint.new(name, json_data)
	return new_blueprint.valid
	
