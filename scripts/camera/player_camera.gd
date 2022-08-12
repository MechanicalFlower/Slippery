class_name PlayerCamera

extends Spatial

export var min_distance := 0.5
export var max_distance := 4.0
export var angle_v_adjust := 0.0
export var autoturn_ray_aperture := 25
export var autoturn_speed := 50

var _target: Spatial = null
var _max_height := 2.0
var _min_height := 1.0


func _ready() -> void:
	# This detaches the camera transform from the parent spatial node
	# set_as_toplevel(true)
	pass


func _physics_process(delta: float) -> void:
	if has_target():
		process_camera(delta)
	else:
		_target = null
		set_physics_process(false)


func process_camera(delta: float) -> void:
	var target = _target.get_global_transform().origin
	var pos = get_global_transform().origin
	var up = Vector3.UP

	var distance = pos - target

	# Regular distance follow

	# Check ranges
	if distance.length() < min_distance:
		distance = distance.normalized() * min_distance
	elif distance.length() > max_distance:
		distance = distance.normalized() * max_distance

	# Check upper and lower height
	if distance.y > _max_height:
		distance.y = _max_height
	if distance.y < _min_height:
		distance.y = _min_height

	# Check autoturn
	var ds = PhysicsServer.space_get_direct_state(get_world().get_space())

	var col_left = ds.intersect_ray(
		target, target + Basis(up, deg2rad(autoturn_ray_aperture)).xform(distance)
	)
	var col = ds.intersect_ray(target, target + distance)
	var col_right = ds.intersect_ray(
		target, target + Basis(up, deg2rad(-autoturn_ray_aperture)).xform(distance)
	)

	if !col.empty():
		# If main ray was occluded, get camera closer, this is the worst case scenario
		distance = col.position - target
	elif !col_left.empty() and col_right.empty():
		# If only left ray is occluded, turn the camera around to the right
		distance = Basis(up, deg2rad(-delta * autoturn_speed)).xform(distance)
	elif col_left.empty() and !col_right.empty():
		# If only right ray is occluded, turn the camera around to the left
		distance = Basis(up, deg2rad(delta * autoturn_speed)).xform(distance)
	else:
		# Do nothing otherwise, left and right are occluded but center is not, so do not autoturn
		pass

	# Apply lookat
	if distance == Vector3.ZERO:
		distance = (pos - target).normalized() * 0.0001

	pos = target + distance
	look_at_from_position(pos, target, up)

	# Turn a little up or down
	var t = get_transform()
	t.basis = Basis(t.basis[0], deg2rad(angle_v_adjust)) * t.basis
	set_transform(t)


func set_target(target: Spatial) -> void:
	_target = target
	if _target != null:
		translation = _target.translation + Vector3(0.1, 1, 0.1)
	set_physics_process(_target != null)


func has_target() -> bool:
	return _target != null and is_instance_valid(_target)
