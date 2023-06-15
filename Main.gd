extends Node3D

@onready var main_menu = $MultiplayerUI/MainMenu
@onready var address_entry = $MultiplayerUI/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $"MultiplayerUI/HUD"
@onready var healthBar = $"MultiplayerUI/HUD/HealthBar"
@onready var hitmarker = $"MultiplayerUI/HUD/Hitmarker"
@onready var map = $Map
var Player = preload("res://Player.tscn")

const PORT = 3000
var peer = ENetMultiplayerPeer.new()

func _ready():
	randomize()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = peer

func add_player(id):
	var new_player = Player.instantiate()
	new_player.name = str(id)
	randomize()
	var spawn_point = get_random_spawn_point()
	new_player.position = spawn_point.position
	new_player.rotation = spawn_point.rotation
	add_child(new_player)
	if new_player.is_multiplayer_authority():
		new_player.connect("healthChanged", update_health_bar)
		new_player.connect("damaged", on_damaged)

func remove_player(id):
	var plr = get_node_or_null(str(id))
	if plr:
		plr.queue_free()

func _on_copy_ip_button_pressed():
	DisplayServer.clipboard_set("localhost")

func update_health_bar(health, max_health):
	healthBar.value = health
	healthBar.max_value = max_health

func on_damaged():
	hitmarker.show()
	var t = Timer.new()
	t.set_wait_time(0.2)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	await t.timeout
	hitmarker.hide()

func _on_multiplayer_spawner_spawned(new_player):
	if new_player.is_multiplayer_authority():
		new_player.connect("healthChanged", update_health_bar)
		new_player.connect("damaged", on_damaged)

func get_random_spawn_point():
	return map.get_node(str("Spawns/SpawnPoint", randi_range(1, map.get_node("Spawns").get_child_count())))
