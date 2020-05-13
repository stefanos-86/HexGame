extends Control

# This is the place where we deal with the input.

var Game = preload("res://FreeScripts//Game.gd")

var terrain
var units
var interface

var game = Game.new()

var selected_unit = null
var selected_cannon = null
var animation_in_progress = false
var target_to_destroy = null

var last_hovered_cell = null

enum mouse_states {COMBAT, ARTILLERY}
var mouse_state = mouse_states.COMBAT

func _ready():
  var root = get_tree().get_root()
  units = root.get_node("HexMap/Units")
  terrain = root.get_node("HexMap/Terrain")
  interface = root.get_node("HexMap/Interface")

  game.begin_game()
  interface.refresh_turn_info(game)
  unselect_current_unit()
  update_unit_list()

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
  elif (event.is_action("PlotArtillery") and just_pressed):
    plot_artillery()
    
    
  if event is InputEventMouseMotion:
    var corrected_mouse_position = get_global_mouse_position()
    var hit = terrain.detect_cell_under_mouse(corrected_mouse_position)
    
    # Change the info only when needed, when a new cell is under the cursor.
    if (last_hovered_cell != hit): 
      last_hovered_cell = hit
      
      interface.put_cursor_at(hit)
      interface.clear_movement_plot()
      
      if (mouse_state == mouse_states.COMBAT):
        combat_mouse_hover(hit)
        
      if (mouse_state == mouse_states.ARTILLERY):
        artillery_mouse_hover(hit)
        

  if event is InputEventMouseButton:
    if event.is_pressed():
      interface.clear_action_descritpion()
      
      if (mouse_state == mouse_states.COMBAT):
        combat_mouse_click(event)
        
      if (mouse_state == mouse_states.ARTILLERY):
        artillery_mouse_click(event)
      
        
func combat_mouse_click(event):
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
 
func artillery_mouse_click(event):   
  if event.button_index == BUTTON_LEFT:
    var corrected_mouse_position = get_global_mouse_position()
    var hit = terrain.detect_cell_under_mouse(corrected_mouse_position) 
    complete_artillery_plot(hit)
    
    
  if event.button_index == BUTTON_RIGHT: 
    plot_artillery()  # Restart plotting from scratch.
        
func combat_mouse_hover(hit):
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
      
      
func artillery_mouse_hover(hit):
  interface.describe_cell_artillery(hit, selected_cannon)
      
func shutdown():
    get_tree().quit() 


func select_unit_in_cell(hit):
  var unit = terrain.what_is_at(hit)
  select_unit(unit)
    
func select_unit(unit):
  if unit != null and unit.alive and unit.belongs_to(game.current_player):
    unselect_current_unit()
    interface.mark_as_selected(unit)
    selected_unit = unit
    update_unit_list()
    interface.allow_selected_unit_actions()
     
func unselect_current_unit():
  if (selected_unit != null):
    interface.unmark(selected_unit)
    interface.clear_movement_plot()
  selected_unit = null
  update_unit_list()
  interface.disable_selected_unit_actions()

  
func move_unit(unit, destination):
  animation_in_progress = true
  var planned_path = terrain.plot_unit_path(unit, destination)
  
  var movement_result = game.movement(unit, planned_path, terrain)
  
  if movement_result.actual_path == []:
    animation_in_progress = false
  else:
    interface.animate_movement(unit, movement_result)
    interface.refresh_unit_description(unit)
    terrain.move(unit, movement_result.actual_path.back())
  
  update_unit_list()

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
  update_unit_list() # Reaction fire or artillery friendly fire, or end of ammo.
  reactivate_input()
  

func turn_towards(position):
  if selected_unit != null:
    selected_unit.look_at(position)
    selected_unit.rotate_turret_towards(position)

func next_turn():
  artillery_plot_done()  # In case the window is still open!
  unselect_current_unit()
  game.next_turn()
  update_unit_list()
  units.reset_points_and_speed(game.current_player)
  units.progress_fire_missions(game.current_player)
  interface.clear_action_descritpion()
  interface.clear_movement_plot()
  interface.refresh_turn_info(game)
  
  var artillery_effects = game.fire_artillery(units.ready_fire_missions(game.current_player), terrain)
  for outcome in artillery_effects:
    
    print ("Before call ", OS.get_ticks_msec())
    yield(interface.animate_artillery(outcome), "completed")
    
    print ("After call ", OS.get_ticks_msec())
    target_to_destroy = outcome.destroyed_target
    after_shoot()
    
  units.clear_executed_fire_missions(game.current_player)
  

func plot_artillery():
  animation_in_progress = true # Block the input on the map.
  
  var cannons = units.available_fire_support(game.current_player)
  interface.show_artillery_box(cannons, self)
  
func cannon_targeting(cannon):
  mouse_state = mouse_states.ARTILLERY
  selected_cannon = cannon
  interface.close_artillery_box()
  animation_in_progress = false


func artillery_plot_done():
  interface.close_artillery_box()
  mouse_state = mouse_states.COMBAT
  animation_in_progress = false


func complete_artillery_plot(target_cell):
  animation_in_progress = true
  selected_cannon.plot_fire_mission(target_cell)
  plot_artillery()
  
func cancel_fire_mission(cannon):
  cannon.cancel_fire_mission()
  plot_artillery()


func update_unit_list():
  var list = units.order_of_battle_of(game.current_player)
  interface.unit_list(list, self, selected_unit)


func center_on_unit():
  if selected_unit != null:
    var position = terrain.where_is(selected_unit)
    interface.pan_to_cell(position)


func change_fire_stance(id):
  if selected_unit != null:
    selected_unit.fire_stance = id


func change_move_stance(id):
  if selected_unit != null:
    selected_unit.movement_stance = id
