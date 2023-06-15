extends CharacterBody3D

signal healthChanged(health, max_health)
signal damaged

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var GRAVITY = 9.8

@export var SENSITIVITY = 1.0

@onready var pistol = $"Camera/Pistol"
@onready var pistolAnimationPlayer = $Camera/Pistol/Model/Animations
@onready var camera = $Camera
@onready var health = $Health
@onready var map = $"../Map"

@onready var raycast = $"Camera/RayCast3D"

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	$Camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#connect to other signals
	$"Camera/Pistol/Model/Animations".connect("animation_finished", fire_done)

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .003 * SENSITIVITY)
		camera.rotate_x(-event.relative.y * .003 * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if Input.is_action_pressed("gun_shoot") and pistolAnimationPlayer.current_animation != "fire":
		gun_fire()

	if pistolAnimationPlayer.current_animation == "fire":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		pistolAnimationPlayer.play("move")
	else:
		pistolAnimationPlayer.play("idle")

	move_and_slide()

func gun_fire():
	pistolAnimationPlayer.stop()
	pistolAnimationPlayer.play("fire")
	if raycast.is_colliding():
		var hit_player = raycast.get_collider()
		if (not hit_player is CharacterBody3D): return
		if is_multiplayer_authority():
			damaged.emit()
		hit_player.health_damage.rpc_id(hit_player.get_multiplayer_authority(), pistol.damage)
		

func fire_done(anim_name):
	if anim_name == "fire":
		pistolAnimationPlayer.play("idle")
		
@rpc("any_peer")
func health_damage(damage_num: float):
	health.health -= damage_num
	if (health.health <= 0):
		health.health = health.MaxHealth
		randomize()
		var spawn_point = get_random_spawn_point()
		position = spawn_point.position
		rotation = spawn_point.rotation
	healthChanged.emit(health.health, health.MaxHealth)

func get_random_spawn_point():
	return map.get_node(str("Spawns/SpawnPoint", randi_range(1, map.get_node("Spawns").get_child_count())))
