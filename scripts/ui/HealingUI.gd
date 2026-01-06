class_name HealingUI
extends BaseUI

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var method_container: VBoxContainer = $MethodContainer
@onready var particles: GPUParticles2D = $Particles

var healing_system: HealingSystem = null
var npc_reference: Node2D = null

func _initialize():
    """初始化方法"""
    setup_buttons()
    connect_signals()

func setup_buttons():
    """设置治疗方法按钮"""
    for method in ["talk", "music", "activity"]:
        var button = Button.new()
        button.text = method.capitalize()
        button.connect("pressed", Callable(self, "_on_method_selected").bind(method))
        method_container.add_child(button)

func connect_signals():
    """连接信号"""
    # 连接治疗系统信号（如果可用）
    if healing_system:
        healing_system.connect("healing_progress_updated", _on_healing_progress_updated)
        healing_system.connect("healing_completed", _on_healing_completed)

func show_healing_ui(npc: Node2D, system: HealingSystem):
    """显示治疗UI（兼容旧接口）"""
    npc_reference = npc
    healing_system = system
    connect_signals()

    # 定位到NPC上方
    if npc:
        _position_above_npc(npc)

    show_ui()

func hide_healing_ui():
    """隐藏治疗UI（兼容旧接口）"""
    hide_ui()

func _position_above_npc(npc: Node2D):
    """定位UI到NPC上方"""
    var screen_pos = npc.get_global_transform_with_canvas().origin
    position = screen_pos - size / 2
    position.y -= 50  # 在NPC上方偏移

func _on_data_updated(data: Dictionary):
    """数据更新处理"""
    if data.has("npc") and data.has("healing_system"):
        show_healing_ui(data["npc"], data["healing_system"])

func _on_method_selected(method: String):
    """治疗方法选择处理"""
    if healing_system and npc_reference:
        var player = get_tree().get_first_node_in_group("player")
        if player:
            healing_system.start_healing(method, npc_reference, player)
            # 不立即隐藏，等待治疗完成

func _on_healing_progress_updated(progress: float):
    """治疗进度更新"""
    update_progress(progress)

func _on_healing_completed(success: bool):
    """治疗完成处理"""
    if success:
        play_success_effect()
    # 延迟后隐藏UI
    get_tree().create_timer(2.0).timeout.connect(func(): UIManager.instance.hide_ui(UIManager.UIType.HEALING))

func update_progress(progress: float):
    """更新进度显示"""
    if progress_bar:
        progress_bar.value = progress * 100

    if progress >= 1.0:
        play_success_effect()

func play_success_effect():
    """播放成功特效"""
    if particles:
        particles.emitting = true
        await get_tree().create_timer(2.0).timeout
        particles.emitting = false

func validate_data(data: Dictionary) -> bool:
    """验证数据"""
    var required_fields = ["npc", "healing_system"]
    for field in required_fields:
        if not data.has(field):
            push_warning("HealingUI: Missing required data field: ", field)
            return false
    return true
