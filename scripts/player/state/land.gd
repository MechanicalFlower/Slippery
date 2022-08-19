class_name Land

extends PlayerState


func enter(_msg := {}) -> void:
	_player.custom_integrator = false


func update(delta: float) -> void:
	if _player.get_global_transform().origin.y < -10:
		state_machine.transition_to("Stun")

	for body in _player.get_colliding_bodies():
		if body.is_in_group("GOAL"):
			# Update velocity
			var velocity = _player.get_linear_velocity()
			var lerp_velocity: Vector3 = lerp(velocity, Vector3.ZERO, delta)
			_player.set_linear_velocity(lerp_velocity)

			if velocity.is_equal_approx(Vector3.ZERO):
				print("Win!")
			break
