extends Node

signal game_state_changed(new_state)
enum GameState {MENU, PLAYING, PAUSED}

var current_state = GameState.MENU

func _ready():
    pass

func change_state(new_state: GameState):
    current_state = new_state
    emit_signal("game_state_changed", new_state)
