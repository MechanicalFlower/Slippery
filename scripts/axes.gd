class_name Axes

extends Spatial

onready var _player_state = get_parent().get_node("StateMachine/Glide") as PlayerState


func _process(_delta: float) -> void:
	# # Avoid rotation of axes
	# global_transform.basis = Basis.IDENTITY
	global_transform.basis = _player_state._basis
