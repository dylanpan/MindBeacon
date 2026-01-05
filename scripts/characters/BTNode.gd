class_name BTNode
extends Node

enum BTStatus { RUNNING, SUCCESS, FAILED }

var status: BTStatus = BTStatus.RUNNING

func _ready():
	pass

func tick(delta: float) -> BTStatus:
	return BTStatus.SUCCESS

func reset():
	status = BTStatus.RUNNING
