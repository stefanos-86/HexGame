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
  var unit_to_place = tank_scene.instance()
  unit_to_place.faction = game.factions.RED
  unit_to_place.move_points = 10
  unit_to_place.shot_points = 2
  unit_to_place.type = "Tank"
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(12, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place = tank_scene.instance()
  unit_to_place.faction = game.factions.RED
  unit_to_place.move_points = 10
  unit_to_place.shot_points = 2
  unit_to_place.type = "Tank 2"
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(5, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
  
  unit_to_place = tank_scene.instance()
  unit_to_place.move_points = 10
  unit_to_place.shot_points = 2
  unit_to_place.type = "Tank"
  unit_to_place.faction = game.factions.BLUE
  interface.unmark(unit_to_place) # Forces the color.
  terrain.emplace(unit_to_place, Vector2(15, 1))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)

func count_units_of(player):
  var counter = 0
  for u in order_of_battle:
    if u.faction == player:
      counter += 1
  return counter
