extends Control

# This is the place where we deal with the input.

var terrain
var units


func _ready():
  var root = get_tree().get_root()
  units = root.get_node("HexMap/Units")
  terrain = root.get_node("HexMap/Terrain")

func _unhandled_input(event):
  if(event.is_action("Shutdown")):
    Shutdown()
    
  if event is InputEventMouseMotion:
    terrain.detect_cell_under_mouse(event.position)
    
  if (event is InputEventMouseButton):
    if event.is_pressed():
      pass  # Must track current cell. Must ask what is in it. Must select that unit.
            
func Shutdown():
    get_tree().quit() 

func _on_Terrain_tile_hovering(tile_coordinates, tile_position):
  var unit = terrain.what_is_at(tile_coordinates)
  
  var unit_description = "No one is there."
  if unit != null:
    unit_description = str(unit)
  
  $CursorPosition.text = str(tile_coordinates) + " " + unit_description
  $CellSelector.position = tile_position
  
