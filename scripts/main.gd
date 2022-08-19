extends Node


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				# Debug command to quit game
				KEY_ESCAPE:
					get_tree().quit()
				# Debug command to restart game
				KEY_R:
					var err = get_tree().change_scene("res://scenes/main.tscn")
					if err != OK:
						print("Error !")
