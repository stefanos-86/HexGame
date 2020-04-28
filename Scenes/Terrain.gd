extends TileMap

# This class responsability is to know where things are
# and to help with coordinates.

signal tile_hovering(tile_position)

# Keep track of what is at every cell.
var units_on_map = {}

# For some reasons map_to_world returns the top 
# left corner of the cell even if I set the origin in 
# the center. This offset corrects for it.
var half_cell = cell_size / 2

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
  print ("mouse ", mouse_pos, " map ", map_coordinate, " tile ", tile_pos)
  
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
  
  print ("mouse origin ", mouse_if_tile_in_origin)
  print ("mouse scaled ", mouse_if_hex_side_unity)
  print ("tr ", inside_top_right)
  print ("br ", inside_bottom_rigth)
  print ("bl ", inside_bottom_left)
  print ("tl ", inside_top_left)
  
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
  print ("At the end ", map_coordinate)
  print (get_cellv(map_coordinate))
  emit_signal("tile_hovering", map_coordinate, cell_to_world(map_coordinate))

func what_is_at(cell_coordinates):
  if (units_on_map.has(cell_coordinates)):
    return units_on_map[cell_coordinates]
  return null
