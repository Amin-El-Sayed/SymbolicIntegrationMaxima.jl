# Proposed Upstream Changes for SymbolicIntegration.jl

## External Backends

Document that external packages can implement:

```julia
struct MyMethod <: AbstractIntegrationMethod
    # backend-specific fields
end

function SymbolicIntegration.integrate(f::Symbolics.Num, x::Symbolics.Num, method::MyMethod; kwargs...)
    # return Symbolics.Num
end
```

## Definite Integrals

Add generic signatures:

```julia
integrate(f::Symbolics.Num, x::Symbolics.Num, a, b)
integrate(f::Symbolics.Num, x::Symbolics.Num, a, b, method::AbstractIntegrationMethod; kwargs...)
```

Fallback behavior:

1. Compute `F = integrate(f, x, method; kwargs...)`.
2. If `F` is still an unevaluated integral, return an unevaluated definite integral.
3. Otherwise return `substitute(F, x => b) - substitute(F, x => a)`.

Backends with direct definite integration, such as Maxima, should specialize this
method.

## Default Method

Add an explicit user-controlled default:

```julia
set_default_integration_method!(method_or_chain)
get_default_integration_method()
```

Loading an external backend should not silently change the default. Users should
opt in:

```julia
using SymbolicIntegration
using SymbolicIntegrationMaxima

set_default_integration_method!(MaximaMethod())
```
