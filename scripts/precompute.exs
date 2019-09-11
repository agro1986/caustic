import Caustic.Utils
import Enum

filename = "lib/caustic/utils.ex"
item_per_line = 50

#marker = "primes"
#count = 10_000

to_insert = [
  {"primes", &Script.primes/0, 10_000, item_per_line},
]

defmodule Script do
  def primes do
    stream(2, &prime?/1)
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
  
  def insert(lines_orig, stream, count, item_per_line, marker) do
    numbers = stream.() |> take(count)
    numbers_split = numbers |> chunk_every(item_per_line)
    prefix = "  @#{marker} ["
    suffix = "  ]"
    lines_to_insert = [prefix] ++ (numbers_split |> map(&("    " <> join(&1, ", ") <> ","))) ++ [suffix]
    replace(lines_orig, marker, lines_to_insert)
  end
end

file_lines = File.read!(filename) |> String.split("\n")

result_str = to_insert
|> reduce(file_lines, fn {name, stream, count, item_per_line}, file_lines -> Script.insert(file_lines, stream, count, item_per_line, name) end)
|> join("\n")

IO.puts(result_str)
