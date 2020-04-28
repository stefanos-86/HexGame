extends Control

var factions = preload("res://FreeScripts/Factions.gd")

var terrain
var units

var moving_unit

var colors_for_factions = {
  factions.names.RED: Color(1, 0, 0),
  factions.names.BLUE: Color(0, 0, 1),
 }
var color_for_highlight = Color(1, 1, 0)

func _ready():
  var root = get_tree().get_root()
  terrain = root.get_node("HexMap/Terrain")
  units = root.get_node("HexMap/Units")

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

func animate_movement(unit, path):
  $MovementPath.curve.clear_points()
  for p in path:
    var point_in_wc = terrain.cell_to_world(p)
    $MovementPath.curve.add_point(point_in_wc)
    
  var distance_to_cover = $MovementPath.curve.get_baked_length()
    
  units.remove_child(unit)
  var transporter = $MovementPath/PathFollow2D/Transporter
  unit.position = Vector2(0, 0)
  transporter.add_child(unit)
  moving_unit = unit # Store it so we can get it back in the animation callback.
  transporter.reset_at_start(distance_to_cover)  
  
func _on_Transporter_movement_animation_done(unit):
  units.add_child(moving_unit)
