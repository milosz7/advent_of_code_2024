defmodule Operation do
  @enforce_keys [:reg_in_l, :reg_in_r, :operator, :reg_out]
  defstruct [:reg_in_l, :reg_in_r, :operator, :reg_out]

  def perform_operation(
        %Operation{reg_in_l: l, reg_in_r: r, operator: op, reg_out: out},
        gates_map
      ) do
    left_val = gates_map[l]
    right_val = gates_map[r]

    case op do
      "XOR" -> Map.put(gates_map, out, :erlang.bxor(left_val, right_val))
      "AND" -> Map.put(gates_map, out, :erlang.band(left_val, right_val))
      "OR" -> Map.put(gates_map, out, :erlang.bor(left_val, right_val))
    end
  end
end

defmodule Solution do
  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  defp parse_input([gates, operations]) do
    gates = parse_gates(gates)
    operations = parse_operations(operations)
    {operations, gates}
  end

  defp parse_operations(operations) do
    operations
    |> String.split("\n")
    |> Enum.map(&String.split(&1, " ", trim: true))
    |> Enum.reduce([], fn [reg_l, op, reg_r, _, reg_out], acc ->
      [
        %Operation{
          reg_in_l: reg_l,
          reg_in_r: reg_r,
          operator: op,
          reg_out: reg_out
        }
        | acc
      ]
    end)
  end

  defp parse_gates(gates) do
    gates
    |> String.split("\n")
    |> Enum.map(&String.split(&1, ": "))
    |> Enum.reduce(
      %{},
      fn [gate, value], acc -> Map.put(acc, gate, String.to_integer(value)) end
    )
  end

  defp perform_operations(operations_gates, not_finished_acc \\ [])

  defp perform_operations({[], gates_map}, []), do: gates_map

  defp perform_operations({[], gates_map}, not_finished_acc),
    do: perform_operations({not_finished_acc, gates_map})

  defp perform_operations({[current_op | operations], gates_map}, not_finished_acc) do
    %Operation{reg_in_l: left, reg_in_r: right} = current_op

    if Map.has_key?(gates_map, left) and Map.has_key?(gates_map, right) do
      gates_map = Operation.perform_operation(current_op, gates_map)
      perform_operations({operations, gates_map}, not_finished_acc)
    else
      perform_operations({operations, gates_map}, [current_op | not_finished_acc])
    end
  end

  defp extract_result(gates_map) do
    power_init = 1

    gates_map
    |> Enum.filter(fn {k, _v} -> Regex.match?(~r/z\d{2}/, k) end)
    |> Enum.sort_by(&elem(&1, 0), :asc)
    |> Enum.map(fn {_k, v} -> v end)
    |> Enum.reduce({power_init, 0}, fn bit, {power_acc, val_acc} ->
      {power_acc * 2, val_acc + power_acc * bit}
    end)
    |> elem(1)
  end

  def is_input_gate?(left, right) do
    reg_x = ~r"x\d{2,}"
    reg_y = ~r"y\d{2,}"
    (left =~ reg_x and right =~ reg_y) or (left =~ reg_y and right =~ reg_x)
  end

  def is_begin_gate?(left, right) do
    begin_x = "x00"
    begin_y = "y00"
    (left == begin_x and right == begin_y) or (left == begin_y and right == begin_x)
  end

  def is_output?(register), do: register =~ ~r"z\d{2,}"

  defp validate_circuit(operation, operations) do
    %Operation{reg_in_l: left, reg_in_r: right, reg_out: out, operator: op} = operation

    cond do
      is_output?(out) and op != "XOR" ->
        false

      not is_output?(out) and not is_input_gate?(left, right) and op == "XOR" ->
        false

      op == "XOR" and is_input_gate?(left, right) and not is_begin_gate?(left, right) ->
        Enum.map(operations, fn operation ->
          (operation.operator == "XOR" and operation.reg_in_l == out) or
            (operation.operator == "XOR" and operation.reg_in_r == out)
        end)
        |> Enum.any?()

      op == "AND" and is_input_gate?(left, right) and not is_begin_gate?(left, right) ->
        Enum.map(operations, fn operation ->
          (operation.operator == "OR" and operation.reg_in_l == out) or
            (operation.operator == "OR" and operation.reg_in_r == out)
        end)
        |> Enum.any?()

      true ->
        true
    end
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> perform_operations()
    |> extract_result()
  end

  def solve_2(path) do
    {operations, gates} =
      path
      |> read_file()
      |> parse_input()

    max_z =
      operations
      |> Enum.filter(fn op -> is_output?(op.reg_out) end)
      |> Enum.map(fn op -> op.reg_out end)
      |> Enum.sort(:desc)
      |> hd()
      |> IO.inspect()

    operations
    |> Enum.split_with(fn gate -> validate_circuit(gate, operations) end)
    |> elem(1)
    |> Enum.map(fn op -> op.reg_out end)
    |> Enum.filter(&(&1 != max_z))
    |> Enum.sort()
    |> Enum.join(",")
  end
end
