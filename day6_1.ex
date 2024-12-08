defmodule Solution do
  @start_symbol "^"

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

  def traverse_grid(input, direction \\ :up, visited \\ MapSet.new())

  def traverse_grid({grid, {y, x}} = data, :up, visited) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        MapSet.size(visited)

      true ->
        next_y = y - 1
        next_char = grid |> elem(next_y) |> elem(x)

        if next_char == "#" do
          traverse_grid(data, :right, visited)
        else
          traverse_grid({grid, {next_y, x}}, :up, visited)
        end
    end
  end

  def traverse_grid({grid, {y, x}} = data, :down, visited) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        MapSet.size(visited)

      true ->
        next_y = y + 1
        next_char = grid |> elem(next_y) |> elem(x)

        if next_char == "#" do
          traverse_grid(data, :left, visited)
        else
          traverse_grid({grid, {next_y, x}}, :down, visited)
        end
    end
  end

  def traverse_grid({grid, {y, x}} = data, :left, visited) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        MapSet.size(visited)

      true ->
        next_x = x - 1
        next_char = grid |> elem(y) |> elem(next_x)

        if next_char == "#" do
          traverse_grid(data, :up, visited)
        else
          traverse_grid({grid, {y, next_x}}, :left, visited)
        end
    end
  end

  def traverse_grid({grid, {y, x}} = data, :right, visited) do
    visited = MapSet.put(visited, {y, x})

    cond do
      check_bounds(grid, x, y) ->
        MapSet.size(visited)

      true ->
        next_x = x + 1
        next_char = grid |> elem(y) |> elem(next_x)

        if next_char == "#" do
          traverse_grid(data, :down, visited)
        else
          traverse_grid({grid, {y, next_x}}, :right, visited)
        end
    end
  end

  def check_bounds(grid, x, y) do
    0 >= y || 0 >= x || y >= tuple_size(grid) - 1 || x >= tuple_size(elem(grid, y)) - 1
  end

  def solve(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> traverse_grid()
  end
end
