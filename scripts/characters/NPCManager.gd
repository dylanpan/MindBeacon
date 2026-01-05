extends Node

class_name NPCManager

var npc_pool: Dictionary = {}  # region_id -> Array[NPC]
var npc_scenes: Dictionary = {}  # npc_type -> PackedScene
var max_npcs_per_region: int = 10
var total_max_npcs: int = 50

@onready var game_manager = get_node("/root/GameManager")

func _ready():
	load_npc_scenes()

func load_npc_scenes():
	# Preload NPC scene templates
	npc_scenes["positive"] = load("res://scenes/characters/NPCPositive.tscn")
	npc_scenes["negative"] = load("res://scenes/characters/NPCNegative.tscn")

func spawn_npc(region_id: String, position: Vector2, npc_type: String = "") -> Node2D:
	if get_total_npcs() >= total_max_npcs:
		return null
	
	if not npc_pool.has(region_id):
		npc_pool[region_id] = []
	
	if npc_pool[region_id].size() >= max_npcs_per_region:
		return null
	
	# Determine NPC type based on region mood if not specified
	if npc_type == "":
		var mood_index = game_manager.get_region_mood(region_id)
		npc_type = "positive" if mood_index > 0.5 else "negative"
	
	if not npc_scenes.has(npc_type):
		return null
	
	var npc_scene = npc_scenes[npc_type].instantiate()
	npc_scene.position = position
	npc_scene.region_id = region_id
	
	# Initialize with personality
	var personality = game_manager.psychology_model.generate_personality()
	npc_scene.set_personality(personality)
	
	npc_pool[region_id].append(npc_scene)
	add_child(npc_scene)
	
	EventBus.emit_signal("npc_spawned", npc_scene)
	
	return npc_scene

func remove_npc(npc: Node2D, region_id: String):
	if npc_pool.has(region_id):
		npc_pool[region_id].erase(npc)
	npc.queue_free()
	EventBus.emit_signal("npc_removed", npc)

func get_npcs_in_region(region_id: String) -> Array:
	return npc_pool.get(region_id, [])

func get_total_npcs() -> int:
	var count = 0
	for region_npcs in npc_pool.values():
		count += region_npcs.size()
	return count

func clear_region(region_id: String):
	if npc_pool.has(region_id):
		for npc in npc_pool[region_id]:
			npc.queue_free()
		npc_pool[region_id].clear()

func update_region_mood(region_id: String, mood_change: float):
	# Update NPCs in region based on mood change
	for npc in get_npcs_in_region(region_id):
		npc.adjust_mood(mood_change)
