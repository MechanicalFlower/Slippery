class_name Player

extends RigidBody

onready var _fsm := get_node("%StateMachine") as StateMachine
onready var _label := get_node("%DebugStateLabel") as Label


func _process(_delta: float) -> void:
	DebugDraw.set_text("FPS", Engine.get_frames_per_second())
	DebugDraw.set_text("State", _fsm._state.name)
	DebugDraw.set_text("Position", global_transform.origin)

	debug_linear_velocity()


func _integrate_forces(state):
	_fsm.integrate_forces(state)


func debug_linear_velocity() -> void:
	var line_begin = global_transform.origin
	var line_end = global_transform.origin + linear_velocity.normalized()

	DebugDraw.draw_line_3d(line_begin, line_end, Color(1, 1, 0))
