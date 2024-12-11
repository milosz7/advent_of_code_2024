defmodule Solution do
  require Integer

  @n_blinks_1 25
  @n_blinks_2 75

  def read_file(path) do
    path
    |> File.read!()
    |> String.split(" ", trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  def n_digits(0), do: 1
  def n_digits(num), do: (num |> :math.log10() |> trunc()) + 1

  def transform_stone(0), do: 1

  def transform_stone(stone) do
    len = n_digits(stone)

    if Integer.is_even(len) do
      half = div(len, 2)
      divisor = 10 ** half
      left = div(stone, divisor)
      right = rem(stone, divisor)
      [left, right]
    else
      stone * 2024
    end
  end

  def transform_stones(stones, n_iter, current_iter \\ 0, acc \\ [])

  def transform_stones([], n_iter, current_iter, acc) do
    transform_stones(acc, n_iter, current_iter + 1)
  end

  def transform_stones(stones, n_iter, current_iter, _) when n_iter == current_iter,
    do: stones

  def transform_stones([stone | rest], n_iter, current_iter, acc) do
    case transform_stone(stone) do
      [left, right] -> transform_stones(rest, n_iter, current_iter, [right, left | acc])
      num -> transform_stones(rest, n_iter, current_iter, [num | acc])
    end
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> transform_stones(@n_blinks_1)
    |> length()
  end
end
