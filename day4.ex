defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def find_xmas(line, start \\ 0, acc \\ 0, len \\ nil)
  def find_xmas(_, _, acc, len) when len < 4, do: acc

  def find_xmas(line, start, acc, _) do
    substring = String.slice(line, start, 4)

    acc =
      case substring do
        "XMAS" -> acc + 1
        "SAMX" -> acc + 1
        _ -> acc
      end

    find_xmas(line, start + 1, acc, String.length(substring))
  end

  def find_crosses([], acc), do: acc

  def find_crosses(candidates, acc \\ 0) do
    [{l, r} | t] = candidates

    acc =
      case {l, r} do
        {"MAS", "MAS"} -> acc + 1
        {"SAM", "SAM"} -> acc + 1
        {"MAS", "SAM"} -> acc + 1
        {"SAM", "MAS"} -> acc + 1
        _ -> acc
      end

    find_crosses(t, acc)
  end

  def character_split(line) do
    line
    |> String.split("", trim: true)
  end

  def transpose(input) do
    input
    |> Enum.map(&character_split/1)
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn line -> List.to_string(line) end)
  end

  def pad_leading(string, idx) do
    len = String.length(string)

    string
    |> String.slice(0, len - idx)
    |> String.pad_leading(len, "0")
  end

  def pad_trailing(string, idx) do
    len = String.length(string)

    string
    |> String.slice(idx, len)
    |> String.pad_trailing(len, "0")
  end

  def offset_leading(input) do
    input
    |> Enum.with_index()
    |> Enum.map(fn {line, index} -> pad_leading(line, index) end)
  end

  def offset_trailing(input) do
    input
    |> Enum.with_index()
    |> Enum.map(fn {line, index} -> pad_trailing(line, index) end)
  end

  def skew_leading(input, n, offset \\ 0) do
    input
    |> Enum.chunk_every(n, 1, :discard)
    |> Enum.map(fn chunk ->
      chunk |> offset_leading() |> transpose()
    end)
  end

  def skew_trailing(input, n, offset \\ 0) do
    input
    |> Enum.chunk_every(n, 1, :discard)
    |> Enum.map(fn chunk ->
      chunk |> offset_trailing() |> transpose()
    end)
  end

  def count_skew_leading(input, n) do
    input
    |> skew_leading(n)
    |> Enum.flat_map(fn x -> Enum.map(x, &find_xmas(&1)) end)
    |> Enum.sum()
  end

  def solve_1(file_path) do
    input =
      file_path
      |> read_file()

    rows_count =
      input
      |> Enum.map(&find_xmas(&1))
      |> Enum.sum()

    columns_count =
      input
      |> transpose()
      |> Enum.map(&find_xmas(&1))
      |> Enum.sum()

    positive_skew =
      input
      |> count_skew_leading(4)

    negative_skew =
      input
      |> Enum.reverse()
      |> count_skew_leading(4)

    rows_count + columns_count + positive_skew + negative_skew
  end

  def solve_2(file_path) do
    input =
      file_path
      |> read_file()

    left_skew =
      input
      |> skew_leading(3)
      |> Enum.map(fn [h1, h2 | t] -> t end)

    right_skew =
      input
      |> skew_trailing(3)

    pairs =
      Enum.zip(left_skew, right_skew)
      |> Enum.flat_map(fn {left, right} ->
        Enum.zip(left, right)
      end)
      |> find_crosses()
  end
end
