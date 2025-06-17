extends Node2D

const blueprints_path:String = 'res://addons/Blueprint/Example/Blueprints'


func _ready() -> void:
	for filename:String in DirAccess.get_files_at(blueprints_path):
		if not filename.ends_with('.json'): continue
		BlueprintManager.add_blueprint_from_file(filename.trim_suffix('.json'), blueprints_path+'/'+filename)
	
	var player_blueprint:Blueprint = BlueprintManager.get_blueprint('player')
	if not player_blueprint: return
	if not player_blueprint.valid: return
	var matched = player_blueprint.match({
		"health": 50,
		"inventory": [{'id':'cookie'}, {'id':'helmet'}]
	})
	print(matched)
