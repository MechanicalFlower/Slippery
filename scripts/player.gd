class_name Player

extends Spatial

export var rot_speed := 5.0

onready var _marble := get_node("%Marble") as RigidBody
onready var _camera := get_node("%PlayerCamera") as Spatial


func _ready() -> void:
	_camera.set_target(_marble)
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	var dir := Vector3.ZERO
	var cam_xform := _camera.get_global_transform()

	dir += -cam_xform.basis[2] * Input.get_action_strength("ui_up")
	dir += cam_xform.basis[2] * Input.get_action_strength("ui_down")
	dir += -cam_xform.basis[0] * Input.get_action_strength("ui_left")
	dir += cam_xform.basis[0] * Input.get_action_strength("ui_right")

	var target_dir := dir - Vector3.UP * dir.dot(Vector3.UP)
	var target_axis := target_dir.rotated(Vector3.UP, PI / 2.0)
	_marble.add_torque(target_axis * rot_speed)
