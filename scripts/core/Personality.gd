## Personality 类 - 玩家人格模型
##
## 该类封装了玩家的心理特征参数，基于MBTI和Big5人格模型。
## 用于计算心理健康值并影响游戏世界中的NPC行为和环境氛围。
##
## 使用示例:
##   var personality = Personality.new()
##   personality.update_parameter("big5_openness", 10)
##   var health = personality.calculate_mental_health()
##
class_name Personality
extends Resource

## MBTI人格类型参数 (0-1范围，表示倾向强度)
@export_range(0.0, 1.0) var mbti_e_i: float  # Extraversion/Introversion - 外向性/内向性
@export_range(0.0, 1.0) var mbti_s_n: float  # Sensing/Intuition - 感觉/直觉
@export_range(0.0, 1.0) var mbti_t_f: float  # Thinking/Feeling - 思考/情感
@export_range(0.0, 1.0) var mbti_j_p: float  # Judging/Perceiving - 判断/感知

## Big5人格特质参数 (0-100范围)
@export_range(0, 100) var big5_openness: float       # 开放性 - 对新经验的开放程度
@export_range(0, 100) var big5_conscientiousness: float  # 尽责性 - 自我控制和责任感
@export_range(0, 100) var big5_extraversion: float   # 外向性 - 社交活跃度
@export_range(0, 100) var big5_agreeableness: float  # 宜人性 - 合作和同理心
@export_range(0, 100) var big5_neuroticism: float    # 神经质 - 情绪稳定性（反向）

## 计算出的心理健康值 (0-100范围)
var mental_health: float = 50.0

## 信号定义
signal parameter_changed(param_name: String, new_value: float)  ## 参数变化时发出
signal mental_health_updated(new_value: float)  ## 心理健康值更新时发出

func _init():
    # 初始化默认值
    initialize_default_values()

func initialize_default_values():
    # 设置平衡的默认人格参数
    mbti_e_i = 0.5
    mbti_s_n = 0.5
    mbti_t_f = 0.5
    mbti_j_p = 0.5

    big5_openness = 50
    big5_conscientiousness = 50
    big5_extraversion = 50
    big5_agreeableness = 50
    big5_neuroticism = 50

    mental_health = ConfigManager.instance.get_float("game_balance", "personality/default_mental_health", 50.0)

func calculate_mental_health() -> float:
    # MBTI贡献：计算人格类型一致性得分
    var mbti_score = (mbti_e_i + mbti_s_n + mbti_t_f + mbti_j_p) / 4.0 * 100

    # Big5贡献：计算积极特质平均值 (神经质取反)
    var big5_avg = (big5_openness + big5_conscientiousness +
                   big5_extraversion + big5_agreeableness +
                   (100 - big5_neuroticism)) / 5.0

    # 复合计算：MBTI权重40% + Big5权重60%
    const MBTI_WEIGHT = ConfigManager.instance.get_float("game_balance", "personality/mbti_weight", 0.4)
    const BIG5_WEIGHT = ConfigManager.instance.get_float("game_balance", "personality/big5_weight", 0.6)
    mental_health = mbti_score * MBTI_WEIGHT + big5_avg * BIG5_WEIGHT

    # 应用环境修正因子
    mental_health *= get_environment_modifier()

    mental_health = clamp(mental_health, 0, 100)
    mental_health_updated.emit(mental_health)
    return mental_health

func get_environment_modifier() -> float:
    # 获取当前环境对心理健康的修正因子
    # 例如：心理空间给予正面修正
    var modifier = 1.0
    if GameManager.current_world_layer == WorldLayer.PSYCHOLOGICAL:
        modifier = ConfigManager.instance.get_float("game_balance", "personality/psychological_modifier", 1.2)  # 心理空间给予20%加成
    return modifier

func update_parameter(param_name: String, delta: float):
    if not has_property(param_name):
        push_error("Invalid parameter: " + param_name)
        return

    var current_value = get(param_name)
    var new_value = clamp(current_value + delta, 0, 100 if param_name.begins_with("big5") else 1)
    set(param_name, new_value)
    parameter_changed.emit(param_name, new_value)
    calculate_mental_health()  # 重新计算心理健康值

    # 负面能量影响
    if param_name == "big5_neuroticism":
        # 这里可以根据配置调整负面能量的影响强度
        pass

func get_mbti_type() -> String:
    var type = ""
    type += "E" if mbti_e_i > 0.5 else "I"
    type += "S" if mbti_s_n > 0.5 else "N"
    type += "T" if mbti_t_f > 0.5 else "F"
    type += "J" if mbti_j_p > 0.5 else "P"
    return type
