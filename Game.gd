extends Node2D

export(int) var CURRENT_LEVEL = 1

onready var levelCount = $GuidelineRight/LevelContainer/LevelLabel
onready var earnablePoints = $GuidelineRight/PointsLabel/PointsContainer/Points
onready var totalScore = $GuidelineRight/TotalScoreLabel/TotalScoreContainer/TotalScore
onready var goodLuck = $LevelResultContainer/VBoxContainer/GoodLuck
onready var keepItUp = $LevelResultContainer/VBoxContainer/KeepItUp
onready var gameOver = $LevelResultContainer/VBoxContainer/GameOver
onready var retryButton = $LevelResultContainer/VBoxContainer/RetryButton
onready var beginGameTimer = $BeginGameTimer
onready var animationPlayer = $AnimationPlayer
onready var boardContainer = $BoardContainer
onready var nextLevelTimer = $NextLevelTimer

var boardScene = preload("Board.tscn")

func _ready():
	setup_level()

func setup_level():
	hide_message()
	setup_board()

func hide_message():
	gameOver.visible = false
	retryButton.visible = false

	if CURRENT_LEVEL == 1:
		goodLuck.visible = true
		keepItUp.visible = false
		animationPlayer.play("ShowResult")
		beginGameTimer.start()

	else:
		goodLuck.visible = false
		keepItUp.visible = true
		animationPlayer.play("HideResult")

func _on_BeginGameTimer_timeout():
	animationPlayer.play("HideResult")

func setup_board():
	var board = boardScene.instance()
	board.setup(CURRENT_LEVEL)
	board.z_index = -1
	boardContainer.add_child(board, true)

	board.connect("earnable_points_updated", self, "_on_earnable_points_updated")
	board.connect("player_won", self, "_on_player_beat_level")
	board.connect("player_lost", self, "_on_player_lost_level")

	levelCount.text = "Level " + String(CURRENT_LEVEL)
	earnablePoints.text = String(board.get_total_earnable_points())

func destroy_level():
	for childIndex in get_child_count():
		var child = get_child(childIndex)

		if child.name == "Board":
			child.queue_free()
			break

func advance_level(points):
	CURRENT_LEVEL = CURRENT_LEVEL + 1
	totalScore.text = String(int(totalScore.text) + points)

func _on_earnable_points_updated(points):
	earnablePoints.text = String(points)

func _on_player_beat_level(points):
	goodLuck.visible = false
	keepItUp.visible = true
	gameOver.visible = false
	retryButton.visible = false
	animationPlayer.play("ShowResult")
	advance_level(points)
	nextLevelTimer.start()
	pass

func _on_player_lost_level():
	goodLuck.visible = false
	keepItUp.visible = false
	gameOver.visible = true
	retryButton.visible = true
	animationPlayer.play("ShowResult")
	pass

func _on_NextLevelTimer_timeout():
	destroy_level()
	setup_level()

func _on_RetryButton_pressed():
	get_tree().reload_current_scene()
