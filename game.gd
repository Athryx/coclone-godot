extends Spatial

export(Resource) var player

func _ready():
	PlayerData.player = player
