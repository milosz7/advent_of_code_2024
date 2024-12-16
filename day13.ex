defmodule Solution do
  @price_boost 10_000_000_000_000
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  def prepare_equation(input) do
    [a, b, c, d, x, y] =
      Regex.scan(~r(\d+), input)
      |> List.flatten()
      |> Enum.map(&String.to_integer/1)

    {a, b, c, d, x, y}
  end

  def solve_equation({a, b, c, d, x, y}) do
    det = a * d - b * c
    a_press = (d * x - c * y) / det
    b_press = (a * y - b * x) / det
    {a_press, b_press}
  end

  def increase_prize({a, b, c, d, x, y}) do
    {a, b, c, d, x + @price_boost, y + @price_boost}
  end

  def get_valid_solutions(solutions) do
    solutions
    |> Enum.filter(fn {a, b} -> Float.round(a) == a and Float.round(b) == b end)
  end

  def count_tokens(solutions) do
    solutions
    |> Enum.reduce(0, fn {a, b}, acc -> acc + 3 * a + b end)
    |> Float.round()
  end

  def solve_1(path) do
    path
    |> read_file()
    |> Enum.map(&prepare_equation/1)
    |> Enum.map(&solve_equation/1)
    |> get_valid_solutions()
    |> count_tokens()
  end

  def solve_2(path) do
    path
    |> read_file()
    |> Enum.map(&prepare_equation/1)
    |> Enum.map(&increase_prize/1)
    |> Enum.map(&solve_equation/1)
    |> get_valid_solutions()
    |> count_tokens()
  end
end
