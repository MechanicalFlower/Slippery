class_name Axes

extends Spatial


func _process(_delta: float) -> void:
	# Avoid rotation of axes
	global_transform.basis = Basis.IDENTITY
