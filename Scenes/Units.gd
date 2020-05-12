extends Node

var game = preload("res://FreeScripts/Game.gd")

var tank_scene = load("res://Units/Tank.tscn")

var Artillery = preload("res://FreeScripts/Artillery.gd")

var terrain
var interface
var order_of_battle = []
var artillery_support = []

func _ready():
  terrain = get_tree().get_root().get_node("HexMap/Terrain")
  interface = get_tree().get_root().get_node("HexMap/Interface")

  # Stub the unit creation code. 
  var standard_armour = {}
  standard_armour[game.armor_part.FRONT] = 300
  standard_armour[game.armor_part.SIDE] = 250
  standard_armour[game.armor_part.REAR] = 100
  
  var unit_to_place = tank_scene.instance()
  unit_to_place.faction = game.factions.RED
  unit_to_place.type = "Tank"
  unit_to_place.reset_points()
  unit_to_place.armour_thickness = standard_armour
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(12, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place = tank_scene.instance()
  unit_to_place.faction = game.factions.RED
  unit_to_place.type = "Tank 2"
  unit_to_place.armour_thickness = standard_armour
  unit_to_place.reset_points()
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(5, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place = tank_scene.instance()
  unit_to_place.type = "Tank"
  unit_to_place.faction = game.factions.BLUE
  unit_to_place.armour_thickness = standard_armour
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(15, 1))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
    
  
  var cannon = Artillery.new()
  cannon.owner = game.factions.RED
  cannon.rounds_left = 3
  cannon.id = 1
  artillery_support.append(cannon)
  cannon = Artillery.new()
  cannon.owner = game.factions.RED
  cannon.rounds_left = 3
  cannon.id = 2
  artillery_support.append(cannon)
  
  cannon = Artillery.new()
  cannon.owner = game.factions.BLUE
  cannon.rounds_left = 3
  cannon.id = 1
  artillery_support.append(cannon)
  cannon = Artillery.new()
  cannon.owner = game.factions.BLUE
  cannon.rounds_left = 3
  cannon.id = 2
  artillery_support.append(cannon)
  

func count_units_of(player):
  var counter = 0
  for u in order_of_battle:
    if u.faction == player and u.alive == true:
      counter += 1
  return counter

func order_of_battle_of(player):
  var units = []
  for u in order_of_battle:
    if u.faction == player:
      units.append(u)
  return units

func mark_destruction(unit):
  unit.alive = false

func reset_points_and_speed(player):
  for u in order_of_battle:
    if u.faction == player:
      u.reset_points()
    
      # Not sure this is good. What if a unit ran out of move points
      # and continue moving at the next turn? But what if it does not 
      # move?    
      u.speed = game.speed_levels.STATIONARY 


func available_fire_support(player):
  var cannons = []
  for c in artillery_support:
    if c.owner == player:
      cannons.append(c)
  return cannons

func progress_fire_missions(player):
  for c in available_fire_support(player):
    c.turns_to_fire -= 1

func ready_fire_missions(player):
  var cannons = []
  for c in available_fire_support(player):
    if c.turns_to_fire == 0:
      cannons.append(c)
  return cannons

func clear_executed_fire_missions(player):
  for c in available_fire_support(player):
    if c.turns_to_fire == 0:
      c.cancel_fire_mission()
