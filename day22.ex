defmodule Solution do
  @n_iter 2000
  defp read_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
  end

  defp parse_input(lines) do
    lines
    |> Enum.map(&String.to_integer/1)
  end

  defp evolve_secret(secret) do
    prune = 16_777_216
    secret = :erlang.bxor(secret, secret * 64) |> rem(prune)
    secret = :erlang.bxor(secret, div(secret, 32)) |> rem(prune)
    secret = :erlang.bxor(secret, secret * 2048) |> rem(prune)
  end

  defp calculate_secrets(secrets, n_iter, iter \\ 0)
  defp calculate_secrets(secrets, n_iter, iter) when n_iter == iter, do: secrets

  defp calculate_secrets(secrets, n_iter, iter) do
    secrets =
      secrets
      |> Enum.map(&evolve_secret/1)

    calculate_secrets(secrets, n_iter, iter + 1)
  end

  defp build_sequence_map(secret, n_iter) do
    {secrets, diffs} =
      1..4
      |> Enum.reduce({[secret], []}, fn _, {secret_acc, diff_acc} ->
        last_secret = hd(secret_acc)
        new_secret = evolve_secret(last_secret)
        price_diff = rem(new_secret, 10) - rem(last_secret, 10)
        {[new_secret | secret_acc], [price_diff | diff_acc]}
      end)

    build_sequence_map(secrets, diffs, n_iter - 4)
  end

  defp build_sequence_map(secrets, diffs, n_iter, iter \\ 0, cache \\ %{})

  defp build_sequence_map(secrets, diffs, n_iter, iter, cache) when n_iter == iter, do: cache

  defp build_sequence_map(secrets, diffs, n_iter, iter, cache) do
    last_secret = hd(secrets)
    last_price = rem(last_secret, 10)
    new_secret = evolve_secret(last_secret)
    new_price = rem(new_secret, 10)
    price_diff = new_price - last_price
    sequence = Enum.take(diffs, 4)

    cache =
      if Map.has_key?(cache, sequence), do: cache, else: Map.put(cache, sequence, last_price)

    build_sequence_map([new_secret | secrets], [price_diff | diffs], n_iter, iter + 1, cache)
  end

  def solve_1(path) do
    path
    |> read_file()
    |> parse_input()
    |> calculate_secrets(@n_iter)
    |> Enum.sum()
  end

  def solve_2(path) do
    path
    |> read_file()
    |> parse_input()
    |> Task.async_stream(&build_sequence_map(&1, @n_iter))
    |> Enum.reduce(%{}, fn {:ok, map}, acc ->
      Map.merge(acc, map, fn _k, v1, v2 -> v1 + v2 end)
    end)
    |> Enum.max_by(fn {_k, v} -> v end)
  end
end
