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

  def get_weight(nil, _), do: 1
  def get_weight(_, nil), do: 1
  def get_weight(:h, :h), do: 1
  def get_weight(:v, :v), do: 1
  def get_weight(_, _), do: 1001

  def get_neighbors({x, y}, map) do
    candidates = [{{x + 1, y}, :h}, {{x - 1, y}, :h}, {{x, y + 1}, :v}, {{x, y - 1}, :v}]

    candidates
    |> Enum.filter(fn {{x, y}, _} -> MapSet.member?(map, {x, y}) end)
  end

  def dijkstra(queue = %MapSet{map: map}, graph, distances, previous, directions)
      when map_size(map) == 0,
      do: {distances, previous}

  def dijkstra(queue, graph, distances, previous, directions) do
    current =
      queue
      |> Enum.min_by(fn val -> Map.get(distances, val) end)

    queue = MapSet.delete(queue, current)

    {previous, distances, directions} =
      current
      |> get_neighbors(graph)
      |> Enum.reduce(
        {previous, distances, directions},
        fn {neighbor, direction}, {previous_acc, distances_acc, directions_acc} ->
          previous_direction = directions_acc |> Map.get(current)
          alt = Map.get(distances_acc, current) + get_weight(direction, previous_direction)

          if alt < Map.get(distances_acc, neighbor) do
            {previous_acc |> Map.put(neighbor, current), distances_acc |> Map.put(neighbor, alt),
             directions_acc |> Map.put(neighbor, direction)}
          else
            {previous_acc, distances_acc, directions_acc}
          end
        end
      )

    dijkstra(queue, graph, distances, previous, directions)
  end

  def prepare_dijkstra(points, start) do
    distances =
      points
      |> Enum.reduce(%{}, fn point, acc -> Map.put(acc, point, @infinity) end)
      |> Map.put(start, 0)

    prev =
      points
      |> Enum.reduce(%{}, fn point, acc -> Map.put(acc, point, nil) end)

    directions =
      points
      |> Enum.reduce(%{}, fn point, acc -> Map.put(acc, point, nil) end)
      |> Map.put(start, :h)

    {distances, prev, directions}
  end

  def solve_1(path) do
    {points, start, finish} =
      path
      |> read_file()
      |> parse_maze()

    {distances, prev, directions} = prepare_dijkstra(points, start)

    {distances, prev} =
      dijkstra(points, points, distances, prev, directions)

    best_distance = distances |> Map.get(finish)
  end

  def solve_2(path) do
    {points, start, finish} =
      path
      |> read_file()
      |> parse_maze()

    {distances, prev, directions} = prepare_dijkstra(points, start)

    {distances, prev} =
      dijkstra(points, points, distances, prev, directions)

    best_distance = distances |> Map.get(finish)

    path = traverse_previous(finish, prev)
    best_path = MapSet.new(path)

    best_path_with_neighbors =
      best_path
      |> Enum.reduce(best_path, fn point, acc ->
        neighbors = get_neighbors(point, points) |> MapSet.new()
        MapSet.union(acc, neighbors)
      end)

    paths_without_one_first_run =
      best_path_with_neighbors
      |> Task.async_stream(
        fn elem ->
          new_queue = MapSet.delete(points, elem)
          {new_distances, new_prev, new_directions} = prepare_dijkstra(new_queue, start)

          {new_distances, new_prev} =
            dijkstra(new_queue, new_queue, new_distances, new_prev, new_directions)

          new_best = new_distances |> Map.get(finish)

          {new_best == best_distance,
           new_best != best_distance || traverse_previous(finish, new_prev)}
        end,
        timeout: :infinity
      )
      |> Enum.reduce([], fn {:ok, res}, acc -> [res | acc] end)
      |> Enum.filter(fn {is_equal, _path} -> is_equal end)
      |> Enum.reduce(best_path, fn {_is_equal, path}, acc ->
        path |> MapSet.new() |> MapSet.union(acc)
      end)
      |> MapSet.put(finish)
      |> MapSet.size()
  end

  def traverse_previous(nodes, previous, visited \\ [])
  def traverse_previous(nil, _, visited), do: tl(visited)

  def traverse_previous(current, previous, visited) do
    to_visit = previous[current]
    traverse_previous(to_visit, previous, [to_visit | visited])
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
