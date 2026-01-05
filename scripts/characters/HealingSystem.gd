class_name HealingSystem
extends Node

signal healing_started(method: String)
signal healing_progress_updated(progress: float)
signal healing_completed(success: bool)
signal healing_interrupted

@export var healing_methods: Dictionary = {
	"talk": {"speed": 1.0, "description": "对话治愈"},
	"music": {"speed": 1.5, "description": "音乐疗愈"},
	"activity": {"speed": 2.0, "description": "活动引导"}
}

var healing_progress: float = 0.0
var is_healing: bool = false
var current_method: String = ""
var healing_timer: Timer
var npc_reference: Node2D = null
var player_reference: Node2D = null

func _ready():
	healing_timer = Timer.new()
	healing_timer.one_shot = false
	healing_timer.timeout.connect(_on_healing_tick)
	add_child(healing_timer)

func start_healing(method: String, npc: Node2D, player: Node2D):
	if not healing_methods.has(method) or is_healing:
		return false
	
	current_method = method
	npc_reference = npc
	player_reference = player
	healing_progress = 0.0
	is_healing = true
	
	var speed = healing_methods[method]["speed"]
	healing_timer.wait_time = 0.5 / speed  # Adjust tick rate based on method speed
	healing_timer.start()
	
	healing_started.emit(method)
	EventBus.emit_signal("healing_started", npc, method)
	
	return true

func stop_healing(interrupt: bool = false):
	if not is_healing:
		return
	
	is_healing = false
	healing_timer.stop()
	
	if interrupt:
		healing_interrupted.emit()
		EventBus.emit_signal("healing_interrupted", npc_reference)
	else:
		var success = healing_progress >= 1.0
		healing_completed.emit(success)
		if success:
			apply_healing_effects()
			EventBus.emit_signal("npc_healed", npc_reference, current_method)
	
	current_method = ""
	npc_reference = null
	player_reference = null

func _on_healing_tick():
	if not is_healing:
		return
	
	var efficiency = npc_reference.get_healing_efficiency() if npc_reference else 1.0
	healing_progress += 0.1 * efficiency
	
	healing_progress_updated.emit(healing_progress)
	
	if healing_progress >= 1.0:
		stop_healing(false)

func apply_healing_effects():
	if npc_reference and npc_reference.has_method("heal"):
		npc_reference.heal(current_method)

func get_healing_progress() -> float:
	return healing_progress

func is_currently_healing() -> bool:
	return is_healing

func get_available_methods() -> Array:
	return healing_methods.keys()

func get_method_description(method: String) -> String:
	return healing_methods.get(method, {}).get("description", "")
