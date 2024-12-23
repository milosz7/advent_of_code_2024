defmodule Solution do
  require Integer
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

    program =
      program
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {idx, val}, acc -> Map.put(acc, val, idx) end)

    last_idx = map_size(program)

    {register, program, last_idx}
  end

  def parse_program(instruction, operand, program_data)

  def parse_program(@adv, combo, {registers, program, current_idx, last_idx, out}) do
    numerator = registers[@register_a]
    denominator = Map.get(registers, combo, combo)
    registers = Map.put(registers, @register_a, div(numerator, 2 ** denominator))
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
    registers = Map.put(registers, @register_b, div(numerator, 2 ** denominator))
    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program(@cdv, combo, {registers, program, current_idx, last_idx, out}) do
    numerator = registers[@register_a]
    denominator = Map.get(registers, combo, combo)
    registers = Map.put(registers, @register_c, div(numerator, 2 ** denominator))
    {registers, program, current_idx + @default_move, last_idx, out}
  end

  def parse_program([], _registers, out) do
    out
    |> Enum.reverse()
    |> Enum.join(",")
  end

  def run_program(program_data)

  def run_program({_registers, program, current_idx, last_idx, out})
      when current_idx >= last_idx - 1 do
    out
    |> Enum.reverse()
    |> Enum.join(",")
  end

  def run_program({registers, program, current_idx, last_idx, out} = input) do
    instruction = program[current_idx]
    operand = program[current_idx + 1]
    next_input = parse_program(instruction, operand, input)
    run_program(next_input)
  end

  def solve_1(path) do
    {registers, program, last_idx} =
      path
      |> read_file()
      |> parse_input()
      |> prepare_program_register()

    starting_idx = 0

    run_program({registers, program, starting_idx, last_idx, []})
  end
end
