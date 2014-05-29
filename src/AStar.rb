#break

class Direction
  DOWN = 2
  LEFT = 4
  RIGHT = 6
  UP = 8
end

class PathNode
  attr_reader   :x
  attr_reader   :y
  attr_accessor :parent
  attr_accessor :f
  attr_accessor :g
  attr_accessor :h
 
  def initialize(x, y, parent=nil, f=0, g=0, h=0)
    @x, @y = x, y
    @f, @g, @h = f, g, h
    @parent = parent
  end
  
  #operator overloads
  def ==(node)
    return @x == node.x && @y == node.y
  end
  
  def !=(node)
    return @x != node.x || @y != node.y
  end
  
  #Heuristics
  def euclidean_distance(node)#Euclidean distance
	x = (@x - node.x).abs
	y = (@y - node.y).abs
    return (x * Math.sqrt(1+((y/x) ** 2))
  end
  
  def manhattan_distance(node)#Manhattan distance, default heuristic calculation
	return (((@x-node.x)).abs+((@y-node.y)).abs)
  end
  def cost
    raise 'not implemented'
  end
end
 
class Game_Character < Game_CharacterBase
 
  alias :pre_pathing_initialize :initialize
  def initialize(*args)
    @pathing = false
    @path = []
    @open_list = []
    @closed_list = []
    pre_pathing_initialize(*args)
  end
  
  def pathing?
    return @pathing
  end
  
  def path_to(tile_x, tile_y)
    @pathing = true
    @dest = PathNode.new(tile_x, tile_y)
    @path.clear
    @open_list.clear
    @closed_list.clear
  end
  
  def end_path
    @pathing = false
  end
  
  def update_path
    return unless pathing? && !moving? && !@move_route_forcing
    next_node = move_next(@dest)
    if next_node.nil?
      end_path
      return
    end
    moveto(next_node.x, next_node.y)
    if next_node == @dest
      end_path
    end
  end
  
  def move_next(dest)
    find_path(dest) if @path.empty?
    next_node = @path.shift   
    next_node = @path.shift if next_node.x == @x && next_node.y == y
    if next_node.nil? || passable?(next_node.x, next_node.y, get_dir(@x, @y, next_node))  
      return next_node
    else
      # our once open node is now impassable, calculate again
      @path.clear
      move_next(dest)
    end
  end
  
  def get_dir(x, y, node)
    if x == node.x
      return y + 1 == node.y ? Direction::UP : Direction::DOWN
    else
      return x + 1 == node.x ? Direction::LEFT : Direction::RIGHT
    end
  end
  
  def find_path(dest)
    current = PathNode.new(@x, @y)
    start = current
    while current != dest do
      connected_nodes = get_connected_nodes(current.x, current.y)
      connected_nodes.each do |n|
        travel_cost = calc_travel_cost(current, n)
        g = current.g + travel_cost
        h = heuristic(n, dest, travel_cost)
        f = g + h
        if @open_list.include?(n) || @closed_list.include?(n)
          if n.f > f
            n.f = f
            n.g = g
            n.h = h
            n.parent = current
          end
        else
          n.f = f
          n.g = g
          n.h = h
          n.parent = current
          @open_list << n
        end
      end
      @closed_list << current
      if @open_list.empty?  
        # todo: handle no place to go
        raise 'no open nodes'
      end
      @open_list.sort {|n| n.f}
      current = @open_list.shift
    end
    @dest = current
    build_path(start)
  end
  
  def build_path(start_node)
    @path.clear
    node = @dest
    @path << node
    while node != start_node do
      node = node.parent
      @path.unshift(node)
    end
  end
  
  def heuristic(node, dest, cost)
    (node.x - dest.x).abs * cost + (node.y - dest.y).abs * cost
  end
  
  def calc_travel_cost(n1, n2)
    n1.manhattan_distance(n2)
  end
  
  def get_connected_nodes(x, y)
    surrounding_tiles = [
      [PathNode.new(x, y-1), Direction::DOWN],
      [PathNode.new(x+1, y), Direction::LEFT],
      [PathNode.new(x, y+1), Direction::UP],
      [PathNode.new(x-1, y), Direction::RIGHT]
    ]
    surrounding_tiles.select {|n| passable?(n[0].x, n[0].y, n[1])}.map {|n| n[0]}
  end
  
  alias :pre_pathing_update :update
  def update(*args)
    pre_pathing_update(*args)
    update_path
  end
  
end
