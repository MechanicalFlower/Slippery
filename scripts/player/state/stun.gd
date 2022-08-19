class_name Stun

extends PlayerState


func enter(_msg := {}) -> void:
	_player.custom_integrator = true
	_player.set_linear_velocity(Vector3.ZERO)
	print("Game Over!")
