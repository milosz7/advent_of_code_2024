defmodule TreeNode do
  defstruct left: nil, right: nil, value: nil
end

defmodule Solution do
  def read_file(path) do
    path
    |> File.read!()
  end

  def parse_input(input) do
    [rule_section, line_section] = String.split(input, "\n\n", trim: true)

    rules_map =
      rule_section
      |> String.split("\n", trim: true)
      |> Enum.map(fn line -> String.split(line, "|", trim: true) end)
      |> Enum.reduce(%{}, fn [key, value], acc ->
        Map.update(acc, key, [value], &[value | &1])
      end)

    lines =
      line_section
      |> String.split("\n", trim: true)
      |> Enum.map(fn line -> String.split(line, ",", trim: true) end)

    {rules_map, lines}
  end

  def validate_line(rules_map, line, visited \\ MapSet.new(), is_valid \\ true)
  def validate_line(_, _, _, false), do: false
  def validate_line(_, [], _, is_valid), do: is_valid

  def validate_line(rules_map, line, visited, _) do
    [h | t] = line
    before = Map.get(rules_map, h, [])

    is_valid =
      Enum.reduce_while(before, true, fn x, _ ->
        if MapSet.member?(visited, x) do
          {:halt, false}
        else
          {:cont, true}
        end
      end)

    validate_line(rules_map, t, MapSet.put(visited, h), is_valid)
  end

  def extract_middle_elem(line) do
    line |> Enum.at((length(line) - 1) |> div(2)) |> String.to_integer()
  end

  def validate_lines({rules_map, lines}) do
    lines
    |> Enum.filter(fn line -> validate_line(rules_map, line) end)
  end

  def sum_middle_elements(lines) do
    lines
    |> Enum.reduce(0, fn line, acc ->
      acc + extract_middle_elem(line)
    end)
  end

  def invalid_lines({rules_map, lines}) do
    filtered =
      lines
      |> Enum.reject(fn line -> validate_line(rules_map, line) end)

    {rules_map, filtered}
  end

  def inorder(nil), do: []

  def inorder(tree) do
    inorder(tree.left) ++ [tree.value] ++ inorder(tree.right)
  end

  def insert(nil, value, _), do: %TreeNode{value: value}

  def insert(
        %TreeNode{left: left, right: right, value: value},
        new_value,
        rules_map
      ) do
    before = Map.get(rules_map, new_value, [])

    if Enum.find(before, &(&1 == value)) do
      %TreeNode{left: insert(left, new_value, rules_map), right: right, value: value}
    else
      %TreeNode{left: left, right: insert(right, new_value, rules_map), value: value}
    end
  end

  def build_tree(rules_map, line, tree \\ nil)
  def build_tree(_, [], tree), do: tree

  def build_tree(rules_map, line, nil) do
    [h | t] = line
    build_tree(rules_map, t, %TreeNode{value: h})
  end

  def build_tree(rules_map, line, tree) do
    [h | t] = line
    build_tree(rules_map, t, insert(tree, h, rules_map))
  end

  def reorder_lines({rules_map, lines}) do
    lines
    |> Enum.map(fn line -> build_tree(rules_map, line) end)
  end

  def solve_1(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> validate_lines()
    |> sum_middle_elements()
  end

  def solve_2(file_path) do
    file_path
    |> read_file()
    |> parse_input()
    |> invalid_lines()
    |> reorder_lines()
    |> Enum.map(&inorder/1)
    |> sum_middle_elements()
  end
end
