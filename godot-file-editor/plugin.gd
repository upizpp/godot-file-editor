tool
extends EditorPlugin


# 文本编辑器
const FileEditor = preload("res://addons/godot-file-editor/editor/FileEditor.tscn")
var file_editor : Control


func _enter_tree() -> void:
	# 生成文本编辑器
	file_editor = FileEditor.instance()
	get_editor_interface().get_editor_viewport().add_child(file_editor)
	make_visible(false)


func _exit_tree() -> void:
	# 删除文本编辑器
	if file_editor:
		file_editor.queue_free()


func _ready():
	# 初始化文本编辑器
	if file_editor:
		var dialog = EditorFileDialog.new()
		dialog.set_access(EditorFileDialog.ACCESS_RESOURCES)
		dialog.mode = EditorFileDialog.MODE_OPEN_FILES
		dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		file_editor.init(dialog)


func make_visible(visible : bool) -> void:
	# 设置文本编辑器的可见性
	if file_editor:
		file_editor.visible = visible
		if visible:
			file_editor.update_text()


func edit(object) -> void:
	if file_editor:
		if Input.is_action_pressed("ui_focus_prev"):
			file_editor.open(object.resource_path, true)
		else:
			file_editor.open(object.resource_path)
		make_visible(true)
		emit_signal("main_screen_changed", "File Editor")


func handles(object) -> bool:
	return object is Resource and not object is Texture and not object is AudioStream


func has_main_screen() -> bool:
	return true


# 主屏幕名
func get_plugin_name() -> String:
	return "File Editor"


# 主屏幕图标
func get_plugin_icon() -> Texture:
	return preload("icon_empty.png")

