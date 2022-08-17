# Generic state machine. Initializes states and delegates engine callbacks
# (_physics_process, _unhandled_input) to the active state
class_name StateMachine

extends Node

# Emitted when transitioning to a new state
signal transitioned(state_name)

# Path to the initial active state
export var initial_state := NodePath()

# The current active state
onready var _state: State = get_node(initial_state)


func _ready() -> void:
	yield(owner, "ready")
	# The state machine assigns itself to the State objects' state_machine property
	for child in get_children():
		child.state_machine = self
		_state.enter()


# The state machine subscribes to node callbacks and delegates them to the state objects
func _unhandled_input(event: InputEvent) -> void:
	_state.handle_input(event)


func _process(delta: float) -> void:
	_state.update(delta)


func _physics_process(delta: float) -> void:
	_state.physics_update(delta)


# This method can only be used with a rigid body owner
# You must call this method from its `_integrate_forces` method
func integrate_forces(state: PhysicsDirectBodyState) -> void:
	_state.integrate_forces(state)


# This function calls the current state's exit() function, then changes the active state,
# and calls its enter function
# It optionally takes a `msg` dictionary to pass to the next state's enter() function
func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	# Safety check, you could use an assert() here to report an error if the state name is incorrect
	# We don't use an assert here to help with code reuse.
	# If you reuse a state in different state machines but you don't want them all,
	# they won't be able to transition to states that aren't in the scene tree
	if not has_node(target_state_name):
		return

	_state.exit()
	_state = get_node(target_state_name)
	_state.enter(msg)
	emit_signal("transitioned", _state.name)
