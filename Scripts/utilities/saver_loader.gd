extends Node


@onready var game: Node2D = $"../.."
@onready var save_menu: CanvasLayer = game.get_node_or_null("%SAVE_LOAD_DEBUG")

func _ready() -> void:
	# Connetti i segnali del menu save
	if save_menu:
		if save_menu.has_signal("save_requested"):
			save_menu.save_requested.connect(save_game)
			print("✅ Save signal connected")
		
		if save_menu.has_signal("load_requested"):
			save_menu.load_requested.connect(load_game)
			print("✅ Load signal connected")
	else:
		push_warning("SaveMenu not found, trying alternative connection method")
		# Metodo alternativo: cerca nell'albero
		call_deferred("_connect_save_menu_deferred")

func _connect_save_menu_deferred():
	# Cerca il SaveMenu nell'albero della scena
	var menus = get_tree().get_nodes_in_group("save_menu")
	if menus.size() > 0:
		save_menu = menus[0]
		if save_menu.has_signal("save_requested"):
			save_menu.save_requested.connect(save_game)
		if save_menu.has_signal("load_requested"):
			save_menu.load_requested.connect(load_game)


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
