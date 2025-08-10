extends Node3D

@export var player: Player

const Attack = preload("res://game_view/attack/attack.tscn")
const BaseEditor = preload("res://game_view/base_editor/base_editor.tscn")

func _ready():
	print(Util.segment_intersects_rect(Vector2(0, 0), Vector2(5, 5), Rect2(Vector2(1, 1), Vector2(2, 3))))
	#print(Util.segment_intersects_rect(Vector2(0, 0), Vector2(5, 5), Rect2(Vector2(1, 1), Vetor2(2, 3))))
	
	PlayerData.player = player
	print(player.base_layout.buildings)
	add_child(Attack.instantiate())
