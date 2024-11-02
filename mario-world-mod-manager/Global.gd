extends Node

var downloaded_image: Texture = null

signal image_downloaded

var image_url := ""

var downloaded_images := {}

var exe_path := ""
var pck_path := ""

var base_pck_found := false

func _ready() -> void:
	load_settings()
	print(ProjectSettings.globalize_path("res://"))

func check_base_pck() -> void:
	base_pck_found = FileAccess.file_exists("user://ModManager/basegame.pck")

func download_image(url := "") -> Texture:
	if downloaded_images.has(url):
		return downloaded_images.get(url)
	var http_request = HTTPRequest.new()
	image_url = url
	add_child(http_request)
	http_request.request_completed.connect(request_completed)
	http_request.request(url)
	await image_downloaded
	downloaded_images[url] = downloaded_image
	return downloaded_image

func save_settings() -> void:
	var settings := {
		"pck_path": pck_path,
		"exe_path": exe_path,
	}
	var file = FileAccess.open("user://ModManager/settings.cfg", FileAccess.WRITE)
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()

func load_image_from_file(file_path := "") -> Texture:
	return ImageTexture.create_from_image(Image.load_from_file(file_path))

func load_settings() -> void:
	if FileAccess.file_exists("user://ModManager/settings.cfg") == false:
		save_settings()
	var file = FileAccess.open("user://ModManager/settings.cfg", FileAccess.READ)
	var settings = JSON.parse_string(file.get_as_text())
	exe_path = settings.exe_path
	pck_path = settings.pck_path

func apply_mod(mod := {}, mod_path := "") -> void:
	mod_path = ProjectSettings.globalize_path(mod_path.replace("modinfo.json", ""))
	if mod.has("pck_patch"):
		if mod.pck_patch != "":
			patch_file(ProjectSettings.globalize_path("user://ModManager/basegame.pck"), mod_path + mod.pck_patch, Global.pck_path)
	if mod.has("exe_patch"):
		if mod.exe_patch != "":
			patch_file(ProjectSettings.globalize_path("user://ModManager/basegame.exe"), mod_path + mod.exe_patch, Global.exe_path)
	print("PATCHED")

func patch_file(original_file := "", patch := "", new_file := "") -> void:
	print([original_file, patch, new_file])
	var output = []
	var delta_path := ProjectSettings.globalize_path("res://") + "xdelta"
	print(delta_path)
	var code = OS.execute(delta_path, ["-d", "-f", "-s", original_file, patch, new_file], output)
	print(code, output)

func request_completed(_result, _response_code, _headers, body) -> void:
	var image = Image.new()
	if image_url.contains(".png"):
		image.load_png_from_buffer(body)
	elif image_url.contains(".jpg"):
		image.load_jpg_from_buffer(body)
	downloaded_image = ImageTexture.create_from_image(image)
	image_downloaded.emit()
