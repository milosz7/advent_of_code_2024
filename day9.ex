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

  def parse_data(data) do
    data =
      data
      |> Enum.reduce({[], 0, 0}, fn {len, code}, {acc, idx, id} ->
        case {len, code} do
          {len, @free_space} ->
            next_idx = idx + len
            {[{@free_space_mark, idx, len} | acc], next_idx, id}

          {len, @is_file} ->
            next_idx = idx + len
            {[{id, idx, len} | acc], next_idx, id + 1}
        end
      end)
      |> elem(0)

    disk_data =
      data |> Enum.filter(fn {val, _, _} -> val != @free_space_mark end)

    free_space =
      data |> Enum.filter(fn {val, _, _} -> val == @free_space_mark end) |> Enum.reverse()

    {disk_data, free_space}
  end

  def update_free_space(file, space, updated \\ :noupdate, acc \\ [])
  def update_free_space(file, [], _, acc), do: {file, Enum.reverse(acc)}

  def update_free_space(
        {id, f_start, f_len} = file,
        [{symbol, s_start, s_len} = space | rest],
        :noupdate,
        acc
      ) do
    if f_start > s_start and f_len <= s_len do
      update_free_space({id, s_start, f_len}, rest, :update, [
        {symbol, s_start + f_len, s_len - f_len} | acc
      ])
    else
      update_free_space(file, rest, :noupdate, [space | acc])
    end
  end

  def update_free_space(file, [fragment | rest], :update, acc) do
    update_free_space(file, rest, :update, [fragment | acc])
  end

  def reorder_files(input, acc \\ [])

  def reorder_files({[], _}, acc), do: acc

  def reorder_files({[file | rest], free_space}, acc) do
    {file, free_space} = update_free_space(file, free_space)
    reorder_files({rest, free_space}, [file | acc])
  end

  def checksum_from_tuples(reordered_disk) do
    reordered_disk
    |> Enum.reduce(0, fn {id, start, len}, acc ->
      sum =
        for(num <- start..(start + len - 1), do: id * num)
        |> Enum.sum()

      acc + sum
    end)
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> parse_data()
    |> reorder_files()
    |> checksum_from_tuples()
  end
end
