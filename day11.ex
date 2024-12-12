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

  def transform_stone(0), do: [1]

  def transform_stone(stone) do
    len = n_digits(stone)

    if Integer.is_even(len) do
      half = div(len, 2)
      divisor = 10 ** half
      left = div(stone, divisor)
      right = rem(stone, divisor)
      [left, right]
    else
      [stone * 2024]
    end
  end

  def transform_stones_cache(counts, n_iter, current_iter \\ 0)
  def transform_stones_cache(counts, n_iter, current_iter) when n_iter == current_iter, do: counts

  def transform_stones_cache(counts, n_iter, current_iter) do
    new_counts =
      counts
      |> Enum.reduce(%{}, fn {val, count}, acc ->
        transform_stone(val)
        |> Enum.reduce(acc, fn num, new_acc ->
          Map.update(new_acc, num, count, fn old_count -> old_count + count end)
        end)
      end)

    transform_stones_cache(new_counts, n_iter, current_iter + 1)
  end

  def init_stones_cache(stones) do
    stones
    |> Enum.reduce(%{}, fn stone, acc ->
      Map.update(acc, stone, 1, fn count -> count + 1 end)
    end)
  end

  def get_size(counts) do
    counts
    |> Enum.reduce(0, fn {_, count}, acc -> count + acc end)
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> init_stones_cache()
    |> transform_stones_cache(@n_blinks_1)
    |> get_size()
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> init_stones_cache()
    |> transform_stones_cache(@n_blinks_2)
    |> get_size()
  end
end
