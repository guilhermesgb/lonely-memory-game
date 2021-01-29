extends Position2D

var isOccupied = false

func _draw():
	draw_circle(Vector2.ZERO, 30, Color.blanchedalmond)

func occupy():
	modulate = Color.webmaroon
	isOccupied = true

func deoccupy():
	modulate = Color.white
	isOccupied = false

func is_occupied():
	return isOccupied

