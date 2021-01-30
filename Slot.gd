extends Position2D

signal slot_occupied

var isOccupied = false

#func _draw():
#	draw_circle(Vector2.ZERO, 15, Color("#b1876c"))

func occupy():
	emit_signal("slot_occupied")
#	modulate = Color("#8a5939")
	isOccupied = true

func deoccupy():
#	modulate = Color.white
	isOccupied = false

func is_occupied():
	return isOccupied
