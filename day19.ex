defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  def parse_input([towels, patterns]) do
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

  def init_table(sequence) do
    len = String.length(sequence)

    table =
      1..len
      |> Enum.reduce(%{}, fn n, acc -> Map.put(acc, n, false) end)
      |> Map.put(0, true)

    {table, len}
  end

  def validate_sequence(_, len, table, _, idx) when len + 1 == idx, do: table[len]

  def validate_sequence(sequence, len, table, towels, idx \\ 0) do
    table =
      0..idx
      |> Enum.reduce_while(table, fn n, acc ->
        substr = String.slice(sequence, n..(idx - 1)//1)

        if acc[n] and substr in towels do
          {:halt, Map.put(acc, idx, true)}
        else
          {:cont, acc}
        end
      end)

    validate_sequence(sequence, len, table, towels, idx + 1)
  end

  def solve_1(path) do
    {towels, patterns} =
      path
      |> read_file()
      |> parse_input()

    patterns
    |> Enum.reduce([], fn pattern, acc ->
      {table, len} = init_table(pattern)
      [validate_sequence(pattern, len, table, towels) | acc]
    end)
    |> Enum.reduce(0, fn res, acc -> if res, do: acc + 1, else: acc end)
  end
end
