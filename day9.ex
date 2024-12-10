defmodule Solution do
  @free_space 1
  @is_file 0
  @free_space_mark "."

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("", trim: true)
    |> Stream.map(&String.to_integer/1)
    |> Enum.with_index(&{&1, rem(&2, 2)})
  end

  def find_valid(seq, n_dots \\ 0)

  def find_valid([@free_space_mark | t], n_dots) do
    find_valid(t, n_dots + 1)
  end

  def find_valid([h | t], n_dots), do: {h, t, n_dots}

  def consume_sequence(input, acc \\ [], found_dots \\ 0, found_nums \\ 0)

  def consume_sequence({_, _, {n_dots, n_nums}}, acc, found_dots, found_nums)
      when found_dots == n_dots and n_nums == found_nums do
    acc
    |> Enum.reverse()
    |> Enum.map(&String.to_integer/1)
  end

  def consume_sequence(
        {[@free_space_mark | t], reversed, counts},
        acc,
        found_dots,
        found_nums
      ) do
    {next, rest, search_dots} = find_valid(reversed)

    consume_sequence(
      {t, rest, counts},
      [next | acc],
      found_dots + search_dots + 1,
      found_nums + 1
    )
  end

  def consume_sequence({[h | t], reversed, counts}, acc, found_dots, found_nums) do
    consume_sequence({t, reversed, counts}, [h | acc], found_dots, found_nums + 1)
  end

  def calculate_checksum(entries) do
    entries
    |> Enum.reduce({0, 0}, fn num, {acc, idx} -> {acc + num * idx, idx + 1} end)
    |> elem(0)
  end

  def parse_input(entries, acc \\ [], index \\ 0, counts \\ {0, 0})

  def parse_input([], acc, _, nums_dots) do
    {Enum.reverse(acc), acc, nums_dots}
  end

  def parse_input([{val, code} | t], acc, index, {n_dots, n_nums}) do
    case {val, code} do
      {val, @is_file} ->
        acc = (index |> Integer.to_string() |> List.duplicate(val)) ++ acc

        parse_input(t, acc, index + 1, {n_dots, n_nums + val})

      {val, @free_space} ->
        acc = List.duplicate(@free_space_mark, val) ++ acc
        parse_input(t, acc, index, {n_dots + val, n_nums})
    end
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> consume_sequence()
    |> calculate_checksum()
  end
end
