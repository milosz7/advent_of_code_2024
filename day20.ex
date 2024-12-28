defmodule Solution do
  @wall "#"
  @start "S"
  @cheat_cost 2
  @step 1
  @min_gain 100

  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  defp parse_maze(lines) do
    {walls, maze} =
      lines
      |> Stream.map(fn line -> String.split(line, "", trim: true) end)
      |> Stream.with_index()
      |> Stream.flat_map(fn {line, y} ->
        Enum.reduce(line, {[], 0}, fn elem, {acc, x} ->
          {[{x, y, elem} | acc], x + 1}
        end)
        |> elem(0)
      end)
      |> Stream.reject(fn {x, y, _symbol} -> x == 0 or y == 0 end)
      |> Enum.split_with(fn {_x, _y, symbol} -> symbol == @wall end)

    {x_start, y_start, _} = maze |> Enum.find(fn {_x, _y, value} -> value == @start end)
    start = {x_start, y_start}

    walls =
      walls |> Enum.reduce(MapSet.new(), fn {x, y, _val}, acc -> MapSet.put(acc, {x, y}) end)

    maze =
      maze |> Enum.reduce(MapSet.new(), fn {x, y, _val}, acc -> MapSet.put(acc, {x, y}) end)

    {maze, walls, start}
  end

  defp get_neighbors({x, y}, map) do
    candiates = [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]

    candiates
    |> Stream.filter(&MapSet.member?(map, &1))
  end

  defp dijkstra(queue, graph, distances, visited) do
    if :gb_sets.size(queue) == 0 do
      distances
    else
      {{current_distance, current_point}, queue} = :gb_sets.take_smallest(queue)
      visited = MapSet.put(visited, current_point)

      {distances, visited, queue} =
        current_point
        |> get_neighbors(graph)
        |> Stream.reject(&MapSet.member?(visited, &1))
        |> Enum.reduce(
          {distances, visited, queue},
          fn neighbor, {distances_acc, visited_acc, queue_acc} ->
            alt_distance = current_distance + @step
            current_neigbor_distance = Map.get(distances_acc, neighbor)

            if alt_distance < current_neigbor_distance do
              distances_acc = Map.put(distances_acc, neighbor, alt_distance)
              queue_acc = :gb_sets.add({alt_distance, neighbor}, queue_acc)
              {distances_acc, visited_acc, queue_acc}
            else
              queue_acc = :gb_sets.add({current_neigbor_distance, neighbor}, queue_acc)
              {distances_acc, visited_acc, queue_acc}
            end
          end
        )

      dijkstra(queue, graph, distances, visited)
    end
  end

  defp get_two_picosecond_cheat({x, y}, maze) do
    vertical = [{x, y - 1}, {x, y + 1}]
    horizontal = [{x - 1, y}, {x + 1, y}]

    cond do
      Enum.all?(vertical, &MapSet.member?(maze, &1)) -> vertical
      Enum.all?(horizontal, &MapSet.member?(maze, &1)) -> horizontal
      true -> nil
    end
  end

  defp find_two_picosecond_cheats(walls, maze) do
    walls
    |> Enum.reduce(MapSet.new(), fn wall, acc ->
      cheat = get_two_picosecond_cheat(wall, maze)

      if cheat do
        MapSet.put(acc, cheat)
      else
        acc
      end
    end)
  end

  defp measure_two_picosecond_cheats(cheats, distances) do
    cheats
    |> Enum.reduce(%{}, fn cheat, acc ->
      [from, to] = Enum.sort_by(cheat, fn pos -> Map.get(distances, pos) end)
      cheat_saved = distances[to] - distances[from] - @cheat_cost
      Map.put(acc, {from, to}, cheat_saved)
    end)
  end

  def solve_1(path) do
    {maze, walls, start} =
      path
      |> read_file()
      |> parse_maze()

    queue = :gb_sets.from_list([{0, start}])
    visited = MapSet.new([start])
    distances = %{start => 0}

    distances = dijkstra(queue, maze, distances, visited)
    cheats = find_two_picosecond_cheats(walls, maze)

    measure_two_picosecond_cheats(cheats, distances)
    |> Map.values()
    |> Enum.reduce(%{}, fn val, acc -> Map.update(acc, val, 1, &(&1 + 1)) end)
    |> Enum.filter(fn {k, _v} -> k >= @min_gain end)
    |> Enum.reduce(0, fn {_k, v}, acc -> acc + v end)
  end

  def find_twenty_picosecond_for_point({x0, y0} = point, maze, distances) do
    point
    # |> IO.inspect(label: "point")
    |> get_surrounding(maze)
    # |> IO.inspect(label: "neighbors")
    |> Enum.reduce(MapSet.new(), fn {x, y, len}, acc ->
      MapSet.put(acc, {{x0, y0}, {x, y}, len})
    end)
    # |> IO.inspect(label: "mapset_distances")
    # |> Stream.filter(fn {p1, p2, _len} -> distances[p1] < distances[p2] end)
    |> Enum.filter(fn {p1, p2, len} -> distances[p2] - distances[p1] - len >= @min_gain end)
    # |> IO.inspect(label: "filtered_distances")
    |> Enum.reduce(%{}, fn {p1, p2, len}, acc ->
      Map.put(acc, {p1, p2, len}, distances[p2] - distances[p1] - len)
    end)
  end

  def get_surrounding({x0, y0}, maze, range \\ 20) do
    for y <- (y0 - range)..(y0 + range), x <- (x0 - range)..(x0 + range) do
      {x, y, abs(x - x0) + abs(y - y0)}
    end
    |> Stream.filter(fn {x, y, dist} -> dist <= range end)
    |> Stream.filter(fn {x, y, _dist} -> MapSet.member?(maze, {x, y}) end)
  end

  def find_twenty_picosecond_cheats(maze, distances) do
    maze
    |> Task.async_stream(&find_twenty_picosecond_for_point(&1, maze, distances))
    |> Enum.reduce([], fn {:ok, res}, acc -> [res | acc] end)

    # |> Enum.map(&find_twenty_picosecond_for_point(&1, maze, distances))
  end

  def solve_2(path) do
    {maze, walls, start} =
      path
      |> read_file()
      |> parse_maze()

    queue = :gb_sets.from_list([{0, start}])
    visited = MapSet.new([start])
    distances = %{start => 0}

    distances = dijkstra(queue, maze, distances, visited)

    find_twenty_picosecond_cheats(maze, distances)
    |> Enum.flat_map(fn data ->
      data
      # |> IO.inspect()
      # |> Stream.filter(&(map_size(&1) > 0))
      |> Enum.reduce(%{}, fn {_key, val}, acc -> Map.update(acc, val, 1, &(&1 + 1)) end)

      # |> IO.inspect()
      # |> Enum.filter(fn {k, _v} -> k >= 20 end)
    end)
    # |> Enum.reduce(%{}, fn {key, val}, acc -> Map.update(acc, key, val, &(&1 + val)) end)
    |> IO.inspect()
    |> Enum.reduce(0, fn {_k, v}, acc -> acc + v end)

    # |> Enum.reduce(%{}, fn {key, val}, acc -> Map.update(acc, key, val, &(&1 + val)) end)
    #   |> Map.values()
    # |> Enum.sum()
  end
end
