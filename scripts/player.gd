extends CharacterBody3D

# --- Stats ---
var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 12.0
var jump_force: float = 10.0
var gravity: float = 28.0
var mouse_sens: float = 0.002

# --- Stamina (3 bars) ---
var stamina_bars: int = 3
var max_stamina_bars: int = 3
var stamina_regen_timer: float = 0.0
var stamina_regen_delay: float = 0.6
var stamina_regen_rate: float = 1.8  # bars per sec

# --- Dash ---
var dash_speed: float = 32.0
var dash_duration: float = 0.15
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_dir: Vector3 = Vector3.ZERO

# --- Slide ---
var slide_speed: float = 22.0
var slide_timer: float = 0.0
var slide_max: float = 0.6
var is_sliding: bool = false

# --- Wall jump ---
var wall_jump_force: float = 9.0

# --- Knife ---
var knife_range: float = 3.5
var knife_damage: float = 50.0
var knife_heal: float = 15.0
var knife_cooldown: float = 0.35
var knife_cd_timer: float = 0.0
var knife_anim_timer: float = 0.0

# --- Push ---
var push_range: float = 6.0
var push_force: float = 25.0
var push_cooldown: float = 0.5
var push_cd_timer: float = 0.0

# --- Shoot ---
var shoot_cooldown: float = 0.12
var shoot_cd_timer: float = 0.0
var bullet_damage: float = 22.0
var current_weapon: String = "pistol"  # pistol, shotgun, revolver, cryo, nailgun

# --- Style Meter ---
var style_points: float = 0.0
var style_decay: float = 5.0
var style_rank: String = "D"

# --- Nodes ---
@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var hp_label: Label = $HUD/HPLabel
@onready var stamina_label: Label = $HUD/StaminaLabel
@onready var style_label: Label = $HUD/StyleLabel
@onready var weapon_label: Label = $HUD/WeaponLabel
@onready var crosshair: Label = $HUD/Crosshair
@onready var wave_label: Label = $HUD/WaveLabel
@onready var knife_anim: Label = $HUD/KnifeAnim
@onready var damage_flash: ColorRect = $HUD/DamageFlash
@onready var audio_shoot: AudioStreamPlayer = $AudioShoot
@onready var audio_knife: AudioStreamPlayer = $AudioKnife
@onready var audio_push: AudioStreamPlayer = $AudioPush
@onready var audio_dash: AudioStreamPlayer = $AudioDash
@onready var audio_heal: AudioStreamPlayer = $AudioHeal

# Bullet scene
var bullet_scene: PackedScene = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	
	# Load bullet scene
	bullet_scene = load("res://scenes/bullet.tscn")
	
	# Setup audio
	audio_shoot.stream = SynthAudio.make_sfx("shoot")
	audio_knife.stream = SynthAudio.make_sfx("knife")
	audio_push.stream = SynthAudio.make_sfx("push")
	audio_dash.stream = SynthAudio.make_sfx("dash")
	audio_heal.stream = SynthAudio.make_sfx("heal")
	
	# Init HUD
	damage_flash.color = Color(1, 0, 0, 0)
	knife_anim.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		camera.rotate_x(-event.relative.y * mouse_sens)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2.2, PI/2.2)

func _process(delta: float) -> void:
	update_hud()
	
	# Knife animation
	if knife_anim_timer > 0.0:
		knife_anim_timer -= delta
		knife_anim.visible = true
	else:
		knife_anim.visible = false
	
	# Damage flash
	if damage_flash.color.a > 0.0:
		damage_flash.color.a = max(0.0, damage_flash.color.a - delta * 4.0)
	
	# Style decay
	style_points = max(0.0, style_points - style_decay * delta)
	update_style_rank()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Dash
	if is_dashing:
		dash_timer -= delta
		velocity = dash_dir * dash_speed
		velocity.y = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		return
	
	# Slide
	if is_sliding:
		slide_timer -= delta
		var slide_dir: Vector3 = -transform.basis.z
		slide_dir.y = 0.0
		slide_dir = slide_dir.normalized()
		velocity.x = slide_dir.x * slide_speed
		velocity.z = slide_dir.z * slide_speed
		if slide_timer <= 0.0 or not Input.is_action_pressed("move_forward"):
			is_sliding = false
		move_and_slide()
		return
	
	# Movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 0.8)
		velocity.z = move_toward(velocity.z, 0, move_speed * 0.8)
	
	# Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_force
		elif is_on_wall():
			# Wall jump
			var wall_normal: Vector3 = get_wall_normal()
			velocity = wall_normal * wall_jump_force + Vector3.UP * jump_force * 0.9
			consume_stamina()
	
	# Dash (Shift)
	if Input.is_action_just_pressed("dash"):
		if stamina_bars > 0:
			start_dash(direction if direction.length() > 0.1 else -transform.basis.z)
	
	move_and_slide()
	
	# Cooldowns
	if shoot_cd_timer > 0.0:
		shoot_cd_timer -= delta
	if knife_cd_timer > 0.0:
		knife_cd_timer -= delta
	if push_cd_timer > 0.0:
		push_cd_timer -= delta
	
	# Stamina regen
	stamina_regen_timer -= delta
	if stamina_regen_timer <= 0.0 and stamina_bars < max_stamina_bars:
		stamina_bars = min(stamina_bars + 1, max_stamina_bars)
		stamina_regen_timer = 1.0 / stamina_regen_rate
	
	# Actions
	if Input.is_action_pressed("shoot"):
		shoot()
	if Input.is_action_just_pressed("knife"):
		knife_attack()
	if Input.is_action_just_pressed("push"):
		push_attack()

