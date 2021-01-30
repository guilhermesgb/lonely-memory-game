extends Position2D

var isOccupied = false

func _draw():
	draw_circle(Vector2.ZERO, 15, Color("#b1876c"))

func occupy():
	modulate = Color("#8a5939")
	isOccupied = true

func deoccupy():
	modulate = Color.white
	isOccupied = false

func is_occupied():
	return isOccupied

