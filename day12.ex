defmodule Solution do
  @max_fences 4

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(lines) do
    lines
    |> Stream.map(&String.split(&1, "", trim: true))
    |> Stream.with_index()
    |> Stream.flat_map(fn {line, y} ->
      Enum.reduce(line, {[], 0}, fn elem, {acc, x} ->
        {[{x, y, elem} | acc], x + 1}
      end)
      |> elem(0)
    end)
    |> Enum.reduce(%{}, fn {x, y, val}, acc -> Map.put(acc, {x, y}, val) end)
  end

  def get_neighbors({x, y}) do
    MapSet.new([{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}])
  end

  def count_fences_area(groups) do
    groups
    |> Enum.map(&count_fence_area/1)
    |> Enum.reduce(0, fn {area, fences}, acc -> acc + area * fences end)
  end

  def count_fence_area(group) do
    group
    |> Enum.reduce({0, 0}, fn point, {area, fences} ->
      n_valid =
        point |> get_neighbors() |> Enum.filter(&MapSet.member?(group, &1)) |> length()

      {area + 1, fences + @max_fences - n_valid}
    end)
  end

  def traverse_graph(
        map,
        start \\ {0, 0},
        groups \\ [],
        total_visited \\ MapSet.new()
      )

  def traverse_graph(_, nil, groups, _), do: groups

  def traverse_graph(
        map,
        start,
        groups,
        total_visited
      ) do
    visited = split_into_groups([start], map)
    total_visited = MapSet.union(total_visited, visited)

    start =
      Enum.reduce_while(map, nil, fn {key, _}, acc ->
        if !MapSet.member?(total_visited, key) do
          {:halt, key}
        else
          {:cont, acc}
        end
      end)

    traverse_graph(map, start, [visited | groups], total_visited)
  end

  def split_into_groups(points, map, visited \\ MapSet.new())

  def split_into_groups([], _, visited), do: visited

  def split_into_groups([current | rest], map, visited) do
    if MapSet.member?(visited, current) do
      split_into_groups(rest, map, visited)
    else
      visited = MapSet.put(visited, current)
      symbol = Map.get(map, current)

      valid_neighbors =
        current
        |> get_neighbors()
        |> Enum.reduce([], fn coords, acc ->
          if Map.has_key?(map, coords) do
            [{coords, Map.get(map, coords)} | acc]
          else
            acc
          end
        end)
        |> Enum.filter(fn {point, new_symbol} ->
          symbol == new_symbol and !MapSet.member?(visited, point)
        end)
        |> Enum.map(fn {point, _} -> point end)

      split_into_groups(
        valid_neighbors ++ rest,
        map,
        visited
      )
    end
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> traverse_graph()
    |> count_fences_area()
  end
end
