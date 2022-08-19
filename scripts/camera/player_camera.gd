class_name PlayerCamera

extends Spatial

export var min_distance := 0.5
export var max_distance := 4.0
export var angle_v_adjust := 0.0
export var autoturn_ray_aperture := 25
export var autoturn_speed := 50

var _collision_exception := []
var _max_height := 2.0
var _min_height := 1.0
var _yaw_degrees := 0.0

onready var _target = get_parent() as Spatial


func _ready() -> void:
	# Find collision exceptions for ray
	var node = self.get_parent()
	while node:
		if node is RigidBody:
			_collision_exception.append(node.get_rid())
			break
		else:
			node = node.get_parent()

	# This detaches the camera transform from the parent spatial node
	set_as_toplevel(true)


func _physics_process(delta: float) -> void:
	process_camera(delta)


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
		target,
		target + Basis(up, deg2rad(autoturn_ray_aperture)).xform(distance),
		_collision_exception
	)
	var col = ds.intersect_ray(target, target + distance, _collision_exception)
	var col_right = ds.intersect_ray(
		target,
		target + Basis(up, deg2rad(-autoturn_ray_aperture)).xform(distance),
		_collision_exception
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
	if distance.is_equal_approx(Vector3.ZERO):
		distance = (pos - target).normalized() * 0.0001

	pos = target + distance
	transform.origin = pos

	# Turn a little up or down
	_yaw_degrees = fmod(_yaw_degrees + angle_v_adjust, 720)
	transform.basis = Basis(Vector3(_yaw_degrees * 180.0 / PI, 0.0, 0.0))

	look_at(target, up)
