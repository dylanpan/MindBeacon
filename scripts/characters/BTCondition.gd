class_name BTCondition
extends "res://scripts/characters/BTNode.gd"

func tick(delta: float) -> BTStatus:
	if check_condition():
		return BTStatus.SUCCESS
	return BTStatus.FAILED

func check_condition() -> bool:
	# Override in subclasses
	return false
