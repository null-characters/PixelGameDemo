extends CanvasLayer
class_name HUD

# ==========================================
# 节点引用
# ==========================================
@onready var hp_bar = $StatsContainer/PanelContainer/VBoxContainer/HPBar
@onready var hp_label = $StatsContainer/PanelContainer/VBoxContainer/HPBar/Label
@onready var stamina_bar = $StatsContainer/PanelContainer/VBoxContainer/StaminaBar
@onready var stamina_label = $StatsContainer/PanelContainer/VBoxContainer/StaminaBar/Label
@onready var radiation_bar = $StatsContainer/PanelContainer/VBoxContainer/RadiationBar
@onready var radiation_label = $StatsContainer/PanelContainer/VBoxContainer/RadiationBar/Label
@onready var time_label = $TimeContainer/PanelContainer/VBoxContainer/TimeLabel
@onready var day_label = $TimeContainer/PanelContainer/VBoxContainer/DayLabel

# ==========================================
# 颜色定义
# ==========================================
# HP 颜色 (红色系)
const HP_COLOR_FULL := Color(0.9, 0.2, 0.2)
const HP_COLOR_LOW := Color(0.6, 0.1, 0.1)

# Stamina 颜色 (绿色系)
const STAMINA_COLOR_FULL := Color(0.2, 0.8, 0.3)
const STAMINA_COLOR_LOW := Color(0.3, 0.4, 0.2)

# Radiation 颜色 (绿 -> 黄 -> 红 渐变)
const RADIATION_COLOR_LOW := Color(0.2, 0.9, 0.2)    # 健康 (绿色)
const RADIATION_COLOR_MID := Color(0.9, 0.9, 0.1)    # 中等 (黄色)
const RADIATION_COLOR_HIGH := Color(0.9, 0.2, 0.1)   # 危险 (红色)

# ==========================================
# 玩家引用
# ==========================================
var player: Player = null

# ==========================================
# 测试模式
# ==========================================
var test_mode := true
var test_hp := 100.0
var test_stamina := 100.0
var test_radiation := 0.0
var test_time_accum := 0.0

# ==========================================
# 初始化
# ==========================================
func _ready() -> void:
    # 连接时间管理器信号
    if TimeManager:
        TimeManager.time_tick.connect(_on_time_tick)
        TimeManager.day_advanced.connect(_on_day_advanced)
        # 初始化时间显示
        _update_time_display()
        _update_day_display()

func _process(delta: float) -> void:
    # 测试模式：自动递减属性值
    if test_mode:
        _run_test(delta)
    else:
        # 正常模式：查找玩家
        if player == null:
            _find_player()

# ==========================================
# 测试代码
# ==========================================
func _run_test(delta: float) -> void:
    test_time_accum += delta
    
    # 每 0.1 秒更新一次
    if test_time_accum >= 0.1:
        test_time_accum = 0.0
        
        # HP 从 100 递减到 0
        if test_hp > 0:
            test_hp -= 1
            _update_hp_bar(test_hp, 100)
        
        # Stamina 从 100 递减到 0
        if test_stamina > 0:
            test_stamina -= 1.5
            if test_stamina < 0:
                test_stamina = 0
            _update_stamina_bar(test_stamina, 100)
        
        # Radiation 从 0 递增到 100
        if test_radiation < 100:
            test_radiation += 0.8
            if test_radiation > 100:
                test_radiation = 100
            _update_radiation_bar(test_radiation, 100)
        
        # 循环测试
        if test_hp <= 0 and test_stamina <= 0 and test_radiation >= 100:
            # 重置测试
            test_hp = 100.0
            test_stamina = 100.0
            test_radiation = 0.0

func _update_hp_bar(current: float, maximum: float) -> void:
    if hp_bar:
        hp_bar.max_value = maximum
        hp_bar.value = current
        _update_bar_color(hp_bar, current / maximum, HP_COLOR_FULL, HP_COLOR_LOW)
    if hp_label:
        hp_label.text = "HP %d/%d" % [int(current), int(maximum)]

