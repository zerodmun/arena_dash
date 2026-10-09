extends Node
## English source strings are stable translation keys. Dynamic strings translate before formatting.
signal changed
var language := "en"
var catalogs: Dictionary = {}
func _ready() -> void:
 for locale in ["en","id"]:
  var values: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://localization/"+locale+".json"))
  catalogs[locale]=values
  var translation:=Translation.new()
  translation.locale=locale
  for key: String in values: translation.add_message(key,values[key])
  TranslationServer.add_translation(translation)
 TranslationServer.set_locale(language)
func t(key: String,args: Array=[]) -> String:
 var value: String=catalogs.get(language,{}).get(key,key)
 return value if args.is_empty() else value % args
func set_language(locale: String,persist := true) -> void:
 language=locale if locale in ["en","id"] else "en"
 TranslationServer.set_locale(language)
 if OS.has_feature("web"):
  JavaScriptBridge.eval("try { localStorage.setItem('arena-dash-language', '"+language+"'); document.documentElement.lang='"+language+"'; } catch (error) {}")
 changed.emit()
 if persist: Game.save_settings()
