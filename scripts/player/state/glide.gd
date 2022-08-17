class_name Glide

extends PlayerState

# max possible speed
const MAX_SPEED := 60.0

# Vertical speed applied when jumping.
export var jump_impulse := 120.0

# how fast player turn in air overall
export var flying_rotation_speed := 5.0

# how fast player rotate up and down
export var flying_up_down_speed = 10.0

# how fast player rotate left and right
export var flying_left_right_speed = 8.0

# how fast player roll
export var flying_roll_speed = 6.0

# how much player accelerate to max speed
export var flying_acceleration := 4.0

# how quickly player slow down when flying
export var flying_deceleration := 0.1

# max flying speed
export var flying_max_speed := 20.0

# min flying speed
export var flying_min_speed := 6.0

# how quickly velocity adjusts to the flying speed
export var flying_adjustment_speed := 2.0

# how much gravity will pull player down when flying
export var flying_gravity_amt := 4.0

# how much gravity affects player when just gliding
export var glide_gravity_amt := 6.0

# how much gravity is lerped when stopping flying
export var flying_grav_build_speed := 0.2

# how much velocity player gain for flying downwards
export var flying_velocity_gain := 1.0

# how much velocity player lose for flying upwards
export var flying_velocity_loss := 0.5

# how much player fly down before a boost
export var flying_lower_limit := -6.0

# how much player fly up before a boost
export var flying_upper_limit := 7.0

# how long wplayere glide for when not flying before player start to fall
export var glide_time := 10.0

var Math := load("res://scripts/math.gd")

# the air timer counting our current actions performed in air
var _action_air_timer := 0.2

# actual gravity apply on the player
var _actual_grave_amt := 0.0

# actual speed of the player
var _actual_speed := 0.0

# the lerp for our adjustment amount
var _flying_adjustment_lerp := 0.0

# the time before the animation stops flying
var _flying_timer := glide_time

#
var _do_jump := false


func enter(msg := {}) -> void:
	if msg.has("do_jump"):
		_velocity.y = jump_impulse

	_rotation = _player.transform.basis

	# Reset flying adjustment
	_flying_adjustment_lerp = 0

	# Reset flying animation
	_flying_timer = glide_time

	# Gravity is returned to the flying amount
	_actual_grave_amt = 0

	_action_air_timer = 0.2

	# Turn off gravity
	_player.set_gravity_scale(0.0)
	_player.custom_integrator = true


func update(_delta: float) -> void:
	_do_jump = Input.is_action_just_pressed("jump")

	if _action_air_timer > 0:
		return

	if _do_jump:
		_velocity.y = jump_impulse

	# check for ground if we are not holding the flying button
#	if not _do_jump:
#		if _player.is_on_floor():
#			# stun character
#			state_machine.transition_to("Roll", {push_direction = -_rotation.z})
#			return


func physics_update(delta: float) -> void:
	var x_mov = Input.get_axis("ui_left", "ui_right")
	var z_mov = Input.get_axis("ui_down", "ui_up")

	if not _do_jump:
		if _flying_timer > 0.0:
			_flying_timer -= delta
	elif _flying_timer < glide_time:
		_flying_timer = glide_time

	if _action_air_timer > 0.0:
		_action_air_timer -= delta

	if _flying_adjustment_lerp < 1.1:
		_flying_adjustment_lerp += delta * flying_adjustment_speed

	var y_amt = _velocity.y
	var fly_accel = flying_acceleration * _flying_adjustment_lerp
	var spd = flying_max_speed

	if not _do_jump:
		# Slow down
		spd = flying_min_speed
		if _actual_speed > flying_min_speed:
			fly_accel = flying_deceleration * _flying_adjustment_lerp

	handle_velocity(delta, spd, fly_accel, y_amt)
	flying_control(delta, _actual_speed, x_mov, z_mov)


func integrate_forces(player_body_state: PhysicsDirectBodyState) -> void:
	# Update velocity & rotation of the player

	player_body_state.set_linear_velocity(_velocity)
	_player.rotation = _rotation.get_euler()


func handle_velocity(delta: float, target_speed: float, accel: float, y_amt: float) -> void:
	# Handle how our speed is increased or decreased when flying

	if _actual_speed > flying_max_speed:
		# Player is over out max speed, slow down it
		accel = accel * 0.8

	if y_amt < flying_lower_limit:
		# Player are flying down, boost speed
		target_speed = target_speed + (flying_velocity_gain * (y_amt * -0.5))

	elif y_amt > flying_upper_limit:
		# Player are flying up, reduce speed
		target_speed = target_speed - (flying_velocity_loss * y_amt)
		_actual_speed -= (flying_velocity_loss * y_amt) * delta

	target_speed = clamp(target_speed, -MAX_SPEED, MAX_SPEED)

	_actual_speed = lerp(_actual_speed, target_speed, accel * delta)


