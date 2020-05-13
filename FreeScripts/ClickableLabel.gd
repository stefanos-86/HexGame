extends Label

# The Label class does not have a "pressed" signal
# like a button. But it can react and filter
# the events anyway. In this case, convert the click
# in a custom signal and ignore everything else.

signal label_clicked

func _enter_tree():
    mouse_filter = MOUSE_FILTER_STOP
    connect("gui_input", self, "handle_input")
    
func handle_input(event):
  if event is InputEventMouseButton:
    emit_signal("label_clicked")
