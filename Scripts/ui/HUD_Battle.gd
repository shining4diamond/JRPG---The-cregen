extends CanvasLayer

@onready var player_panels = {}
@onready var current_turn_label: Label = %CurrentTurn_Label
@onready var turn_order_h_box_container: HBoxContainer = %TurnOrder_HBoxContainer

const HP_COLOR_CRITICAL = Color.RED
const HP_COLOR_LOW = Color.YELLOW
const HP_COLOR_NORMAL = Color.WEB_GREEN
const HPMP_PLAYER_TAB_SCENEPATH = "res://Scenes/ui/HPMP_Player_Tab.tscn"



func connect_player_signals():
	var players = get_parent().get_tree().get_nodes_in_group("player_battlers")
	for player in players:
		var battle_action = player.battleAction
		if battle_action.has_signal("update_hpmp_ui"):
			battle_action.update_hpmp_ui.connect(_update_hp_ui)
			print("✅ battle_action Connesso: ", player.name)
		else:
			print("❌ battle_action Segnale mancante su: ", player.name)
	
	var battleManager = get_parent().get_node_or_null("BattleManager")
	
	#_reset_focus_on_hpmp_players()
	if battleManager.has_signal("toggle_focus_on_player"):
		battleManager.toggle_focus_on_player.connect(_toggle_focus_on_hpmp_player)
		print("✅ toggle_focus_on_player Connesso",)
	else:
		print("❌ toggle_focus_on_player Segnale mancante")

func connect_enemy_signals():
	
	var enemies = get_parent().get_tree().get_nodes_in_group("enemy_battlers")
	for enemy in enemies:
		var battle_action = enemy.battleAction
		if battle_action.has_signal("update_hpmp_ui"):
			battle_action.update_hpmp_ui.connect(_update_hp_ui)
			print("✅ battle_action Connesso: ", enemy.name)
		else:
			print("❌ battle_action Segnale mancante su: ", enemy.name)





# Inizializza tutto
func initialize_player_ui(stats: StatsResource, party_member: int):
	if party_member < 0:
		push_error("Party member non valido: ", party_member)
		return
		
	var scene = load(HPMP_PLAYER_TAB_SCENEPATH) as PackedScene
	if not scene:
		push_error("Cannot load scene: " + HPMP_PLAYER_TAB_SCENEPATH)
		return null
	
	var hpmp_tab = scene.instantiate() as HBoxContainer
	
	hpmp_tab.name = str(party_member)
	
	var tab_container = self.get_node_or_null("%HPMP_Tab_Grid_Container")
	if not tab_container:
		push_error("Cannot find tab_container: %HPMP_Tab_Grid_Container")
		return
	
	tab_container.add_child(hpmp_tab)
	

	var container = tab_container
	var panel = hpmp_tab.get_node("%HPMP_Player")
	var spacer = hpmp_tab.get_node("%Spacer_Player")
	
	player_panels[party_member] = {
		"container" : container,
		"panel" : panel,
		"spacer" : spacer
	}
	
	# Mostra container HPMP
	container.show()
	
	# Nascondi spacer
	spacer.visible = true
	
	# Setup HP
	var hp_bar = panel.get_node("%HP_ProgressBar")
	hp_bar.max_value = stats.max_hp
	hp_bar.value = stats.current_hp
	hp_bar.get_node("Current_HP_Label").text = "%d" % [stats.current_hp]
	
	_update_hp_bar_color(hp_bar, stats.current_hp)
	
	# Setup MP
	var mp_bar = panel.get_node("%MP_ProgressBar")
	mp_bar.max_value = stats.max_mp
	mp_bar.value = stats.current_mp
	mp_bar.get_node("Current_MP_Label").text = "%d" % [stats.current_mp]
	
	print("✅ UI inizializzata per party member %d" % [party_member])




# Update HP
func _update_hp_ui(character: Character):
	var current_hp = character.stats.current_hp
	var party_member = character.stats.party_member
	# Player update
	if party_member > 0:
		_update_player_hp(current_hp, party_member)
		return
	
	# Enemy update
	if party_member < 0:
		_update_enemy_hp(current_hp, character)
		return
	
	push_warning("Party member non riconosciuto: %d" % party_member)

func _update_player_hp(current_hp: int, party_member: int):
	var panel = player_panels[party_member].panel
	var hp_bar = panel.get_node("%HP_ProgressBar")
	
	# Animazione smooth (opzionale)
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.3)
	
	# Update label
	hp_bar.get_node("Current_HP_Label").text = str(current_hp)
	
	# Update colore
	_update_hp_bar_color(hp_bar, current_hp)

func _update_enemy_hp(current_hp: int, character: Character):
	var hp_bar = character.get_node_or_null("HP_ProgressBar_Enemy")
	
	if not hp_bar:
		push_error("HP bar enemy non trovata: %s" % character)
		return
	
	# Animazione smooth
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.3)
	
	# Update colore
	_update_hp_bar_color(hp_bar, current_hp)



func _update_hp_bar_color(hp_bar: ProgressBar, current_hp: int):
	# Color coding
	var hp_percent = float(current_hp) / hp_bar.max_value
	hp_bar["theme_override_styles/fill"] = hp_bar["theme_override_styles/fill"].duplicate()
	if hp_percent <= 0.25:
		hp_bar["theme_override_styles/fill"].bg_color = HP_COLOR_CRITICAL
	elif hp_percent <= 0.5:
		hp_bar["theme_override_styles/fill"].bg_color = HP_COLOR_LOW
	else:
		hp_bar["theme_override_styles/fill"].bg_color = HP_COLOR_NORMAL




func _toggle_focus_on_hpmp_player(party_member: int):
	if not player_panels.has(party_member):
		#push_error("Party member non valido: %d" % party_member)
		return
	
	var panel_data = player_panels[party_member]
	var spacer = panel_data.spacer
	
	# Crea tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if spacer.visible:
		# Rimpicciolisci e poi nascondi
		tween.tween_property(spacer, "size_flags_stretch_ratio", 0.0, 0.3)
		tween.tween_callback(spacer.hide)
	else:
		# Mostra e poi ingrandisci
		spacer.show()
		spacer.size_flags_stretch_ratio = 0.0
		tween.tween_property(spacer, "size_flags_stretch_ratio", 0.2, 0.3)

func _set_current_turn_name(name: String):
	var label = current_turn_label.duplicate()
	turn_order_h_box_container.add_child(label)
	
	current_turn_label.text = name
	
	var child = turn_order_h_box_container.get_child(0)
	turn_order_h_box_container.remove_child(child)
	child.queue_free()

func _initialize_turn_order_bar(battlers: Array[Character]):
	if not battlers:
		return
	
	for battler in battlers:
		if battler == battlers[0]:
			current_turn_label.text = battler.stats.character_name
		else:
			var label = current_turn_label.duplicate()
			label.text = battler.stats.character_name
			turn_order_h_box_container.add_child(label)

func _reset_turn_order_bar(battlers: Array[Character]):
	for child in turn_order_h_box_container.get_children():
		turn_order_h_box_container.remove_child(child)
		child.queue_free()
	
	_initialize_turn_order_bar(battlers)
