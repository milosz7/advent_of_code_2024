defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(input) do
    input
    |> Enum.reduce([[], []], fn line, [acc1, acc2] ->
      [l, r] =
        String.split(line, ~r{\s+})
        |> Enum.map(&String.to_integer/1)

      [[l | acc1], [r | acc2]]
    end)
  end

  def sort_lists(lists) do
    lists
    |> Enum.map(&Enum.sort/1)
  end

  def calculate_distance(lists) do
    lists
    |> Enum.zip()
    |> Enum.reduce(0, fn {l, r}, acc -> acc + abs(l - r) end)
  end

  def calculate_similarity([left, right]) do
    counts_map =
      right
      |> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)

    left
    |> Enum.reduce(0, fn x, acc -> Map.get(counts_map, x, 0) * x + acc end)
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> sort_lists()
    |> calculate_distance()
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> calculate_similarity()
  end
end
