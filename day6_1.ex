defmodule Solution do
  @start_symbol "^"
  @wall "#"
  @no_loop 0
  @loop 1

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(lines) do
    {parsed_lines, start} =
      lines
      |> Stream.with_index()
      |> Enum.reduce({[], :nomatch}, fn {line, idx}, {acc, match} ->
        chars = String.split(line, "", trim: true) |> List.to_tuple()

        case :binary.match(line, @start_symbol) do
          {begin, _} -> {[chars | acc], {idx, begin}}
          :nomatch -> {[chars | acc], match}
        end
      end)

    parsed_lines =
      parsed_lines |> Enum.reverse() |> List.to_tuple()

    {parsed_lines, start}
  end

  def traverse_grid(input, direction \\ :up, visited \\ MapSet.new(), return_grid \\ false)

  def traverse_grid({grid, {y, x}} = data, :up, visited, return_grid) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        if return_grid, do: visited, else: MapSet.size(visited)

      true ->
        next_y = y - 1
        next_char = grid |> elem(next_y) |> elem(x)

        if next_char == @wall do
          traverse_grid(data, :right, visited, return_grid)
        else
          traverse_grid({grid, {next_y, x}}, :up, visited, return_grid)
        end
    end
  end

  def traverse_grid({grid, {y, x}} = data, :down, visited, return_grid) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        if return_grid, do: visited, else: MapSet.size(visited)

      true ->
        next_y = y + 1
        next_char = grid |> elem(next_y) |> elem(x)

        if next_char == @wall do
          traverse_grid(data, :left, visited, return_grid)
        else
          traverse_grid({grid, {next_y, x}}, :down, visited, return_grid)
        end
    end
  end

  def traverse_grid({grid, {y, x}} = data, :left, visited, return_grid) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        if return_grid, do: visited, else: MapSet.size(visited)

      true ->
        next_x = x - 1
        next_char = grid |> elem(y) |> elem(next_x)

        if next_char == @wall do
          traverse_grid(data, :up, visited, return_grid)
        else
          traverse_grid({grid, {y, next_x}}, :left, visited, return_grid)
        end
    end
  end

  def traverse_grid({grid, {y, x}} = data, :right, visited, return_grid) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        if return_grid, do: visited, else: MapSet.size(visited)

      true ->
        next_x = x + 1
        next_char = grid |> elem(y) |> elem(next_x)

        if next_char == @wall do
          traverse_grid(data, :down, visited, return_grid)
        else
          traverse_grid({grid, {y, next_x}}, :right, visited, return_grid)
        end
    end
  end

  def check_bounds(grid, x, y) do
    0 >= y || 0 >= x || y >= tuple_size(grid) - 1 || x >= tuple_size(elem(grid, y)) - 1
  end

  def traverse_grid_with_dir(new_obstacle, input, direction \\ :up, visited \\ MapSet.new())

  def traverse_grid_with_dir(new_obstacle, {grid, {y, x, dir}}, :up, visited) do
    cond do
      check_bounds(grid, x, y) ->
        @no_loop

      MapSet.member?(visited, {y, x, dir}) ->
        @loop

      true ->
        visited = MapSet.put(visited, {y, x, dir})
        next_y = y - 1
        next_char = grid |> elem(next_y) |> elem(x)

        if next_char == @wall or {next_y, x} == new_obstacle do
          traverse_grid_with_dir(
            new_obstacle,
            {grid, {y, x, :right}},
            :right,
            visited
          )
        else
          traverse_grid_with_dir(
            new_obstacle,
            {grid, {next_y, x, :up}},
            :up,
            visited
          )
        end
    end
  end

  def traverse_grid_with_dir(
        new_obstacle,
        {grid, {y, x, dir}},
        :down,
        visited
      ) do
    cond do
      check_bounds(grid, x, y) ->
        @no_loop

      MapSet.member?(visited, {y, x, dir}) ->
        @loop

      true ->
        visited = MapSet.put(visited, {y, x, dir})
        next_y = y + 1
        next_char = grid |> elem(next_y) |> elem(x)

        if next_char == @wall or {next_y, x} == new_obstacle do
          traverse_grid_with_dir(new_obstacle, {grid, {y, x, :left}}, :left, visited)
        else
          traverse_grid_with_dir(
            new_obstacle,
            {grid, {next_y, x, dir}},
            :down,
            visited
          )
        end
    end
  end

  def traverse_grid_with_dir(
        new_obstacle,
        {grid, {y, x, dir}},
        :right,
        visited
      ) do
    cond do
      check_bounds(grid, x, y) ->
        @no_loop

      MapSet.member?(visited, {y, x, dir}) ->
        @loop

      true ->
        visited = MapSet.put(visited, {y, x, dir})
        next_x = x + 1
        next_char = grid |> elem(y) |> elem(next_x)

        if next_char == @wall or {y, next_x} == new_obstacle do
          traverse_grid_with_dir(new_obstacle, {grid, {y, x, :down}}, :down, visited)
        else
          traverse_grid_with_dir(
            new_obstacle,
            {grid, {y, next_x, dir}},
            :right,
            visited
          )
        end
    end
  end

  def traverse_grid_with_dir(
        new_obstacle,
        {grid, {y, x, dir}},
        :left,
        visited
      ) do
    cond do
      check_bounds(grid, x, y) ->
        @no_loop

      MapSet.member?(visited, {y, x, dir}) ->
        @loop

      true ->
        visited = MapSet.put(visited, {y, x, dir})
        next_x = x - 1
        next_char = grid |> elem(y) |> elem(next_x)

        if next_char == @wall or {y, next_x} == new_obstacle do
          traverse_grid_with_dir(new_obstacle, {grid, {y, x, :up}}, :up, visited)
        else
          traverse_grid_with_dir(
            new_obstacle,
            {grid, {y, next_x, dir}},
            :left,
            visited
          )
        end
    end
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> traverse_grid()
  end

  def solve_2(file_path) do
    {grid, start} =
      file_path
      |> read_file()
      |> parse_input()

    path = traverse_grid({grid, start}, :up, MapSet.new(), true)
    path = MapSet.delete(path, start)

    {y_start, x_start} = start

    path
    |> Task.async_stream(fn x -> traverse_grid_with_dir(x, {grid, {y_start, x_start, :up}}) end)
    |> Enum.reduce(0, fn {:ok, res}, acc -> res + acc end)
  end
end
