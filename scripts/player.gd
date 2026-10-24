extends CharacterBody3D

# --- Stats ---
var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 13.0
var jump_force: float = 11.0
var gravity: float = 28.0
var mouse_sens: float = 0.0022

# --- Stamina (3 bars) ---
var stamina_bars: int = 3
var max_stamina_bars: int = 3
var stamina_regen_timer: float = 0.0
var stamina_regen_delay: float = 0.65

# --- Dash ---
var dash_speed: float = 34.0
var dash_duration: float = 0.14
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_dir: Vector3 = Vector3.ZERO

# --- Knife Melee ---
var knife_range: float = 4.2
var knife_damage: float = 65.0
var knife_heal: float = 20.0
var knife_cooldown: float = 0.35
var knife_cd_timer: float = 0.0

# --- Push / Parry ---
var push_range: float = 6.5
var push_force: float = 24.0
var push_cooldown: float = 0.45
var push_cd_timer: float = 0.0

# --- Weapons ---
# 1 = shotgun, 2 = revolver, 3 = cryo
var current_weapon: int = 1
var shoot_cooldown: float = 0.15
var shoot_cd_timer: float = 0.0

# --- Style Meter ---
var style_points: float = 0.0
var style_decay: float = 3.5
var style_rank: String = "BRUTAL"

# --- Nodes ---
@onready var camera: Camera3D = $Camera3D
@onready var hp_label: Label = $HUD/MarginLeft/VBox/HPLabel
@onready var stamina_box: HBoxContainer = $HUD/MarginLeft/VBox/StaminaBox
@onready var weapon_label: Label = $HUD/MarginLeft/VBox/WeaponLabel
@onready var style_label: Label = $HUD/MarginRight/VBox/StyleLabel
@onready var style_bar: ProgressBar = $HUD/MarginRight/VBox/StyleBar
@onready var wave_label: Label = $HUD/TopCenter/WaveLabel
@onready var damage_flash: ColorRect = $HUD/DamageFlash

@onready var audio_shoot: AudioStreamPlayer = $AudioShoot
@onready var audio_knife: AudioStreamPlayer = $AudioKnife
@onready var audio_push: AudioStreamPlayer = $AudioPush
@onready var audio_heal: AudioStreamPlayer = $AudioHeal

var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")

	# Audio setup via SynthAudio
	audio_shoot.stream = SynthAudio.make_sfx("shoot")
	audio_knife.stream = SynthAudio.make_sfx("knife")
	audio_push.stream = SynthAudio.make_sfx("push")
	audio_heal.stream = SynthAudio.make_sfx("heal")

	damage_flash.color = Color(1, 0, 0, 0)
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		camera.rotate_x(-event.relative.y * mouse_sens)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2.2, PI/2.2)

func _process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	# Weapon keys
	if Input.is_action_just_pressed("weapon_1"):
		current_weapon = 1
	elif Input.is_action_just_pressed("weapon_2"):
		current_weapon = 2
	elif Input.is_action_just_pressed("weapon_3"):
		current_weapon = 3

	# Damage flash fade
	if damage_flash.color.a > 0.0:
		damage_flash.color.a = max(0.0, damage_flash.color.a - delta * 4.5)

	# Style decay
	style_points = max(0.0, style_points - style_decay * delta)
	update_style_rank()

	# Stamina regeneration
	stamina_regen_timer += delta
	if stamina_regen_timer >= stamina_regen_delay:
		if stamina_bars < max_stamina_bars:
			stamina_bars += 1
			stamina_regen_timer = 0.0

	# Cooldowns
	if shoot_cd_timer > 0.0:
		shoot_cd_timer -= delta
	if knife_cd_timer > 0.0:
		knife_cd_timer -= delta
	if push_cd_timer > 0.0:
		push_cd_timer -= delta

	# Actions
	if Input.is_action_pressed("shoot"):
		shoot()
	if Input.is_action_just_pressed("knife"):
		knife_attack()
	if Input.is_action_just_pressed("push"):
		push_attack()

	update_hud()

func _physics_process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if not is_on_floor():
			velocity.y -= gravity * delta
			move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Dash execution
	if is_dashing:
		dash_timer -= delta
		velocity = dash_dir * dash_speed
		velocity.y = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		return

	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length_squared() > 0.01:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 0.7)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 0.7)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# Dash start
	if Input.is_action_just_pressed("dash") and stamina_bars > 0:
		start_dash(direction if direction.length() > 0.1 else -transform.basis.z)

	move_and_slide()

func start_dash(dir: Vector3) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_dir = dir.normalized()
	dash_dir.y = 0.0
	stamina_bars = max(0, stamina_bars - 1)
	audio_push.play()
	add_style("DASH", 5.0)

