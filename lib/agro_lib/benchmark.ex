defmodule Caustic.Benchmark do
  @moduledoc """
  To compare speed of native implementation vs optimized implementation.
  """
  
  alias Caustic.Utils
  alias Caustic.Benchmark

  def repeat(_f, 0), do: nil
  def repeat(f, n) do
    f.()
    repeat(f, n - 1)
  end

  def benchmark_pow_mod(x \\ 5, y \\ 12345, m \\ 17, times \\ 1000) do
    {t1, _} = :timer.tc(Benchmark, :_benchmark, [&Utils.pow_mod/3, x, y, m, times])
    IO.puts("Optimized: #{t1}")

    {t2, _} = :timer.tc(Benchmark, :_benchmark, [&pow_mod_fine/3, x, y, m, times])
    IO.puts("Fine: #{t2}")

    {t3, _} = :timer.tc(Benchmark, :_benchmark, [&pow_mod_slow/3, x, y, m, times])
    IO.puts("Naive: #{t3}")
  end
  
  def _benchmark(f, times) do
    repeat(f, times)
  end
  
  def _benchmark(f, x, times) do
    repeat(fn -> f.(x) end, times)
  end

  def _benchmark(f, x, y, times) do
    repeat(fn -> f.(x, y) end, times)
  end

  def _benchmark(f, x, y, z, times) do
    repeat(fn -> f.(x, y, z) end, times)
  end

  def pow_mod_fine(x, y, m) do
    digits = Utils.to_digits(y, 2)

    factor_mod = digits
    |> Enum.reduce([], fn _n, acc ->
      case acc do
        [] -> [Utils.mod(x, m)]
        [last | _rest] ->
          new = last * last |> Utils.mod(m)
          [new | acc]
      end
    end)

    Enum.zip(digits, factor_mod)
    |> Enum.filter(fn {digit, _factor} -> digit == 1 end)
    |> Enum.reduce(1, fn {_digit, factor}, acc -> acc * factor end)
    |> Utils.mod(m)
  end

  def pow_mod_slow(x, y, m), do: Utils.pow(x, y) |> Utils.mod(m)
end
