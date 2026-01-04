extends Node

class_name StateMachine

var current_state: State
var states: Dictionary = {}

func _ready():
    # 初始化所有子状态
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.state_machine = self
            child.connect("finished", Callable(self, "_change_state"))

func _process(delta):
    if current_state:
        current_state.update(delta)

func _physics_process(delta):
    if current_state:
        current_state.physics_update(delta)

func _change_state(state_name: String):
    if current_state:
        current_state.exit()

    current_state = states.get(state_name)
    if current_state:
        current_state.enter()

func change_state(state_name: String):
    _change_state(state_name)

func get_current_state_name() -> String:
    return current_state.name if current_state else ""

# 状态基类
class State extends Node:
    signal finished(next_state_name)

    var state_machine: StateMachine

    func enter():
        pass

    func update(delta: float):
        pass

    func physics_update(delta: float):
        pass

    func exit():
        pass
