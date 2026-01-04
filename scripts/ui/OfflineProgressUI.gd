extends Control

@onready var time_label = $Panel/VBoxContainer/TimeLabel
@onready var progress_label = $Panel/VBoxContainer/ProgressLabel
@onready var close_button = $Panel/VBoxContainer/CloseButton

var progress_data: Dictionary

func _ready():
    close_button.connect("pressed", Callable(self, "_on_close_pressed"))

func set_progress_data(data: Dictionary):
    progress_data = data
    _update_display()

func _update_display():
    if progress_data.is_empty():
        return

    # 显示离线时间
    var offline_seconds = progress_data.get("time_offline", 0.0)
    time_label.text = "离线时间: " + OfflineProgressSystem.format_offline_time(offline_seconds)

    # 显示收益
    var progress = progress_data.get("progress", 0.0)
    progress_label.text = "获得收益: " + OfflineProgressSystem.format_progress_amount(progress)

func _on_close_pressed():
    # 播放关闭动画或音效
    queue_free()

# 获取收益数据（供其他系统调用）
func get_progress_amount() -> float:
    return progress_data.get("progress", 0.0)

func get_offline_time() -> float:
    return progress_data.get("time_offline", 0.0)
