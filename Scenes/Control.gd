extends Control

# This is the place where we deal with the input.

var Game = preload("res://FreeScripts//Game.gd")

var terrain
var units
var interface

var game = Game.new()

var selected_unit = null
var selected_cannon = null
var input_blocked = false

var last_hovered_cell = null

enum mouse_states {COMBAT, ARTILLERY}
var mouse_state = mouse_states.COMBAT

func _ready():
  var root = get_tree().get_root()
  units = root.get_node("HexMap/Units")
  terrain = root.get_node("HexMap/Terrain")
  interface = root.get_node("HexMap/Interface")

  units.reset_points_and_speed(game.factions.BLUE)
  units.reset_points_and_speed(game.factions.RED)
  
  for unit in units.all_units():
    interface.unmark(unit) # Also forces the faction color.
  
  game.begin_game()
  interface.refresh_turn_info(game)
  unselect_current_unit()
  update_unit_list()


func _unhandled_input(event):
  if(event.is_action("Shutdown")):
    shutdown()
    
  if input_blocked:
    return
    
  # Ensure to act only once on certain keys.
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
    # Change the info only when needed, when a new cell is under the cursor.
    var hit = clicked_cell()
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
 

func activate_input():
  input_blocked = false
  disable_widgets(false)
  
  
func block_input():
  input_blocked = true
  disable_widgets(true)

   
func disable_widgets(state):
  var widgets = get_tree().get_nodes_in_group("input_to_block")
  for w in widgets:
    w.disabled = state
  
  
func clicked_cell():
  var corrected_mouse_position = get_global_mouse_position()
  return  terrain.detect_cell_under_mouse(corrected_mouse_position)
   
       
func combat_mouse_click(event):
  if event.button_index == BUTTON_LEFT:
    var hit = clicked_cell()
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
    var hit = clicked_cell()
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
    selected_unit = unit
    update_unit_list()
    interface.mark_as_selected(unit)
    interface.allow_selected_unit_actions()
    
     
func unselect_current_unit():
  if (selected_unit != null):
    interface.unmark(selected_unit)
    selected_unit = null
    interface.clear_movement_plot()
    update_unit_list()
    interface.disable_selected_unit_actions()

  
func move_unit(unit, destination):
  block_input()
  
  var planned_path = terrain.plot_unit_path(unit, destination)
  var movement_result = game.movement(unit, planned_path, terrain)
  
  if movement_result.actual_path != []:
    interface.animate_movement(unit, movement_result)
    yield(interface, "movement_completed")
    
    interface.refresh_unit_description(unit)
    terrain.move(unit, movement_result.actual_path.back())
  
  update_unit_list()
  activate_input()

  
func shoot(attacker, target):
  var attack_result = game.fire(attacker, target, terrain)
  
  if attack_result.final_result == game.fire_outcome.OUT_OF_RANGE:
    interface.out_of_range()
    return
    
  if attack_result.final_result == game.fire_outcome.NO_FIRE_POINTS:
    interface.no_fire_points()
    return
  
  block_input()
    
  interface.refresh_unit_description(attacker)
  interface.animate_attack(attacker, target, attack_result)
  yield(interface, "attack_completed")
  
  after_shoot(attack_result)
  update_unit_list()
  
  var opponents = units.enemies_of(attacker)
  var counter_attacks = game.reaction_fire(attacker, target, terrain, opponents)
  
  for reaction in counter_attacks:
    if reaction.final_result == game.fire_outcome.NO_FIRE_POINTS:
      continue
    
    if reaction.final_result == game.fire_outcome.OUT_OF_RANGE:
      continue
    
    interface.animate_attack(reaction.shooter, attacker, reaction)
    yield(interface, "attack_completed")
    
    if reaction.final_result == game.fire_outcome.DESTROYED:
      unselect_current_unit() # The attacker must be the current unit.
    
    after_shoot(reaction)
    update_unit_list()
    
  activate_input()
  

func after_shoot(attack_result):
  if attack_result.final_result == game.fire_outcome.DESTROYED:
    attack_result.target.mark_destruction()
    interface.mark_destruction(attack_result.target)
     
    if halt_if_defeat_of(attack_result.target.faction):
      return # End game, nothing left to do.
  
  
func halt_if_defeat_of(opposite_faction):
    var enemies_left = units.count_remaining_units_of(opposite_faction)
    if enemies_left == 0:
      block_input()
      interface.victory(game.current_player)
      return true
    
    return false


func turn_towards(position):
  if selected_unit != null:
    selected_unit.look_at(position)


func next_turn():
  block_input()
  artillery_plot_done()  # In case the window is still open!
  unselect_current_unit()
  game.next_turn()
  units.reset_points_and_speed(game.current_player)
  units.progress_fire_missions(game.current_player)
  interface.clear_action_descritpion()
  interface.clear_movement_plot()
  interface.refresh_turn_info(game)
  update_unit_list()
  
  var artillery_effects = game.fire_artillery(units.ready_fire_missions(game.current_player), terrain)
  for outcome in artillery_effects:
    yield(interface.animate_artillery(outcome), "completed")
    after_shoot(outcome)
    update_unit_list()
    
  units.clear_executed_fire_missions(game.current_player)
  activate_input()


func plot_artillery():
  block_input()
  var cannons = units.available_fire_support(game.current_player)
  interface.show_artillery_box(cannons, self)
  
  
func cannon_targeting(cannon):
  mouse_state = mouse_states.ARTILLERY
  selected_cannon = cannon
  interface.close_artillery_box()
  activate_input()
  disable_widgets(true) # Allow only the mouse.


func artillery_plot_done():
  interface.close_artillery_box()
  mouse_state = mouse_states.COMBAT
  activate_input()


func complete_artillery_plot(target_cell):
  block_input()
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
