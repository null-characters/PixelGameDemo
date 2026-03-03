extends Node2D
## 手搓 MVP 关卡地图脚本
## 负责地图初始化、净化翻转效果

@onready var base_layer: TileMapLayer = $BaseLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer
@onready var purified_layer: TileMapLayer = $PurifiedLayer
@onready var purification_tree: Marker2D = $PurificationTree
@onready var player_spawn: Marker2D = $PlayerSpawn

# 农田地块记录 (用于后续种植系统)
var farm_plots: Dictionary = {}

# 记录地图原始结构（用于挖地、填地时恢复）
# 结构：{ Vector2i(x, y): {"source_id": int, "atlas_coords": Vector2i} }
var original_terrain: Dictionary = {}

func _ready() -> void:
	_init_farm_plots()
	_record_original_terrain()
	_setup_purification_tree()

## 初始化农田地块记录
func _init_farm_plots() -> void:
	# 扫描 BaseLayer，找到所有农田地块并记录
	var used_cells = base_layer.get_used_cells()
	for cell in used_cells:
		# 假设 source_id == 2 是可种植的土地（根据你的 TileSet 配置，source 2 是 Tilled Dirt）
		if base_layer.get_cell_source_id(cell) == 2:
			farm_plots[cell] = {"tilled": false, "watered": false}

## 记录所有手工铺设的原始地形信息
func _record_original_terrain() -> void:
	var used_cells = base_layer.get_used_cells()
	for cell in used_cells:
		var source_id = base_layer.get_cell_source_id(cell)
		var atlas_coords = base_layer.get_cell_atlas_coords(cell)
		original_terrain[cell] = {
			"source_id": source_id,
			"atlas_coords": atlas_coords
		}

## 获取某个坐标点在手工铺设时的原始地形信息
func get_original_terrain(pos: Vector2i) -> Dictionary:
	return original_terrain.get(pos, {})

## 设置净化树
func _setup_purification_tree() -> void:
	# 标记净化树位置
	if purification_tree:
		purification_tree.set_meta("type", "purification_target")
		purification_tree.set_meta("active", false)

## 触发净化效果 (公开接口)
func trigger_purification() -> void:
	"""当净化树成熟时调用，触发全地图净化翻转"""
	print("🌍 净化效果触发！")
	
	# 显示净化层
	purified_layer.visible = true
	
	# 生成净化后的地形
	_generate_purified_layer()
	
	# 创建视觉过渡效果
	_create_purge_effect()

## 生成净化后的地形
func _generate_purified_layer() -> void:
	# 根据基础层的地块范围生成对应的净化层草地
	var used_cells = base_layer.get_used_cells()
	for cell in used_cells:
		# source_id = 0 是净化层配置的草地
		purified_layer.set_cell(cell, 0, Vector2i(0, 0))

## 创建净化视觉特效
func _create_purge_effect() -> void:
	"""创建 The Purge Moment 视觉演出"""
	# TODO: 添加 Tween 动画和粒子效果
	# 1. 冲击波从净化树向外扩散
	# 2. 地块颜色渐变翻转
	# 3. 粒子效果（花瓣飘落）
	pass

## 获取农田地块信息 (供种植系统调用)
func get_farm_plot(pos: Vector2i) -> Dictionary:
	return farm_plots.get(pos, {})

## 更新农田地块状态 (供种植系统调用)
func update_farm_plot(pos: Vector2i, key: String, value: Variant) -> void:
	if farm_plots.has(pos):
		farm_plots[pos][key] = value
