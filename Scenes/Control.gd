extends Control

# This is the place where we deal with the input.

var terrain
var units
var interface

var selected_unit = null

func _ready():
  var root = get_tree().get_root()
  units = root.get_node("HexMap/Units")
  terrain = root.get_node("HexMap/Terrain")
  interface = root.get_node("HexMap/Interface")

func _unhandled_input(event):
  if(event.is_action("Shutdown")):
    Shutdown()
    
  if event is InputEventMouseMotion:
    var hit = terrain.detect_cell_under_mouse(event.position)
    interface.describe_cell(hit)
    if (selected_unit != null): # TODO ... and the current cell did not change
      print("pathfinding")
      var planned_path = terrain.plot_unit_path(selected_unit, hit)
      interface.plot_movement(planned_path)
    
  # What you do on a click will, eventually 
  # depend on what is under the cursor and the status.
  if (event is InputEventMouseButton):
    if event.is_pressed():
      if event.button_index == BUTTON_LEFT:
          select_unit_in_cell(event.position)
          
      if event.button_index == BUTTON_RIGHT:
        unselect_current_unit()
        
      
func Shutdown():
    get_tree().quit() 


func select_unit_in_cell(mouse_position):
  unselect_current_unit()
  
  var hit = terrain.detect_cell_under_mouse(mouse_position)
  var unit = terrain.what_is_at(hit)
      
  if (unit != null):
    interface.mark_as_selected(unit)
    selected_unit = unit
     
func unselect_current_unit():
  if (selected_unit != null):
    interface.unmark(selected_unit)
  
  selected_unit = null

  
