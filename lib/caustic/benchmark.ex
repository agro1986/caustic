defmodule Caustic.Benchmark do
  @moduledoc """
  To compare speed of native implementation vs optimized implementation.
  """
  @moduledoc false
  
  alias Caustic.Utils
  alias Caustic.Benchmark

  def repeat(_f, 0), do: nil
  def repeat(f, n) do
    f.()
    repeat(f, n - 1)
  end

  def benchmark_ecpoint_mul(g \\ {{15, 223}, {86, 223}, {0, 223}, {7, 223}}, n_max \\ 9999, times \\ 10) do
    the_benchmark = fn f ->
      fn ->
        1..n_max
        |> Enum.each(&f.(&1, g))
      end
    end

    {t1, _} = :timer.tc(Benchmark, :_benchmark, [the_benchmark.(&Caustic.ECPoint.mul/2), times])
    IO.puts("Optimized: #{t1}")

    {t2, _} = :timer.tc(Benchmark, :_benchmark, [the_benchmark.(&Caustic.Benchmark.ecpoint_mul_fine/2), times])
    IO.puts("Original : #{t2}")
  end

  def benchmark_ecpoint_mul_simple(g \\ {{15, 223}, {86, 223}, {0, 223}, {7, 223}},
        n_max \\ 9999999998000000000189999999988600000000484499999984496000000387599999992248000000125969999998320400000018475599999832040000001259699999992248000000038759999999844960000000484499999998860000000001899999999998000000000001,
        times \\ 10) do
    {t1, _} = :timer.tc(Benchmark, :_benchmark, [&Caustic.ECPoint.mul/2, n_max, g, times])
    IO.puts("Optimized: #{t1}")

    {t2, _} = :timer.tc(Benchmark, :_benchmark, [&Caustic.Benchmark.ecpoint_mul_fine/2, n_max, g, times])
    IO.puts("Original : #{t2}")
  end

  def benchmark_pow_mod(x \\ 5, y \\ 12345, m \\ 17, times \\ 1000) do
    {t1, _} = :timer.tc(Benchmark, :_benchmark, [&Utils.pow_mod/3, x, y, m, times])
    IO.puts("Optimized: #{t1}")

    {t2, _} = :timer.tc(Benchmark, :_benchmark, [&pow_mod_fine/3, x, y, m, times])
    IO.puts("Fine: #{t2}")

    {t3, _} = :timer.tc(Benchmark, :_benchmark, [&pow_mod_slow/3, x, y, m, times])
    IO.puts("Naive: #{t3}")
  end
  
  def benchmark_factorize(max \\ 5000000, times \\ 2) do
    {t1, _} = :timer.tc(Benchmark, :_benchmark_range, [&Utils.factorize/1, 1, max, times])
    IO.puts("Optimized: #{t1}")

#    {t2, _} = :timer.tc(Benchmark, :_benchmark_range, [&Utils.factorize2/1, 1, max, times])
#    IO.puts("Faster: #{t2}")
  end
  
  def benchmark_prime?(max \\ 5000000, times \\ 2) do
    {t1, _} = :timer.tc(Benchmark, :_benchmark_range, [&Utils.prime?/1, 1, max, times])
    IO.puts("Optimized: #{t1}")

    {t1, _} = :timer.tc(Benchmark, :_benchmark_range, [&Caustic.Alt.prime?/1, 1, max, times])
    IO.puts("Naive: #{t1}")
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
  
  def _benchmark_range(f, min, max, times) do
    repeat(fn ->
      (min..max)
      |> Enum.map(f)
    end, times)
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

  def ecpoint_mul_fine(0, {_, _, a, b}), do: Caustic.ECPoint.infinity(a, b)
  def ecpoint_mul_fine(1, p), do: p
  def ecpoint_mul_fine(k, p) when rem(k, 2) == 0 do
    half = ecpoint_mul_fine(div(k, 2), p)
    Caustic.ECPoint.add(half, half)
  end
  def ecpoint_mul_fine(k, p) do
    half = ecpoint_mul_fine(div(k, 2), p)
    Caustic.ECPoint.add(Caustic.ECPoint.add(half, half), p)
  end
end
