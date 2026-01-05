class_name BehaviorTreeRoot
extends "res://scripts/characters/BTNode.gd"

@export var tick_rate: float = 0.5  # How often to tick the tree
@export var enable_debug: bool = false

var last_tick_time: float = 0.0
var npc_reference: Node2D = null

func _ready():
	set_process(true)

func _process(delta: float):
	last_tick_time += delta
	if last_tick_time >= tick_rate:
		tick_tree(delta)
		last_tick_time = 0.0

func tick_tree(delta: float):
	if get_child_count() > 0:
		var root_child = get_child(0)
		if root_child is BTNode:
			var status = root_child.tick(delta)
			if enable_debug:
				print("BT Tree Status: ", status)

func set_npc_reference(npc: Node2D):
	npc_reference = npc

func load_subtree(subtree_path: String):
	# Load and attach a subtree
	var subtree = load(subtree_path)
	if subtree:
		var subtree_instance = subtree.instantiate()
		add_child(subtree_instance)
		return subtree_instance
	return null
