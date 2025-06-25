extends Node2D

const blueprints_path:String = 'res://addons/Blueprint/Example/Blueprints'


func _ready() -> void:
	# Register all blueprints from a directory with JSON files.
	for filename:String in DirAccess.get_files_at(blueprints_path):
		if not filename.ends_with('.json'): continue
		BlueprintManager.add_blueprint_from_file(filename.trim_suffix('.json'), blueprints_path+'/'+filename)
	
	# Get the blueprint.
	var player_blueprint:Blueprint = BlueprintManager.get_blueprint('player')
	# If the blueprint doesn't exist, return.
	if not player_blueprint: return
	# If the blueprint is not valid, return.
	if not player_blueprint.valid: return
	# Match a dictionary against the blueprint.
	var match_result = player_blueprint.match({
		"health": 50,
		"inventory": [{'id':'cookie'}, {'id':'helmet'}],
	})
	# Print the matched dictionary.
	print(match_result.matched)

	# Print all matching errors.
	for key in match_result.errors:
		var err_code = match_result.errors[key]
		print(key+' -- '+Blueprint.error_strings[err_code])
