extends Control

var mod_paths := []
var mod_names := []

const MODCONTAINER = preload("res://modcontainer.tscn")

var mod_list := {}

var all_selected := false

func _ready() -> void:
	refresh_list()
	set_starting_checks()

func refresh_list() ->void:
	for i in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()
	mod_paths.clear()
	mod_names.clear()
	
	get_mod_list_file()
	get_mods()
	
	for i in mod_names:
		add_mod_nodes(i)

func get_mods() -> void:
	for i in DirAccess.get_files_at("user://Addons"):
		mod_paths.append("user://Addons/" + i)
		mod_names.append(i)

func add_mod_nodes(mod_path := "") -> void:
	var node = MODCONTAINER.instantiate()
	node.get_node("Label").text = mod_path
	if mod_list.has(mod_path):
		node.get_node("CheckBox").set_pressed(mod_list[mod_path])
	$VBoxContainer/ScrollContainer/VBoxContainer.add_child(node)

func get_mod_list_file() -> void:
	if FileAccess.file_exists("user://modlist.json"):
		var file = FileAccess.open("user://modlist.json", FileAccess.READ)
		mod_list = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		save_list()
		get_mod_list_file()


func _on_button_pressed() -> void:
	for i in mod_paths.size():
		mod_list[mod_paths[i]] = $VBoxContainer/ScrollContainer/VBoxContainer.get_child(i).get_node("CheckBox").is_pressed()
	save_list()
	$VBoxContainer/Container/Button.text = "Saved!"
	await get_tree().create_timer(0.5, false).timeout
	$VBoxContainer/Container/Button.text = "Save"

func save_list() -> void:
	var file = FileAccess.open("user://modlist.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(mod_list, "\t"))
	file.close()

func set_starting_checks() -> void:
	for i in mod_paths.size():
		if mod_list.has(mod_paths[i]):
			$VBoxContainer/ScrollContainer/VBoxContainer.get_child(i).get_node("CheckBox").set_pressed(mod_list[mod_paths[i]])

func _on_button_2_pressed() -> void:
	for i in mod_paths.size():
		$VBoxContainer/ScrollContainer/VBoxContainer.get_child(i).get_node("CheckBox").set_pressed(not all_selected)
	all_selected = not all_selected