func shoot() -> void:
	if shoot_cd_timer > 0.0:
		return

	var cam_forward = -camera.global_transform.basis.z

	if current_weapon == 1:
		# Shotgun: 7 spread pellets
		shoot_cd_timer = 0.45
		for i in range(7):
			var spread = Vector3(
				randf_range(-0.12, 0.12),
				randf_range(-0.12, 0.12),
				randf_range(-0.12, 0.12)
			)
			fire_bullet((cam_forward + spread).normalized(), 24.0, false)
		audio_shoot.stream = SynthAudio.make_sfx("shotgun")
		audio_shoot.play()
		add_style("SHOTGUN BLAST", 4.0)
	elif current_weapon == 2:
		# Revolver: High precision hitscan / fast projectile
		shoot_cd_timer = 0.4
		fire_bullet(cam_forward, 90.0, false)
		audio_shoot.stream = SynthAudio.make_sfx("shoot")
		audio_shoot.play()
		add_style("REVOLVER SHOT", 10.0)
	elif current_weapon == 3:
		# Cryo-Rifle: Rapid cryo shots
		shoot_cd_timer = 0.18
		fire_bullet(cam_forward, 25.0, true)
		audio_shoot.stream = SynthAudio.make_sfx("shoot")
		audio_shoot.play()
		add_style("CRYO SHOT", 6.0)

func fire_bullet(dir: Vector3, dmg: float, cryo: bool = false) -> void:
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = camera.global_position + dir * 0.8
	if b.has_method("setup"):
		b.setup(dir, dmg, cryo)

func knife_attack() -> void:
	if knife_cd_timer > 0.0:
		return
	knife_cd_timer = knife_cooldown
	audio_knife.play()

	var hit_enemy = false
	var enemies = get_tree().get_nodes_in_group("enemies")
	for en in enemies:
		if en.global_position.distance_to(global_position) < knife_range:
			hit_enemy = true
			if en.has_method("take_damage"):
				en.take_damage(knife_damage, en.global_position, -camera.global_transform.basis.z * 10.0, false)
			heal(knife_heal)
			stamina_bars = min(max_stamina_bars, stamina_bars + 1)
			add_style("BLOOD ABSORPTION", 25.0)

	if not hit_enemy:
		add_style("SWING", 1.0)

func push_attack() -> void:
	if push_cd_timer > 0.0 or stamina_bars <= 0:
		return
	push_cd_timer = push_cooldown
	stamina_bars = max(0, stamina_bars - 1)
	audio_push.play()
	add_style("SHOCKWAVE", 8.0)

	var cam_forward = -camera.global_transform.basis.z

	# Parry Fireballs
	for fb in get_tree().get_nodes_in_group("fireballs"):
		if fb.global_position.distance_to(camera.global_position) < push_range:
			if fb.has_method("parry"):
				fb.parry(cam_forward)
				add_style("PARRY REFLECT!", 45.0)
				var parry_sfx = AudioStreamPlayer.new()
				parry_sfx.stream = SynthAudio.make_sfx("parry")
				add_child(parry_sfx)
				parry_sfx.play()
				parry_sfx.finished.connect(parry_sfx.queue_free)

	# Push Enemies
	for en in get_tree().get_nodes_in_group("enemies"):
		if en.global_position.distance_to(global_position) < push_range:
			var push_dir = (en.global_position - global_position).normalized()
			push_dir.y = 0.2
			if "velocity" in en:
				en.velocity += push_dir * push_force

func heal(amount: float) -> void:
	hp = min(max_hp, hp + amount)
	audio_heal.play()

func take_damage(amount: float) -> void:
	hp -= amount
	damage_flash.color.a = 0.5
	if hp <= 0.0:
		die()

func die() -> void:
	hp = 0.0
	var main = get_tree().current_scene
	if main and main.has_method("player_died"):
		main.player_died()

func add_style(_action_name: String, points: float) -> void:
	style_points += points

func update_style_rank() -> void:
	if style_points >= 260.0:
		style_rank = "ULTRAKILL"
	elif style_points >= 190.0:
		style_rank = "SSSLAYER"
	elif style_points >= 130.0:
		style_rank = "CHAOS"
	elif style_points >= 75.0:
		style_rank = "BRUTAL"
	elif style_points >= 30.0:
		style_rank = "ANARCHY"
	else:
		style_rank = "DESTRUCTIVE"

func set_wave(wave_num: int) -> void:
	if wave_label:
		wave_label.text = "WAVE %d / 3" % wave_num

func update_hud() -> void:
	if hp_label:
		hp_label.text = str(int(max(0, hp)))
	if weapon_label:
		var w_names = ["[1] SHOTGUN", "[2] REVOLVER", "[3] CRYO-RIFLE"]
		weapon_label.text = w_names[current_weapon - 1]
	if style_label:
		style_label.text = style_rank
	if style_bar:
		style_bar.value = clamp((style_points / 260.0) * 100.0, 0.0, 100.0)

	if stamina_box:
		var bars = stamina_box.get_children()
		for i in range(bars.size()):
			if i < stamina_bars:
				bars[i].modulate = Color(0.0, 1.0, 1.0, 1.0)
			else:
				bars[i].modulate = Color(0.1, 0.25, 0.25, 1.0)
