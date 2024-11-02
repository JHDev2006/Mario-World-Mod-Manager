extends Control

@onready var mod_picture: TextureRect = $"TabContainer/Manage Mods/MarginContainer/VBoxContainer/HSplitContainer/ModInfo/Picture"
@onready var title_label: Label = $"TabContainer/Manage Mods/MarginContainer/VBoxContainer/HSplitContainer/ModInfo/PanelContainer/MarginContainer/VBoxContainer/ModName"
@onready var submitter: Label = $"TabContainer/Manage Mods/MarginContainer/VBoxContainer/HSplitContainer/ModInfo/PanelContainer/MarginContainer/VBoxContainer/Submitter"
@onready var category: Label = $"TabContainer/Manage Mods/MarginContainer/VBoxContainer/HSplitContainer/ModInfo/PanelContainer/MarginContainer/VBoxContainer/Category"
@onready var description: Label = $"TabContainer/Manage Mods/MarginContainer/VBoxContainer/HSplitContainer/ModInfo/PanelContainer/MarginContainer/VBoxContainer/Description"
@onready var mod_list: HFlowContainer = $"TabContainer/Manage Mods/MarginContainer/VBoxContainer/HSplitContainer/PanelContainer/ScrollContainer/ModList"
const MOD_CONTAINER = preload("res://mod_container.tscn")
var mod_folders := []
var valid_mods := []

enum Flags {OK, MISSING_PCK, MISSING_EXE, PCK_SETUP_NEEDED}

var current_flag := Flags.OK

var selected_mod = {}
var selected_mod_path := ""

const flag_text = [
	"No Errors Found - Good to go!",
	"Missing PCK path, add in settings.",
	"Missing EXE path, add in settings.",
	"PCK setup required. Press 'Setup' in 'Manage Mods'"
]

func _ready() -> void:
	Global.check_base_pck()
	refresh_list()
	$TabContainer/Settings/MarginContainer/VBoxContainer/HBoxContainer/ExePath.text = Global.exe_path
	$TabContainer/Settings/MarginContainer/VBoxContainer/HBoxContainer2/PckPath.text = Global.pck_path

func _process(delta: float) -> void:
	get_flag()
	if current_flag == Flags.OK:
		$Errors.modulate = Color.GREEN
	else:
		$Errors.modulate = Color.RED
	$Errors.text = flag_text[current_flag]

func get_flag() -> void:
	if Global.exe_path == "":
		current_flag = Flags.MISSING_EXE
	elif Global.pck_path == "":
		current_flag = Flags.MISSING_PCK
	elif Global.base_pck_found == false:
		current_flag = Flags.PCK_SETUP_NEEDED
	else:
		current_flag = Flags.OK

func refresh_list() -> void:
	mod_folders.clear()
	valid_mods.clear()
	for i in mod_list.get_children():
		i.queue_free()
	get_mods()
	add_containers()
	setup_mod_containers()

func get_mods() -> void:
	mod_folders.clear()
	for i in DirAccess.get_directories_at("user://Mods"):
		mod_folders.append(i)
		if FileAccess.file_exists("user://Mods/" + i + "/modinfo.json"):
			valid_mods.append("user://Mods/" + i + "/modinfo.json")

func add_containers() -> void:
	for i in valid_mods:
		var container = MOD_CONTAINER.instantiate()
		container.mod = parse_mod_json(i)
		container.mod_path = i
		mod_list.add_child(container)

func uninstall_mods() -> void:
	DirAccess.copy_absolute("user://ModManager/basegame.pck", Global.pck_path)
	DirAccess.copy_absolute("user://ModManager/basegame.exe", Global.exe_path)

func patch_mod() -> void:
	Global.apply_mod(selected_mod, selected_mod_path)

func launch_game() -> void:
	OS.execute(Global.exe_path, [])

func parse_mod_json(json_path := "") -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	
	return JSON.parse_string(file.get_as_text())

func setup_mod_containers() -> void:
	for i in mod_list.get_children():
		if i.clicked.is_connected(mod_clicked) == false:
			i.clicked.connect(mod_clicked)

func setup_pck() -> void:
	print("PCK Path: " + Global.pck_path)
	DirAccess.copy_absolute(Global.pck_path, ProjectSettings.globalize_path("user://ModManager/basegame.pck"))
	DirAccess.copy_absolute(Global.exe_path, ProjectSettings.globalize_path("user://ModManager/basegame.exe"))
	Global.check_base_pck()

func mod_clicked(mod := {}, mod_path := "") -> void:
	selected_mod = mod
	selected_mod_path = mod_path
	update_mod_info(mod)

func update_mod_info(mod_info := {}) -> void:
	if mod_info.has("title"):
		title_label.text = mod_info.title
	if mod_info.has("submitter"):
		submitter.text = "Submitter: " + mod_info.submitter
	if mod_info.has("category"):
		category.text = "Category: " + mod_info.category
	if mod_info.has("description"):
		description.text = "Description: " + mod_info.description
	
	if mod_info.has("image"):
		if mod_info.image.contains("http"):
			mod_picture.texture = await Global.download_image(mod_info.image)
		else:
			var path = selected_mod_path.replace("modinfo.json", mod_info.image)
			mod_picture.texture = Global.load_image_from_file(path)

func set_error_text(error := 0) -> void:
	pass


func _on_exe_path_text_changed(new_text: String) -> void:
	Global.exe_path = new_text
	Global.save_settings()

func _on_pck_path_text_changed(new_text: String) -> void:
	Global.pck_path = new_text
	Global.save_settings()
