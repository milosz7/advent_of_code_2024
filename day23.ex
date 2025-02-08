defmodule Solution do
  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  defp parse_input(lines) do
    lines
    |> Enum.reduce({MapSet.new(), MapSet.new()}, fn line, {edge_acc, vertex_acc} ->
      [vertex0, vertex1] = String.split(line, "-", trim: true)
      edge_acc = MapSet.put(edge_acc, {vertex0, vertex1})
      vertex_acc = vertex_acc |> MapSet.put(vertex0) |> MapSet.put(vertex1)
      {edge_acc, vertex_acc}
    end)
  end

  defp has_edge?(edges, v1, v2) do
    MapSet.member?(edges, {v1, v2}) || MapSet.member?(edges, {v2, v1})
  end

  defp find_three_cycles({edges, vertices}) do
    for v0 <- vertices, {v1, v2} <- edges, reduce: MapSet.new() do
      acc ->
        if has_edge?(edges, v0, v2) and has_edge?(edges, v0, v1),
          do: MapSet.put(acc, Enum.sort([v0, v1, v2])),
          else: acc
    end
  end

  defp expand_clique(vertices, edges, visited, clique \\ MapSet.new())

  defp expand_clique([], _, _, clique), do: clique

  defp expand_clique([vertex | vertices_rest], edges, visited, clique) do
    if MapSet.member?(visited, vertex) do
      expand_clique(vertices_rest, edges, visited, clique)
    else
      visited = MapSet.put(visited, vertex)

      if Enum.all?(clique, fn clique_vertex -> has_edge?(edges, clique_vertex, vertex) end) do
        expand_clique(vertices_rest, edges, visited, MapSet.put(clique, vertex))
      else
        expand_clique(vertices_rest, edges, visited, clique)
      end
    end
  end

  defp find_max_clique(graph, visited \\ MapSet.new(), max_clique \\ MapSet.new())

  defp find_max_clique({edges, vertices}, visited, max_clique) do
    if MapSet.size(visited) == MapSet.size(vertices) do
      max_clique
    else
      clique = expand_clique(MapSet.to_list(vertices), edges, visited)

      visited =
        for vertex <- clique, reduce: visited do
          acc -> MapSet.put(acc, vertex)
        end

      if MapSet.size(clique) > MapSet.size(max_clique) do
        find_max_clique({edges, vertices}, visited, clique)
      else
        find_max_clique({edges, vertices}, visited, max_clique)
      end
    end
  end

  defp construct_password(clique) do
    clique
    |> Enum.sort(:asc)
    |> Enum.join(",")
  end

  defp filter_cycles(cycles) do
    cycles
    |> Enum.filter(
      &Enum.any?(&1, fn <<first::binary-size(1), _rest::binary>> -> first == "t" end)
    )
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> find_three_cycles()
    |> filter_cycles()
    |> length()
  end

  def solve_2(path) do
    path
    |> read_file()
    |> parse_input()
    |> find_max_clique()
    |> construct_password()
  end
end
