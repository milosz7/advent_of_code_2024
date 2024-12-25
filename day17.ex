defmodule Solution do
  @adv 0
  @bxl 1
  @bst 2
  @jnz 3
  @bxc 4
  @out 5
  @bdv 6
  @cdv 7
  @register_a 4
  @register_b 5
  @register_c 6
  @default_move 2

  def read_file(path) do
    path
    |> File.read!()
    |> String.split("\n\n")
  end

  def parse_input(input) do
    input
    |> Enum.map(&extract_numbers/1)
  end

  def extract_numbers(line) do
    Regex.scan(~r(\d+), line)
    |> List.flatten()
    |> Enum.map(&String.to_integer/1)
  end

  def prepare_program_register([register_vals, program]) do
    register =
      register_vals
      |> Stream.zip([@register_a, @register_b, @register_c])
      |> Enum.reduce(%{}, fn {v, k}, acc -> Map.put(acc, k, v) end)

    program_map =
      program
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {idx, val}, acc -> Map.put(acc, val, idx) end)

    last_idx = map_size(program_map)

    {register, program_map, program, last_idx}
  end

  def parse_program(instruction, operand, program_data)

  def parse_program(@adv, combo, {registers, program, current_idx, last_idx, out}) do
    numerator = registers[@register_a]
    denominator = Map.get(registers, combo, combo)
    registers = Map.put(registers, @register_a, :erlang.bsr(numerator, denominator))
    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program(@bxl, literal, {registers, program, current_idx, last_idx, out}) do
    registers =
      registers
      |> Map.put(@register_b, :erlang.bxor(registers[@register_b], literal))

    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program(@bst, combo, {registers, program, current_idx, last_idx, out}) do
    operand = Map.get(registers, combo, combo)

    registers =
      registers
      |> Map.put(@register_b, rem(operand, 8))

    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program(@jnz, literal, {registers, program, current_idx, last_idx, out}) do
    if registers[@register_a] == 0 do
      {registers, program, current_idx + @default_move, last_idx, out}
    else
      {registers, program, literal, last_idx, out}
    end
  end

  def parse_program(@bxc, _literal, {registers, program, current_idx, last_idx, out}) do
    registers =
      registers
      |> Map.put(@register_b, :erlang.bxor(registers[@register_b], registers[@register_c]))

    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program(@out, combo, {registers, program, current_idx, last_idx, out}) do
    operand = Map.get(registers, combo, combo)
    {registers, program, current_idx + @default_move, last_idx, [rem(operand, 8) | out]}
  end

  def parse_program(@bdv, combo, {registers, program, current_idx, last_idx, out}) do
    numerator = registers[@register_a]
    denominator = Map.get(registers, combo, combo)
    registers = Map.put(registers, @register_b, :erlang.bsr(numerator, denominator))
    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program(@cdv, combo, {registers, program, current_idx, last_idx, out}) do
    numerator = registers[@register_a]
    denominator = Map.get(registers, combo, combo)
    registers = Map.put(registers, @register_c, :erlang.bsr(numerator, denominator))
    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def run_program(program_data)

  def run_program({_registers, _program, current_idx, last_idx, out})
      when current_idx >= last_idx - 1,
      do: out

  def run_program({_registers, program, current_idx, _last_idx, _out} = input) do
    instruction = program[current_idx]
    operand = program[current_idx + 1]
    next_input = parse_program(instruction, operand, input)
    run_program(next_input)
  end

  def find_inverse({registers, program, starting_idx, last_idx, []}) do
    run_program({registers, program, starting_idx, last_idx, []})
  end

  def program_part_valid?(out, program) do
    Enum.zip(out, program)
    |> Enum.all?(fn {out, truth} -> out == truth end)
  end

  def perform_search({registers, program_map, program, last_idx}, last_valid \\ %{}) do
    backtrack_start = Map.get(last_valid, @register_a, 0) + 1
    initial_value = registers[@register_a]

    {out, registers, current_length} =
      backtrack_start..7
      |> Enum.reduce_while({nil, registers, 0}, fn value, {_, register_acc, _} ->
        starting_idx = 0
        new_register = Map.put(register_acc, @register_a, register_acc[@register_a] + value)

        out = run_program({new_register, program_map, starting_idx, last_idx, []})

        if program_part_valid?(out, program) do
          {:halt, {out, new_register, length(out)}}
        else
          {:cont, {out, register_acc, length(out)}}
        end
      end)

    if program_part_valid?(out, program) do
      if current_length == length(program) do
        registers[@register_a]
      else
        last_valid = Map.put(last_valid, initial_value, rem(registers[@register_a], 8))
        registers = Map.put(registers, @register_a, :erlang.bsl(registers[@register_a], 3))
        perform_search({registers, program_map, program, last_idx}, last_valid)
      end
    else
      registers =
        Map.put(
          registers,
          @register_a,
          :erlang.bsr(registers[@register_a], 3)
        )

      last_valid =
        last_valid
        |> Map.filter(fn {register, _v} -> register < initial_value end)

      perform_search({registers, program_map, program, last_idx}, last_valid)
    end
  end

  def solve_2(path) do
    {_registers, program_map, program, last_idx} =
      path
      |> read_file()
      |> parse_input()
      |> prepare_program_register()

    registers = %{@register_a => 0, @register_b => 0, @register_c => 0}

    program =
      program |> Enum.reverse()

    perform_search({registers, program_map, program, last_idx})
  end

  def solve_1(path) do
    {registers, program_map, _program, last_idx} =
      path
      |> read_file()
      |> parse_input()
      |> prepare_program_register()

    starting_idx = 0

    run_program({registers, program_map, starting_idx, last_idx, []})
    |> Enum.reverse()
    |> Enum.join(",")
  end
end
