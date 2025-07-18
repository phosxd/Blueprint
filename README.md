
A Godot-4.4 plugin that validates & corrects dictionary data.
It allows you to define expected data structures (Blueprints) & compare dictionaries against them.

**Version:** 2.0.0

------------

<details><summary><b>How to install</b></summary>

------------

If everything installed correctly, both the `Blueprint`, `BlueprintMatch`, & `BlueprintManager` classes should be globally available in your GDScripts.

### From Asset Library:
 1. In your Godot project, navigate to the "Asset Library" tab & search for ["Blueprint - Data Validation" or just "Blueprint"](https://godotengine.org/asset-library/asset/4098).
 2. Click "Download" & make sure only the `addons/Blueprint` folder is selected, you dont need any of the other files.
 3. Click "Install" to merge the selected files with your project.
 4. (Optional) Activate the plugin from `Project -> Project Setings -> Plugins`, then refresh the project.
### From Github:
 1. Navigate to the latest [Github](https://github.com/phosxd/Blueprint) release. Typically found on the right-hand side under "Releases".
 2. Download the ZIP file for the latest release.
 3. Unpack the ZIP file to a new folder & delete the ZIP file.
 4. Move the `addons/Blueprint` folder from your new folder to the "addons" folder in your Godot project.
 5. (Optional) Activate the plugin from `Project -> Project Setings -> Plugins`, then refresh the project.

Alternatively, you can download from the "main" branch which may include new features but can also contain unfinished code or unexpected issues. Bug reports for unreleased versions are not accepted.

</details>

------------

<details><summary><b>How to use</b></summary>

------------

# Making a `Blueprint`:
Generally you should make a blueprint by writing it in a `.json` file. The JSON file can be read & registered during run-time with the `add_blueprint_from_file` method from the `BlueprintManager` class.

A blueprint consists of key/value pairs where the value is a dictionary of parameters (aka "parameter set") that determine what is expected of the value being matched to it.

# Base parameters:
## `type`:
Required parameter.
Expressed as a string, determines the type of the value.
Parameters that are not applicable paired with the specified type are simply ignored.
Valid types:
- "string"
- "bool"
- "int"
- "float"
- "array"
- "dict"

Exceptions:
- If `null`, the value can be of any type.
- If begins with `>`, references a blueprint.
- If begins with `/`, references a base class.
This does NOT reference Variant Types (E.g. `Vector2`, `Color`, `Callable`, or anything else defined in `Variant.Type`).
This does NOT reference custom classes, only the base Godot classes in `ClassDB.get_class_list()`.
`default` or `enum` parameters paired with a type referencing a base class would need to be defined during run-time as you cannot construct class objects through JSON.
## `optional`:
Expressed as a boolean, determines whether or not this value is required to be included.
## `default`:
Required parameter except when `type` references a blueprint.
Determines what the value should default to if it is not already *properly* defined.
## `range`:
Expressed as an array of 2 integers, determines the minimum & maximum size/length of the value. If `null` then the value can have any size or length.
## `step`:
Expressed as an integer or float, determines the step size which value size/length should be a multiple of. Should never be `0`. If `null` then the value does not need to be a multiple of the step.
## `enum`:
Expressed as an array, determines the expected values.

# String parameters:
## `prefix`:
Expressed as a string, determines the prefix the value must have.
## `suffix`:
Expressed as a string, determines the suffix the value must have.
## `format`:
Expressed as a string, determines the format the value must follow. Custom formats can be added to Blueprints, see [add_format](#methods).
Valid formats:
- "digits"
- "integer"
- "float"
- "letters"
- "uppercase"
- "lowercase"
- "ascii"
- "hexadecimal"
- "date_yyyy_mm_dd"
- "date_mm_dd_yyyy"
- "time_12_hour"
- "time_12_hour_signed"
- "time_24_hour"
- "email"
- "url"
## `regex`:
Expressed as a string, determines the RegEx pattern the value must follow. (Advanced).
For information on what RegEx is & how it works, refer to the [Regular Expressions Wikipedia page](https://en.wikipedia.org/wiki/Regular_expression).

# Array parameters:
## `element_types`:
Expressed as an array of strings, determines the type of all elements in the array.

</details>

------------

<details><summary><b>JSON examples</b></summary>

------------

# Player:
```json
{
	"name": {
		"type": "string",
		"range": [4,20],
		"regex": "[[:alnum:]]+",
		"default": "placeholder",
	},
	"health": {
		"type": "int",
		"range": [0,100],
		"default": 100,
	},
	"inventory": {
		"type": "array",
		"range": null,
		"element_types": [">item"],
		"default": [],
	},
	"date_joined": {
		"type": "string",
		"format": "date_yyyy_mm_dd",
		"default": "none",
	},
}
```
In this example, the blueprint specifies:
- `name` should be a string with a length between 4 & 20 characters, only containing letters & digits (expressed through Regex).
- `health` should be an integer between 0 & 100.
- `inventory` should be an array with unlimited size, and that contains dictionaries matching the item blueprint.
- `date_joined` should be a string that follows the YYYY/MM/DD date format (E.g. "2008/12/5").

# Item:
```json
{
	"id": {
		"type": "string",
		"enum": ["helmet", "sword", "cookie", "placeholder"],
		"default": "placeholder",
	},
	"metadata": {
		"type": "dict",
		"default": {},
		"optional": true,
	},
}
```
In this example, the blueprint specifies:
- `id` should be a string that matches one of the values defined in the `enum` parameter.
- `metadata` should be a dictionary containing anything, OR should not exist at all.

</details>

------------

<details><summary><b>Code examples</b></summary>

------------

# Creating a `Blueprint`:
```gdscript
var example_blueprint := Blueprint.new('example', {
	'example': {
		'type': 'string',
		'default': 'some string',
	},
})
```
In this example, we create a new Blueprint with the name "example" and with an example blueprint dictionary.
This `Blueprint` is now accesible with `BlueprintManager.get_blueprint` if the reference to the variable is lost.

# Getting a `Blueprint`:
```gdscript
var example_blueprint = BlueprintManager.get_blueprint('example')
if example_blueprint == null: return
if example_blueprint.valid == false: return
```
In this example we retrieve an already created `Blueprint` with the name "example" from the `BlueprintManager`.
If no `Blueprint` by the name "example" is found then we do not use it.
If the `Blueprint` IS found but it is invalid, we should also not use it.

# Generating new dictionary from a `Blueprint`:
```gdscript
var match_result:BlueprintMatch = example_blueprint.match({})
var new_dictionary:Dictionary = match_result.matched
```
In this example we match an empty dictionary against the example `Blueprint` which fills it with the `Blueprint`s default values.
We then access the fixed dictionary from the `BlueprintMatch` returned from the match.

</details>

------------

<details><summary><b>Interfaces</b></summary>

------------

# `Blueprint`:
## Properties:
- `data:Dictionary`: Blueprint data. If modified (which is not recommended), `_validate` needs to be called immediately after.
## Methods:
- `_init(name:String, data:Dictionary) -> void`: Initializes, then registers in the `BlueprintManager`.
- `match(data:Dictionary) -> BlueprintMatch`: Matches the `object` to this Blueprint, mismatched values will be fixed. Returns a `BlueprintMatch` with the fixed "object" & an unordered list of matching errors.
- `add_format(name:String, regex_pattern:String) -> void`: Adds the RegEx pattern to the list of available formats for all Blueprints.

# `BlueprintMatch`:
## Properties:
- `matched:Variant`: The variable after matching.
- `errors:Dictionary[String, Blueprint.error]`: All matching errors, as Blueprint error codes.

# `BlueprintManager`:
## Properties:
- `registered_blueprints:Dictionary[String,Blueprint]`: All currently registered `Blueprint`s.
## Methods:
- `add_blueprint(name:String, blueprint:Blueprint) -> bool`: Registers the `Blueprint`. Returns true if successfully added the `Blueprint`. Automatically called when a `Blueprint` is created.
- `remove_blueprint(name:String) -> void`: Removes the `Blueprint` by it's registered name. Does nothing if it doesn't exist.
- `get_blueprint(name:String) -> Blueprint`: Returns the `Blueprint` by it's registered name. Returns `null` if it doesn't exist.
- `add_blueprint_from_file(name:String, filepath:String) -> bool`: Registers a `Blueprint` from a JSON file. Returns whether or not the `Blueprint` is valid.

</details>

------------
