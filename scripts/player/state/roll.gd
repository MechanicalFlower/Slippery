class_name Roll

extends PlayerState

export var rot_speed := 5.0


func physics_update(_delta: float) -> void:
	var dir := Vector3.ZERO
	var cam_xform := _camera.get_global_transform()

	dir += -cam_xform.basis[2] * Input.get_action_strength("ui_up")
	dir += cam_xform.basis[2] * Input.get_action_strength("ui_down")
	dir += -cam_xform.basis[0] * Input.get_action_strength("ui_left")
	dir += cam_xform.basis[0] * Input.get_action_strength("ui_right")

	var target_dir := dir - Vector3.UP * dir.dot(Vector3.UP)
	var target_axis := target_dir.rotated(Vector3.UP, PI / 2.0)
	_player.add_torque(target_axis * rot_speed)

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("Glide", {do_jump = true})
