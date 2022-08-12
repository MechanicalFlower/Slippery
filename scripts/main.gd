class_name Main

extends Node

onready var _player = get_node("%Player") as RigidBody
onready var _player_camera = get_node("%PlayerCamera") as Spatial


func _ready():
	_player.set_camera(_player_camera)
