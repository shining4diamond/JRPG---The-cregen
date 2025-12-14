extends CanvasLayer

# Segnali per save/load
signal save_requested
signal load_requested

# Languages
var next_language_index = 1
var languages: Array[String] = ["en", "it"]
var language = "automatic"

func _ready() -> void:
	# Load here language from the user settings file
	if language == "automatic":
		
		var preferred_language = OS.get_locale_language()
		TranslationServer.set_locale(preferred_language)
		language = preferred_language
	else:
		TranslationServer.set_locale(language)
	

func _on_save_button_pressed() -> void:
	save_requested.emit()
	print("Save requested")

func _on_load_button_pressed() -> void:
	load_requested.emit()
	print("Load requested")

func _on_language_button_pressed() -> void:
	var next_language = languages[next_language_index]
	if next_language == language:
		next_language_index = (next_language_index + 1) % languages.size()
		next_language = languages[next_language_index]
	
	change_language(next_language)
	next_language_index = (next_language_index + 1) % languages.size()
	language = next_language

func change_language(lang: String):
	TranslationServer.set_locale(lang)
	print(lang)
