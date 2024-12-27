defmodule Solution do
  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  defp parse_input([towels, patterns]) do
    towels =
      for towel <- String.split(towels, ", ", trim: true), reduce: MapSet.new() do
        acc -> MapSet.put(acc, towel)
      end

    patterns =
      for pattern <- String.split(patterns, "\n", trim: true), reduce: [] do
        acc -> [pattern | acc]
      end

    {towels, patterns}
  end

  defp init_table(sequence) do
    len = String.length(sequence)

    table =
      1..len
      |> Enum.reduce(%{}, fn n, acc -> Map.put(acc, n, 0) end)
      |> Map.put(0, 1)

    {table, len}
  end

  defp validate_sequence(sequence, len, table, towels, idx \\ 0)
  defp validate_sequence(_, len, table, _, idx) when len + 1 == idx, do: table[len]

  defp validate_sequence(sequence, len, table, towels, idx) do
    table =
      0..idx
      |> Enum.reduce(table, fn n, acc ->
        substr = String.slice(sequence, n..(idx - 1)//1)

        if acc[n] != 0 and substr in towels do
          Map.update(acc, idx, nil, &(&1 + Map.get(acc, n)))
        else
          acc
        end
      end)

    validate_sequence(sequence, len, table, towels, idx + 1)
  end

  def solve(path) do
    {towels, patterns} =
      path
      |> read_file()
      |> parse_input()

    patterns
    |> Task.async_stream(fn pattern ->
      {table, len} = init_table(pattern)
      validate_sequence(pattern, len, table, towels)
    end)
    |> Enum.reduce({0, 0}, fn {:ok, res}, {valid, n_patterns} ->
      if res != 0, do: {valid + 1, n_patterns + res}, else: {valid, n_patterns}
    end)
  end
end
