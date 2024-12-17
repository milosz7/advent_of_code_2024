defmodule Solution do
  @space_x 100
  @space_y 102

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  def parse_input(lines) do
    lines
    |> Enum.map(
      &(Regex.scan(~r(-?\d+), &1)
        |> List.flatten()
        |> Enum.map(fn x -> String.to_integer(x) end)
        |> List.to_tuple())
    )
  end

  def new_x(x, vx) when vx < 0 do
    if x + vx < 0, do: @space_x + x + vx + 1, else: x + vx
  end

  def new_x(x, vx) when vx > 0 do
    if x + vx > @space_x, do: rem(x + vx - 1, @space_x), else: x + vx
  end

  def new_y(y, vy) when vy < 0 do
    if y + vy < 0, do: @space_y + (y + vy) + 1, else: y + vy
  end

  def new_y(y, vy) when vy > 0 do
    if y + vy > @space_y, do: rem(y + vy - 1, @space_y), else: y + vy
  end

  def move_robot(data, n_iter, current_iter \\ 0)

  def move_robot({x, y, vx, vy}, n_iter, current_iter) when n_iter == current_iter,
    do: {x, y, vx, vy}

  def move_robot({x, y, vx, vy}, n_iter, current_iter) do
    move_robot({new_x(x, vx), new_y(y, vy), vx, vy}, n_iter, current_iter + 1)
  end

  def count_quadrants(coords) do
    x_center = div(@space_x, 2)
    y_center = div(@space_y, 2)

    coords
    |> Enum.reject(fn {x, y, _, _} -> x == x_center or y == y_center end)
    |> Enum.reduce(%{}, fn {x, y, _, _}, acc ->
      Map.update(acc, {div(x, x_center + 1), div(y, y_center + 1)}, 1, &(&1 + 1))
    end)
    |> Map.values()
    |> Enum.product()
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> Enum.map(fn data -> move_robot(data, 100) end)
    |> count_quadrants()
  end

  def solve_2(path) do
    input =
      path
      |> read_file()
      |> parse_input()

    patterns =
      1..10000
      |> Enum.reduce({[], input}, fn second, {configs, robots} ->
        robots = Enum.map(robots, fn robot -> move_robot(robot, 1) end)
        {[{robots, second} | configs], robots}
      end)
      |> elem(0)
      # |> Stream.map(fn {robots, second} -> {MapSet.new(robots)})
      |> Task.async_stream(fn {robots, second} -> {count_quadrants(robots), second, robots} end)
      |> Stream.map(fn {:ok, res} -> res end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.take(1)
      |> Enum.map(&visualise/1)
  end

  def visualise({score, idx, pattern}) do
    map =
      pattern
      |> Enum.reduce(%{}, fn {x, y, _, _}, acc -> Map.put(acc, {x, y}, true) end)

    0..@space_y
    |> Enum.map(fn y ->
      0..@space_x
      |> Enum.reduce("", fn x, acc ->
        present = if Map.has_key?(map, {x, y}), do: "*", else: "O"
        acc <> present
      end)
    end)
    |> Enum.each(&IO.inspect/1)

    {score, idx}
  end
end
