defmodule Solution do
  @robot "@"
  @wall "#"
  @food_left "["
  @food_right "]"
  @food "O"
  @space "."
  @left "<"
  @right ">"
  @up "^"
  @down "v"
  @input_x 100
  @input_y 49

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  def parse_maze(lines) do
    lines
    |> String.replace(@wall, @wall <> @wall)
    |> String.replace(@space, @space <> @space)
    |> String.replace(@food, @food_left <> @food_right)
    |> String.replace(@robot, @robot <> @space)
    |> String.split("\n")
    |> Stream.map(fn line -> String.split(line, "", trim: true) end)
    |> Stream.with_index()
    |> Stream.flat_map(fn {line, y} ->
      Enum.reduce(line, {[], 0}, fn elem, {acc, x} ->
        {[{x, y, elem} | acc], x + 1}
      end)
      |> elem(0)
    end)
    |> Stream.reject(fn {_, _, elem} -> elem == @space end)
    |> Enum.reduce(%{}, fn {x, y, val}, acc -> Map.put(acc, {x, y}, val) end)
  end

  def make_move(@down, map, {x, y} = robot) do
    next = {x, y + 1}
    next_sign = Map.get(map, next, @space)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.delete(robot), next}

      @food_left ->
        candidates =
          move_food_vertical(@down, {next, next_sign}, {{x + 1, y + 1}, @food_right}, map)

        if Enum.find(candidates, fn {_, symbol} -> symbol == @wall end) do
          {map, robot}
        else
          {update_vertical(@down, map, [{robot, @robot} | candidates]), {x, y + 1}}
        end

      @food_right ->
        candidates =
          move_food_vertical(@down, {{x - 1, y + 1}, @food_left}, {next, next_sign}, map)

        if Enum.find(candidates, fn {_, symbol} -> symbol == @wall end) do
          {map, robot}
        else
          {update_vertical(@down, map, [{robot, @robot} | candidates]), {x, y + 1}}
        end
    end
  end

  def make_move(@left, map, {x, y} = robot) do
    next = {x - 1, y}
    next_sign = Map.get(map, next, @space)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.delete(robot), next}

      _ ->
        move_food_horizontal(@left, {next, next_sign}, robot, map)
    end
  end

  def make_move(@right, map, {x, y} = robot) do
    next = {x + 1, y}
    next_sign = Map.get(map, next, @space)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.delete(robot), next}

      _ ->
        move_food_horizontal(@right, {next, next_sign}, robot, map)
    end
  end

  def make_move(@up, map, {x, y} = robot) do
    next = {x, y - 1}
    next_sign = Map.get(map, next, @space)

    case next_sign do
      @wall ->
        {map, robot}

      @space ->
        {map |> Map.put(next, @robot) |> Map.delete(robot), next}

      @food_left ->
        candidates =
          move_food_vertical(@up, {next, next_sign}, {{x + 1, y - 1}, @food_right}, map)

        if Enum.find(candidates, fn {_, symbol} -> symbol == @wall end) do
          {map, robot}
        else
          {update_vertical(@up, map, [{robot, @robot} | candidates]), {x, y - 1}}
        end

      @food_right ->
        candidates =
          move_food_vertical(@up, {{x - 1, y - 1}, @food_left}, {next, next_sign}, map)

        if Enum.find(candidates, fn {_, symbol} -> symbol == @wall end) do
          {map, robot}
        else
          {update_vertical(@up, map, [{robot, @robot} | candidates]), {x, y - 1}}
        end
    end
  end

  def clear_map(map, keys) do
    keys
    |> MapSet.new()
    |> Enum.reduce(map, fn {{x, y}, _}, acc ->
      acc
      |> Map.delete({x, y})
    end)
  end

  def update_vertical(@up, map, candidates) do
    candidates
    |> Enum.reduce(clear_map(map, candidates), fn {{x, y}, symbol}, acc ->
      acc
      |> Map.put({x, y - 1}, symbol)
    end)
  end

  def update_vertical(@down, map, candidates) do
    candidates
    |> Enum.reduce(clear_map(map, candidates), fn {{x, y}, symbol}, acc ->
      acc
      |> Map.put({x, y + 1}, symbol)
    end)
  end

  def move_food_vertical(direction, left, right, map)

  def move_food_vertical(@up, {{xl, yl}, @food_left} = left, {{xr, yr}, @food_right} = right, map) do
    above_left = {xl, yl - 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_right = {xr, yr - 1}
    above_right_sign = Map.get(map, above_right, @space)

    [left, right] ++
      move_food_vertical(@up, {above_left, above_left_sign}, {above_right, above_right_sign}, map)
  end

  def move_food_vertical(@up, {{xl, yl}, @food_right} = left, {{xr, yr}, @food_left} = right, map) do
    above_left = {xl, yl - 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_left_next = {xl - 1, yl - 1}
    above_left_next_sign = Map.get(map, above_left_next, @space)
    above_right = {xr, yr - 1}
    above_right_sign = Map.get(map, above_right, @space)
    above_right_next = {xr + 1, yr - 1}
    above_right_next_sign = Map.get(map, above_right_next, @space)

    current_left = {{xl - 1, yl}, @food_left}
    current_right = {{xr + 1, yr}, @food_right}

    [left, right, current_left, current_right] ++
      move_food_vertical(
        @up,
        {above_left_next, above_left_next_sign},
        {above_left, above_left_sign},
        map
      ) ++
      move_food_vertical(
        @up,
        {above_right, above_right_sign},
        {above_right_next, above_right_next_sign},
        map
      )
  end

  def move_food_vertical(@up, {_, @space}, {{xr, yr}, @food_left} = right, map) do
    above_right = {xr, yr - 1}
    above_right_sign = Map.get(map, above_right, @space)
    above_right_next = {xr + 1, yr - 1}
    above_right_next_sign = Map.get(map, above_right_next, @space)

    current_right = {{xr + 1, yr}, @food_right}

    [right, current_right] ++
      move_food_vertical(
        @up,
        {above_right, above_right_sign},
        {above_right_next, above_right_next_sign},
        map
      )
  end

  def move_food_vertical(@up, {{xl, yl}, @food_right} = left, {_, @space}, map) do
    above_left = {xl, yl - 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_left_next = {xl - 1, yl - 1}
    above_left_next_sign = Map.get(map, above_left_next, @space)

    current_left = {{xl - 1, yl}, @food_left}

    [left, current_left] ++
      move_food_vertical(
        @up,
        {above_left_next, above_left_next_sign},
        {above_left, above_left_sign},
        map
      )
  end

  def move_food_vertical(@up, {_, @space}, {_, @space}, _), do: []

  def move_food_vertical(@up, {_, @wall} = left, _, _), do: [left]
  def move_food_vertical(@up, _, {_, @wall} = right, _), do: [right]

  # ======

  def move_food_vertical(
        @down,
        {{xl, yl}, @food_left} = left,
        {{xr, yr}, @food_right} = right,
        map
      ) do
    above_left = {xl, yl + 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_right = {xr, yr + 1}
    above_right_sign = Map.get(map, above_right, @space)

    [left, right] ++
      move_food_vertical(
        @down,
        {above_left, above_left_sign},
        {above_right, above_right_sign},
        map
      )
  end

  def move_food_vertical(
        @down,
        {{xl, yl}, @food_right} = left,
        {{xr, yr}, @food_left} = right,
        map
      ) do
    above_left = {xl, yl + 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_left_next = {xl - 1, yl + 1}
    above_left_next_sign = Map.get(map, above_left_next, @space)
    above_right = {xr, yr + 1}
    above_right_sign = Map.get(map, above_right, @space)
    above_right_next = {xr + 1, yr + 1}
    above_right_next_sign = Map.get(map, above_right_next, @space)

    current_left = {{xl - 1, yl}, @food_left}
    current_right = {{xr + 1, yr}, @food_right}

    [left, right, current_left, current_right] ++
      move_food_vertical(
        @down,
        {above_left_next, above_left_next_sign},
        {above_left, above_left_sign},
        map
      ) ++
      move_food_vertical(
        @down,
        {above_right, above_right_sign},
        {above_right_next, above_right_next_sign},
        map
      )
  end

  def move_food_vertical(@down, {_, @space}, {{xr, yr}, @food_left} = right, map) do
    above_left = {xr, yr + 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_left_next = {xr + 1, yr + 1}
    above_left_next_sign = Map.get(map, above_left_next, @space)

    current_right = {{xr + 1, yr}, @food_right}

    [right, current_right] ++
      move_food_vertical(
        @down,
        {above_left, above_left_sign},
        {above_left_next, above_left_next_sign},
        map
      )
  end

  def move_food_vertical(@down, {{xl, yl}, @food_right} = left, {_, @space}, map) do
    above_left = {xl, yl + 1}
    above_left_sign = Map.get(map, above_left, @space)
    above_left_next = {xl - 1, yl + 1}
    above_left_next_sign = Map.get(map, above_left_next, @space)

    current_left = {{xl - 1, yl}, @food_left}

    [left, current_left] ++
      move_food_vertical(
        @down,
        {above_left_next, above_left_next_sign},
        {above_left, above_left_sign},
        map
      )
  end

  def move_food_vertical(@down, {_, @space}, {_, @space}, _), do: []
  def move_food_vertical(@down, {_, @wall} = left, _, _), do: [left]
  def move_food_vertical(@down, _, {_, @wall} = right, _), do: [right]

  # ======

  def move_food_horizontal(direction, current, robot, map, acc \\ [])

  def move_food_horizontal(@left, {_, @wall}, robot, map, _) do
    {map, robot}
  end

  def move_food_horizontal(@left, {_, @space}, {x0, y0}, map, acc) do
    acc = [{{x0, y0}, @robot} | acc]

    map =
      acc
      |> Enum.reduce(clear_map(map, acc), fn {{x, y}, symbol}, acc ->
        acc
        |> Map.put({x - 1, y}, symbol)
      end)

    {map, {x0 - 1, y0}}
  end

  def move_food_horizontal(@left, {{x, y}, _} = current, robot, map, acc) do
    next = {x - 1, y}
    next_symbol = Map.get(map, next, @space)
    move_food_horizontal(@left, {next, next_symbol}, robot, map, [current | acc])
  end

  # =====

  def move_food_horizontal(@right, {_, @wall}, robot, map, _) do
    {map, robot}
  end

  def move_food_horizontal(@right, {_, @space}, {x0, y0}, map, acc) do
    acc = [{{x0, y0}, @robot} | acc]

    map =
      acc
      |> Enum.reduce(clear_map(map, acc), fn {{x, y}, symbol}, acc ->
        acc
        |> Map.put({x + 1, y}, symbol)
      end)

    {map, {x0 + 1, y0}}
  end

  def move_food_horizontal(@right, {{x, y}, _} = current, robot, map, acc) do
    next = {x + 1, y}
    next_symbol = Map.get(map, next, @space)
    move_food_horizontal(@right, {next, next_symbol}, robot, map, [current | acc])
  end

  def parse_move("", maze_map, _), do: maze_map

  def parse_move(moves, maze_map, robot_pos) do
    <<move::binary-size(1), rest::binary>> = moves

    {maze_map, next_robot_pos} = make_move(move, maze_map, robot_pos)
    parse_move(rest, maze_map, next_robot_pos)
  end

  def count_coordinates(map) do
    map
    |> Stream.filter(fn {_, v} -> v == @food_left end)
    |> Stream.map(fn {k, _} -> k end)
    |> Enum.reduce(0, fn {x, y}, acc -> 100 * y + x + acc end)
  end

  def solve(path) do
    [maze, moves] =
      path
      |> read_file()

    moves = moves |> String.replace("\n", "")
    maze_map = parse_maze(maze)

    robot_position =
      maze_map
      |> Enum.find(fn {_, v} -> v == @robot end)
      |> elem(0)

    maze_map
    |> visualise(@input_x, @input_y)

    parse_move(moves, maze_map, robot_position)
    |> visualise(@input_x, @input_y)
    |> count_coordinates()
  end

  def visualise(map, x_lim, y_lim) do
    0..y_lim
    |> Enum.map(fn y ->
      0..x_lim
      |> Enum.reduce("", fn x, acc ->
        present = Map.get(map, {x, y}, ".")
        acc <> present
      end)
    end)
    |> Enum.each(&IO.inspect/1)

    map
  end
end
