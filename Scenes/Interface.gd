extends Control

signal movement_completed
signal explosion_completed

var terrain
var units

# Controls the camera zoom. Big number, big field of view
# (increase the level to zoom out).
var zoom_level = 1
const max_zoom_level = 3
const min_zoom_level = 0.5
const pan_step = 20

var cam_lim_top
var cam_lim_bottom

var rng = RandomNumberGenerator.new()

var g = preload("res://FreeScripts/Game.gd")
var colors_for_factions = {
  g.factions.RED: Color(1, 0.4, 0.4),
  g.factions.BLUE: Color(0.4, 0.4, 1),
 }
var color_for_highlight = Color(1, 1, 0)
var color_for_destruction = Color(0.2, 0.2, 0.2)
var color_for_warning = Color(1, 0.5, 0)
var colors_for_fire = {
  g.fire_outcome.MISS: Color(1, 0.4, 0.4),
  g.fire_outcome.INEFFECTIVE: color_for_warning,
  g.fire_outcome.DESTROYED: Color(0.4, 1, 0.4),
 }

func _ready():
  var root = get_tree().get_root()
  terrain = root.get_node("HexMap/Terrain")
  units = root.get_node("HexMap/Units")
  rng.randomize()
  
  compute_pan_limits()
  pan_up() # Ensure the camera gets re-positioned within the limits.


func get_action_label():
  return $Camera/L/Sidebar/Descriptions/VB/ActionResults

func animate_movement(unit, move_effect):
  $MovementPath.curve.clear_points()
  for p in move_effect.actual_path:
    var point_in_wc = terrain.cell_to_world(p)
    $MovementPath.curve.add_point(point_in_wc)
    
  var distance_to_cover = $MovementPath.curve.get_baked_length()
    
  units.remove_child(unit)
  var transporter = $MovementPath/PathFollow2D/Transporter

  transporter.reset_at_start(distance_to_cover, 120, "movement_animation_done", unit)  
  
  describe_movement_effect(move_effect)
  
func complete_movement_animation(moving_unit):
  units.add_child(moving_unit)
  moving_unit.set_rotation($MovementPath/PathFollow2D.get_rotation());
  moving_unit.set_position($MovementPath/PathFollow2D.get_position());
  emit_signal("movement_completed")
  
  
func describe_movement_effect(move_effect):
  if move_effect.final_result == g.movement_outcome.NO_MOVE_POINTS:
    var action_label = get_action_label()
    action_label.modulate = color_for_warning
    action_label.text = "Need more fuel!"
  
func animate_attack(attacker, target, outcome):
  attacker.rotate_turret_towards(target.position)
  
  $MovementPath.curve.clear_points()
  
  var attack_from = terrain.cell_to_world(terrain.where_is(attacker))
  var attack_to = terrain.cell_to_world(terrain.where_is(target))
  
  $Explosion.position = attack_to
  if outcome.final_result == g.fire_outcome.MISS:
    var fudge_angle = rng.randf_range(0, PI * 2)
    var fudge_vector = Vector2(30, 0).rotated(fudge_angle)
    $Explosion.position += fudge_vector
  
  $MovementPath.curve.add_point(attack_from)
  $MovementPath.curve.add_point($Explosion.position)
    
  var distance_to_cover = $MovementPath.curve.get_baked_length()
    
  var m = $Missile
  remove_child(m)
  $MovementPath/PathFollow2D/Transporter.reset_at_start(distance_to_cover, 500, "start_explosion_animation", m)  
  
  var message = "Missed!"
  if outcome.final_result != g.fire_outcome.MISS:
    var hit_name = g.armor_part.keys()[outcome.armor_part_hit]
    var result_name = g.fire_outcome.keys()[outcome.final_result]
    message = "{0} hit: {1}.".format([hit_name, result_name])
  
  var action_label = get_action_label()
  action_label.text = message
  action_label.modulate = colors_for_fire[outcome.final_result]
  
func animate_explosion(missile):
  add_child(missile)
  $Explosion/AnimationPlayer.play("ExplosionAnimation")
  emit_signal("explosion_completed")

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


func clear_movement_plot():
  $PlannedPath.clear_points ()
  
func plot_movement(path):  
  clear_movement_plot()
  
  var id = 0
  for point in path:
    $PlannedPath.add_point(terrain.cell_to_world(point), id)
    id += 1

 
func describe_cell(map_coordinates, distance, hit_probability):
  $CellCursor.position = terrain.cell_to_world(map_coordinates)
  
  var terrain_type = terrain.terrain_type_at(map_coordinates)
  var terrain_desc = "({0}, {1}) - {2}".format([map_coordinates.x, map_coordinates.y, terrain_type])
  $Camera/L/Sidebar/Descriptions/VB/CellDescription.text = terrain_desc
    
  var target = terrain.what_is_at(map_coordinates)
  var target_desc = ""
  if target != null:
    target_desc = target.type
    
    if target.alive == true:
      if distance != null:
        target_desc += ", %s hexes" % distance
      
      if hit_probability != null:
        target_desc += ", %s %%" % hit_probability
    else:
      target_desc += ", Destroyed."
      
  $Camera/L/Sidebar/Descriptions/VB/TargetDescription.text = target_desc
  
  
func mark_as_selected(unit):
  unit.get_node("Highlight").modulate =  color_for_highlight
  refresh_unit_description(unit)
  
func refresh_unit_description(unit):
  var unit_desc = "{0}, Moves {1}, shots {2}".format([unit.type, unit.move_points, unit.fire_points])
  $Camera/L/Sidebar/Descriptions/VB/UnitDescription.text = unit_desc
  
func no_fire_points():
  var action_label = get_action_label()
  action_label.modulate = color_for_warning
  action_label.text = "Must reload!"
  
func unmark(unit):
  # This must be dealth with by the unit itself: the color
  # depends on the faction it belongs to!
  unit.get_node("Highlight").modulate = colors_for_factions[unit.faction]
  $Camera/L/Sidebar/Descriptions/VB/UnitDescription.text = ""
  
func clear_action_descritpion():
  get_action_label().text = ""

func mark_destruction(unit):
  $Camera/L/Sidebar/Descriptions/VB/TargetDescription.text = ""
  unit.get_node("Highlight").modulate = color_for_destruction

func victory(winner):
  var message = "Battle finished: %s victory." % g.factions.keys()[winner]
  $Camera/L/VictoryBox/CenterContainer/VBoxContainer/Winner.text = message
  $Camera/L/VictoryBox.visible = true
  # And this is it: the box has a quit button, the only thing you can push.
