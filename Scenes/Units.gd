extends Node

var tank_class = load("res://Units/Tank.tscn")
var terrain
var order_of_battle = []

func _ready():
  terrain = get_tree().get_root().get_node("HexMap/Terrain")

  # Mock unit, just for testing.  
  var unit_to_place = tank_class.instance() as Node2D
  var wc = terrain.emplace(unit_to_place, Vector2(12, 3))
  
  order_of_battle.append(unit_to_place)
  add_child(unit_to_place)
