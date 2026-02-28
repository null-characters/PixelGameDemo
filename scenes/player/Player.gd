extends CharacterBody2D
class_name Player

# ==========================================
# 基础属性配置
# ==========================================
@export var base_speed: float = 120.0  # 基础移动速度

# 预留给任务 1 的三个种族预设 (MVP 阶段先用 Enum 区分)
enum Species { CAT, BEAR, RABBIT }
@export var current_species: Species = Species.CAT

# ==========================================
# 物理帧更新 (移动逻辑)
# ==========================================
func _physics_process(delta: float) -> void:
    # Godot 4 极其强大的内置函数：直接将 4 个方向键转化为一个 2D 向量
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    
    # 计算当前速度
    var current_speed = base_speed
    
    # 任务 5 的小铺垫：如果是猫科，移速基础增加
    if current_species == Species.CAT:
        current_speed *= 1.15 
    
    # 应用移动
    if input_dir != Vector2.ZERO:
        # Godot 会自动处理斜向移动的速度（不会出现斜着走比直走快的问题）
        velocity = input_dir * current_speed
        
        # 简单的精灵图翻转逻辑（根据左右移动方向）
        if input_dir.x != 0:
            $Sprite2D.flip_h = input_dir.x < 0
    else:
        # 如果没有按键，提供一个摩擦力平滑停止
        velocity = velocity.move_toward(Vector2.ZERO, current_speed)

    # Godot 4 专属移动函数，自带滑动检测
    move_and_slide()
