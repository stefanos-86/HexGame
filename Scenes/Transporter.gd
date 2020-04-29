extends Node2D

# The only alternative I can think of is a spinlock. 
signal movement_animation_done

var animation_speed
var follow_me

var moving = false
var path_length

func _ready():
  follow_me = get_parent()

func reset_at_start(distance_to_cover, speed):
  follow_me.set_offset(0)
  path_length = distance_to_cover
  animation_speed = speed
  moving = true

func _physics_process(delta):
  if (not moving):
   return
  
  var new_offset = follow_me.get_offset () + animation_speed * delta  
  if (new_offset >= path_length):
    new_offset = path_length
    moving = false
    emit_signal("movement_animation_done")
    
  follow_me.set_offset(new_offset)
