require 'set'

class Nonet < Set
  def add(num)
    super(num) and return self unless member?(num)
    raise StandardError.new('Already included')
  end
end

class Cell
  attr_accessor :num, :annotations
  def initialize
    @annotations = Set.new
  end

  def occupied?
    !num.nil?
  end

  def to_s
    num ? " #{num} " : '   '
  end

  def inspect
    to_s
  end
end

class Grid
  attr_reader :rows, :cols, :boxes, :grid, :placed

  def self.grid_to_box(x, y)
    (x / 3) * 3 + (y / 3)
  end

  def self.box_to_grid(x, y, box)
    gx = (box / 3) * 3 + x
    gy = (box % 3) * 3 + y
    [gx, gy]
  end

  def self.box_pos_to_grid(box, pos)
    self.box_to_grid(pos / 3, pos % 3, box)
  end

  def initialize
    @rows = Array.new(9) { Nonet.new }
    @cols = Array.new(9) { Nonet.new }
    @boxes = Array.new(9) { Nonet.new }
    @grid = Array.new(9) { Array.new(9) { Cell.new } }
  end

  def place(num, x, y)
    raise StandardError.new('Cell Occupied') if @grid[x][y].occupied?

    box = self.class.grid_to_box(x, y)
    puts "Place #{num} #{x} #{y} in box #{box}"
    @rows[x].add(num)
    @cols[y].add(num)
    @boxes[box].add(num)
    @grid[x][y].num = num
    @placed += 1
  end

  def full?
    @placed == 81
  end

  def remaining_for(x, y)
    (1..9).select do |num|
      !@rows[x].member?(num) &&
        !@cols[y].member?(num) &&
        !@boxes[self.class.grid_to_box(x, y)].member?(num)
    end
  end

  def place_in_row(num, x)
    raise StandardError.new("Number #{num} in Row #{x}") if @rows[x].member?(num)
    y = (0..8).to_a.shuffle.find do |col|
      !@cols[col].member?(num) &&
        !@boxes[self.class.grid_to_box(x, col)].member?(num) &&
        !@grid[x][col].occupied?
    end

    raise StandardError.new("Cannot Place #{num} in Row #{x}") unless y
    place(num, x, y)
  end

  def place_in_box(num, box)
    raise StandardError.new("Number #{num} in Box #{box}") if @boxes[box].member?(num)
    pos_in_box = (0..8).to_a.shuffle.find do |pos|
      x, y = self.class.box_pos_to_grid(box, pos)
      !@cols[y].member?(num) &&
        !@rows[x].member?(num) &&
        !@grid[x][y].occupied?
    end

    raise StandardError.new("Cannot Place #{num} in Box #{box}") unless pos_in_box
    x, y = self.class.box_pos_to_grid(box, pos_in_box)
    place(num, x, y)
  end

  def annotate(num, x, y)
    @grid[x][y].annotations.add(num)
  end

  def to_s
    sgrid = grid.map { |row| row.join('|') + "\n" }
    sgrid.join('---+'*8+"---\n")
  end

  def inspect
    to_s
  end
end

class Puzzle
  DIAGONAL = [0, 4, 8].freeze
  BOXES = (0..8).to_a.freeze

  attr_reader :grid

  def initialize
    @grid = Grid.new
  end

  def remaining_for(x, y)
    (1..9).select do |num|
      !grid.rows[x].member?(num) &&
        !grid.cols[y].member?(num) &&
        !grid.boxes[Grid.grid_to_box(x, y)].member?(num)
    end
  end

  def fill_recursive(idx, parent)
    x = idx / 9
    y = idx % 9

    while !grid.full? && !candidates.empty?
      candidates = remaining_for(x, y)
      grid[x][y] = candidates.shift
      fill_recursive(idx + 1)
    end
  end

  def fill!
    # first, do diagonal boxes
    DIAGONAL.each do |box_num|
      nums = (1..9).to_a.shuffle
      until nums.empty?
        (0..2).each do |bx|
          (0..2).each do |by|
            x,y = Grid.box_to_grid(bx, by, box_num)
            grid.place(nums.shift, x, y)
          end
        end
      end
    end

    # fill recursively starting at the 3rd box
    # fill_recursive(3, nil)

    # # then do the other boxes
    # (BOXES - DIAGONAL).each do |box_num|
    #   nums = BOXES.sample([9 - difficulty, 2].max)

    #   until nums.empty?
    #     num = nums.shift
    #     @grid.place_in_box(num, box_num)
    #   end
    # end
  rescue StandardError => e
    puts e
    print @grid
  end
end