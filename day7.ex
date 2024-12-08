defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_nums(nums) do
    nums
    |> String.split(" ", trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  def parse_input(lines) do
    lines
    |> Stream.map(fn x -> String.split(x, ":") end)
    |> Stream.map(fn [result, nums] -> {String.to_integer(result), parse_nums(nums)} end)
  end

  def find_operators(input, current \\ nil)

  def find_operators({result, [a | rest]}, nil) do
    find_operators({result, rest}, a)
  end

  def find_operators({result, []}, current) do
    if current == result, do: current, else: false
  end

  def find_operators({result, [a | rest]}, current) do
    find_operators({result, rest}, current + a) || find_operators({result, rest}, current * a)
  end

  def concat(a, b) do
    (Integer.to_string(a) <> Integer.to_string(b)) |> String.to_integer()
  end

  def find_operators_concat(input, current \\ nil)

  def find_operators_concat({result, []}, current) do
    if current == result, do: current, else: false
  end

  def find_operators_concat({result, [a | rest]}, nil) do
    find_operators_concat({result, rest}, a)
  end

  def find_operators_concat({result, [a | rest]}, current) do
    find_operators_concat({result, rest}, current + a) ||
      find_operators_concat({result, rest}, current * a) ||
      find_operators_concat({result, rest}, concat(current, a))
  end

  def solve_1(file_name) do
    file_name
    |> read_file()
    |> parse_input()
    |> Task.async_stream(&find_operators/1)
    |> Enum.reduce(0, fn {:ok, res}, acc -> if res, do: acc + res, else: acc end)
  end

  def solve_2(file_name) do
    file_name
    |> read_file()
    |> parse_input()
    |> Task.async_stream(&find_operators_concat/1)
    |> Enum.reduce(0, fn {:ok, res}, acc -> if res, do: acc + res, else: acc end)
  end
end
