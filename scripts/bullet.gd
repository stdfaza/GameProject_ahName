extends Area3D

var speed: float = 85.0
var damage: float = 30.0
var direction: Vector3 = Vector3.FORWARD
var life_time: float = 2.0
var is_cryo: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector3, dmg: float = 30.0, cryo: bool = false) -> void:
	direction = dir.normalized()
	damage = dmg
	is_cryo = cryo

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position, direction * 8.0, is_cryo)
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage, global_position, direction * 8.0, is_cryo)
		queue_free()
