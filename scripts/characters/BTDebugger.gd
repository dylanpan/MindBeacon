class_name BTDebugger
extends Control

@onready var tree_container: Tree = $Tree
@onready var status_label: Label = $StatusLabel

var bt_root: BehaviorTreeRoot = null
var tree_items: Dictionary = {}  # BTNode -> TreeItem

func _ready():
	visible = false

func attach_to_bt_root(root: BehaviorTreeRoot):
	bt_root = root
	build_tree_display()
	root.connect("tree_updated", Callable(self, "_on_tree_updated"))

func build_tree_display():
	tree_container.clear()
	tree_items.clear()
	
	if not bt_root:
		return
	
	var root_item = tree_container.create_item()
	root_item.set_text(0, "Behavior Tree Root")
	tree_items[bt_root] = root_item
	
	_build_tree_recursive(bt_root, root_item)

func _build_tree_recursive(node: BTNode, parent_item: TreeItem):
	for child in node.get_children():
		if child is BTNode:
			var item = tree_container.create_item(parent_item)
			item.set_text(0, child.name + " (" + _get_status_text(child.status) + ")")
			tree_items[child] = item
			_build_tree_recursive(child, item)

func _on_tree_updated():
	update_status_display()

func update_status_display():
	if not bt_root:
		return
	
	for node in tree_items.keys():
		var item = tree_items[node]
		item.set_text(0, node.name + " (" + _get_status_text(node.status) + ")")
	
	status_label.text = "Tree Status: " + _get_status_text(bt_root.status)

func _get_status_text(status: BTNode.BTStatus) -> String:
	match status:
		BTNode.BTStatus.RUNNING:
			return "Running"
		BTNode.BTStatus.SUCCESS:
			return "Success"
		BTNode.BTStatus.FAILED:
			return "Failed"
	return "Unknown"

func toggle_visibility():
	visible = !visible
	if visible:
		update_status_display()
