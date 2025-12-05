extends Node

@onready var player: CharacterBody2D = %Player
@onready var coins: Node = %Coins
@onready var ui_death_count: Label = %UIDeathCount
@onready var ui_time_passed_label: Label = %UITimePassedLabel
@onready var ui_coins_collected_label: Label = %UICoinsCollectedLabel
@onready var game: Node2D = $"../.."

func _ready() -> void:
#	Globals.save_signal.connect(save_game)
	pass

func save_game():
	
	var saved_game:SavedGame = SavedGame.new()
	
	var saved_data:Array[SavedData] = []
	get_tree().call_group("game_events", "on_save_game", saved_data)
	
	saved_game.saved_data = saved_data
#	saved_game.player_position = player.global_position
#	saved_game.score = Globals.score
#	saved_game.deaths = Globals.deathCount


	ResourceSaver.save(saved_game, "user://savegame.tres")


func load_game():
	var saved_game:SavedGame = SafeResourceLoader.load("user://savegame.tres")
	
	if save_game == null:
		print("Save game is unsafe!")
		return
	
	player.global_position = saved_game.player_position
#	Globals.score = saved_game.score
#	Globals.coinsCollectedLabel = str(saved_game.score)
#	Globals.deathCount = saved_game.deaths
#	Globals.isDead = false
	
	get_tree().call_group("game_events", "on_before_load_game")
	
	for item in saved_game.saved_data:
		if item.scene_path != null and item.scene_path != "":
			var scene = load(item.scene_path) as PackedScene
			var restored_node = scene.instantiate()
			game.add_child(restored_node)
		
			if restored_node.has_method("on_load_game"):
				restored_node.on_load_game(item)

#	ui_coins_collected_label.text = str(Globals.score)
#	ui_death_count.text = "You died " + str(Globals.deathCount) + " times"


func _on_save_button_pressed() -> void:
	save_game()


func _on_load_button_pressed() -> void:
	load_game()
