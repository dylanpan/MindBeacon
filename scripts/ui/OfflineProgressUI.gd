class_name OfflineProgressUI
extends BaseUI

@onready var time_label = $Panel/VBoxContainer/TimeLabel
@onready var progress_label = $Panel/VBoxContainer/ProgressLabel
@onready var close_button = $Panel/VBoxContainer/CloseButton

var progress_data: Dictionary

func _initialize():
    """初始化方法"""
    if close_button:
        close_button.connect("pressed", _on_close_pressed)

func _on_data_updated(data: Dictionary):
    """数据更新处理"""
    if data.has("progress_data"):
        set_progress_data(data["progress_data"])

func set_progress_data(data: Dictionary):
    """设置进度数据"""
    progress_data = data
    _update_display()

func _update_display():
    """更新显示"""
    if progress_data.is_empty():
        return

    # 显示离线时间
    var offline_seconds = progress_data.get("time_offline", 0.0)
    time_label.text = "离线时间: " + OfflineProgressSystem.format_offline_time(offline_seconds)

    # 显示收益
    var progress = progress_data.get("progress", 0.0)
    progress_label.text = "获得收益: " + OfflineProgressSystem.format_progress_amount(progress)

func _on_close_pressed():
    """关闭按钮处理"""
    # 使用UIManager关闭UI
    UIManager.instance.hide_ui(UIManager.UIType.OFFLINE_PROGRESS)

func validate_data(data: Dictionary) -> bool:
    """验证数据"""
    if data.has("progress_data"):
        var progress_data = data["progress_data"]
        if not progress_data.has("time_offline") or not progress_data.has("progress"):
            push_warning("OfflineProgressUI: Missing required progress data fields")
            return false
    return true

# 获取收益数据（供其他系统调用）
func get_progress_amount() -> float:
    return progress_data.get("progress", 0.0)

func get_offline_time() -> float:
    return progress_data.get("time_offline", 0.0)
