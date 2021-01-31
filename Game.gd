extends Node2D

onready var levelCount = $GuidelineRight/LevelContainer/LevelLabel
onready var earnablePoints = $GuidelineRight/PointsLabel/PointsContainer/Points
onready var totalScore = $GuidelineRight/TotalScoreLabel/TotalScoreContainer/TotalScore
onready var board = $Board

func _ready():
	levelCount.text = "Level " + String(board.CURRENT_LEVEL)
	earnablePoints.text = String(board.get_total_earnable_points())

func _on_Board_earnable_points_updated(points):
	earnablePoints.text = String(points)
