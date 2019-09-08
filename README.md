# Caustic Cryptocurrency Library

Caustic is an Elixir cryptocurrency library which contains
algorithms used in Bitcoin, Ethereum, and other blockchains.
It also includes a rich cryptography, number theory,
and general mathematics class library.
You can use Caustic to quickly implement your own crypto wallet
or client. With the low-level math library, you can have fun with
exploratory mathematics.

Warning: This library is developed for learning purposes. Please do not
use for production.

# Documentation

<https://hexdocs.pm/caustic/>

# Installation

Add to `mix.exs` of your Elixir project:

```elixir
defp deps do
  [
    {:caustic, "~> 0.1.22"}
  ]
end
```

And then run:

```bash
mix deps.get
```

# Usage

## Cryptocurrency

You can generate Bitcoin private keys.

```elixir
privkey = Caustic.Secp256k1.generate_private_key()
# 55129182198667841522063226112743062531539377180872956850932941251085402073984

privkey_base58check = Caustic.Utils.base58check_encode(<<privkey::size(256)>>, :private_key_wif, convert_from_hex: false)
# 5Jjxv41cLxb3hBZRr5voBB7zj77MDo7QVVLf3XgK2tpdAoTNq9n
```

You can then digitally sign a message.

```elixir
pubkey = Caustic.Secp256k1.public_key(privkey)
# {6316467786437337873577388437635743649101330733943708346103893494005928771381, 36516277665018688612645564779200795235396005730419130160033716279021320193545}

message = "Hello, world!!!"
hash = Caustic.Utils.hash256(message)
signature = Caustic.Secp256k1.ecdsa_sign(hash, privkey)
Caustic.Secp256k1.ecdsa_verify?(pubkey, hash, signature) # true
```

## Number theory

Caustic has many functions to deal with integers and their properties.
For example you can do primality testing.

```elixir
first_primes = 1..20 |> Enum.filter(&Caustic.Utils.prime?/1)
# [2, 3, 5, 7, 11, 13, 17, 19]
```

So 7 is supposed to be a prime. Let's confirm by finding its divisors:

```elixir
Caustic.Utils.divisors 7
# [1, 7]
```

This is in contrast to 6 for example, which has divisors other than 1
and itself:

```elixir
Caustic.Utils.divisors 6
# [1, 2, 3, 6]
```

The sum of 6's divisors other than itself (its proper divisors) equals to 6 again. Those kinds of numbers
are called perfect numbers.

```elixir
Caustic.Utils.proper_divisors 6    
# [1, 2, 3]
Caustic.Utils.proper_divisors_sum 6                               
# 6
Caustic.Utils.perfect? 6
# true
```

We can easily find other perfect numbers.

```elixir
1..10000 |> Enum.filter(&Caustic.Utils.perfect?/1)
# [6, 28, 496, 8128]
```

There aren't that many of them, it seems...

Now back to our list of first primes. You can find the primitive roots of those primes:

```elixir
first_primes |> Enum.map(&{&1, Caustic.Utils.primitive_roots(&1)})
# [
#   {2, [1]},
#   {3, [2]},
#   {5, [2, 3]},
#   {7, [3, 5]},
#   {11, [2, 6, 7, 8]},
#   {13, [2, 6, 7, 11]},
#   {17, [3, 5, 6, 7, 10, 11, 12, 14]},
#   {19, [2, 3, 10, 13, 14, 15]}
# ]
```

We can see that 5 is a primitive root of 7. It means that repeated
exponentiation of 5 modulo 7 will generate all numbers relatively
prime to 7. Let's confirm it:

```elixir
Caustic.Utils.order_multiplicative 5, 7
# 6
1..6 |> Enum.map(&Caustic.Utils.pow_mod(5, &1, 7))
# [5, 4, 6, 2, 3, 1]
```

First we check the order of 5 modulo 7. It is 6, which means that
5^6 = 1 (mod 7), so further repeated multiplication (5^7 etc.) will
just repeat previous values.

Then we calculate 5^1 to 5^6 (mod 7), and as expected it cycles
through all numbers relatively prime to 7 because 5 is a primitive
root of 7.

For more examples, please see the documentation of `Caustic.Utils`.

# Contribute

Please send pull requests to <https://github.com/agro1986/caustic>

# Contact

[@agro1986](https://twitter.com/agro1986) on Twitter
