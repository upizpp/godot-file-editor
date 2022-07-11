tool
extends VBoxContainer


signal init


# file_button id
enum FILE{
	NEW,
	A,
	OPEN,
	SAVE,
	SAVE_AS,
	B,
	CHECK_ERROR
}
# edit_button id
enum EDIT{
	UNDO,
	REDO,
	A,
	SELECT_ALL,
	B,
	COPY,
	CUT,
	PASTE
}


const DataPath = "user://FE_data.bin"
const Password = "namespace:upizpp"


# 获取节点
onready var file_button = $HeadHBoxContainer/FileMenuButton
onready var edit_button = $HeadHBoxContainer/EditMenuButton
onready var editor = $TextEditor
onready var editor_tip = $TextEditor/Tip
onready var tabs = $FileTabs
onready var file_path = $HeadHBoxContainer/FilePath


# 文件选择器
var file_dialog : EditorFileDialog


# 已创建文件数
var file_count = 0
# 选择的id
var select_id := -1
# 打开的文件
var files := []


# ----- 自定义函数 -----
func init(dialog : EditorFileDialog) -> void:
	# 初始化file dialog
	# 获取file dialog
	file_dialog = dialog
	if file_dialog.get_parent():
		file_dialog.get_parent().remove_child(file_dialog)
	add_child(file_dialog)
	# 连接信号
	file_dialog.connect("file_selected", self, "_on_file_dialog_file_selected")
	file_dialog.connect("files_selected", self, "_on_file_dialog_files_selected")
	
	
	# 初始化head
	file_button.get_popup().connect("id_pressed", self, "_on_file_button_id_pressed")
	edit_button.get_popup().connect("id_pressed", self, "_on_edit_button_id_pressed")
	
	# 初始化文本输入框
	if files.size() <= 0:
		hide_editor()
	
	# 加载储存数据
	load_files()
	
	emit_signal("init")


func _exit_tree():
	save_files()


# 加载储存数据
func load_files() -> void:
	var file := File.new()
	if not file.file_exists(DataPath):
		save_files()
		return
	file.open_encrypted_with_pass(DataPath, File.READ, Password)
	var data = file.get_buffer(file.get_len())
	var paths = bytes2var(data)
	
	for path in paths:
		open(path)
	
	file.close()


# 储存数据
func save_files() -> void:
	var paths := PoolStringArray()
	for f in files:
		paths.push_back(f.path)
	var file := File.new()
	file.open_encrypted_with_pass(DataPath, File.WRITE, Password)
	file.store_buffer(var2bytes(paths))
	file.close()


# 新建文件
func new():
	file_count += 1
	var filename = "未命名%d" % file_count
	push_file("", "", filename)
	
	# 更新tab
	tabs.add_tab(filename)
	tabs.set_current_tab(tabs.get_tab_count() - 1)
	tabs.emit_signal("tab_changed", tabs.get_tab_count() - 1)
	
	# 更新文本输入框
	show_editor()


# 打开文件
func open(path : String):
	var file = File.new()
	var error = file.open(path, File.READ)
	if error != OK:
		return error
	push_file(path, file.get_as_text())
	
	# 更新tab
	tabs.add_tab(path.get_file())
	tabs.set_current_tab(tabs.get_tab_count() - 1)
	tabs.emit_signal("tab_changed", tabs.get_tab_count() - 1)
	
	# 更新文本输入框
	show_editor()
	
	return OK


# 保存文件
func save(path : String, text : String):
	var file = File.new()
	var error = file.open(path, File.WRITE)
	if error != OK:
		return error
	
	file.store_string(text)
	
	set_file_current(tabs.current_tab, false)
	
	return OK


# 隐藏文本输入框
func hide_editor():
	editor.text = ""
	editor.readonly = true
	editor_tip.show()


# 显示文本输入框
func show_editor():
	editor.readonly = false
	editor_tip.hide()


