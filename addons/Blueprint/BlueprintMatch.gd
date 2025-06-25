class_name BlueprintMatch
## Represents a result from `Blueprint.match`.

## The variable after matching.
var matched:Variant
## All matching errors, as Blueprint error codes.
var errors:Dictionary[String, Blueprint.error]


func _init(matched:Variant, errors:Dictionary[String, Blueprint.error]):
	self.matched = matched
	self.errors = errors
