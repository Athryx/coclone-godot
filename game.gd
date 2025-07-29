extends Node3D

@export var player: Resource

const Attack = preload("res://game_view/attack/attack.tscn")
const BaseEditor = preload("res://game_view/base_editor/base_editor.tscn")

func _ready():
	PlayerData.player = player
	add_child(Attack.instantiate())
