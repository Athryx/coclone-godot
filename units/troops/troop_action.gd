#extends RefCounted
#
#var type: TroopActionType
#
## vector2
#var position = null
#var building: Building = null
#
#func _init(type: TroopActionType):
	#self.type = type
#
#static func move(position: Vector2) -> TroopAction:
	#var out := TroopAction.new(TroopActionType.MOVE)
	#out.position = position
	#return out
#
#static func attack_building(building: Building) -> TroopAction:
	#var out := TroopAction.new(TroopActionType.ATTACK_BUILDING)
	#out.building = building
	#return out
