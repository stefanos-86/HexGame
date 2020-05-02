extends TileMap

# This class responsability is to know where things are
# and to help with coordinates. 
#
# It also handles the terrain stats, but this will likely be moved to
# something more sophisticated in the future.

class TerrainStats:
  const impassable = -1
  var base_movement_cost
  var terrain_name
  
  func _init(movement_cost, name):
    base_movement_cost = movement_cost
    terrain_name = name
  
# The keys are the tiles indexes.
var tiles_db = {
  0: TerrainStats.new(1, "open grassland"), # Open terrain costs 1 movement point.
  1: TerrainStats.new(TerrainStats.impassable, "deep water")  # Water is impassable.
 }

# I am not sure if this can easily handle the complex movement
# I would like to implement in the future (e. g. cells passable
# to certain units but not others, cost that varies if the map changes,
# like on broken up terrain, or with deployable bridges).
var navigation = AStar2D.new()    # Accounts for impassable cells and move cost.
var shortest_path = AStar2D.new() # For hex distance computation. Easier than doing the math..
var positions_id = {}
  
# Keep track of what is at every cell.
var units_on_map = {}

# Useful to figure out the full size of the map.
var bounding_box : Rect2

# For some reasons map_to_world returns the top 
# left corner of the cell even if I set the origin in 
# the center. This offset corrects for it.
var half_cell = cell_size / 2

func _ready():
  fill_navigation_info()
  compute_bounding_box()
  
  
func compute_bounding_box():
  # get_used_rect returns something I don't fully get.
  # Seems to miss the cells in the negative part.
  # TODO: check again.
  var cells = get_used_cells()
  for c in cells:
    bounding_box = bounding_box.expand(c)
  
  bounding_box = bounding_box.grow(1)
  
  var pos_wc = cell_to_world(bounding_box.position) 
  var size_wc = cell_to_world(bounding_box.size) 
  
  $DebugSquare.scale = size_wc / 64
  $DebugSquare.position = pos_wc
 
# Set the object at the given position and tells you
# where in the world it ended up.
func emplace(something, cell_coordinates):
  units_on_map[cell_coordinates] = something
  something.position = cell_to_world(cell_coordinates)
  
func cell_to_world(cell_coordinates):
  return map_to_world(cell_coordinates) + half_cell
    
# The game cells are hexes, but the real cells are square.
# This function accounts for the difference.
func detect_cell_under_mouse(mouse_pos):
  var map_coordinate = world_to_map(mouse_pos)
  var tile_pos = map_to_world(map_coordinate)
  
  # Bring stuff in the usual circle centered in the origin.
  # Hex texture is 64 pixels. Hex radius must be 32.
  var mouse_if_tile_in_origin = mouse_pos - half_cell - tile_pos;
  var mouse_if_hex_side_unity = mouse_if_tile_in_origin / 32
  mouse_if_hex_side_unity.y = - mouse_if_hex_side_unity.y # I made all the calculation on the usual axis, not the screen axis!
  
  # Usual poligon test, knowing that 2 of the 6 sides equation are
  # certainly satisfied because the hex vertical sides are on the 
  # tile sides. You can not go out of the hex on sides.
  var sqrt3_half = sqrt(3) / 2
  var px_half = mouse_if_hex_side_unity.x / 2
  var py_sqrt3_half = sqrt3_half * mouse_if_hex_side_unity.y
  var inside_top_right =        px_half + py_sqrt3_half - sqrt3_half < 0
  var inside_bottom_rigth =     px_half + py_sqrt3_half + sqrt3_half > 0
  var inside_bottom_left =    - px_half - py_sqrt3_half - sqrt3_half < 0
  var inside_top_left    =      px_half - py_sqrt3_half + sqrt3_half > 0
  
  var even_x = (int(map_coordinate.x) % 2) == 0
  
  if not((inside_top_right and inside_bottom_rigth and inside_bottom_left and inside_top_left)):
    if (mouse_if_hex_side_unity.x > 0 and mouse_if_hex_side_unity.y > 0):
      map_coordinate.x += 1
      if (even_x):
        map_coordinate.y -= 1
    elif (mouse_if_hex_side_unity.x > 0 and mouse_if_hex_side_unity.y < 0):
      map_coordinate.x += 1
      if (not even_x):
        map_coordinate.y += 1
    elif (mouse_if_hex_side_unity.x < 0 and mouse_if_hex_side_unity.y < 0):
      map_coordinate.x -= 1
      if (not even_x):
        map_coordinate.y += 1
    elif (mouse_if_hex_side_unity.x < 0 and mouse_if_hex_side_unity.y > 0):
      map_coordinate.x -= 1
      if (even_x):
        map_coordinate.y -= 1
    # else, we are inside the tile that was it.
  
  return map_coordinate

