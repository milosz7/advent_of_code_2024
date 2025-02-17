defmodule Solution do
  @row_length 5
  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  defp split_into_locks_keys(schematics) do
    schematics
    |> Enum.split_with(fn <<first::binary-size(1), _rest::binary>> -> first == "." end)
  end

  defp parse_schematic(schematic) do
    schematic
    |> String.split("\n")
  end

  defp parse_data({keys, locks}) do
    keys_parsed =
      keys
      |> Enum.map(&parse_schematic/1)
      |> Enum.map(&Enum.reverse/1)
      |> Enum.map(&parse_schematic_lines/1)

    locks_parsed =
      locks
      |> Enum.map(&parse_schematic/1)
      |> Enum.map(&parse_schematic_lines/1)

    {keys_parsed, locks_parsed}
  end

  defp preprocess_schematics({keys, locks}) do
    keys
    |> Enum.reduce(0, fn key, acc -> acc + find_matches(key, locks) end)
  end

  defp is_match?(key, lock) do
    [key, lock]
    |> Enum.zip()
    |> Enum.any?(fn {k, l} -> k + l > @row_length end)
    |> Kernel.not()
  end

  defp find_matches(key, locks) do
    locks
    |> Enum.reduce(0, fn lock, acc -> if is_match?(key, lock), do: acc + 1, else: acc end)
  end

  defp parse_schematic_lines(schematic) do
    schematic
    |> tl()
    |> Enum.map(&String.split(&1, "", trim: true))
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn line -> Enum.filter(line, &(&1 == "#")) end)
    |> Enum.map(&length/1)
  end

  def solve_1(path) do
    path
    |> read_file()
    |> split_into_locks_keys()
    |> parse_data()
    |> preprocess_schematics()
  end
end
