defmodule Caustic.Format do
  alias Caustic.Utils
  
  @moduledoc """
  Formatting for beautiful layout of equations and tables.
  """

  @doc ~S"""
  ## Examples
  
      iex> Caustic.Format.equations ["x", "1 + 1 + 1", "1 + 2", "3"]
      "x = 1 + 1 + 1\n  = 1 + 2\n  = 3"
  """
  def equations eqs do
    [first | [second | rest]] = eqs
    first_line = "#{first} = #{second}"
    spaces = String.duplicate " ", String.length(first)
    prefix = spaces <> " = "
    lines = rest |> Enum.map(&prefix <> &1)
    lines = [first_line | lines]
    lines |> Enum.join("\n")
  end
  
  def print_equations(eqs), do: IO.puts(equations(eqs))

  def print_fn(ns, f) do
    f_n = ns |> Enum.map(& f.(&1))
    n = if is_list(ns), do: ns, else: Enum.to_list(ns)
    print_table([f_n], ["f(n)"], n)
  end

  def print_fn(ns, f, g) do
    f_n = ns |> Enum.map(& f.(&1))
    g_n = ns |> Enum.map(& g.(&1))
    n = if is_list(ns), do: ns, else: Enum.to_list(ns)
    print_table([f_n, g_n], ["f(n)", "g(n)"], n)
  end

  def print_fn(ns, f, g, h) do
    f_n = ns |> Enum.map(& f.(&1))
    g_n = ns |> Enum.map(& g.(&1))
    h_n = ns |> Enum.map(& h.(&1))
    n = if is_list(ns), do: ns, else: Enum.to_list(ns)
    print_table([f_n, g_n, h_n], ["f(n)", "g(n)", "h(n)"], n)
  end

  @doc ~S"""
  ## Examples
  
      iex> Caustic.Format.table [[2, 3], [1, 4]], ["x + 1", "x^2"], [1, 2]
      "      | 1 | 2\nx + 1 | 2 | 3\n  x^2 | 1 | 4"
  """
  def table(t, row_labels, col_labels) do
    table_with_row_label = Enum.zip(row_labels, t)
    |> Enum.map(fn {row_label, row} -> [row_label | row] end)

    col_labels = ["" | col_labels]
    table_with_label = [col_labels | table_with_row_label]

    col_widths = List.zip(table_with_label)
    |> Enum.map(fn row ->
      row
      |> Tuple.to_list()
      |> Enum.map(&String.length(to_string(&1)))
      |> Enum.max()
    end)

    table_with_label
    |> Enum.map(fn row ->
      Enum.zip(row, col_widths)
      |> Enum.map(fn {col, width} -> String.pad_leading(to_string(col), width) end)
      |> Enum.join(" | ")
    end)
    |> Enum.join("\n")
  end

  def print_table(t, row_labels, col_labels) do
    IO.puts(table(t, row_labels, col_labels))
  end

  def print_multiplication_table_mod(m) do
    table = Utils.multiplication_table_mod m

    row_labels = 0..(m - 1) |> Enum.to_list()
    col_labels = row_labels

    print_table(table, row_labels, col_labels)
  end

  def print_exponentiation_table_mod(m, opts \\ [relatively_prime_only: false]) do
    rows = if opts[:relatively_prime_only] do
      max = if m == 1, do: 1, else: m - 1
      1..max |> Enum.filter(& Utils.gcd(&1, m) == 1) |> Enum.to_list()
    else
      0..(m - 1) |> Enum.to_list()
    end

    cols = if opts[:relatively_prime_only] do
      1..Utils.totient(m) |> Enum.to_list()
    else
      max = if m == 1, do: 1, else: m - 1
      0..max |> Enum.to_list()
    end

    table = Utils.exponentiation_table_mod m, rows, cols
    table = if opts[:relatively_prime_only] do
      _mark_primitive_root table
    else
      table
    end

    print_table table, rows, cols ++ ["√"]
  end

  defp _mark_primitive_root table do
    table
    |> Enum.map(fn row ->
      one_count = row
                  |> Enum.filter(& &1 == 1)
                  |> Enum.count()
      is_root = one_count == 1
      row ++ [(if is_root, do: "*", else: " ")]
    end)
  end
end
