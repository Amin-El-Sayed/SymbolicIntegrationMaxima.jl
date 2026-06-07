# SymbolicIntegrationMaxima.jl

Optional Maxima backend for `SymbolicIntegration.jl`.

The package extends the existing method interface instead of introducing a
parallel integration API:

```julia
using Symbolics
using SymbolicIntegration
using SymbolicIntegrationMaxima

@variables x a

integrate(sin(x), x, MaximaMethod())
integrate(sin(x), x, 0, π, MaximaMethod())
integrate(exp(a*x), x, MaximaMethod())
integrate(exp(-x^2), x, MaximaMethod())
integrate(exp(-x^2), x, 0, Inf, MaximaMethod())
integrate(exp(-a*x), x, 0, Inf, MaximaMethod(); assumptions=(a > 0,))
```

Maxima must be installed and available as `maxima` on `PATH`.

## Installation

Until the package is registered, develop it from a local checkout:

```julia
using Pkg
Pkg.develop(path="/path/to/SymbolicIntegrationMaxima.jl")
```

Maxima is an external runtime dependency:

```bash
brew install maxima        # macOS
sudo apt install maxima    # Debian/Ubuntu
```

On Windows, install the latest 64-bit Maxima installer from the official Maxima
downloads page. After installation, make sure `maxima` is available on `PATH`;
`maxima_available()` should return `true` from Julia.

## Design

- `MaximaMethod <: SymbolicIntegration.AbstractIntegrationMethod`
- direct process bridge to Maxima
- no dependency on `Maxima.jl`
- explicit backend selection via `integrate(f, x, MaximaMethod())`
- direct Maxima support for definite integrals
- support for common Maxima special-function results such as `erf` and
  `gamma_incomplete`

This package deliberately does not override `SymbolicIntegration.integrate(f, x)`.
Changing the default backend should happen through a small upstream hook in
`SymbolicIntegration.jl`.

## Current Coverage

The backend delegates integration to Maxima, but the Julia bridge must still
translate expressions in both directions. The current parser covers:

- arithmetic, powers, rational numbers, `π`, `im`, `Inf`, `-Inf`
- `sin`, `cos`, `tan`, inverse trig, hyperbolic trig
- `exp`, `log`, `sqrt`, `abs`
- `erf`, `erfc`, `gamma`
- symbolic placeholders for Maxima-only functions:
  `gamma_incomplete`, `expintegral_e`, `sin_integral`, `cos_integral`

Unsupported Maxima output forms intentionally throw `MaximaError` instead of
silently returning a wrong expression.

## Validation

`MaximaMethod(validate=false)` is the default. Validation differentiates the
returned antiderivative with Symbolics and is useful for simple elementary
results, but it is not reliable for all special functions. Use it explicitly
when desired:

```julia
integrate(sin(x), x, MaximaMethod(validate=true))
```

## Upstream Hooks To Propose

```julia
set_default_integration_method!(method_or_chain)
get_default_integration_method()

integrate(f, x, a, b)
integrate(f, x, a, b, method::AbstractIntegrationMethod)
```

For native methods without direct definite integration, the generic fallback can
compute an antiderivative and substitute the bounds. `MaximaMethod` should keep
its direct Maxima implementation.
