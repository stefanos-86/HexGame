extends Control

# This is the place where we deal with the input.

var Game = preload("res://FreeScripts//Game.gd")

var terrain
var units
var interface

var game = Game.new()

var selected_unit = null
var animation_in_progress = false

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
    # corrected_mouse_position = event.position
    var hit = terrain.detect_cell_under_mouse(corrected_mouse_position)
    interface.describe_cell(hit)
    if (selected_unit != null): # TODO ... and the current cell did not change
      var target = terrain.what_is_at(hit)
      if (target == null):
        var planned_path = terrain.plot_unit_path(selected_unit, hit)
        interface.plot_movement(planned_path)
    
  # What you do on a click will, eventually 
  # depend on what is under the cursor and the status.
  if (event is InputEventMouseButton):
    if event.is_pressed():
      if event.button_index == BUTTON_LEFT:
        var corrected_mouse_position = get_global_mouse_position()
        var hit = terrain.detect_cell_under_mouse(corrected_mouse_position)
        if(selected_unit == null):
          select_unit_in_cell(hit)
        else:
          var target = terrain.what_is_at(hit)
          if (target == null):
            move_unit(selected_unit, hit)
          else:
            shoot(selected_unit, target)
          
      if event.button_index == BUTTON_RIGHT:
        unselect_current_unit()
        
      
func shutdown():
    get_tree().quit() 


func select_unit_in_cell(hit):
  unselect_current_unit()
  
  var unit = terrain.what_is_at(hit)
      
  if (unit != null):
    interface.mark_as_selected(unit)
    selected_unit = unit
     
func unselect_current_unit():
  if (selected_unit != null):
    interface.unmark(selected_unit)
  
  selected_unit = null

  
func move_unit(unit, destination):
  animation_in_progress = true
  var planned_path = terrain.plot_unit_path(unit, destination)
  interface.animate_movement(unit, planned_path)
  terrain.move(unit, destination)

func _on_Transporter_movement_animation_done():
  animation_in_progress = false

func shoot(attacker, target):
  animation_in_progress = true
  var attack_from = terrain.where_is(attacker)
  var attack_to = terrain.where_is(target)
  var bullet_path = [attack_from, attack_to]
  interface.animate_attack(bullet_path)
  # TODO: remove target from map at the end of the animation...
  # May use another transporter or a different signal to know
  # what to do post-animation. Or bake the target removal
  # in the animation.

func next_turn():
  game.next_turn()
  interface.refresh_turn_info(game)
