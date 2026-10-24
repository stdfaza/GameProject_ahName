extends Node3D

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var wave: int = 1
var max_waves: int = 3
var active_enemies: Array[Node] = []
var player_name: String = "Player1"
var is_playing: bool = false

@onready var player: Node3D = $Player
@onready var menu_layer: CanvasLayer = $MenuLayer
@onready var game_over_panel: PanelContainer = $MenuLayer/GameOverPanel
@onready var victory_panel: PanelContainer = $MenuLayer/VictoryPanel
@onready var start_panel: PanelContainer = $MenuLayer/StartPanel
@onready var name_input: LineEdit = $MenuLayer/StartPanel/VBox/NameInput
@onready var wave_timer: Timer = $WaveTimer

const MONSTER_POOL = [
	"devil", "golem", "hound", "dragon", "elemental",
	"flower", "ghost", "lantern", "magma", "crab"
]

const SAVE_PATH = "user://player_data.cfg"

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	start_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	load_saved_name()

	if wave_timer:
		wave_timer.timeout.connect(spawn_wave)

func load_saved_name() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		player_name = config.get_value("player", "name", "Player1")
	if name_input:
		name_input.text = player_name

func save_player_name() -> void:
	var config = ConfigFile.new()
	config.set_value("player", "name", player_name)
	config.save(SAVE_PATH)

func _on_start_pressed() -> void:
	if name_input and name_input.text.strip_edges() != "":
		player_name = name_input.text.strip_edges()
	else:
		player_name = "Player1"
	save_player_name()

	start_panel.visible = false
	start_game()

func start_game() -> void:
	wave = 1
	is_playing = true
	clear_entities()
	if player:
		player.hp = 100.0
		player.stamina_bars = 3
		player.style_points = 0.0
		player.global_position = Vector3(0, 1.0, 10)
		player.set_wave(wave)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_wave()

func clear_entities() -> void:
	for en in active_enemies:
		if is_instance_valid(en):
			en.queue_free()
	active_enemies.clear()

	for fb in get_tree().get_nodes_in_group("fireballs"):
		fb.queue_free()

func spawn_wave() -> void:
	if not is_playing:
		return
	var count = wave * 6
	if player and player.has_method("set_wave"):
		player.set_wave(wave)

	for i in range(count):
		if enemy_scene == null:
			break
		var en = enemy_scene.instantiate()
		var m_type = MONSTER_POOL[i % MONSTER_POOL.size()]

		var angle = randf() * TAU
		var dist = randf_range(16.0, 34.0)
		var spawn_pos = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

		add_child(en)
		en.global_position = spawn_pos
		if en.has_method("setup"):
			en.setup(m_type, wave)

		en.died.connect(_on_enemy_died)
		active_enemies.append(en)

func _on_enemy_died(en: Node) -> void:
	active_enemies.erase(en)
	if active_enemies.size() == 0:
		if wave < max_waves:
			wave += 1
			if wave_timer:
				wave_timer.start(1.0)
			else:
				spawn_wave()
		else:
			trigger_victory()

func player_died() -> void:
	is_playing = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_panel.visible = true
	submit_score(player_name, player.style_points, wave)

func trigger_victory() -> void:
	is_playing = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	victory_panel.visible = true
	submit_score(player_name, player.style_points, wave)

func _on_retry_pressed() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	start_game()

func submit_score(p_name: String, final_style: float, final_wave: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, _response_code, _headers, _body):
		http.queue_free()
	)
	var payload = JSON.stringify({
		"player": p_name,
		"style": snapped(final_style, 0.1),
		"wave": final_wave
	})
	var headers = ["Content-Type: application/json"]
	http.request("http://192.168.1.5:5000/api/scores", headers, HTTPClient.METHOD_POST, payload)
