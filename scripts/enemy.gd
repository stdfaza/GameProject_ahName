class_name Enemy
extends CharacterBody3D

signal died(enemy: Enemy)

@export var monster_type: String = "devil"
var max_hp: float = 35.0
var hp: float = 35.0
var move_speed: float = 4.0
var scale_factor: float = 2.8
var is_ranged: bool = true
var attack_cooldown: float = 2.6
var attack_timer: float = 0.0

var player: Node3D = null
var gravity: float = 24.0

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var fireball_scene: PackedScene = preload("res://scenes/fireball.tscn")

const MONSTER_SPECS = {
	"devil": {"scale": 2.8, "speed": 4.0, "hp_mult": 1.0, "shoots": true},
	"golem": {"scale": 3.4, "speed": 2.5, "hp_mult": 2.2, "shoots": false},
	"hound": {"scale": 2.4, "speed": 5.5, "hp_mult": 0.8, "shoots": false},
	"dragon": {"scale": 3.6, "speed": 3.2, "hp_mult": 2.5, "shoots": true},
	"elemental": {"scale": 2.2, "speed": 5.0, "hp_mult": 0.6, "shoots": true},
	"flower": {"scale": 2.5, "speed": 2.0, "hp_mult": 1.3, "shoots": true},
	"ghost": {"scale": 2.4, "speed": 4.5, "hp_mult": 0.8, "shoots": true},
	"lantern": {"scale": 2.2, "speed": 3.5, "hp_mult": 0.9, "shoots": false},
	"magma": {"scale": 2.0, "speed": 2.2, "hp_mult": 0.9, "shoots": true},
	"crab": {"scale": 2.4, "speed": 3.2, "hp_mult": 1.1, "shoots": false}
}

func _ready() -> void:
	add_to_group("enemies")
	attack_timer = randf_range(0.2, 1.5)
	find_player()
	apply_specs()

func setup(type_name: String, wave: int = 1) -> void:
	monster_type = type_name.to_lower()
	apply_specs(wave)

func apply_specs(wave: int = 1) -> void:
	var spec = MONSTER_SPECS.get(monster_type, MONSTER_SPECS["devil"])
	scale_factor = spec["scale"]
	move_speed = spec["speed"]
	is_ranged = spec["shoots"]
	var base_hp = 35.0 + float(wave) * 25.0
	max_hp = base_hp * spec["hp_mult"]
	hp = max_hp
	attack_cooldown = 2.6 if is_ranged else 1.5

	if sprite:
		var frame_path = "res://assets/frames/" + monster_type + "_frames.tres"
		if ResourceLoader.exists(frame_path):
			sprite.sprite_frames = load(frame_path)
			sprite.play("default")
		sprite.scale = Vector3(scale_factor, scale_factor, scale_factor)

func find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if player == null:
		find_player()
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	to_player.y = 0.0
	var dist = to_player.length()

	if dist > 2.2:
		var dir = to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 5.0)

	move_and_slide()

	# Attack logic
	attack_timer -= delta
	if attack_timer <= 0.0 and dist < 26.0:
		attack_timer = attack_cooldown
		if is_ranged:
			shoot_fireball()
		else:
			if dist < 2.8 and player.has_method("take_damage"):
				player.take_damage(14.0)

func shoot_fireball() -> void:
	if fireball_scene == null or player == null:
		return
	var fb = fireball_scene.instantiate()
	var spawn_pos = global_position + Vector3(0, scale_factor * 0.4, 0)
	var shoot_dir = (player.global_position + Vector3(0, 1.2, 0) - spawn_pos).normalized()
	get_parent().add_child(fb)
	fb.global_position = spawn_pos
	if fb.has_method("setup"):
		fb.setup(shoot_dir)

func take_damage(dmg: float, _hit_pos: Vector3 = Vector3.ZERO, impulse: Vector3 = Vector3.ZERO, is_cryo: bool = false) -> void:
	hp -= dmg
	if impulse != Vector3.ZERO:
		velocity += impulse * 0.5

	# Flash white
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0) if is_cryo else Color(2.5, 1.5, 1.0)
		get_tree().create_timer(0.08).timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate = Color.WHITE
		)

	if hp <= 0.0:
		die()

func die() -> void:
	died.emit(self)
	# Style points to player
	if player and player.has_method("add_style"):
		player.add_style(monster_type.to_upper() + " OBLITERATED", 25.0)
	queue_free()
