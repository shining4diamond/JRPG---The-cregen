extends CanvasLayer

@onready var player_panels = {
	1: {
		"panel": $HPMP_Container/GridContainer/Player_Character_1/HPMP_Player1,
		"spacer": $HPMP_Container/GridContainer/Player_Character_1/Spacer_Player1
	},
	2: {
		"panel": $HPMP_Container/GridContainer/Player_Character_2/HPMP_Player2,
		"spacer": $HPMP_Container/GridContainer/Player_Character_2/Spacer_Player2
	},
	3: {
		"panel": $HPMP_Container/GridContainer/Player_Character_3/HPMP_Player3,
		"spacer": $HPMP_Container/GridContainer/Player_Character_3/Spacer_Player3
	}
}

@onready var enemy_panels = {
	-1: {
		"hp_bar": "Enemy1/HP_ProgressBar_Ememy",
	},
	-2: {
		"hp_bar": "Enemy2/HP_ProgressBar_Ememy",
	},
	-3: {
		"hp_bar": "Enemy3/HP_ProgressBar_Ememy",
	}
}

const HP_COLOR_CRITICAL = Color.RED
const HP_COLOR_LOW = Color.YELLOW
const HP_COLOR_NORMAL = Color.WEB_GREEN
const ENEMIES = ["Enemy1", "Enemy2", "Enemy3"]
const PLAYERS = ["Player1", "Player2", "Player3"]


func connect_player_signals():
	
	for player_name in PLAYERS:
		var player = get_parent().get_node_or_null(player_name)
		var battleManager = get_parent().get_node_or_null("BattleManager")
		if player:
			var battle_action = player.battleAction
			if battle_action.has_signal("update_hpmp_ui"):
				battle_action.update_hpmp_ui.connect(_update_hp_ui)
				print("✅ battle_action Connesso: ", player_name)
			else:
				print("❌ battle_action Segnale mancante su: ", player_name)
			
			if battleManager.has_signal("toggle_focus_on_player"):
				battleManager.toggle_focus_on_player.connect(_toggle_focus_on_hpmp_player)
				print("✅ toggle_focus_on_player Connesso: ", player_name)
			else:
				print("❌ toggle_focus_on_player Segnale mancante su: ", player_name)
		else:
			print("⚠️ Player non trovato: ", player_name)


func connect_enemy_signals():
	
	for enemy_name in ENEMIES:
		var enemy = get_parent().get_node_or_null(enemy_name)
		if enemy:
			var battle_action = enemy.battleAction
			if battle_action.has_signal("update_hpmp_ui"):
				battle_action.update_hpmp_ui.connect(_update_hp_ui)
				print("✅ battle_action Connesso: ", enemy_name)
			else:
				print("❌ battle_action Segnale mancante su: ", enemy_name)
		else:
			print("⚠️ Enemy non trovato: ", enemy_name)





# Inizializza tutto
func initialize_player_ui(stats: StatsResource, party_member: int):
	if not player_panels.has(party_member):
		push_error("Party member non valido: " + str(party_member))
		return
	
	var panel_data = player_panels[party_member]
	var panel = panel_data.panel
	var spacer = panel_data.spacer
	
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
func _update_hp_ui(current_hp: int, party_member: int):
	# Player update
	if player_panels.has(party_member):
		_update_player_hp(current_hp, party_member)
		return
	
	# Enemy update
	if enemy_panels.has(party_member):
		_update_enemy_hp(current_hp, party_member)
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

func _update_enemy_hp(current_hp: int, party_member: int):
	var hp_bar_path = enemy_panels[party_member].hp_bar
	var hp_bar = get_parent().get_node_or_null(hp_bar_path)
	
	if not hp_bar:
		push_error("HP bar enemy non trovata: %s" % hp_bar_path)
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
		push_error("Party member non valido: %d" % party_member)
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
