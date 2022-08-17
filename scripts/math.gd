static func square_magnitude(vec: Vector3) -> float:
	return vec.dot(vec)


# https://github.com/Unity-Technologies/Unity.Mathematics
static func look_rotation(forward: Vector3, up: Vector3 = Vector3.UP) -> Quat:
	if forward == Vector3.ZERO:
		return Quat.IDENTITY

	var t := up.cross(forward).normalized()
	return Basis(t, forward.cross(t), forward).get_rotation_quat().normalized()


# https://github.com/nxrighthere/UnrealCLR
static func from_to_rotation(from_direction: Vector3, to_direction: Vector3) -> Quat:
	var axis = from_direction.cross(to_direction).normalized()
	var angle = from_direction.angle_to(to_direction)

	# https://github.com/godotengine/godot/issues/49858#issuecomment-913227941
	if not axis:
		if is_zero_approx(angle):
			return Quat.IDENTITY
		axis = Vector3.RIGHT

	return Quat(axis, angle).normalized()
