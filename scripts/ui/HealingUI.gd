extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var method_container: VBoxContainer = $MethodContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var particles: GPUParticles2D = $Particles

var healing_system: HealingSystem = null
var npc_reference: Node2D = null

func _ready():
	hide()
	setup_buttons()
	connect_signals()

func setup_buttons():
	for method in ["talk", "music", "activity"]:
		var button = Button.new()
		button.text = method.capitalize()
		button.connect("pressed", Callable(self, "_on_method_selected").bind(method))
		method_container.add_child(button)

func connect_signals():
	# Connect to healing system signals if available
	pass

func show_healing_ui(npc: Node2D, system: HealingSystem):
	npc_reference = npc
	healing_system = system
	show()
	animation_player.play("fade_in")
	
	# Position UI above NPC
	if npc:
		var screen_pos = npc.get_global_transform_with_canvas().origin
		position = screen_pos - size / 2
		position.y -= 50  # Offset above NPC

func hide_healing_ui():
	animation_player.play("fade_out")
	await animation_player.animation_finished
	hide()

func _on_method_selected(method: String):
	if healing_system and npc_reference:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			healing_system.start_healing(method, npc_reference, player)
			hide_healing_ui()

func update_progress(progress: float):
	if progress_bar:
		progress_bar.value = progress * 100
	
	if progress >= 1.0:
		play_success_effect()

func play_success_effect():
	if particles:
		particles.emitting = true
		await get_tree().create_timer(2.0).timeout
		particles.emitting = false
