class_name Accessory
extends Node2D

enum AccessoryType { VISUAL, MODIFIER }

@export var accessory_type: AccessoryType = AccessoryType.MODIFIER
@export var name: String = "Accessory"
@export var description: String = ""
@export var modifiers: Dictionary = {}  # key: modifier_name, value: modifier_value

func _ready():
	if accessory_type == AccessoryType.VISUAL:
		setup_visual()
	else:
		setup_modifier()

func setup_visual():
	# Add visual effects like particles, sprites
	pass

func setup_modifier():
	# Apply stat modifiers
	pass

func get_modifier(modifier_name: String) -> float:
	return modifiers.get(modifier_name, 0.0)

func apply_to_character(character_data: CharacterData):
	if accessory_type == AccessoryType.MODIFIER:
		# Apply modifiers to character data
		pass

func remove_from_character(character_data: CharacterData):
	if accessory_type == AccessoryType.MODIFIER:
		# Remove modifiers from character data
		pass