func _update_stamina_bar(current: float, maximum: float) -> void:
    if stamina_bar:
        stamina_bar.max_value = maximum
        stamina_bar.value = current
        _update_bar_color(stamina_bar, current / maximum, STAMINA_COLOR_FULL, STAMINA_COLOR_LOW)
    if stamina_label:
        stamina_label.text = "STA %d/%d" % [int(current), int(maximum)]

func _update_radiation_bar(current: float, maximum: float) -> void:
    if radiation_bar:
        radiation_bar.max_value = maximum
        radiation_bar.value = current
        # 辐射条使用三色渐变：低=绿，中=黄，高=红
        var ratio := current / maximum
        var bar_color: Color
        if ratio < 0.5:
            bar_color = RADIATION_COLOR_LOW.lerp(RADIATION_COLOR_MID, ratio * 2)
        else:
            bar_color = RADIATION_COLOR_MID.lerp(RADIATION_COLOR_HIGH, (ratio - 0.5) * 2)
        _set_progress_color(radiation_bar, bar_color)
    if radiation_label:
        radiation_label.text = "RAD %d/%d" % [int(current), int(maximum)]

# ==========================================
# 查找玩家
# ==========================================
func _find_player() -> void:
    var found_player = get_tree().get_first_node_in_group("player")
    if found_player and found_player is Player:
        set_player(found_player)

# ==========================================
# 设置玩家引用
# ==========================================
func set_player(new_player: Player) -> void:
    # 断开旧玩家的信号
    if player:
        if player.hp_changed.is_connected(_on_hp_changed):
            player.hp_changed.disconnect(_on_hp_changed)
        if player.stamina_changed.is_connected(_on_stamina_changed):
            player.stamina_changed.disconnect(_on_stamina_changed)
        if player.radiation_changed.is_connected(_on_radiation_changed):
            player.radiation_changed.disconnect(_on_radiation_changed)
    
    player = new_player
    
    # 连接新玩家的信号
    if player:
        player.hp_changed.connect(_on_hp_changed)
        player.stamina_changed.connect(_on_stamina_changed)
        player.radiation_changed.connect(_on_radiation_changed)
        
        # 初始化属性条显示
        _on_hp_changed(player.current_hp, player.max_hp)
        _on_stamina_changed(player.current_stamina, player.max_stamina)
        _on_radiation_changed(player.current_radiation, player.max_radiation)

# ==========================================
# 属性变化回调（玩家模式）
# ==========================================
func _on_hp_changed(current: float, maximum: float) -> void:
    if test_mode:
        return
    _update_hp_bar(current, maximum)

func _on_stamina_changed(current: float, maximum: float) -> void:
    if test_mode:
        return
    _update_stamina_bar(current, maximum)

func _on_radiation_changed(current: float, maximum: float) -> void:
    if test_mode:
        return
    _update_radiation_bar(current, maximum)

# ==========================================
# 辅助函数：更新进度条颜色
# ==========================================
func _update_bar_color(bar: ProgressBar, ratio: float, color_full: Color, color_low: Color) -> void:
    var bar_color := color_full.lerp(color_low, 1.0 - ratio)
    _set_progress_color(bar, bar_color)

func _set_progress_color(bar: ProgressBar, color: Color) -> void:
    # 创建或更新填充样式
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 2
    style.corner_radius_top_right = 2
    style.corner_radius_bottom_right = 2
    style.corner_radius_bottom_left = 2
    bar.add_theme_stylebox_override("fill", style)

# ==========================================
# 时间变化回调
# ==========================================
func _on_time_tick(_hour: int, _minute: int) -> void:
    _update_time_display()

func _on_day_advanced(_new_day: int) -> void:
    _update_day_display()

func _update_time_display() -> void:
    if time_label and TimeManager:
        time_label.text = TimeManager.get_time_string()

func _update_day_display() -> void:
    if day_label and TimeManager:
        day_label.text = "Day %d" % TimeManager.current_day