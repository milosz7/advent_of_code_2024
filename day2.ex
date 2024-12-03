defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(input) do
    input
    |> Enum.reduce([], fn line, acc ->
      parsed =
        String.split(line, ~r{\s+})
        |> Enum.map(&String.to_integer/1)

      [parsed | acc]
    end)
    |> Enum.reverse()
  end

  def check_line_safety(entry) do
    pairs =
      Enum.zip(entry, tl(entry))
      |> Enum.map(fn {x, y} -> x - y end)

    Enum.all?(pairs, &(abs(&1) <= 3 and &1 > 0)) || Enum.all?(pairs, &(abs(&1) <= 3 and &1 < 0))
  end

  def check_safety(entries) do
    entries
    |> Enum.reduce(0, fn entry, acc -> if check_line_safety(entry), do: acc + 1, else: acc end)
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> check_safety()
  end

  # EX 2 below

  def parse_entry([], acc, last_sign, _) do
    acc |> check_line_safety()
  end

  def parse_entry([h | t], acc, last_sign, true) do
    parse_entry(t, [h | acc], last_sign, true)
  end

  def parse_entry([h | t], acc, last_sign, false) do
    prev = hd(acc)
    diff = prev - h
    sign = sign(diff)

    if sign == last_sign and abs(diff) <= 3 do
      parse_entry(t, [h | acc], sign, false)
    else
      parse_entry(t, acc, sign, true)
    end
  end

  def check_line_safety_dampener(entry) do
    [h1, h2 | t] = entry
    diff = h1 - h2
    sign = sign(diff)

    if abs(diff) > 3 do
      parse_entry(t, [h2], sign, true)
    else
      parse_entry(t, [h2, h1], sign, false)
    end
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> check_safety_dampener()
  end

  def sign(x) do
    case x do
      0 -> 0
      x when x > 0 -> 1
      x when x < 0 -> -1
    end
  end

  def validate_distance(x, sign) do
    if sign(x) != sign or abs(x) > 3, do: false, else: true
  end

  def check_safety_dampener(entries) do
    entries
    |> Enum.map(fn entry ->
      check_line_safety_dampener(entry) || check_line_safety_dampener(Enum.reverse(entry))
    end)
    |> Enum.reduce(0, fn entry, acc -> if entry, do: acc + 1, else: acc end)
  end
end