func what_is_at(cell_coordinates):
  if (units_on_map.has(cell_coordinates)):
    return units_on_map[cell_coordinates]
  return null
  
func where_is(something):
  for coordinate in units_on_map:
    if (units_on_map[coordinate] == something):
      return coordinate
  return null

func terrain_type_at(map_coordinate):
  var cell_type = get_cellv(map_coordinate) 
  if (cell_type < 0):
    return "no terrain"
  return tiles_db[cell_type].terrain_name

func fill_navigation_info():
  var max_map_size = 30 # Todo: use the map extent like for the debug sprite
  var start_point = -10
  var cell_id = 0
  for i in range(start_point, max_map_size):
    for j in range(start_point, max_map_size):
      var map_coordinate = Vector2(i, j)
      positions_id[map_coordinate] = cell_id   
      
      shortest_path.add_point(cell_id, map_coordinate)
      
      var movement_cost = movement_cost_for_position(map_coordinate)
      if (movement_cost != TerrainStats.impassable):
        navigation.add_point(cell_id, map_coordinate, movement_cost)
        
      cell_id += 1
        
          
  for i in range(start_point, max_map_size):
    for j in range(start_point, max_map_size):
      var map_coordinate = Vector2(i, j)
      var movement_cost = movement_cost_for_position(map_coordinate)
      var start = positions_id[map_coordinate]
      var near = neighbors_of(map_coordinate)     
      
      for n in near:
        if (positions_id.has(n)):
          var end = positions_id[n]
          var neighbor_cost = movement_cost_for_position(n)
          shortest_path.connect_points(start, end)
          if movement_cost != TerrainStats.impassable and neighbor_cost != TerrainStats.impassable:   
            navigation.connect_points(start, end)
        
          
func movement_cost_for_position(map_coordinate):
  var tile_terrain_type = get_cellv(map_coordinate) 
  if (tile_terrain_type < 0):
    return -1 # No terrain here. Impassable.
    
  return tiles_db[tile_terrain_type].base_movement_cost
  
func neighbors_of(map_coordinate):
  var x = map_coordinate.x
  var y = map_coordinate.y
  if (int(x) % 2 == 0):
    return [
        Vector2(x -1, y -1), Vector2(x +1, y -1),
      Vector2(x -2, y),         Vector2(x +2, y),
        Vector2(x -1, y), Vector2(x +1, y),
    ] 
  else:
    return [
        Vector2(x -1, y), Vector2(x +1, y),
      Vector2(x -2, y),         Vector2(x +2, y),
        Vector2(x -1, y +1), Vector2(x +1, y +1),
    ]

  
func plot_unit_path(unit, destination_coordinate):
  if (movement_cost_for_position(destination_coordinate) == TerrainStats.impassable):
    return []
    
  var start_coordinate = where_is(unit)
  if (start_coordinate == null):
    return []  # TODO: handle error in a decent way.
    
  var start = positions_id[start_coordinate]
  var end = positions_id[destination_coordinate]
  
  var path = navigation.get_point_path(start, end)
  return path

func move(something, here):
  var old_position = where_is(something)
  units_on_map[old_position] = null
  units_on_map[here] = something

func distance_between(unit_a, unit_b):
  var coord_a = where_is(unit_a)
  var coord_b = where_is(unit_b)
  
  var start = positions_id[coord_a]
  var end = positions_id[coord_b]
  
  var path = shortest_path.get_point_path(start, end)
  return path.size() -2 # "Discount" the start and end cells.

