# Caustic Cryptocurrency Library

Caustic is an Elixir library of useful methods used in various cryptocurrencies
(Bitcoin, Ethereum, etc.).

Warning: This library is developed for learning purposes. Please do not
use for production.

# Documentation

https://hexdocs.pm/caustic/

# Installation

```elixir
def deps do
  [
    {:caustic, "~> 0.1.17"}
  ]
end
```

# Usage

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
