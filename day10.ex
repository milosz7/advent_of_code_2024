defmodule Solution do
  @start 0
  @finish 9

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(lines) do
    map =
      lines
      |> Stream.map(&String.split(&1, "", trim: true))
      |> Stream.map(fn line -> Stream.map(line, &String.to_integer/1) end)
      |> Stream.with_index()
      |> Stream.flat_map(fn {line, y} ->
        Enum.reduce(line, {[], 0}, fn elem, {acc, x} ->
          {[{x, y, elem} | acc], x + 1}
        end)
        |> elem(0)
      end)
      |> Enum.reduce(%{}, fn {x, y, val}, acc -> Map.put(acc, {x, y}, val) end)

    {get_start(map), get_finish(map), map}
  end

  def get_neighbors({x, y}) do
    [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
  end

  def get_start(map) do
    Enum.filter(map, fn {_, val} -> val == @start end)
  end

  def get_finish(map) do
    map
    |> Enum.filter(fn {_, val} -> val == @finish end)
    |> Enum.map(fn {key, _} -> key end)
    |> MapSet.new()
  end

  def traverse_map(points, map, visited \\ MapSet.new())

  def traverse_map([], _, visited), do: visited

  def traverse_map([{current, val} | rest], map, visited) do
    visited = MapSet.put(visited, current)

    new_points =
      current
      |> get_neighbors()
      |> Enum.reduce([], fn coords, acc ->
        if Map.has_key?(map, coords) do
          [{coords, Map.get(map, coords)} | acc]
        else
          acc
        end
      end)
      |> Enum.filter(fn {point, new_val} ->
        new_val - val == 1 and !MapSet.member?(visited, point)
      end)

    traverse_map(rest ++ new_points, map, visited)
  end

  def solve_1(file_path) do
    {start, finish, map} =
      file_path
      |> read_file()
      |> parse_input()

    start
    |> Enum.map(fn point -> traverse_map([point], map) end)
    |> Enum.reduce(0, fn result, acc -> acc + MapSet.size(MapSet.intersection(finish, result)) end)
  end
end
