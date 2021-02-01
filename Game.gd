extends Node2D

export(int) var CURRENT_LEVEL = 1

onready var levelCount = $GuidelineRight/LevelContainer/LevelLabel
onready var earnablePoints = $GuidelineRight/PointsLabel/PointsContainer/Points
onready var totalScore = $GuidelineRight/TotalScoreLabel/TotalScoreContainer/TotalScore

var boardScene = preload("Board.tscn")

func _ready():
	setup_level()

func setup_level():
	var board = boardScene.instance()
	board.setup(CURRENT_LEVEL)
	board.z_index = -1
	add_child(board, true)

	board.connect("earnable_points_updated", self, "_on_earnable_points_updated")
	board.connect("player_won", self, "_on_player_beat_level")
	board.connect("player_lost", self, "_on_player_lost_level")

	levelCount.text = "Level " + String(CURRENT_LEVEL)
	earnablePoints.text = String(board.get_total_earnable_points())

func advance_level(points):
	CURRENT_LEVEL = CURRENT_LEVEL + 1
	totalScore.text = String(int(totalScore.text) + points)

func destroy_level():
	for childIndex in get_child_count():
		var child = get_child(childIndex)

		if child.name == "Board":
			child.queue_free()
			break

func _on_earnable_points_updated(points):
	earnablePoints.text = String(points)

func _on_player_beat_level(points):
	destroy_level()
	advance_level(points)
	setup_level()
	pass

func _on_player_lost_level():
	pass

