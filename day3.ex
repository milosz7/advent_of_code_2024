defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
  end

  def calculate_sum(input) do
    Regex.scan(~r{mul\((\d+),(\d+)\)}, input, capture: :all_but_first)
    |> Enum.map(fn [a, b] -> String.to_integer(a) * String.to_integer(b) end)
    |> Enum.sum()
  end

  def calculate_start_stop(input) do
    captures =
      Regex.scan(~r{(do\(\)|don't\(\))|mul\((\d+),(\d+)\)}, input,
        capture: :all_but_first,
        trim: true
      )

    Enum.map(captures, fn line -> Enum.reject(line, fn match -> match == "" end) end)
    |> Enum.reduce({0, :add}, fn x, {acc, action} ->
      case x do
        ["do()"] ->
          {acc, :add}

        ["don't()"] ->
          {acc, :dont}

        [a, b] ->
          if action == :add,
            do: {acc + String.to_integer(a) * String.to_integer(b), action},
            else: {acc, action}
      end
    end)
    |> elem(0)
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> calculate_sum()
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> calculate_start_stop()
  end
end
