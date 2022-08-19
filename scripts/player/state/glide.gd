class_name Glide

extends PlayerState

# Max possible speed
const MAX_SPEED := 60.0

# Vertical speed applied when jumping.
export var jump_impulse := 120.0

# How fast player turn in air overall
export var flying_rotation_speed := 5.0

# How fast player rotate up and down
export var flying_up_down_speed = 10.0

# How fast player rotate left and right
export var flying_left_right_speed = 8.0

# How fast player roll
export var flying_roll_speed = 6.0

# How much player accelerate to max speed
export var flying_acceleration := 4.0

# How quickly player slow down when flying
export var flying_deceleration := 0.1

# Max flying speed
export var flying_max_speed := 20.0

# Min flying speed
export var flying_min_speed := 6.0

# How quickly velocity adjusts to the flying speed
export var flying_adjustment_speed := 2.0

# How much gravity will pull player down when flying
export var flying_gravity_amt := 4.0

# How much gravity affects player when just gliding
export var glide_gravity_amt := 6.0

# How much gravity is lerped when stopping flying
export var flying_grav_build_speed := 0.2

# How much velocity player gain for flying downwards
export var flying_velocity_gain := 1.0

# How much velocity player lose for flying upwards
export var flying_velocity_loss := 0.5

# How much player fly down before a boost
export var flying_lower_limit := -6.0

# How much player fly up before a boost
export var flying_upper_limit := 7.0

# How long wplayere glide for when not flying before player start to fall
export var glide_time := 10.0

var Math := load("res://scripts/math.gd")

# The air timer counting our current actions performed in air
var _action_air_timer := 0.2

# Actual gravity apply on the player
var _actual_grave_amt := 0.0

# Actual speed of the player
var _actual_speed := 0.0

# The lerp for our adjustment amount
var _flying_adjustment_lerp := 0.0

# The time before the animation stops flying
var _flying_timer := glide_time

#
var _do_jump := false


func enter(msg := {}) -> void:
	if msg.has("do_jump"):
		_velocity.y = jump_impulse

	# Turn off gravity
	_player.custom_integrator = true


func update(_delta: float) -> void:
	for body in _player.get_colliding_bodies():
		if not body.is_in_group("START"):
			state_machine.transition_to("Stun")

	if _player.get_global_transform().origin.y < -10.0:
		state_machine.transition_to("Stun")

	if _action_air_timer > 0:
		return

	_do_jump = Input.is_action_just_pressed("jump")

#	if _do_jump:
#		_velocity.y = jump_impulse

	# check for ground if we are not holding the flying button
	if _do_jump:
		state_machine.transition_to("Land")
		return


func physics_update(delta: float) -> void:
	if not _do_jump:
		if _flying_timer > 0.0:
			_flying_timer -= delta
	elif _flying_timer < glide_time:
		_flying_timer = glide_time

	if _action_air_timer > 0.0:
		_action_air_timer -= delta

	if _flying_adjustment_lerp < 1.1:
		_flying_adjustment_lerp += delta * flying_adjustment_speed

	compute_speed(delta)
	compute_rotation(delta)
	compute_velocity(delta, _actual_speed)


func integrate_forces(player_body_state: PhysicsDirectBodyState) -> void:
	# Update velocity
	player_body_state.set_linear_velocity(_velocity)


func compute_speed(delta: float) -> void:
	# Handle how our speed is increased or decreased when flying

	var y_amt := _velocity.y
	var fly_accel := flying_acceleration * _flying_adjustment_lerp
	var target_speed := flying_max_speed

	# When the jump button is not pressed
	if not _do_jump:
		# Slow down the player
		target_speed = flying_min_speed
		if _actual_speed > flying_min_speed:
			fly_accel = flying_deceleration * _flying_adjustment_lerp

	if _actual_speed > flying_max_speed:
		# Player is over out max speed, slow down it
		fly_accel = fly_accel * 0.8

	if y_amt < flying_lower_limit:
		# Player are flying down, boost speed
		target_speed = target_speed + (flying_velocity_gain * (y_amt * -0.5))

	elif y_amt > flying_upper_limit:
		# Player are flying up, reduce speed
		target_speed = target_speed - (flying_velocity_loss * y_amt)
		_actual_speed -= (flying_velocity_loss * y_amt) * delta

	target_speed = clamp(target_speed, -MAX_SPEED, MAX_SPEED)
	_actual_speed = lerp(_actual_speed, target_speed, fly_accel * delta)


