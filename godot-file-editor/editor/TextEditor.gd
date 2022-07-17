tool
extends TextEdit


signal type(ch, backspace)


export(Array, Array, String) var regions
export(PoolStringArray) var filter_keys
export(Array, PoolStringArray) var texts


const Colors = {
	"String" : Color(1, 0.92549, 0.631373),
	"Exegesis" : Color(0.8, 0.807843, 0.827451, 0.501961),
	"Keyword" : Color(1, 0.439216, 0.521569)
}


# ----- Drop File -----
func can_drop_data(position, data):
	if readonly:
		return false
	if data is Dictionary:
		match data["type"]:
			"files":
				return true
			"files_and_dirs":
				return true
			"nodes":
				return true
			"obj_property":
				return true
	return false


func drop_data(position, data):
	match data["type"]:
		"files", "files_and_dirs": # 插入文件路径
			
			for i in data["files"].size():
				insert_text_at_cursor("\"%s\"" % data["files"][i])
				if i < data["files"].size() - 1:
					insert_text_at_cursor(", ")
		"nodes": # 插入节点相对于场景根节点的路径
			var message = ""
			for i in data.nodes.size():
				var path = data.nodes[i]
				var root_path = str(path).substr(0, str(path).find("/", 138))
				var root = get_node(root_path)
				var path_to_root = root.get_path_to(get_node(path))
				message += "\"%s\"" % path_to_root
				if (i < data.nodes.size() - 1):
					message += ", "
			insert_text_at_cursor(message)
		"obj_property": # 插入值路径
			insert_text_at_cursor("\"%s\"" % data["property"])


# ----- 覆盖函数 -----
func _ready():
	add_keyword_color("true", Colors.Keyword)
	add_keyword_color("false", Colors.Keyword)
	add_color_region("\"", "\"", Colors.String)
	add_color_region("\'", "\'", Colors.String)


# ----- 自动补全 -----
func _gui_input(event):
	if event is InputEventKey and event.pressed:
		var text = event.as_text()
		if text in filter_keys:
			return
		if "Control" in text or "Alt" in text:
			return
		var is_backspace = text == "BackSpace"
		if text != "BackSpace":
			text = to_char(text)
			yield(self, "text_changed")
		else:
			text = get_current_char()
		emit_signal("type", text, is_backspace)


func _on_type(ch, backspace : bool):
	if ch == null:
		return
	for i in regions:
		if ch == i[0]:
			if backspace == true:
				var line = get_line(cursor_get_line())
				if not (cursor_get_column() < line.length()):
					continue
				if line[cursor_get_column()] == i[1]:
					line.erase(cursor_get_column(), 1)
				set_line(cursor_get_line(), line)
			else:
				insert_text_at_cursor(i[1])
				cursor_set_column(cursor_get_column() - 1)
				return


func to_char(text : String):
	for i in texts:
		if text == i[0]:
			return i[1]
	return null


func get_current_char():
	var line := get_line(cursor_get_line())
	return line[cursor_get_column() - 1] if not line.empty() else null
