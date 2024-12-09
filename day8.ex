defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(lines) do
    max_y = length(lines) - 1
    max_x = (lines |> hd() |> String.length()) - 1

    anthenas =
      lines
      |> Stream.with_index()
      |> Stream.flat_map(fn {line, y} ->
        Enum.zip(
          String.split(line, "", trim: true) |> Enum.with_index(),
          Stream.cycle([y])
        )
      end)
      |> Stream.reject(fn {{char, _}, _} -> char == "." end)
      |> Enum.reduce(%{}, fn {{char, x}, y}, acc ->
        Map.update(acc, char, [{y, x}], &[{y, x} | &1])
      end)

    {max_y, max_x, anthenas}
  end

  def check_bounds({y, x}, max_y, max_x) do
    0 <= y and y <= max_y and 0 <= x and x <= max_x
  end

  def calculate_antinodes({{y0, x0}, {y1, x1}}, scale \\ 2) do
    move_x = scale * abs(abs(x0) - abs(x1))
    move_y = scale * abs(abs(y0) - abs(y1))

    cond do
      y0 > y1 and x0 > x1 -> [{y0 - move_y, x0 - move_x}, {y1 + move_y, x1 + move_x}]
      y0 > y1 and x0 < x1 -> [{y0 - move_y, x0 + move_x}, {y1 + move_y, x1 - move_x}]
      y0 < y1 and x0 > x1 -> [{y0 + move_y, x0 - move_x}, {y1 - move_y, x1 + move_x}]
      y0 < y1 and x0 < x1 -> [{y0 + move_y, x0 + move_x}, {y1 - move_y, x1 - move_x}]
    end
  end

  def get_pairs(points, acc \\ [])

  def get_pairs([], acc), do: acc |> List.flatten()

  def get_pairs([h | t], acc) do
    get_pairs(t, [Enum.zip(Stream.cycle([h]), t) | acc])
  end

  def parse_anthenas({max_y, max_x, anthenas}) do
    anthenas
    |> Enum.flat_map(fn {_, coordinates} -> get_pairs(coordinates) end)
    |> Enum.flat_map(&calculate_antinodes/1)
    |> Enum.filter(&check_bounds(&1, max_y, max_x))
    |> MapSet.new()
    |> MapSet.size()
  end

  def parse_anthenas_increment_range({max_y, max_x, anthenas}) do
    pairs =
      anthenas
      |> Enum.flat_map(fn {_, coordinates} -> get_pairs(coordinates) end)

    1..max(max_x, max_y)
    |> Stream.zip(Stream.cycle([pairs]))
    |> Enum.flat_map(fn {scale, pairs} ->
      pairs
      |> Enum.flat_map(&calculate_antinodes(&1, scale))
    end)
    |> Enum.filter(&check_bounds(&1, max_y, max_x))
    |> MapSet.new()
    |> MapSet.size()
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> parse_anthenas()
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> parse_anthenas_increment_range()
  end
end
