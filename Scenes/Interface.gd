extends Control

var factions = preload("res://FreeScripts/Factions.gd")

var terrain

var colors_for_factions = {
  factions.names.RED: Color(1, 0, 0),
  factions.names.BLUE: Color(0, 0, 1),
 }
var color_for_highlight = Color(1, 1, 0)

func _ready():
  var root = get_tree().get_root()
  terrain = root.get_node("HexMap/Terrain")

func describe_cell(cell_coordinates):
  var unit = terrain.what_is_at(cell_coordinates)
  
  var unit_description = "No one is there."
  if unit != null:
    unit_description = str(unit.name) + " " + unit.unit_name
  
  $CellDescription.text = str(cell_coordinates) + " " + unit_description
  $CellCursor.position = terrain.cell_to_world(cell_coordinates)
  
  
func mark_as_selected(unit):
  # I could keep the highlight in the interface, but
  # I believe it is more practial this way.
  # Every unit has to have a marker...
  unit.get_node("Highlight").modulate =  color_for_highlight
    
func unmark(unit):
  # This must be dealth with by the unit itself: the color
  # depends on the faction it belongs to!
  unit.get_node("Highlight").modulate = colors_for_factions[unit.faction]

func plot_movement(path):  
  $PlannedPath.clear_points ()
  
  var id = 0
  for point in path:
    $PlannedPath.add_point(terrain.cell_to_world(point), id)
    id += 1
