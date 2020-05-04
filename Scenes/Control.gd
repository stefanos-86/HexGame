extends Control

# This is the place where we deal with the input.

var Game = preload("res://FreeScripts//Game.gd")

var terrain
var units
var interface

var game = Game.new()

var selected_unit = null
var animation_in_progress = false
var target_to_destroy = null

var last_hovered_cell = null

func _ready():
  var root = get_tree().get_root()
  units = root.get_node("HexMap/Units")
  terrain = root.get_node("HexMap/Terrain")
  interface = root.get_node("HexMap/Interface")
  
  game.begin_game()
  interface.refresh_turn_info(game)
  

func _unhandled_input(event):
  if(event.is_action("Shutdown")):
    shutdown()
    
  # Block input when things are moving.
  # TODO: the input in the side bar has been already
  # handled!!! The signal will bypass this.
  if (animation_in_progress):
    return
    
  var just_pressed = event.is_pressed() and not event.is_echo()
    
  if(event.is_action("ZoomIn")):
    interface.zoom_in()
  elif (event.is_action("ZoomOut")):
    interface.zoom_out()
  elif (event.is_action("PanUp")):
    interface.pan_up()
  elif (event.is_action("PanDown")):
    interface.pan_down()
  elif (event.is_action("PanLeft")):
    interface.pan_left()
  elif (event.is_action("PanRight")):
    interface.pan_right()
  elif (event.is_action("NextTurn") and just_pressed):
    next_turn()
    
    
  if event is InputEventMouseMotion:
    var corrected_mouse_position = get_global_mouse_position()
    var hit = terrain.detect_cell_under_mouse(corrected_mouse_position)
    
    # Change the info only when needed, when a new cell is under the cursor.
    if (last_hovered_cell != hit): 
      last_hovered_cell = hit
      
      interface.put_cursor_at(hit)
      interface.clear_movement_plot()
 
      var distance = null
      var hit_probability = null
      
      if (selected_unit != null):
        var target = terrain.what_is_at(hit)
        if target != selected_unit:
          if target == null or target.alive == false:
            var planned_path = terrain.plot_unit_path(selected_unit, hit)
            interface.plot_movement(planned_path)
          else:
            if not target.belongs_to(game.current_player):
              distance = terrain.distance_between(selected_unit, target)
              hit_probability = game.hit_probability(selected_unit, target, distance)
          
      interface.describe_cell(hit, distance, hit_probability)
        

  if event is InputEventMouseButton:
    if event.is_pressed():
      interface.clear_action_descritpion()
      if event.button_index == BUTTON_LEFT:
        var corrected_mouse_position = get_global_mouse_position()
        var hit = terrain.detect_cell_under_mouse(corrected_mouse_position)
        if(selected_unit == null):
          select_unit_in_cell(hit)
        else:
          var target = terrain.what_is_at(hit)
          if target == null or target.alive == false:
            move_unit(selected_unit, hit)
          elif target.belongs_to(game.current_player):
            select_unit_in_cell(hit)
          else:
            shoot(selected_unit, target)
          
      if event.button_index == BUTTON_RIGHT:
        var corrected_mouse_position = get_global_mouse_position()
        turn_towards(corrected_mouse_position)
        
      if event.button_index == BUTTON_MIDDLE:
        unselect_current_unit()
        
      
func shutdown():
    get_tree().quit() 


func select_unit_in_cell(hit):
  var unit = terrain.what_is_at(hit)
      
  if unit != null and unit.alive and unit.belongs_to(game.current_player):
    unselect_current_unit()
    interface.mark_as_selected(unit)
    selected_unit = unit
     
func unselect_current_unit():
  if (selected_unit != null):
    interface.unmark(selected_unit)
  selected_unit = null

  
func move_unit(unit, destination):
  animation_in_progress = true
  var planned_path = terrain.plot_unit_path(unit, destination)
  
  var movement_result = game.movement(unit, planned_path, terrain)
  print (movement_result.actual_path)
  
  if movement_result.actual_path == []:
    animation_in_progress = false
  else:
    interface.animate_movement(unit, movement_result)
    interface.refresh_unit_description(unit)
    terrain.move(unit, movement_result.actual_path.back())

func reactivate_input():
  animation_in_progress = false

func shoot(attacker, target):
  if attacker.fire_points == 0:
    interface.no_fire_points()
    return
  
  var attack_result = game.fire(attacker, target, terrain)
  
  if attack_result.final_result == game.fire_outcome.OUT_OF_RANGE:
    interface.out_of_range()
    return
  
  animation_in_progress = true
  
  # Save the target to be erased after the animation is completed-
  # Everything else is a parameter of the signals, but I could not find
  # an easy way to pass everything around. I have to think of some
  # kind of method...
  if attack_result.final_result == game.fire_outcome.DESTROYED:
    target_to_destroy = target
    
  interface.refresh_unit_description(attacker)
  interface.animate_attack(attacker, target, attack_result)

func after_shoot():
  if target_to_destroy != null:
    target_to_destroy.mark_destruction()
    interface.mark_destruction(target_to_destroy)
    units.mark_destruction(target_to_destroy)
     
    var enemies_left = units.count_units_of(target_to_destroy.faction)
    if enemies_left == 0:
      animation_in_progress = true # Re-block input.
      interface.victory(game.current_player)
      return # End game, nothing left to do.
      
    target_to_destroy = null
  reactivate_input()

func turn_towards(position):
  if selected_unit != null:
    selected_unit.look_at(position)
    selected_unit.rotate_turret_towards(position)

func next_turn():
  unselect_current_unit()
  game.next_turn()
  units.reset_points_and_speed()
  interface.clear_action_descritpion()
  interface.clear_movement_plot()
  interface.refresh_turn_info(game)
