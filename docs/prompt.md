# 《废土花开》 (Wasteland Bloom) 开发上下文与流程记录

这份文档（`prompt.md`）用于记录项目从概念诞生到当前开发阶段的完整流程。作为 AI 或新加入开发者的快速上下文入口，阅读本文档可以迅速了解项目的核心愿景、技术架构以及当前的开发进度。

## 一、 项目背景与核心愿景 (Project Vision)
- **游戏名称**：《废土花开》(Wasteland Bloom)
- **游戏类型**：2D 俯视角 / 废土生存 / 异星种田 / 动作 RPG
- **核心体验**：在危机四伏的辐射废土中，建立最后一片纯净的绿洲。
- **画风美学**：废土的压抑阴暗（冷色调、辐射尘埃）与庇护所的治愈生机（暖色调、翠绿草地）形成强烈的反差美学。
- **核心玩法循环**：【庇护所发育】 ↔ 【废土探索战斗】 ↔ 【生态净化与扩张】。
- **特色机制**：
  - **异星废土种田**：种出来的不仅仅是食物，更是武器（如藤蔓鞭）和陷阱（如荆棘地雷）。
  - **Furry 兽化人特质**：主角设定为新人类（具有猫、熊、兔等特征），不同种族在移动、战斗或种植上有轻量化的被动加成和专属表现动作。
  - **The Purge Moment (净化高光)**：极具视听震撼的动态地形翻转与生态净化演出。

## 二、 核心参考文档 (Reference Documents)
开发过程中，我们产出了以下核心规划文档，后续开发请随时参阅（均位于 `docs/` 目录下）：
1. `docs/游戏策划.md`：最新版本的概念设计草案（v4.0），包含世界观、核心机制深化、MVP 范围锁定。
2. `docs/技术架构与排期.md`：定义了推荐的文件夹树结构、三大核心驱动数据结构（TimeManager, PlantResource, FarmingManager）以及 4 个月的排期甘特图。
3. `docs/tasks_01.md` ~ `docs/tasks_04.md`：将四个月的开发周期拆分成了 40 个具体的执行任务，涵盖了从玩具箱 Demo 到最终抛光的所有细节。

## 三、 已完成的开发流程记录 (Completed Work Log)

### [阶段 0] 策划脑暴与方案定型
- 确立了“种田即武装”的设定，摒弃了传统的农场物语模式，引入了武器耐久耗尽后“种回土里强化”的闭环。
- 确立了 MVP (最小可行性产品) 范围，第一阶段绝对克制，坚决手搓微型地图，不碰程序化生成地图与复杂的 NPC AI。

### [阶段 1] 项目初始化与基础设定 (对应 tasks_01.md)
我们已经开始执行 `tasks_01.md`，目前已完成 **任务 1** 和 **任务 2**。

**1. 引擎调教与分辨率设定 (Task 1 核心部分)**
- 修改了 `project.godot`，将基础分辨率锁定为 `640x360`（16:9 的黄金像素分辨率）。
- 设置了缩放模式为 `viewport`，保持纵横比为 `keep`，保证像素完美放大。
- 关闭了纹理抗锯齿（Texture Filter 设为 Nearest），确保像素风画面的锐利度。

**2. 核心输入映射配置 (Input Map)**
- 利用 Godot 引擎自带的脚本模式（headless mode）精确写入了 8 向移动的键位绑定：
  - `move_up` (W / Up Arrow)
  - `move_down` (S / Down Arrow)
  - `move_left` (A / Left Arrow)
  - `move_right` (D / Right Arrow)

**3. 搭建主角基础肉身与 8 向移动 (Player.tscn & Player.gd)**
- 在 `res://scenes/player/` 下创建了 `Player.tscn` (基于 CharacterBody2D)。
- 挂载了 `AnimatedSprite2D`，包含完整的 5 个动画（idle, walk_down, walk_left, walk_right, walk_up）。
- 使用 CapsuleShape2D (radius=6, height=14) 只包裹脚部，产生 2.5D 遮挡纵深效果。
- 添加了 `ActionPoint` (Marker2D) 准星节点，带有红色 ColorRect 可视化指示器。
- 编写了 `Player.gd`，实现了：
  - 平滑的 8 向移动（使用自定义 `move_*` 输入映射）
  - 方向动画播放（根据移动方向自动切换动画）
  - 准星跟随朝向移动（`ACTION_DISTANCE = 16` 像素）
  - 挖地功能 (`dig_ground()`) - 按下 Enter/Space 键触发
  - 填地功能 (`build_ground()`) - 按住 B 键触发
  - Furry 种族枚举 (`Species.CAT`, `BEAR`, `RABBIT`) 带来的移速被动加成（CAT 移速 +15%）
- 完成了旧版 Player 的迁移，删除了根目录下的旧 `player.tscn` 和 `player.gd`。

**4. 实现全局时间系统 (Task 2: TimeManager)**
- 在 `res://autoload/` 下创建了 `TimeManager.gd`。
- 将其注册为全局单例 (Autoload)。
- 实现了核心时间魔法：现实 10 分钟映射为游戏内 1 天，精确发送 `time_tick`、`day_advanced`、`time_of_day_changed` 等信号，供后续的光照、UI 和植物生长系统监听。

## 四、 当前项目状态树 (Current Project Structure)
```text
res://
├── project.godot               # 已配置好分辨率、缩放、输入映射、自动加载
├── main.tscn                   # 测试用主场景（包含基础草地 TileMap 和 Player）
├── autoload/
│   └── TimeManager.gd          # 【已完成】全局时间单例
├── scenes/
│   └── player/
│       ├── Player.tscn         # 【已完成】主角场景
│       └── Player.gd           # 【已完成】8向移动与基础属性预留脚本
├── assets/                     # 存放各类贴图与素材
└── docs/                       # 项目文档目录
    ├── prompt.md               # 开发上下文与流程记录
    ├── 游戏策划.md              # 概念设计草案
    ├── 技术架构与排期.md         # 技术架构与排期甘特图
    └── tasks_01.md ~ tasks_04.md # 开发任务拆解
```

## 五、 下一步开发指南 (Next Steps)
接下来的开发工作请严格按照 `tasks_01.md` 的顺延任务进行：
1. **执行任务 3：扩展玩家基础属性与 UI**
   - 在 `Player.gd` 中补充 HP/Stamina/Radiation。
   - 制作 `HUD.tscn`，订阅 `TimeManager` 的信号来更新时间显示。
2. **执行任务 4：Furry 元素轻量化表现**
   - 给 `Player` 加入 AnimationPlayer，实现待机、呼吸、舔爪等特定行为。
3. **执行任务 5：坚决手搓 MVP 关卡地图**
   - 清理 `main.tscn`，或者新建 `world/map_01.tscn`。
   - 使用现有的素材画出一个左侧农田、右侧辐射区的微型测试场。

---
**AI 阅读提示**：
每当你被唤醒进行新的开发时，请先阅读 `docs/prompt.md` 以获取最新上下文，然后查看 `docs/tasks_01.md` 中未勾选（`- [ ]`）的任务，确认当前应该处理的具体工作。所有的改动请确保遵循“数据驱动 (Resource)”与“轻量化 MVP”的原则。