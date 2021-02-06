extends Node2D

const boardScene = preload("Board.tscn")

export(int) var CURRENT_LEVEL = 1

onready var levelCount = $GuidelineRight/LevelContainer/LevelLabel
onready var peeksCount = $GuidelineRight/CenterContainer/ItemsPanel/PeeksContainer/PeeksCount
onready var livesCount = $GuidelineRight/CenterContainer/ItemsPanel/LivesContainer/LivesCount
onready var earnablePoints = $GuidelineRight/PointsLabel/PointsContainer/Points
onready var totalScore = $GuidelineRight/TotalScoreLabel/TotalScoreContainer/TotalScore
onready var goodLuck = $LevelResultContainer/VBoxContainer/GoodLuck
onready var keepItUp = $LevelResultContainer/VBoxContainer/KeepItUp
onready var oopsTryAgain = $LevelResultContainer/VBoxContainer/OopsTryAgain
onready var gameOver = $LevelResultContainer/VBoxContainer/GameOver
onready var retryButton = $LevelResultContainer/VBoxContainer/RetryButton
onready var beginGameTimer = $BeginGameTimer
onready var animationPlayer = $AnimationPlayer
onready var boardContainer = $BoardContainer
onready var nextLevelTimer = $NextLevelTimer

onready var rng = RandomNumberGenerator.new()

var earnedLivesCount = 0

func _ready():
	rng.randomize()
	goodLuck.visible = true
	keepItUp.visible = false
	oopsTryAgain.visible = false
	gameOver.visible = false
	retryButton.visible = false
	setup_level()

func setup_level():
	hide_message()
	setup_board()

func hide_message():
	if CURRENT_LEVEL == 1:
		animationPlayer.play("ShowResult")
		beginGameTimer.start()

	else:
		animationPlayer.play("HideResult")

func _on_BeginGameTimer_timeout():
	animationPlayer.play("HideResult")

func setup_board():
	var board = boardScene.instance()
	board.setup(CURRENT_LEVEL, rng)
	board.z_index = -1
	boardContainer.add_child(board, true)

	board.connect("earnable_points_updated", self, "_on_earnable_points_updated")
	board.connect("peek_count_updated", self, "_on_peek_count_updated")
	board.connect("player_won", self, "_on_player_beat_level")
	board.connect("player_lost", self, "_on_player_lost_level")

	levelCount.text = "LEVEL " + String(CURRENT_LEVEL)
	earnablePoints.text = String(board.get_total_earnable_points())

func destroy_level():
	for childIndex in get_child_count():
		var child = get_child(childIndex)

		if child.name == "Board":
			child.destroy()
			break

func advance_level(points):
	var newTotalScore = int(totalScore.text) + points

	var currentThreshold = 0
	for count in CURRENT_LEVEL:
		currentThreshold = currentThreshold + (50 * (count + 1))
	currentThreshold = currentThreshold * 0.85

	if newTotalScore > currentThreshold:
		earnedLivesCount = earnedLivesCount + 1
		update_lives_count(earnedLivesCount)

	totalScore.text = String(newTotalScore)

	CURRENT_LEVEL = CURRENT_LEVEL + 1

func _on_earnable_points_updated(points):
	earnablePoints.text = String(points)

func _on_peek_count_updated(count):
	if count >= 10:
		peeksCount.text = "x" + String(count)

	else:
		peeksCount.text = "x0" + String(count)

func update_lives_count(count):
	if count >= 10:
		livesCount.text = "x" + String(count)

	else:
		livesCount.text = "x0" + String(count)

func _on_player_beat_level(points):
	goodLuck.visible = false
	keepItUp.visible = true
	oopsTryAgain.visible = false
	gameOver.visible = false
	retryButton.visible = false
	animationPlayer.play("ShowResult")
	advance_level(points)
	nextLevelTimer.start()

func _on_player_lost_level():
	if earnedLivesCount <= 0:
		goodLuck.visible = false
		keepItUp.visible = false
		oopsTryAgain.visible = false
		gameOver.visible = true
		retryButton.visible = true
		animationPlayer.play("ShowResult")

	else:
		earnedLivesCount = earnedLivesCount - 1
		update_lives_count(earnedLivesCount)

		goodLuck.visible = false
		keepItUp.visible = false
		oopsTryAgain.visible = true
		gameOver.visible = false
		retryButton.visible = false
		animationPlayer.play("ShowResult")
		nextLevelTimer.start()

func _on_NextLevelTimer_timeout():
	destroy_level()
	setup_level()

func _on_RetryButton_pressed():
	get_tree().reload_current_scene()
