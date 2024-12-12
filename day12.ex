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

  def traverse_graph(
        map,
        start \\ {0, 0},
        groups \\ [],
        total_visited \\ MapSet.new(),
        fence_price \\ 0
      )

  def traverse_graph(_, nil, _, _, fence_price), do: fence_price

  def traverse_graph(
        map,
        start,
        groups,
        total_visited,
        fence_price
      ) do
    {visited, fence} = split_into_groups([start], map)
    total_visited = MapSet.union(total_visited, visited)

    start =
      Enum.reduce_while(map, nil, fn {key, _}, acc ->
        if !MapSet.member?(total_visited, key) do
          {:halt, key}
        else
          {:cont, acc}
        end
      end)

    fence_price = fence_price + MapSet.size(visited) * fence

    traverse_graph(map, start, [visited | groups], total_visited, fence_price)
  end

  def split_into_groups(points, map, visited \\ MapSet.new(), total_fences \\ 0)

  def split_into_groups([], _, visited, total_fences), do: {visited, total_fences}

  def split_into_groups([current | rest], map, visited, total_fences) do
    if MapSet.member?(visited, current) do
      split_into_groups(rest, map, visited, total_fences)
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
        |> Enum.filter(fn {_, new_symbol} ->
          symbol == new_symbol
        end)

      new_points =
        valid_neighbors
        |> Stream.reject(fn {point, _} -> MapSet.member?(visited, point) end)
        |> Enum.map(fn {point, _} -> point end)

      split_into_groups(
        new_points ++ rest,
        map,
        visited,
        total_fences + @max_fences - length(valid_neighbors)
      )
    end
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> traverse_graph()
  end
end
