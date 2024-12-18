defmodule Solution do
  @robot "@"
  @wall "#"
  @food "O"
  @space "."
  @left "<"
  @right ">"
  @up "^"
  @down "v"

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  def parse_maze(lines) do
    lines
    |> String.split("\n")
    |> Stream.map(fn line -> String.split(line, "", trim: true) end)
    |> Stream.with_index()
    |> Stream.flat_map(fn {line, y} ->
      Enum.reduce(line, {[], 0}, fn elem, {acc, x} ->
        {[{x, y, elem} | acc], x + 1}
      end)
      |> elem(0)
    end)
    |> Enum.reduce(%{}, fn {x, y, val}, acc -> Map.put(acc, {x, y}, val) end)
  end

  def make_move(@down, map, {x, y} = robot) do
    next = {x, y + 1}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.put(robot, @space), next}

      @food ->
        find_food_place(@down, map, robot, next, next)
    end
  end

  def make_move(@left, map, {x, y} = robot) do
    next = {x - 1, y}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.put(robot, @space), next}

      @food ->
        find_food_place(@left, map, robot, next, next)
    end
  end

  def make_move(@right, map, {x, y} = robot) do
    next = {x + 1, y}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.put(robot, @space), next}

      @food ->
        find_food_place(@right, map, robot, next, next)
    end
  end

  def make_move(@up, map, {x, y} = robot) do
    next = {x, y - 1}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.put(robot, @space), next}

      @food ->
        find_food_place(@up, map, robot, next, next)
    end
  end

  def find_food_place(direction, map, robot, old_food, prev_loc)

  def find_food_place(@down, map, robot, old_food, {x, y}) do
    next = {x, y + 1}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        map =
          map
          |> Map.put(robot, @space)
          |> Map.put(old_food, @robot)
          |> Map.put(next, @food)

        {map, old_food}

      @food ->
        find_food_place(@down, map, robot, old_food, next)
    end
  end

  def find_food_place(@left, map, robot, old_food, {x, y}) do
    next = {x - 1, y}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        map =
          map
          |> Map.put(robot, @space)
          |> Map.put(old_food, @robot)
          |> Map.put(next, @food)

        {map, old_food}

      @food ->
        find_food_place(@left, map, robot, old_food, {x - 1, y})
    end
  end

  def find_food_place(@right, map, robot, old_food, {x, y}) do
    next = {x + 1, y}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        map =
          map
          |> Map.put(robot, @space)
          |> Map.put(old_food, @robot)
          |> Map.put(next, @food)

        {map, old_food}

      @food ->
        find_food_place(@right, map, robot, old_food, next)
    end
  end

  def find_food_place(@up, map, robot, old_food, {x, y}) do
    next = {x, y - 1}
    next_sign = Map.get(map, next)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        map =
          map
          |> Map.put(robot, @space)
          |> Map.put(old_food, @robot)
          |> Map.put(next, @food)

        {map, old_food}

      @food ->
        find_food_place(@up, map, robot, old_food, next)
    end
  end

  def parse_move("", maze_map, _), do: maze_map

  def parse_move(moves, maze_map, robot_pos) do
    <<move::binary-size(1), rest::binary>> = moves

    {maze_map, next_robot_pos} = make_move(move, maze_map, robot_pos)
    parse_move(rest, maze_map, next_robot_pos)
  end

  def count_coordinates(map) do
    map
    |> Stream.filter(fn {_, v} -> v == @food end)
    |> Stream.map(fn {k, _} -> k end)
    |> Enum.reduce(0, fn {x, y}, acc -> 100 * y + x + acc end)
  end

  def solve_1(path) do
    [maze, moves] =
      path
      |> read_file()

    maze_map = parse_maze(maze)
    moves = moves |> String.replace("\n", "")

    robot_position =
      maze_map
      |> Enum.find(fn {_, v} -> v == @robot end)
      |> elem(0)

    parse_move(moves, maze_map, robot_position)
    |> count_coordinates()
  end

  def visualise(map) do
    0..9
    |> Enum.map(fn y ->
      0..9
      |> Enum.reduce("", fn x, acc ->
        present = Map.get(map, {x, y})
        acc <> present
      end)
    end)
    |> Enum.each(&IO.inspect/1)
  end
end
