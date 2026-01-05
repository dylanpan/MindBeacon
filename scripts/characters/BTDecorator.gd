class_name BTDecorator
extends "res://scripts/characters/BTNode.gd"

@export var invert: bool = false

func tick(delta: float) -> BTStatus:
	if get_child_count() == 0:
		return BTStatus.FAILED
	
	var child = get_child(0)
	if child is BTNode:
		var child_status = child.tick(delta)
		if invert:
			if child_status == BTStatus.SUCCESS:
				return BTStatus.FAILED
			elif child_status == BTStatus.FAILED:
				return BTStatus.SUCCESS
		return child_status
	
	return BTStatus.FAILED
