defmodule Solution do
  @accept "A"

  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  defp parse_input(lines) do
    lines
    |> Enum.map(&String.split(&1, "", trim: true))
  end

  defp numpad_map() do
    positions =
      for x <- 0..3, y <- 0..2, reduce: MapSet.new() do
        acc -> MapSet.put(acc, {x, y})
      end
      |> MapSet.delete({3, 0})

    pos_to_key =
      %{
        {0, 0} => "7",
        {0, 1} => "8",
        {0, 2} => "9",
        {1, 0} => "4",
        {1, 1} => "5",
        {1, 2} => "6",
        {2, 0} => "1",
        {2, 1} => "2",
        {2, 2} => "3",
        {3, 1} => "0",
        {3, 2} => "A"
      }

    {positions, pos_to_key}
  end

  defp keypad_map() do
    positions =
      for x <- 0..1, y <- 0..2, reduce: MapSet.new() do
        acc -> MapSet.put(acc, {x, y})
      end
      |> MapSet.delete({0, 0})

    pos_to_btn = %{
      {0, 1} => "^",
      {0, 2} => "A",
      {1, 0} => "<",
      {1, 1} => "v",
      {1, 2} => ">"
    }

    {positions, pos_to_btn}
  end

  defp get_neighbors({row, col}, grid) do
    candidates = [{row, col + 1}, {row, col - 1}, {row + 1, col}, {row - 1, col}]

    Enum.filter(candidates, fn {x, y} -> MapSet.member?(grid, {x, y}) end)
  end

  defp bfs(to_visit, grid, visited \\ Map.new())

  defp bfs([], grid, visited), do: visited

  defp bfs([{coords, distance} | rest], grid, visited) do
    if coords in visited do
      bfs(rest, visited)
    else
      visited = Map.put(visited, coords, distance)

      neighbors =
        get_neighbors(coords, grid)
        |> Enum.reject(&Map.has_key?(visited, &1))
        |> Enum.map(fn point -> {point, distance + 1} end)

      bfs(rest ++ neighbors, grid, visited)
    end
  end

  defp backtrack_bfs(paths, distances, target, grid, finished_paths \\ [])

  defp backtrack_bfs([], _distances, _target, _grid, finished_paths) do
    finished_paths |> Enum.map(&coords_to_arrows/1)
  end

  defp backtrack_bfs(
         [[last_node | _path_nodes] = path | other_paths],
         distances,
         target,
         grid,
         finished_paths
       )
       when last_node == target do
    backtrack_bfs(other_paths, distances, target, grid, [path | finished_paths])
  end

  defp backtrack_bfs([current_path | other_paths], distances, target, grid, finished_paths) do
    last_node = hd(current_path)
    last_distance = Map.get(distances, last_node)
    neighbors = last_node |> get_neighbors(grid)

    valid_neighbors =
      neighbors
      |> Enum.filter(fn point -> Map.get(distances, point) == last_distance - 1 end)

    new_paths =
      valid_neighbors
      |> Enum.map(&[&1 | current_path])

    backtrack_bfs(new_paths ++ other_paths, distances, target, grid, finished_paths)
  end

  defp coords_to_arrows(pairs, out \\ "")

  defp coords_to_arrows([[{prev_row, prev_col}, {next_row, next_col}] | rest], out) do
    cond do
      prev_row < next_row -> coords_to_arrows(rest, out <> "v")
      prev_row > next_row -> coords_to_arrows(rest, out <> "^")
      prev_col > next_col -> coords_to_arrows(rest, out <> "<")
      prev_col < next_col -> coords_to_arrows(rest, out <> ">")
    end
  end

  defp coords_to_arrows([], out), do: out

  defp coords_to_arrows(sequence, "") do
    coords_to_arrows(Enum.chunk_every(sequence, 2, 1, :discard))
  end

  defp find_paths(positions, pos_to_key) do
    positions
    |> Enum.map(fn pos -> {pos, bfs([{pos, 0}], positions)} end)
    |> Enum.map(fn {pos, distances} ->
      combs = Enum.zip(Stream.cycle([pos]), positions)

      combs
      |> Enum.reduce(%{}, fn {from, to}, acc ->
        paths = backtrack_bfs([[to]], distances, from, positions)
        Map.put(acc, {pos_to_key[from], pos_to_key[to]}, paths)
      end)
    end)
    |> Enum.reduce(%{}, fn map, map_acc -> Map.merge(map, map_acc) end)
  end

  defp build_sequence(keys, sequences_map, prev_key \\ @accept, sequences \\ [])

  defp build_sequence(<<>>, _sequences_map, _prev_key, sequences), do: sequences

  defp build_sequence(<<key::binary-size(1), rest::binary>>, sequences_map, prev_key, []) do
    sequences = sequences_map[{prev_key, key}] |> Enum.map(&(&1 <> @accept))
    build_sequence(rest, sequences_map, key, sequences)
  end

  defp build_sequence(<<key::binary-size(1), rest::binary>>, sequences_map, prev_key, sequences) do
    new_sequences = sequences_map[{prev_key, key}]
    sequences = for new_seq <- new_sequences, seq <- sequences, do: seq <> new_seq <> @accept
    build_sequence(rest, sequences_map, key, sequences)
  end

  defp shortest_sequence(keys, depth, sequences_map, cache \\ %{})

  defp shortest_sequence(keys, depth, sequences_map, cache) do
    if depth == 0 do
      {String.length(keys), cache}
    else
      case Map.get(cache, {keys, depth}) do
        nil ->
          subkeys = String.split(keys, ~r([^A-Z]*A), include_captures: true, trim: true)

          {total, updated_cache} =
            Enum.reduce(subkeys, {0, cache}, fn subkey, {acc, acc_cache} ->
              sequences = build_sequence(subkey, sequences_map)

              {min_len, latest_cache} =
                Enum.reduce(sequences, {nil, acc_cache}, fn seq, {curr_min, curr_cache} ->
                  {res_len, new_cache} =
                    shortest_sequence(seq, depth - 1, sequences_map, curr_cache)

                  new_min = min(curr_min, res_len)
                  {new_min, new_cache}
                end)

              {acc + min_len, latest_cache}
            end)

          final_cache = Map.put(updated_cache, {keys, depth}, total)
          {total, final_cache}

        cached ->
          {cached, cache}
      end
    end
  end

  def calculate_result(depth, input, numpad_map, keypad_map) do
    input_nums =
      input
      |> Enum.map(&String.replace(&1, @accept, ""))
      |> Enum.map(&String.to_integer/1)

    shortest_sequences =
      input
      |> Enum.map(
        &(build_sequence(&1, numpad_map)
          |> Enum.map(fn seq -> shortest_sequence(seq, depth, keypad_map) end))
      )
      |> Enum.map(&Enum.min_by(&1, fn {res, _cache} -> res end))
      |> Enum.map(&elem(&1, 0))

    Enum.zip(shortest_sequences, input_nums)
    |> Enum.reduce(0, fn {len, val}, acc -> acc + val * len end)
  end

  def solve(path) do
    {positions_numpad, pos_to_key_numpad} = numpad_map()
    {positions_keypad, pos_to_key_keypad} = keypad_map()

    numpad_direction_map = find_paths(positions_numpad, pos_to_key_numpad)
    keypad_direction_map = find_paths(positions_keypad, pos_to_key_keypad)

    input = read_file(path)

    depth_2 = calculate_result(2, input, numpad_direction_map, keypad_direction_map)
    depth_25 = calculate_result(25, input, numpad_direction_map, keypad_direction_map)

    {depth_2, depth_25}
  end
end
