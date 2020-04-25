extends Control

func _ready():
  pass

func _unhandled_input(event):
  if(event.is_action("Shutdown")):
    Shutdown()
            
func Shutdown():
    get_tree().quit() 

func _on_Terrain_tile_hovering(tile_coordinates, tile_position):
  $CursorPosition.text = str(tile_coordinates)
  $CellSelector.position = tile_position
  
