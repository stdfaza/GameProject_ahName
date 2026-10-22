extends Area3D

var speed: float = 24.0
var damage: float = 22.0
var direction: Vector3 = Vector3.FORWARD
var life_time: float = 5.0
var is_parried: bool = false
var mesh_instance: MeshInstance3D

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	add_to_group("fireballs")

func setup(dir: Vector3) -> void:
	direction = dir.normalized()

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func parry(new_dir: Vector3) -> void:
	if is_parried:
		return
	is_parried = true
	direction = new_dir.normalized()
	speed = 50.0
	damage = 100.0
	life_time = 4.0
	# Change color to electric cyan/gold
	var mesh: MeshInstance3D = get_node_or_null("Mesh")
	if mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 1.0, 1.0)
		mat.emission_energy_multiplier = 3.0
		mesh.material_override = mat

func _on_body_entered(body: Node3D) -> void:
	if is_parried:
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position, direction * 15.0, false)
			queue_free()
		elif not body.is_in_group("player"):
			queue_free()
	else:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
			queue_free()
		elif not body.is_in_group("enemies"):
			queue_free()

func _on_area_entered(_area: Area3D) -> void:
	pass
