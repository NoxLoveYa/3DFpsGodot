extends Node

signal Died

@export var MaxHealth = 100.0
@export var health = 100.0

func _ready():
	health = MaxHealth
