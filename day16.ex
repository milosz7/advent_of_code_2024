defmodule Solution do
  require Integer
  @wall "#"
  @start "S"
  @finish "E"
  @infinity 100_000_000_000

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_maze(lines) do
    maze =
      lines
      |> Stream.map(fn line -> String.split(line, "", trim: true) end)
      |> Stream.with_index()
      |> Stream.flat_map(fn {line, y} ->
        Enum.reduce(line, {[], 0}, fn elem, {acc, x} ->
          {[{x, y, elem} | acc], x + 1}
        end)
        |> elem(0)
      end)
      |> Enum.reduce(%{}, fn {x, y, val}, acc -> Map.put(acc, {x, y}, val) end)
      |> Map.reject(fn {_, v} -> v == @wall end)
      |> visualise(0, 0)

    {start, _} = maze |> Enum.find(fn {{x, y}, value} -> value == @start end)
    {finish, _} = maze |> Enum.find(fn {{x, y}, value} -> value == @finish end)

    {maze |> Map.keys() |> MapSet.new(), start, finish}
  end

  def get_weight(:north, :east), do: 1001
  def get_weight(:north, :south), do: 2001
  def get_weight(:north, :west), do: 1001

  def get_weight(:east, :north), do: 1001
  def get_weight(:east, :south), do: 1001
  def get_weight(:east, :west), do: 2001

  def get_weight(:south, :north), do: 2001
  def get_weight(:south, :east), do: 1001
  def get_weight(:south, :west), do: 1001

  def get_weight(:west, :north), do: 1001
  def get_weight(:west, :east), do: 2001
  def get_weight(:west, :south), do: 1001

  def get_weight(_, _), do: 1

  def get_neighbors({x, y}, map) do
    candidates = [
      {{x + 1, y}, :east},
      {{x - 1, y}, :west},
      {{x, y + 1}, :south},
      {{x, y - 1}, :north}
    ]

    candidates
    |> Enum.filter(fn {{x, y}, _} -> MapSet.member?(map, {x, y}) end)
  end

  def dijkstra(queue, graph, distances, global_distances, prev, visited) do
    if MapSet.size(queue) == 0 do
      {distances, distances, prev}
    else
      {current, current_direction} =
        queue
        |> Enum.min_by(fn val -> Map.get(distances, val) end)

      queue = MapSet.delete(queue, {current, current_direction})

      visited = MapSet.put(visited, {current, current_direction})

      {prev, distances, global_distances, visited} =
        current
        |> get_neighbors(graph)
        |> Enum.reject(fn point -> MapSet.member?(visited, point) end)
        |> Enum.reduce(
          {prev, distances, global_distances, visited},
          fn {neighbor, direction}, {prev_acc, distances_acc, global_acc, visited_acc} ->
            alt =
              Map.get(distances_acc, {current, current_direction}) +
                get_weight(direction, current_direction)

            current_neighbor_dist =
              Map.get(distances_acc, {neighbor, direction})

            cond do
              alt <= current_neighbor_dist ->
                new_distances = Map.put(distances_acc, {neighbor, direction}, alt)

                new_prev =
                  if alt < current_neighbor_dist do
                    Map.put(
                      prev_acc,
                      {neighbor, direction},
                      MapSet.new([{current, current_direction}])
                    )
                  else
                    Map.update(
                      prev_acc,
                      {neighbor, direction},
                      MapSet.new([{current, current_direction}]),
                      &MapSet.put(&1, {current, current_direction})
                    )
                  end

                {new_prev, new_distances, global_acc, visited_acc}

              true ->
                {prev_acc, distances_acc, global_acc, visited_acc}
            end
          end
        )

      dijkstra(queue, graph, distances, global_distances, prev, visited)
    end
  end

  def prepare_dijkstra(points, start) do
    distances =
      points
      |> Enum.reduce(%{}, fn point, acc ->
        acc
        |> Map.put({point, :north}, @infinity)
        |> Map.put({point, :south}, @infinity)
        |> Map.put({point, :east}, @infinity)
        |> Map.put({point, :west}, @infinity)
      end)
      |> Map.put({start, :east}, 0)

    prev =
      points
      |> Enum.reduce(%{}, fn point, acc -> Map.put(acc, point, MapSet.new()) end)

    global_distances =
      points
      |> Enum.reduce(%{}, fn point, acc ->
        Map.put(acc, point, @infinity)
      end)
      |> Map.put(start, 0)

    {distances, prev, global_distances}
  end

  def solve_1(path) do
    {points, start, finish} =
      path
      |> read_file()
      |> parse_maze()

    {distances, prev, global_distances} = prepare_dijkstra(points, start)

    queue =
      points
      |> Enum.reduce(MapSet.new(), fn point, acc ->
        acc
        |> MapSet.put({point, :north})
        |> MapSet.put({point, :south})
        |> MapSet.put({point, :west})
        |> MapSet.put({point, :east})
      end)

    {distances, global_distances, prev} =
      dijkstra(
        queue,
        points,
        distances,
        global_distances,
        prev,
        MapSet.new([{start, :east}])
      )

    {traversal_start_tile, score} =
      distances
      |> Map.filter(fn {{coords, _dist}, _score} -> coords == finish end)
      |> Enum.min_by(fn {{_coords, _dist}, score} -> score end)

    {traverse_previous([traversal_start_tile], prev, {start, :east}), score}
  end

  def traverse_previous(to_visit, previous, start, visited \\ MapSet.new())

  def traverse_previous([current | rest], previous, start, visited) do
    if current == start do
      MapSet.size(visited) + 1
    else
      to_visit = previous[current]

      nodes =
        to_visit |> Enum.reduce(MapSet.new(), fn {point, _dir}, acc -> MapSet.put(acc, point) end)

      traverse_previous(
        rest ++ MapSet.to_list(to_visit),
        previous,
        start,
        MapSet.union(visited, nodes)
      )
    end
  end

  def visualise(map, x_lim, y_lim) do
    0..15
    |> Enum.map(fn y ->
      0..15
      |> Enum.reduce("", fn x, acc ->
        present = Map.get(map, {x, y}, "#")
        acc <> present
      end)
    end)
    |> Enum.each(&IO.inspect/1)

    map
  end

  def visualise_path(map, path) do
    0..15
    |> Enum.map(fn y ->
      0..15
      |> Enum.reduce("", fn x, acc ->
        present =
          if MapSet.member?(path, {x, y}),
            do: "O",
            else: if(MapSet.member?(map, {x, y}), do: ".", else: "#")

        acc <> present
      end)
    end)
    |> Enum.each(&IO.inspect/1)

    path
  end

  def visualise_distances(map) do
    0..15
    |> Enum.map(fn y ->
      0..15
      |> Enum.reduce("", fn x, acc ->
        present = Map.get(map, {x, y}, "#")
        present = if is_number(present), do: Integer.to_string(present), else: present
        acc <> String.pad_leading(present, 6)
      end)
    end)
    |> Enum.each(&IO.inspect/1)

    map
  end
end