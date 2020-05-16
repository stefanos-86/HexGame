extends Node

# This class keeps track of the armies. It knows the list of units
# of each army (I think they call it "order of battle") and their artillery.


var game = preload("res://FreeScripts/Game.gd")
var tank_scene = load("res://Units/Tank.tscn")
var Artillery = preload("res://FreeScripts/Artillery.gd")

var terrain
var order_of_battle = {}
var artillery_support = {}

# Armor thickness in rolled steel millimiters.
# All the tanks are of the same model in the game.
var standard_armour = {
  game.armor_part.FRONT:  300,
  game.armor_part.SIDE: 250,
  game.armor_part.REAR: 100,
}

func _prepare_data_structures():
  for faction in game.factions:
    var faction_value = game.factions[faction]
    order_of_battle[faction_value] = []
    artillery_support[faction_value] = []

func _place_tank(owner, position, facing):
  var unit_to_place = tank_scene.instance()
  unit_to_place.faction = owner
  unit_to_place.type = "Tank"
  unit_to_place.reset_points()
  unit_to_place.armour_thickness = standard_armour
  unit_to_place.movement_stance = game.movement_stances.GO_SLOW
  unit_to_place.fire_stance = game.fire_stances.FIRE_AT_WILL
  terrain.emplace(unit_to_place, position)
  
  order_of_battle[owner].append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place.look_at(terrain.cell_to_world(facing))
  
func _create_cannon(owner, id):
  var cannon = Artillery.new()
  cannon.owner = owner
  cannon.rounds_left = 3
  cannon.id = id
  artillery_support[owner].append(cannon)

func _ready():
  terrain = get_tree().get_root().get_node("HexMap/Terrain")
  create_all_units(terrain)
  

func create_all_units(terrain):
  _prepare_data_structures()
  
  _place_tank(game.factions.RED, Vector2(7, 0), Vector2(9, 0))
  _place_tank(game.factions.RED, Vector2(7, 1), Vector2(9, 1))
  _place_tank(game.factions.RED, Vector2(7, 2), Vector2(9, 2))
  
  _place_tank(game.factions.RED, Vector2(11, 7), Vector2(13, 7))
  _place_tank(game.factions.RED, Vector2(7, 7), Vector2(9, 7))
  _place_tank(game.factions.RED, Vector2(3, 7), Vector2(5, 7))
 
  _place_tank(game.factions.BLUE, Vector2(53, 0), Vector2(49, 0))
  _place_tank(game.factions.BLUE, Vector2(56, 2), Vector2(52, 2))
  _place_tank(game.factions.BLUE, Vector2(58, 7), Vector2(56, 7))  
  
  # Activate those units to do quick tests of engagements.
  #_place_tank(game.factions.BLUE, Vector2(38, 2), Vector2(56, 7))  
  #_place_tank(game.factions.RED, Vector2(34, 2), Vector2(56, 7))  
  
  _create_cannon(game.factions.RED, 1)
  _create_cannon(game.factions.RED, 2)
  _create_cannon(game.factions.BLUE, 1)
  _create_cannon(game.factions.BLUE, 2)
  
  
func all_units():
  var all = []
  for sub_array in order_of_battle.values(): 
    all += sub_array
  return all
  
  
func count_remaining_units_of(player):
  var counter = 0
  for u in order_of_battle[player]:
    if u.alive == true:  # TODO: no count_if equivalent?
      counter += 1
  return counter


func order_of_battle_of(player):
  return order_of_battle[player]
  
  
func enemies_of(unit):
  var enemy_player = game.factions.RED
  if unit.faction == game.factions.RED:
    enemy_player = game.factions.BLUE
  
  return order_of_battle[enemy_player]


func reset_points_and_speed(player):
  for u in order_of_battle[player]:
      u.reset_points()
      
      # Not sure this is good. What if a unit ran out of move points
      # and continue moving at the next turn? But what if it does not 
      # move?    
      u.speed = game.speed_levels.STATIONARY 


func available_fire_support(player):
  return artillery_support[player]


func progress_fire_missions(player):
  for c in available_fire_support(player):
    c.progress_fire_mission()


func ready_fire_missions(player):
  var cannons = []
  for c in available_fire_support(player):
    if c.ready_to_fire():
      cannons.append(c)
  return cannons


func clear_executed_fire_missions(player):
  for c in available_fire_support(player):
    if c.ready_to_fire():
      c.cancel_fire_mission()
