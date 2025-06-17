

A Godot-4.4 plugin that validates & corrects dictionary data.
It allows you to define expected data structures (Blueprints) & compare dictionaries against them.

# Table of Contents:
- [Installation](#how-to-install)
- [Usage](#how-to-use)
- [Examples](#blueprint-examples)
- [Interfaces](#interfaces)
- [To-do](#to-do)

# How to install:
If everything installed correctly, both the `Blueprint` & `BlueprintManager` classes should be globally available in your GDScripts.

### From Asset Library:
Blueprint currently is not available on the Godot Asset Library. I might submit it when I feel it is ready for serious use.

### From Github:
 1. Navigate to the latest [Github](https://github.com/phosxd/Blueprint) release. Typically found on the right-hand side under "Releases".
 2. Download the ZIP file for the latest release.
 3. Unpack the ZIP file to a new folder & delete the ZIP file.
 4. Move the `addons/Blueprint` folder from your new folder to the "addons" folder in your Godot project.
 5. Activate the plugin from `Project -> Project Setings -> Plugins`, then refresh the project.

Alternatively, you can download from the "main" branch which may include new features but can also contain unfinished code or unexpected issues. Bug reports for unreleased versions are not accepted.

# How to use:
## Making a `Blueprint`:
Generally you should make a blueprint by writing it in a `.json` file. The JSON file can be read & registered during run-time by using the `add_blueprint_from_file` method in the `BlueprintManager` class.

A blueprint consists of key/value pairs where the value is a dictionary of parameters (aka "parameter set") that determine what is expected of the value being matched to it.

## Base parameters:
### `type`:
Required parameter.
Expressed as a string, determines the type of the value. Can also be an array of strings, allowing multiple types.
Valid types:
- "string"
- "int"
- "float"
- "array"
- "dict"

Exceptions:
- If `null`, the value can be of any type.
- If begins with `>`, represents a blueprint.
### `optional`:
Expressed as a boolean, determines whether or not this value is required to be included.
### `default`:
Required parameter if `optional` is false or undefined, or if `type` is not a blueprint.
Determines what the value should default to if it is not already properly defined.
### `range`:
Expressed as an array of 2 integers, determines the minimum & maximum size or length of the value. If `null`, then the value can have any size or length.
### `enum`:
Expressed as an array, determines the expected values.

## String parameters:
### `prefix`:
Expressed as a string, determines the prefix the value must have.
### `suffix`:
Expressed as a string, determines the suffix the value must have.
### `regex`:
Expressed as a string, determines the Regex pattern the value must follow. (Advanced).

## Array parameters:
### `element_types`:
Expressed as an array of strings, determines the type of all elements in the array.

# `Blueprint` examples:
## Player:
```json
{
	"name": {"type":"string", "range":[4,20], "regex":"[A-Z,a-z,0-9]+", "default":"Placeholder"},
	"health": {"type":"int", "range":[0,100], "default":100},
	"inventory": {"type":"array", "range":null, "element_types":[">item"], "default":[]},
}
```
In this example, the blueprint specifies:
- `name` should be a string with a length between 4 & 20 characters, only containing letters & digits (expressed through Regex).
- `health` should be an integer between 0 & 100.
- `inventory` should be an array with unlimited size, and that contains dictionaries matching the item blueprint.

## Item:
```json
{
	"id": {"type":"string", "default":"Placeholder"},
	"metadata": {"type":"dict", "optional":true},
}
```
In this example, the blueprint specifies:
- `id` should be a string.
- `metadata` should be a dictionary containing anything, OR should not exist at all.

# Interfaces:
## `Blueprint`:
### Properties:
- `data:Dictionary`: The raw Blueprint data.
### Methods:
- `_init(name:String, data:Dictionary) -> void`: Initializes, then registers in the `BlueprintManager`.
- `match(data:Dictionary) -> Dictionary[String,Variant]`: Matches the `object` to this Blueprint, mismatched values will be fixed. Returns fixed `object`.

## `BlueprintManager`:
### Properties:
- `registered_blueprints:Dictionary[String,Blueprint]`: All currently registered Blueprints.
### Methods:
- `add_blueprint(name:String, blueprint:Blueprint) -> void`: Registers the Blueprint with the given name. Automatically called in `Blueprint._init`.
- `remove_blueprint(name:String) -> void`: Removes the Blueprint by it's registered name. Does nothing if it doesn't exist.
- `get_blueprint(name:String) -> Blueprint`: Returns the Blueprint by it's registered name. Returns `null` if it doesn't exist.
- `add_blueprint_from_file(name:String, filepath:String) -> void`: Registers a Blueprint from a JSON file. Does nothing if error occurs.



# TO-DO:
## Blueprint validation:
Ensure that the Blueprint follows all the rules & only contains valid parameter sets. Currently, an error will likely occur if the Blueprint is not valid, I want to make sure the Blueprint is not put in use if it's not valid.

## Match errors:
For `Blueprint.match`, add an option to print the reason the match failed & defaulted to the parameter set default.

## Regex alternatives for common uses:
An option in Blueprint parameters to specify a `format` like a time, date, email, url, and other common formats. This would be much better than having to use ambiguous Regex patterns.

Custom formats will also be available for the user to employ.

## Pre-compiled Regex patterns:
Instead of compiling Regex patterns when matching, compile & store all Regex patterns when first initializing the Blueprint.
