extends Node2D

const blueprints_path:String = 'res://addons/json-blueprint/Example/Blueprints'


func _ready() -> void:
	for filename:String in DirAccess.get_files_at(blueprints_path):
		if not filename.ends_with('.json'): continue
		BlueprintManager.add_blueprint_from_file(filename.trim_suffix('.json'), blueprints_path+'/'+filename)
	
	var main_blueprint:Blueprint = BlueprintManager.get_blueprint('main')
	var matched := main_blueprint.match({
		'hello': 1,
	})
	print(matched.object)
