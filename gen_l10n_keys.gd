tool
extends EditorScript

const TR_FILE_PATH := "res://translations.csv"
const CSV_DELIM := ","
const CLEAN_NOT_FOUND := false
const SKIP_DIRS := ["res://addons"]

const TEXT_TR_PROPS := ["text", "hint_tooltip", "placeholder_text", "bbcode_text",
		"dialog_text"]
const ITEMS_CLASSES := ["PopupMenu", "OptionButton", "ItemList"]
const ITEMS_INDEX := [10, 5, 3]
const WINDOW_CLASSES := ["WindowDialog", "AcceptDialog", "ConfirmationDialog", "FileDialog"]
const WINDOW_DEFAULT_TITLE := ["", "Alert!", "Please Confirm...", "Save a File"]

var regex := RegEx.new()
var keys := {}
var control_classes := []
var locales := PoolStringArray()
var locales_dict := {}


func _run() -> void:
	print("\n-------\nGenerating translation file...")
	read_translation_file()
	control_classes = ClassDB.get_inheriters_from_class("Control")
	scan_dir("res://")
	save_translation_file()


func read_translation_file() -> void:
	var file := File.new()
	if file.file_exists(TR_FILE_PATH):
		var e := file.open(TR_FILE_PATH, File.READ)
		assert(e == OK, "Can't open translation file")
		locales = file.get_csv_line(CSV_DELIM)
		locales.remove(0)
		while true:
			var line :=  file.get_csv_line(CSV_DELIM)
			if line.size() == 0 or (line.size() == 1 and line[0] == ""):
				break
			var key := line[0]
			line.remove(0)
			locales_dict[key] = line

		file.close()
	else:
		var dir_path := TR_FILE_PATH.get_base_dir()
		var dir := Directory.new()
		if not dir.dir_exists(dir_path):
			var e := dir.make_dir_recursive(dir_path)
			assert(e == OK, "Can't create directory")
		locales = PoolStringArray(["en"])


func save_translation_file() -> void:
	var not_found := PoolStringArray()
	var found := keys.size()
	for key in locales_dict.keys():
		var add := true
		if not keys.has(key):
			not_found.push_back(key)
			add = not CLEAN_NOT_FOUND
		if add:
			keys[key] = locales_dict[key]
	var keys_arr := keys.keys()
	keys_arr.sort()
	var file := File.new()
	var e := file.open(TR_FILE_PATH, File.WRITE)
	assert(e == OK, "Can't open translation file")
	var header := PoolStringArray(["keys"])
	header.append_array(locales)
	file.store_csv_line(header, CSV_DELIM)
	var new := 0
	for key in keys_arr:
		var a := PoolStringArray(keys[key])
		if a.size() == 0:
			a.resize(locales.size())
			a[0] = key
			new += 1
		var line := PoolStringArray([key])
		line.append_array(a)
		file.store_csv_line(line, CSV_DELIM)
	file.close()
	print("Translation file generated\nFound %d translation strings\nFound %d new string" % [found, new])
	if not_found.size() != 0:
		print("%d strings present in the translation file were not found in the project:" % not_found.size())
		for s in not_found:
			print("- %s" % s)
	print("Total strings: %d" % keys.size())


func scan_dir(path: String) -> void:
	var dir := Directory.new()
	if dir.open(path) == OK:
		var e := dir.list_dir_begin(true, true)
		assert(e == OK, "Can't start traversing directories")
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var dir_path := path + file_name
				if not SKIP_DIRS.has(dir_path):
					scan_dir(dir_path + "/")
			else:
				var ext := file_name.get_extension()
				if ext == "gd":
					process_gd(path + file_name)
				elif ext == "tscn" or ext == "scn":
					process_scene(path + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")


func get_file_content(path: String) -> String:
	var file := File.new()
	var e := file.open(path, File.READ)
	assert(e == OK, "Can't open file")
	var content = file.get_as_text()
	file.close()
	return content


func process_gd(path: String) -> void:
	var text = get_file_content(path)
	var e := regex.compile("(?<=[.,\\s\\+]tr\\(\")(.*?)(?=\"\\))")
	assert(e == OK, "Can't compile Regex")
	var matches = regex.search_all(text)
	for m in matches:
		var s: String = m.get_string()
		keys[s] = []


func process_scene(path: String) -> void:
	var scene: PackedScene = load(path) as PackedScene
	if not scene:
		return

	var names: PoolStringArray = scene._bundled.names
	var variants: Array = scene._bundled.variants
	var node_paths: Array = scene._bundled.node_paths
	var nodes: PoolIntArray = scene._bundled.nodes
	var num_nodes: int = scene._bundled.node_count
	var tabs: Array = []
	var itabs: Array = []
	var index := 0
	for ni in num_nodes:
		var iparent := nodes[index]
		var itype := nodes[index + 2]
		var iname := nodes[index + 3]
		var instance := nodes[index + 4]
		var nprops := nodes[index + 5]
		var node_path: String = ""
		var type := "" if instance != -1 else names[itype]
		var is_control := control_classes.has(type)
		if node_paths.size() > 0:
			if ni != 0:
				node_path = node_paths[ni - 1]
			iparent = -1
		index += 6
		var wclass: int = WINDOW_CLASSES.find(type)
		var title := ""
		if wclass != -1:
			title = WINDOW_DEFAULT_TITLE[wclass]
		var strings := PoolStringArray()
		for i in nprops:
			var iprop := nodes[index]
			var prop := names[iprop]
			if is_control and TEXT_TR_PROPS.has(prop):
				var text: String = variants[nodes[index + 1]]
				if text != "":
					strings.push_back(text)
			elif prop == "window_title" and wclass != -1:
				title = variants[nodes[index + 1]]
			elif prop == "items":
				var iclass: int = ITEMS_CLASSES.find(type)
				if iclass != -1:
					var a: Array = variants[nodes[index + 1]]
					strings.append_array(get_items_strings(a, ITEMS_INDEX[iclass]))
			index += 2
		if title != "":
			strings.push_back(title)
		var ngroups := nodes[index]
		index += 1
		var can_translate := true
		for ig in ngroups:
			var group: String = names[nodes[index]]
			if group == "notranslation":
				can_translate = false
			index += 1
		if not can_translate:
			continue
		for s in strings:
			keys[s] = []
		if type == "TabContainer":
			tabs.push_back(node_path)
			itabs.push_back(ni)
		if tabs.size() != 0:
			if iparent == -1:
				for it in tabs.size():
					if path_is_child(tabs[it], node_path):
						keys[names[iname]] = []
			elif itabs.has(iparent):
				keys[names[iname]] = []


func path_is_child(parent: String, child: String) -> bool:
	if child.begins_with(parent):
		var path := NodePath(child.trim_prefix(parent))
		if path.get_name_count() == 1:
			return true
	return false


func get_items_strings(a: Array, increment: int) -> PoolStringArray:
	var strings := PoolStringArray()
	for i in range(0, a.size(), increment):
		var s: String = a[i]
		if s != "":
			strings.push_back(s)
	return strings
