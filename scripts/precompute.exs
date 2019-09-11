import Caustic.Utils
import Enum

cache_filename = "lib/caustic/cache.ex"
utils_filename = "lib/caustic/utils.ex"
item_per_line = 50
primes_length = 25_000
largest_prime = 287_117

to_insert_simple = [
  {"cached_primes_length", primes_length},
  {"cached_primes_max", largest_prime}
]

to_insert = [
  {"primes", &Script.primes/0, primes_length, item_per_line, :list},
  {"factorization", &Script.factorization/1, largest_prime, item_per_line * 10, :map}
]

defmodule Script do
  def primes do
    stream(2, &prime?/1)
  end
  
  def factorization(max) do
    (2..max)
    |> Enum.map(fn n ->
      factor = Caustic.Utils.smallest_prime_divisor(n)
      if factor == n do
        {n, {factor, 1}}
      else
        {n, {factor, div(n, factor)}}
      end
    end)
    |> Enum.filter(fn {_, {factor, _}} -> factor > 5 end)
  end
  
  def marker_start(marker) do
    "# " <> String.upcase(marker) <> "_START"
  end
  
  def marker_end(marker) do
    "# " <> String.upcase(marker) <> "_END"
  end
  
  def replace(lines, marker, to_insert_lines) do
    m_start = marker_start(marker)
    m_end = marker_end(marker)
    {lines, :end} = lines
    |> reduce(
      {[], :start},
      fn
        line, {acc, :start} ->
          if String.contains?(line, m_start) do
            {reverse(to_insert_lines) ++ [line | acc], :ignore}
          else
            {[line | acc], :start}
          end
        line, {acc, :ignore} ->
          if String.contains?(line, m_end) do
            {[line | acc], :end}
          else
            {acc, :ignore}
          end
        line, {acc, :end} ->
          {[line | acc], :end}
      end
    )
    lines |> reverse()
  end
  
  def insert(lines_orig, stream, count, item_per_line, name, :list) do
    items = stream.() |> take(count)
    lines_to_insert = generate_lines(name, items, item_per_line, :list)
    replace(lines_orig, name, lines_to_insert)
  end

  def insert(lines_orig, stream, max, item_per_line, name, :map) do
    items = stream.(max)
    lines_to_insert = generate_lines(name, items, item_per_line, :map)
    replace(lines_orig, name, lines_to_insert)
  end
  
  def insert_simple(lines_orig, name, value) do
    lines_to_insert = ["  @#{name} #{inspect value}"]
    replace(lines_orig, name, lines_to_insert)
  end
  
  def generate_lines(name, numbers, item_per_line, :list) do
    numbers_split = numbers |> chunk_every(item_per_line)
    pref = "  @#{name} ["
    suffix = "  ]"
    [pref] ++ (numbers_split |> map(&("    " <> join(&1, ", ") <> ","))) ++ [suffix]
  end

  def generate_lines(name, kvs, item_per_line, :map) do
    kvs_split = kvs |> map(fn {k, v} -> "#{k} => #{inspect v}" end) |> chunk_every(item_per_line)
    pref = "  @#{name} %{"
    suffix = "  }"
    [pref] ++ (kvs_split |> map(&("    " <> join(&1, ", ") <> ","))) ++ [suffix]
  end
end

# cache file

cache_file_lines = File.read!(cache_filename) |> String.split("\n")

cache_result_str = to_insert
|> reduce(cache_file_lines, fn {name, stream, count, item_per_line, mode}, cache_file_lines -> Script.insert(cache_file_lines, stream, count, item_per_line, name, mode) end)
|> join("\n")

file = File.open! cache_filename, [:write]
IO.binwrite file, cache_result_str
File.close file

# utils file

utils_file_lines = File.read!(utils_filename) |> String.split("\n")

utils_result_str = to_insert_simple
|> reduce(utils_file_lines, fn {name, value}, utils_file_lines -> Script.insert_simple(utils_file_lines, name, value) end)
|> join("\n")

file = File.open! utils_filename, [:write]
IO.binwrite file, utils_result_str
File.close file
