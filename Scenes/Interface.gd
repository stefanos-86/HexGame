extends Control


var terrain
var units

var moving_unit

# Controls the camera zoom. Big number, big field of view
# (increase the level to zoom out).
var zoom_level = 1
const max_zoom_level = 3
const min_zoom_level = 0.5
const pan_step = 20

var cam_lim_top
var cam_lim_bottom

var g = preload("res://FreeScripts/Game.gd")
var colors_for_factions = {
  g.factions.RED: Color(1, 0.4, 0.4),
  g.factions.BLUE: Color(0.4, 0.4, 1),
 }
var color_for_highlight = Color(1, 1, 0)

func _ready():
  var root = get_tree().get_root()
  terrain = root.get_node("HexMap/Terrain")
  units = root.get_node("HexMap/Units")
  
  compute_pan_limits()
  pan_up() # Ensure the camera gets re-positioned within the limits.

  
func describe_cell(map_coordinates):
  $CellCursor.position = terrain.cell_to_world(map_coordinates)
  
  var terrain_type = terrain.terrain_type_at(map_coordinates)
  var terrain_desc = "({0}, {1}) - {2}".format([map_coordinates.x, map_coordinates.y, terrain_type])
  $Camera/L/Sidebar/Descriptions/VB/CellDescription.text = terrain_desc
  
  
  var unit = terrain.what_is_at(map_coordinates)
  
  var unit_description = "No one is there."
  if unit != null:
    unit_description = str(unit.name) + " " + unit.unit_name
  
  #$Camera/L/Sidebar/CellDescription.text = str(map_coordinates) + " " + unit_description
  
  
  
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
  unit.set_rotation(0)
  transporter.add_child(unit)
  moving_unit = unit # Store it so we can get it back in the animation callback.
  transporter.reset_at_start(distance_to_cover, 120)  
  
func _on_Transporter_movement_animation_done():
  if (moving_unit == $MovementPath/PathFollow2D/Transporter/Missile):
    moving_unit.set_visible(false)
  else:
    var transporter = $MovementPath/PathFollow2D/Transporter
    transporter.remove_child(moving_unit)
    units.add_child(moving_unit)
    moving_unit.set_rotation($MovementPath/PathFollow2D.get_rotation());
    moving_unit.set_position($MovementPath/PathFollow2D.get_position());
    moving_unit = null
  
func animate_attack(fire_path):
  $MovementPath.curve.clear_points()
  for p in fire_path:
    var point_in_wc = terrain.cell_to_world(p)
    $MovementPath.curve.add_point(point_in_wc)
    
  var distance_to_cover = $MovementPath.curve.get_baked_length()
    
  var missile = $MovementPath/PathFollow2D/Transporter/Missile
  missile.set_position(Vector2(0, 0))
  missile.set_rotation(0)
  missile.set_visible(true)
  moving_unit = missile
  $MovementPath/PathFollow2D/Transporter.reset_at_start(distance_to_cover, 300)  

func zoom_out():
  change_zoom(1.1)
 
func zoom_in():
  change_zoom(0.9)
  
func change_zoom(multiplier):
  zoom_level *= multiplier
  zoom_level = clamp(zoom_level, min_zoom_level, max_zoom_level)
  $Camera.zoom = Vector2(zoom_level, zoom_level)  

func pan_up():
  pan(0, -pan_step)

func pan_down():
  pan(0, pan_step)
  
func pan_left():
  pan(-pan_step, 0)

func pan_right():
  pan(pan_step, 0)

func pan(x, y):
  var future_position = $Camera.position + Vector2(x, y) * zoom_level # Go fast when zoom out.
  
  # The field of view won't go past the limits, but the
  # camera pivot point would keep moving. So the pivot has
  # smaller limits to move.
  var zoom_factor = clamp(zoom_level, min_zoom_level, 1) # Avoid crossing the clamping limit when zooming out.
  var half_screen = get_viewport().size * zoom_factor / 2
  
  future_position.x = clamp(future_position.x, cam_lim_bottom.x + half_screen.x, cam_lim_top.x - half_screen.x)
  future_position.y = clamp(future_position.y, cam_lim_bottom.y + half_screen.y, cam_lim_top.y - half_screen.y)
  
  $Camera.position = future_position
  
func compute_pan_limits():
  var map_extent = terrain.bounding_box 
  var min_extent = terrain.cell_to_world(map_extent.position)
  var max_extent = terrain.cell_to_world(map_extent.end)
  
  var covered_by_sidebar = $Camera/L/Sidebar.rect_size.x

  cam_lim_bottom = Vector2(min_extent.x, min_extent.y)
  cam_lim_top = Vector2(max_extent.x + covered_by_sidebar, max_extent.y)

func refresh_turn_info(game):
  var player = game.current_player_name()
  var turn = game.turn_count
  var color = colors_for_factions[game.current_player]
  var turn_info = "Turn {0} - {1}.".format([turn, player])
  
  $Camera/L/Sidebar/Turn.modulate = color
  $Camera/L/Sidebar/Turn/TurnInformation.text = turn_info