# 设置文件的current
func set_file_current(index, current):
	files[index].current = current
	if current:
		tabs.set_tab_title(index, "* " + files[index].filename)
	else:
		tabs.set_tab_title(index, files[index].filename)


# 将文件存入数组
func push_file(path : String, text : String, filename : String = ""):
	files.push_back({
		"path" : path,																			# 路径
		"text" : text,																			# 文本
		"filename" : filename if not filename.empty() else get_filename_from_path(path),		# 文件名
		"changed" : false,																		# 已更改
		"cursor" : Vector2.ZERO																	# 光标位置
	})


# 从路径获取xxx.xxx的文件名
func get_filename_from_path(path : String) -> String:
	var filename = path.get_file()
	var extension = path.get_extension()
	return "%s.%s" % [filename, extension] if not "." in filename else filename


# ----- 信号 -----

# 当按下【文件】按钮时
func _on_file_button_id_pressed(id : int):
	
	# 匹配id
	match id:
		FILE.NEW:
			new()
		FILE.OPEN:
			file_dialog.popup_centered(Vector2(1000, 800))
			file_dialog.mode = EditorFileDialog.MODE_OPEN_FILES
		FILE.SAVE:
			if files.empty():
				return
			var path = files[tabs.current_tab].path
			if not path.empty():
				save(path, files[tabs.current_tab].text)
			else:
				file_dialog.popup_centered(Vector2(1000, 800))
			file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
		FILE.SAVE_AS:
			if files.empty():
				return
			file_dialog.popup_centered(Vector2(1000, 800))
			file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
		FILE.CHECK_ERROR:
			pass
	
	# 记录id
	select_id = id


# 当按下【编辑】按钮时
func _on_edit_button_id_pressed(id : int):
	# 匹配id
	match id:
		EDIT.UNDO:
			editor.undo()
		EDIT.REDO:
			editor.redo()
		EDIT.SELECT_ALL:
			editor.select_all()
		EDIT.COPY:
			editor.copy()
		EDIT.CUT:
			editor.cut()
		EDIT.PASTE:
			editor.paste()


# 当玩家选择文件时
func _on_file_dialog_file_selected(path : String):
	match select_id:
		FILE.SAVE, FILE.SAVE_AS:
			files[tabs.current_tab].path = path
			files[tabs.current_tab].filename = path.get_file()
			save(path, files[tabs.current_tab].text)


func _on_file_dialog_files_selected(paths : PoolStringArray):
	match select_id:
		FILE.OPEN:
			for path in paths:
				open(path)


func _on_FileTabs_tab_close(tab):
	tabs.remove_tab(tab)
	files.remove(tab)
	if files.size() > 0:
		tabs.emit_signal("tab_changed", tabs.get_tab_count() - 1)
	else:
		hide_editor()


func _on_FileTabs_tab_changed(tab):
	# 更新文本
	editor.clear_undo_history()
	editor.text = files[tab].text
	file_path.text = files[tab].path
	editor.cursor_set_column(files[tabs.current_tab].cursor.x)
	editor.cursor_set_line(files[tabs.current_tab].cursor.y)


func _on_TextEditor_text_changed():
	set_file_current(tabs.current_tab, true)
	files[tabs.current_tab].text = editor.text


func _on_TextEditor_cursor_changed():
	if tabs.current_tab >= 0 and tabs.current_tab < files.size() and files.size() != 0:
		files[tabs.current_tab].cursor = Vector2(
			editor.cursor_get_column(),
			editor.cursor_get_line()
		)


func _on_TextEditor_gui_input(event):
	if event is InputEventKey and event.pressed:
		match event.as_text():
			"Control+N":
				_on_file_button_id_pressed(FILE.NEW)
			"Control+S":
				_on_file_button_id_pressed(FILE.SAVE)
			"Control+O":
				_on_file_button_id_pressed(FILE.OPEN)
			"Control+Shift+s":
				_on_file_button_id_pressed(FILE.SAVE_AS)
