defmodule Solution do
  @max_x 70
  @max_y 70
  @n_bytes 1024
  @step 1
  @start {0, 0}
  @finish {@max_x, @max_y}

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(lines) do
    {wall_bytes, rest_bytes} = Enum.split(lines, @n_bytes)

    {wall_bytes, rest_bytes} =
      lines
      |> Stream.map(&String.split(&1, ",", trim: true))
      |> Stream.map(&Enum.map(&1, fn num -> String.to_integer(num) end))
      |> Enum.split(@n_bytes)

    walls =
      wall_bytes
      |> Enum.reduce(MapSet.new(), fn [x, y], acc -> MapSet.put(acc, {x, y}) end)

    grid =
      for x <- 0..@max_x, y <- 0..@max_y, reduce: MapSet.new() do
        acc ->
          if {x, y} in walls do
            acc
          else
            MapSet.put(acc, {x, y})
          end
      end

    {grid, rest_bytes}
  end

  def get_neighbors({x, y}, map) do
    candiates = [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]

    candiates
    |> Stream.filter(&MapSet.member?(map, &1))
  end

  def dijkstra(queue, graph, distances, visited) do
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

  def solve_2(path) do
    {graph, rest_bytes} =
      path
      |> read_file()
      |> parse_input()

    queue = :gb_sets.from_list([{0, @start}])
    visited = MapSet.new([@start])
    distances = %{@start => 0}

    rest_bytes
    |> Enum.reduce_while(graph, fn [x, y], acc ->
      acc = MapSet.delete(acc, {x, y})
      new_distances = dijkstra(queue, acc, distances, visited)

      if Map.get(new_distances, @finish) == nil do
        {:halt, {x, y}}
      else
        {:cont, acc}
      end
    end)
  end

  def solve_1(path) do
    {graph, rest_bytes} =
      path
      |> read_file()
      |> parse_input()

    queue = :gb_sets.from_list([{0, @start}])
    visited = MapSet.new([@start])
    distances = %{@start => 0}

    distances = dijkstra(queue, graph, distances, visited)

    Map.get(distances, @finish)
  end
end
