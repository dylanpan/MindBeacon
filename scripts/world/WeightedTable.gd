extends RefCounted
class_name WeightedTable

# 权重表数据
var weights: Dictionary = {}  # item_id: weight
var total_weight: float = 0.0

# 构造函数，接受权重字典
func _init(weight_dict: Dictionary = {}):
	set_weights(weight_dict)

# 设置权重表
func set_weights(weight_dict: Dictionary):
	weights = weight_dict.duplicate()
	_calculate_total_weight()

# 更新单个项的权重
func update_weight(item_id, new_weight: float):
	weights[item_id] = new_weight
	_calculate_total_weight()

# 添加新项
func add_item(item_id, weight: float):
	weights[item_id] = weight
	total_weight += weight

# 移除项
func remove_item(item_id):
	if weights.has(item_id):
		total_weight -= weights[item_id]
		weights.erase(item_id)

# 计算总权重
func _calculate_total_weight():
	total_weight = 0.0
	for weight in weights.values():
		total_weight += weight

# 随机选择项，使用累积概率算法
func select_random():
	if weights.is_empty() or total_weight <= 0:
		return null
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for item_id in weights:
		cumulative_weight += weights[item_id]
		if random_value <= cumulative_weight:
			return item_id
	
	# 理论上不会到达这里，但作为保险
	return weights.keys()[0] if not weights.is_empty() else null

# 获取所有项ID
func get_items() -> Array:
	return weights.keys()

# 检查项是否存在
func has_item(item_id) -> bool:
	return weights.has(item_id)

# 获取项权重
func get_weight(item_id) -> float:
	return weights.get(item_id, 0.0)

# 清空权重表
func clear():
	weights.clear()
	total_weight = 0.0

# 获取权重表副本
func get_weights() -> Dictionary:
	return weights.duplicate()

# 获取总权重
func get_total_weight() -> float:
	return total_weight
