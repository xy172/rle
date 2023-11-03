extends ContentInfo

const MOD_STRINGS := [
	preload("mod_strings.en.translation"),
]
# Settings
var setting_rle_mod_status: bool = true
var setting_rle_modifier_value: float = 1.0

const RESOURCES := [
	{
		"resource": "battle/xyBattle.gd",
		"resource_path": "res://battle/Battle.gd",
	},
]

# Mod interop
const MODUTILS: Dictionary = {
	"updates": "https://gist.githubusercontent.com/xy172/0ea9c940b9282d483571c94c3bda4d84/raw/updates.json",
	"settings": [
		{
			"property": "setting_rle_mod_status",
			"type": "toggle",
			"label": "UI_SETTINGS_XY_RLE_MOD",
		},
		{
			"property": "setting_rle_modifier_value",
			"type": "slider",
			"label": "UI_SETTINGS_XY_RLE_LOSS_MULTIPLIER",
			"min_value": 0.0,
			"max_value": 10.0,
			"step": 0.1,
		},
	],
}
	
func init_content() -> void:
	
	# Add translation strings
	for translation in MOD_STRINGS:
		TranslationServer.add_translation(translation)

	if not setting_rle_mod_status: 
		return

	# Show MissingDependencies screen if cat_modutils isn't loaded
	if not DLC.has_mod("cat_modutils", 0):
		DLC.get_tree().connect("idle_frame", SceneManager, "change_scene", ["res://mods/xy_rle/menus/MissingDependency.tscn"], CONNECT_ONESHOT)
		return
		
		for def in RESOURCES:
			def.resource = load("res://mods/xy_rle/" + def.resource)
			def.resource.take_over_path(def.resource_path)
