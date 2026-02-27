extends CharacterBody2D

# 别忘了在最上面声明你的 AnimatedSprite2D 节点！
@onready var animated_sprite = $AnimatedSprite2D
@onready var action_point = $ActionPoint

# 设定的速度
const SPEED = 100.0

func _physics_process(delta):
	# 1. 获取键盘按键的方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. 计算速度并移动小猫
	velocity = input_dir * SPEED
	move_and_slide()
	
	# 3. 调用动画更新函数
	update_animation(input_dir)
	
	# 4. 挖地/填地检测
	if Input.is_action_just_pressed("ui_accept"):
		dig_ground()
	if Input.is_key_pressed(KEY_B):
		build_ground()


# 专门负责判断方向并播放动画的函数
func update_animation(dir: Vector2):
	# 如果没有按方向键 (dir 是 0,0)，就播放发呆动画
	if dir == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		# 判断是横向移动多，还是纵向移动多 (防止斜着走时动画抽搐)
		if abs(dir.x) > abs(dir.y):
			# 横向移动：判断是向右还是向左
			if dir.x > 0:
				animated_sprite.play("walk_right")
				animated_sprite.flip_h = false
			else:
				animated_sprite.play("walk_left")
		else:
			# 纵向移动：判断是向下还是向上
			if dir.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")

func dig_ground():
	var tilemap = get_parent().get_node_or_null("TileMapLayer")
	if tilemap != null:
		var target_pos = action_point.global_position
		# 【补丁】：把绝对坐标转换成 TileMapLayer 自己的内部坐标，永不偏移！
		var local_pos = tilemap.to_local(target_pos) 
		var grid_pos = tilemap.local_to_map(local_pos)
		tilemap.set_cell(grid_pos, -1)

func build_ground():
	var tilemap = get_parent().get_node_or_null("TileMapLayer")
	if tilemap != null:
		var target_pos = action_point.global_position
		var local_pos = tilemap.to_local(target_pos)
		var grid_pos = tilemap.local_to_map(local_pos)
		
		# 使用 get_cell_source_id 检查该坐标有没有放东西
		# 如果返回值是 -1，说明这个格子是空的！
		if tilemap.get_cell_source_id(grid_pos) == -1:
			tilemap.set_cells_terrain_connect([grid_pos], 0, 0)
