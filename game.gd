extends Node3D

@export var player: Resource

const Attack = preload("res://attack.tscn")
const BaseEditor = preload("res://base_editor/base_editor.tscn")

func _ready():
	PlayerData.player = player
	add_child(Attack.instantiate())
