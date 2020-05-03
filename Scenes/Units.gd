extends Node

var game = preload("res://FreeScripts/Game.gd")

var tank_scene = load("res://Units/Tank.tscn")

var terrain
var interface
var order_of_battle = []

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
  unit_to_place.move_points = 10
  unit_to_place.fire_points = 2
  unit_to_place.type = "Tank"
  unit_to_place.speed = game.speed_levels.SLOW
  unit_to_place.gun_max_range = 15
  unit_to_place.armour_thickness = standard_armour
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(12, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place = tank_scene.instance()
  unit_to_place.faction = game.factions.RED
  unit_to_place.move_points = 10
  unit_to_place.fire_points = 2
  unit_to_place.type = "Tank 2"
  unit_to_place.speed = game.speed_levels.FAST
  unit_to_place.armour_thickness = standard_armour
  unit_to_place.gun_max_range = 15
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(5, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place = tank_scene.instance()
  unit_to_place.move_points = 10
  unit_to_place.fire_points = 2
  unit_to_place.type = "Tank"
  unit_to_place.speed = game.speed_levels.STATIONARY
  unit_to_place.faction = game.factions.BLUE
  unit_to_place.armour_thickness = standard_armour
  unit_to_place.gun_max_range = 15
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(15, 1))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)

func count_units_of(player):
  var counter = 0
  for u in order_of_battle:
    if u.faction == player and u.alive == true:
      counter += 1
  return counter

func mark_destruction(unit):
  order_of_battle.erase(unit)

func reload_all_points():
  for u in order_of_battle:
    u.fire_points = 2
    u.move_points = 10
