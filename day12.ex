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

  def left({x, y}), do: {x - 1, y}
  def right({x, y}), do: {x + 1, y}
  def top({x, y}), do: {x, y - 1}
  def bottom({x, y}), do: {x, y + 1}
  def bottom_right({x, y}), do: {x + 1, y + 1}
  def bottom_left({x, y}), do: {x - 1, y + 1}
  def top_right({x, y}), do: {x + 1, y - 1}
  def top_left({x, y}), do: {x - 1, y - 1}

  def check_two_neighbors(point, group) do
    cond do
      MapSet.member?(group, left(point)) and MapSet.member?(group, right(point)) ->
        0

      MapSet.member?(group, top(point)) and MapSet.member?(group, bottom(point)) ->
        0

      MapSet.member?(group, left(point)) and MapSet.member?(group, top(point)) ->
        if MapSet.member?(group, top_left(point)), do: 1, else: 2

      MapSet.member?(group, left(point)) and MapSet.member?(group, bottom(point)) ->
        if MapSet.member?(group, bottom_left(point)), do: 1, else: 2

      MapSet.member?(group, right(point)) and MapSet.member?(group, top(point)) ->
        if MapSet.member?(group, top_right(point)), do: 1, else: 2

      MapSet.member?(group, right(point)) and MapSet.member?(group, bottom(point)) ->
        if MapSet.member?(group, bottom_right(point)), do: 1, else: 2
    end
  end

  def check_three_neighbors(point, group) do
    cond do
      MapSet.member?(group, left(point)) and MapSet.member?(group, right(point)) and
          MapSet.member?(group, top(point)) ->
        tl = if MapSet.member?(group, top_left(point)), do: 1, else: 0
        tr = if MapSet.member?(group, top_right(point)), do: 1, else: 0
        2 - tl - tr

      MapSet.member?(group, left(point)) and MapSet.member?(group, right(point)) and
          MapSet.member?(group, bottom(point)) ->
        bl = if MapSet.member?(group, bottom_left(point)), do: 1, else: 0
        br = if MapSet.member?(group, bottom_right(point)), do: 1, else: 0
        2 - bl - br

      MapSet.member?(group, top(point)) and MapSet.member?(group, right(point)) and
          MapSet.member?(group, bottom(point)) ->
        tr = if MapSet.member?(group, top_right(point)), do: 1, else: 0
        br = if MapSet.member?(group, bottom_right(point)), do: 1, else: 0
        2 - tr - br

      MapSet.member?(group, top(point)) and MapSet.member?(group, left(point)) and
          MapSet.member?(group, bottom(point)) ->
        tl = if MapSet.member?(group, top_left(point)), do: 1, else: 0
        bl = if MapSet.member?(group, bottom_left(point)), do: 1, else: 0
        2 - tl - bl
    end
  end

  def check_four_neighbors(point, group) do
    tl = if MapSet.member?(group, top_left(point)), do: 1, else: 0
    bl = if MapSet.member?(group, bottom_left(point)), do: 1, else: 0
    tr = if MapSet.member?(group, top_right(point)), do: 1, else: 0
    br = if MapSet.member?(group, bottom_right(point)), do: 1, else: 0
    4 - tl - bl - tr - br
  end

  def count_corners(points, group, corners \\ 0, area \\ 0)
  def count_corners([], _, corners, area), do: corners * area

  def count_corners([point | rest], group, corners, area) do
    neighbors =
      point |> get_neighbors() |> Enum.filter(&MapSet.member?(group, &1))

    case length(neighbors) do
      0 ->
        count_corners(rest, group, corners + 4, area + 1)

      1 ->
        count_corners(rest, group, corners + 2, area + 1)

      2 ->
        count_corners(rest, group, corners + check_two_neighbors(point, group), area + 1)

      3 ->
        count_corners(rest, group, corners + check_three_neighbors(point, group), area + 1)

      4 ->
        count_corners(rest, group, corners + check_four_neighbors(point, group), area + 1)
    end
  end

  def count_corners_all(groups) do
    groups
    |> Task.async_stream(fn group -> count_corners(MapSet.to_list(group), group) end)
    |> Enum.reduce(0, fn {:ok, res}, acc -> acc + res end)
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> traverse_graph()
    |> count_fences_area()
  end

  def solve_2(path) do
    path
    |> read_file()
    |> parse_input()
    |> traverse_graph()
    |> count_corners_all()
  end
end
