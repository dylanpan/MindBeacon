class_name BTAction
extends "res://scripts/characters/BTNode.gd"

func tick(delta: float) -> BTStatus:
	return execute_action(delta)

func execute_action(delta: float) -> BTStatus:
	# Override in subclasses
	return BTStatus.SUCCESS
