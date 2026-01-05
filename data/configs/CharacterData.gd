class_name CharacterData
extends Resource

@export var name: String = "NPC"
@export var level: int = 1
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var personality: Resource  # Personality resource
@export var accessories: Array[Resource] = []  # Array of Accessory resources

func _init():
	pass

func get_total_healing_efficiency() -> float:
	var base_efficiency = 1.0
	for accessory in accessories:
		if accessory and accessory.has_method("get_modifier"):
			base_efficiency += accessory.get_modifier("healing_efficiency")
	return base_efficiency

func level_up():
	level += 1
	max_health += 10.0
	health = max_health
	# Unlock new accessories based on level