func compute_rotation(delta: float) -> void:
	# Handle how the mesh is rotated on user input

	var x_move := Input.get_axis("ui_left", "ui_right")
	var z_move := Input.get_axis("ui_up", "ui_down")  # inverted

	# Get direction
	var downward_dir := flying_downward_direction(delta, z_move)
	var side_dir := flying_side_direction(delta, x_move)

	# Get rotation speed
	var rot_spd := flying_rotation_speed

	# Lerp mesh slower when not on ground
	rotate_self(downward_dir, delta, rot_spd)
	rotate_mesh(delta, side_dir, rot_spd)

	# Lerp to velocity, if not flying
	if _flying_timer < glide_time * 0.7:
		rotate_to_velocity(delta, rot_spd * 0.05)


func compute_velocity(delta: float, speed: float) -> void:
	# Get adjustment speed
	var fly_lerp_spd := flying_adjustment_speed * _flying_adjustment_lerp

	# When the jump button is not pressed
	if not _do_jump:
		# Push the player down
		_actual_grave_amt = lerp(
			_actual_grave_amt, glide_gravity_amt, flying_grav_build_speed * 0.5 * delta
		)
	else:
		# Otherwise, push the player up
		_actual_grave_amt = lerp(
			_actual_grave_amt, flying_gravity_amt, flying_grav_build_speed * 4.0 * delta
		)

	# Compute the target velocity
	var target_velocity := _basis.z * speed - Vector3.UP * _actual_grave_amt

	# Let's get closer of the target velocity
	_velocity = lerp(_velocity, target_velocity, delta * fly_lerp_spd)


func flying_downward_direction(delta: float, z_move: float) -> Vector3:
	var downward_dir := -_basis.y
	var downward_lerp_spd: float = flying_up_down_speed * abs(z_move)

	# Up and down movement affects downward direction
	if z_move > 0.1:
		downward_dir = lerp(downward_dir, -_basis.z, delta * downward_lerp_spd)
	elif z_move < -0.1:
		downward_dir = lerp(downward_dir, _basis.z, delta * downward_lerp_spd)

	if Input.is_action_just_pressed("ui_left"):
		downward_dir = lerp(downward_dir, -_basis.x, delta * flying_roll_speed)
	elif Input.is_action_just_pressed("ui_right"):
		downward_dir = lerp(downward_dir, _basis.x, delta * flying_roll_speed)

	return downward_dir


func flying_side_direction(delta: float, x_move: float) -> Vector3:
	var side_dir := _basis.z
	var side_lerp_spd: float = flying_left_right_speed * abs(x_move)

	if x_move > 0.1:
		side_dir = lerp(side_dir, -_basis.x, delta * side_lerp_spd)
	elif x_move < -0.1:
		side_dir = lerp(side_dir, _basis.x, delta * side_lerp_spd)

	if Input.is_action_just_pressed("ui_left"):
		side_dir = lerp(side_dir, -_basis.x, delta * flying_left_right_speed * 0.2)
	elif Input.is_action_just_pressed("ui_right"):
		side_dir = lerp(side_dir, _basis.x, delta * flying_left_right_speed * 0.2)

	return side_dir


func rotate_self(direction: Vector3, delta: float, gravity_speed: float) -> void:
	# Convert basis to quaternion, scale is lost
	var from_rot := Quat(_basis)

	# Lerp direction
	var lerp_dir: Vector3 = lerp(_basis.y, direction, delta * gravity_speed)

	# Compute target Quat rotation
	var new_rot: Quat = Math.from_to_rotation(_basis.y, lerp_dir) * from_rot

	# Apply back
	_basis = Basis(new_rot)


func rotate_mesh(delta: float, look_dir: Vector3, speed: float) -> void:
	# Convert basis to quaternion, scale is lost
	var from_rot := Quat(_basis)

	# Compute target Quat rotation
	var to_rot: Quat = Math.look_rotation(look_dir, _basis.y)

	# Interpolate using spherical-linear interpolation
	var slerp_rot := from_rot.slerp(to_rot, speed * delta)

	# Apply back
	_basis = Basis(slerp_rot)


func rotate_to_velocity(delta: float, speed: float) -> void:
	# Convert basis to quaternion, scale is lost
	var from_rot := Quat(_basis)

	# Compute target Quat rotation
	var to_rot: Quat = Math.look_rotation(_velocity.normalized())

	# Interpolate using spherical-linear interpolation
	var slerp_rot := from_rot.slerp(to_rot, speed * delta)

	# Apply back
	_basis = Basis(slerp_rot)
