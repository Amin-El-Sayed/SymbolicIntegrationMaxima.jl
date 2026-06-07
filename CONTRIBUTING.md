# Contributing

This package is intended to stay small: it should extend `SymbolicIntegration.jl`
with a Maxima backend, not become a general Maxima wrapper.

## Development

Install Maxima first. On macOS with Homebrew:

```bash
brew install maxima
```

Run tests from the package root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

## Parser Policy

Every newly supported Maxima output form should come with a regression test.
Unsupported output must throw `MaximaError`; returning an incorrect Symbolics
expression is worse than failing loudly.

## Pull Requests

- Keep PRs focused on one feature or parser extension.
- Add tests for both successful and intentionally unsupported behavior.
- Document public API changes in `README.md` and docstrings.