func flying_control(delta: float, speed: float, x_move: float, z_move: float) -> void:
	x_move = x_move * 1
	z_move = z_move * -1

	# Get direction
	var downward_dir = flying_downward_direction(delta, z_move)
	var side_dir = flying_side_direction(delta, x_move)

	# Get rotation and adjustment speeds
	var rot_spd = flying_rotation_speed
	var fly_lerp_spd = flying_adjustment_speed * _flying_adjustment_lerp

	# Lerp mesh slower when not on ground
	rotate_self(downward_dir, delta, rot_spd)
	rotate_mesh(delta, side_dir, rot_spd)

	# Lerp to velocity if not flying
	if _flying_timer < glide_time * 0.7:
		rotate_to_velocity(delta, rot_spd * 0.05)

	# Push down more when not pressing fly
	if _do_jump:
		_actual_grave_amt = lerp(
			_actual_grave_amt, flying_gravity_amt, flying_grav_build_speed * 4.0 * delta
		)
	else:
		_actual_grave_amt = lerp(
			_actual_grave_amt, glide_gravity_amt, flying_grav_build_speed * 0.5 * delta
		)

	var target_velocity = _rotation.z * speed
	target_velocity -= Vector3.UP * _actual_grave_amt

	_velocity = lerp(_velocity, target_velocity, delta * fly_lerp_spd)


func flying_downward_direction(delta: float, z_move: float) -> Vector3:
	var downward_dir = -_rotation.y

	if z_move > 0.1:
		downward_dir = lerp(downward_dir, -_rotation.z, delta * (flying_up_down_speed * z_move))
	elif z_move < -0.1:
		downward_dir = lerp(
			downward_dir, _rotation.z, delta * (flying_up_down_speed * (z_move * -1.0))
		)

	if Input.is_action_just_pressed("ui_left"):
		downward_dir = lerp(downward_dir, -_rotation.x, delta * flying_roll_speed)
	elif Input.is_action_just_pressed("ui_right"):
		downward_dir = lerp(downward_dir, _rotation.x, delta * flying_roll_speed)

	return downward_dir


func flying_side_direction(delta: float, x_move: float) -> Vector3:
	var side_dir = _rotation.z

	if x_move > 0.1:
		side_dir = lerp(side_dir, -_rotation.x, delta * (flying_left_right_speed * x_move))
	elif x_move < -0.1:
		side_dir = lerp(side_dir, _rotation.x, delta * (flying_left_right_speed * (x_move * -1)))

	if Input.is_action_just_pressed("ui_left"):
		side_dir = lerp(side_dir, -_rotation.x, delta * flying_left_right_speed * 0.2)
	elif Input.is_action_just_pressed("ui_right"):
		side_dir = lerp(side_dir, _rotation.x, delta * flying_left_right_speed * 0.2)

	return side_dir


func rotate_self(direction: Vector3, delta: float, gravity_speed: float) -> void:
	# Convert basis to quaternion, scale is lost
	var from_rot = Quat(_rotation)

	# Lerp direction
	var lerp_dir = lerp(_rotation.y, direction, delta * gravity_speed)

	# Compute target Quat rotation
	var new_rot = Math.from_to_rotation(_rotation.y, lerp_dir) * from_rot

	# Apply back
	_rotation = Basis(new_rot)


func rotate_mesh(delta: float, look_dir: Vector3, speed: float) -> void:
	# Convert basis to quaternion, scale is lost
	var from_rot = Quat(_rotation)

	# Compute target Quat rotation
	var to_rot = Math.look_rotation(look_dir, _rotation.y)

	# Interpolate using spherical-linear interpolation
	var slerp_rot = from_rot.slerp(to_rot, speed * delta)

	# Apply back
	_rotation = Basis(slerp_rot)


func rotate_to_velocity(delta: float, speed: float) -> void:
	# Convert basis to quaternion, scale is lost
	var from_rot = Quat(_rotation)

	# Compute target Quat rotation
	var to_rot = Math.look_rotation(_velocity.normalized())

	# Interpolate using spherical-linear interpolation
	var slerp_rot = from_rot.slerp(to_rot, speed * delta)

	# Apply back
	_rotation = Basis(slerp_rot)
