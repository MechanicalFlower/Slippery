class_name PlayerState

extends State

var _velocity := Vector3.ZERO
var _rotation := Basis.IDENTITY
var _player: Player = null

onready var _camera := get_node("%PlayerCamera") as PlayerCamera


func _ready() -> void:
	set_physics_process(true)
	yield(owner, "ready")
	_player = owner as Player
	assert(_player != null)
