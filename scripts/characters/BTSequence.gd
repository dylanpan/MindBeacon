class_name BTSequence
extends "res://scripts/characters/BTNode.gd"

func tick(delta: float) -> BTStatus:
	for child in get_children():
		if child is BTNode:
			var child_status = child.tick(delta)
			if child_status == BTStatus.RUNNING:
				return BTStatus.RUNNING
			elif child_status == BTStatus.FAILED:
				return BTStatus.FAILED
	return BTStatus.SUCCESS