func start_dash(dir: Vector3) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_dir = dir.normalized()
	dash_dir.y = 0.0
	consume_stamina()
	audio_dash.play()

func consume_stamina() -> void:
	stamina_bars = max(0, stamina_bars - 1)
	stamina_regen_timer = stamina_regen_delay

func restore_stamina_bar() -> void:
	stamina_bars = min(max_stamina_bars, stamina_bars + 1)

func shoot() -> void:
	if shoot_cd_timer > 0.0:
		return
	
	match current_weapon:
		"pistol":
			shoot_cd_timer = 0.12
			fire_bullet(camera.global_transform.basis * Vector3.FORWARD * -1.0, 22.0)
			audio_shoot.play()
		"shotgun":
			shoot_cd_timer = 0.55
			for i in range(6):
				var spread: Vector3 = Vector3(randf_range(-0.08, 0.08), randf_range(-0.05, 0.05), 0)
				fire_bullet((camera.global_transform.basis * (Vector3.FORWARD * -1.0 + spread)).normalized(), 15.0)
			audio_shoot.stream = SynthAudio.make_sfx("shotgun")
			audio_shoot.play()
		"revolver":
			shoot_cd_timer = 0.7
			fire_bullet(camera.global_transform.basis * Vector3.FORWARD * -1.0, 80.0)
			audio_shoot.play()
		"cryo":
			shoot_cd_timer = 0.18
			fire_bullet(camera.global_transform.basis * Vector3.FORWARD * -1.0, 18.0, true)
			audio_shoot.play()
		"nailgun":
			shoot_cd_timer = 0.06
			var spread: Vector3 = Vector3(randf_range(-0.03, 0.03), randf_range(-0.02, 0.02), 0)
			fire_bullet((camera.global_transform.basis * (Vector3.FORWARD * -1.0 + spread)).normalized(), 10.0)
			audio_shoot.play()
	
	add_style(2.0)

func fire_bullet(dir: Vector3, dmg: float, cryo: bool = false) -> void:
	if not bullet_scene:
		return
	var b: Node3D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = camera.global_position + dir * 1.5
	b.setup(dir, dmg, cryo)

func knife_attack() -> void:
	if knife_cd_timer > 0.0:
		return
	knife_cd_timer = knife_cooldown
	knife_anim_timer = 0.15
	audio_knife.play()
	
	# Raycast from camera
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_transform.basis.z) * knife_range
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result: Dictionary = space.intersect_ray(query)
	
	if result:
		var target: Node3D = result.collider
		if target.has_method("take_damage"):
			target.take_damage(knife_damage, result.position, -camera.global_transform.basis.z * 10.0, false)
			heal(knife_heal)
			restore_stamina_bar()
			add_style(15.0)
	else:
		add_style(1.0)

func push_attack() -> void:
	if push_cd_timer > 0.0 or stamina_bars <= 0:
		return
	push_cd_timer = push_cooldown
	consume_stamina()
	audio_push.play()
	
	var cam_forward: Vector3 = -camera.global_transform.basis.z
	
	# Parry fireballs
	for fb in get_tree().get_nodes_in_group("fireballs"):
		if fb.global_position.distance_to(camera.global_position) < push_range:
			if fb.has_method("parry"):
				fb.parry(cam_forward)
				add_style(25.0)
				var parry_audio: AudioStreamPlayer = AudioStreamPlayer.new()
				parry_audio.stream = SynthAudio.make_sfx("parry")
				add_child(parry_audio)
				parry_audio.play()
				parry_audio.finished.connect(parry_audio.queue_free)
	
	# Push enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist: float = enemy.global_position.distance_to(global_position)
		if dist < push_range:
			var dir: Vector3 = (enemy.global_position - global_position).normalized()
			dir.y = 0.3
			if enemy.has_method("receive_push"):
				enemy.receive_push(dir * push_force)
				add_style(10.0)

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
	# Get main and restart
	var main: Node = get_tree().current_scene
	if main.has_method("player_died"):
		main.player_died()

func add_style(points: float) -> void:
	style_points += points

func update_style_rank() -> void:
	if style_points >= 150.0:
		style_rank = "S"
	elif style_points >= 100.0:
		style_rank = "A"
	elif style_points >= 60.0:
		style_rank = "B"
	elif style_points >= 30.0:
		style_rank = "C"
	else:
		style_rank = "D"

func set_weapon(weapon_name: String) -> void:
	current_weapon = weapon_name

func update_hud() -> void:
	hp_label.text = "HP: %d / %d" % [int(hp), int(max_hp)]
	hp_label.modulate = Color.RED if hp < 30 else Color.WHITE
	
	var bars_text: String = ""
	for i in range(max_stamina_bars):
		bars_text += "█ " if i < stamina_bars else "░ "
	stamina_label.text = "STAMINA: " + bars_text
	
	var style_color: Color
	match style_rank:
		"S": style_color = Color(1.0, 0.84, 0.0)
		"A": style_color = Color(1.0, 0.4, 0.1)
		"B": style_color = Color(0.2, 0.8, 1.0)
		"C": style_color = Color(0.8, 0.8, 0.8)
		_: style_color = Color(0.5, 0.5, 0.5)
	style_label.text = "STYLE: %s [%d]" % [style_rank, int(style_points)]
	style_label.modulate = style_color
	
	weapon_label.text = "WEAPON: %s" % current_weapon.to_upper()
