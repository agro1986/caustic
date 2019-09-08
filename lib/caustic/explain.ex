defmodule Caustic.Explain do
  alias Caustic.Utils
  alias Caustic.Format
  
  @moduledoc """
  Step-by-step explanation of the computation in Caustic.Utils.
  """

  def totient(1) do
    IO.puts "The only positive number less than or equal to 1 which is relatively prime to 1 is 1 itself."
    IO.puts "Therefore, φ(1) = 1"
  end

  def totient(m) do
    factors = Utils.factorize_grouped(m)
    factor_count = Enum.count(factors)
    factors_str = factors
                  |> Enum.map(fn
      {a, 1} -> "#{a}"
      {a, e} -> "#{a}^#{e}"
    end)
    factors_str_joined = factors_str |> Enum.join(" . ")
    totient_expanded = factors_str |> Enum.map(&"φ(#{&1})") |> Enum.join(" ")

    big_bracket_opening = if factor_count > 1, do: "[", else: ""
    big_bracket_closing = if factor_count > 1, do: "]", else: ""

    totient_expanded_2 = factors |> Enum.map(fn
      {a, 1} -> "(#{a}-1)"
      {a, e} -> "#{big_bracket_opening}#{a}^(#{e}-1) . (#{a}-1)#{big_bracket_closing}"
    end) |> Enum.join(" . ")

    totient_expanded_3 = factors |> Enum.map(fn
      {a, 1} -> "#{a - 1}"
      {a, e} -> "#{big_bracket_opening}#{a}^#{e - 1} . #{a - 1}#{big_bracket_closing}"
    end) |> Enum.join(" . ")

    if factor_count > 1 do
      IO.puts "φ(m) is multiplicative, so φ(ab) = φ(a) φ(b) if a and b are relatively prime."
    end

    IO.puts "#{if factor_count > 1, do: "Also, ", else: ""}φ(p^n) = p^(n-1) . (p-1) for any prime p and positive integer n."
    IO.puts "#{m} can be factorized as #{factors_str_joined}. Therefore,"
    intro = "φ(#{m})"
    steps = Enum.uniq([intro, "φ(#{factors_str_joined})", totient_expanded, totient_expanded_2, totient_expanded_3, "#{Utils.totient(m)}"])
    Format.print_equations steps
  end

  def linear_congruence_solve(a, b, m) do
    result = Utils.linear_congruence_solve a, b, m
    a_str = if a == 1, do: "", else: "#{a}"
    eq_str = "#{a_str}x = #{b} (mod #{m})"
    if result == [] do
      IO.puts "The equation #{eq_str} has no solutions."
    else if length(result) == 1 do
      [n] = result
      IO.puts "The only solution of #{eq_str} is x = #{n}."
    else
      sol_str = Enum.join result, ", "
      IO.puts "The solutions of #{eq_str} are x = #{sol_str}."
    end end
  end
end
