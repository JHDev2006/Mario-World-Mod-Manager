extends Control

signal clicked(mod_info, mod_path)
const NULL_ICON = preload("res://NullIcon.png")

var mod_path := ""
var mod := {
	"title": "Unnamed Mod",
	"image": NULL_ICON,
	"submitter": "Me",
	"category": "Character",
	"description": "This mod adds nothing, fuck you!"
}

@onready var mod_picture: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/ModPicture
@onready var name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Label

func _ready() -> void:
	$Button.pressed.connect(func(): clicked.emit(mod, mod_path))
	set_info()

func set_info() -> void:
	if mod.has("title"):
		name_label.text = mod.title
	if mod.has("image"):
		if mod.image.contains("http"):
			mod_picture.texture = await Global.download_image(mod.image)
		else:
			var path = mod_path.replace("modinfo.json", mod.image)
			mod_picture.texture = Global.load_image_from_file(path)
	
