defmodule Caustic.Format do
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
end
