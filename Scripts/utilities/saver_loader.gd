extends Node


@onready var game: Node2D = $"../.."

func _ready() -> void:
#	Globals.save_signal.connect(save_game)
	pass

func save_game():
	
	var saved_game:SavedGame = SavedGame.new()
	
	var saved_data:Array[SavedData] = []
	get_tree().call_group("game_events", "on_save_game", saved_data)
	
	saved_game.saved_data = saved_data


	ResourceSaver.save(saved_game, "user://savegame.tres")


func load_game():
	var saved_game:SavedGame = SafeResourceLoader.load("user://savegame.tres")
	
	if save_game == null:
		print("Save game is unsafe!")
		return
	
	
	get_tree().call_group("game_events", "on_before_load_game")
	
	for item in saved_game.saved_data:
		if item.scene_path != null and item.scene_path != "":
			var scene = load(item.scene_path) as PackedScene
			var restored_node = scene.instantiate()
			if restored_node.has_signal("toggle_focus_on_player"):
				restored_node.battle_data = BattleData.new()
			game.add_child(restored_node)
		
			if restored_node.has_method("on_load_game"):
				restored_node.on_load_game(item)
	
	get_tree().call_group("game_events", "on_after_load_game")
	




func _on_save_button_pressed() -> void:
	save_game()


func _on_load_button_pressed() -> void:
	load_game()
