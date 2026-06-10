using Dates
using Pkg
using Printf
using Symbolics
using SymbolicIntegration
using SymbolicIntegrationMaxima
using SpecialFunctions: erf, erfi

const RESULT_OK = 0
const RESULT_MAYBE_FAIL = 1
const RESULT_FAIL = 2
const RESULT_EXCEPTION = 3

const METHODS = (
    ("MaximaMethod", MaximaMethod(timeout=10, validate=false)),
    ("RuleBasedMethod", RuleBasedMethod()),
    ("RischMethod", RischMethod()),
)

"""
    BenchmarkCase(name, integrand, variable, expected)

One symbolic integration benchmark case. `expected` is used only as a light
correctness check; results that do not simplify cleanly are reported as
"maybe fail" rather than hard failures.
"""
struct BenchmarkCase
    name::String
    integrand
    variable
    expected
end

@variables x a b

const CASES = [
    BenchmarkCase("polynomial", x^5 + 3x^2 - 7, x, x^6 / 6 + x^3 - 7x),
    BenchmarkCase("rational arctan", 1 / (1 + x^2), x, atan(x)),
    BenchmarkCase("rational log", x / (1 + x^2), x, log(1 + x^2) / 2),
    BenchmarkCase("exponential parameter", exp(a * x), x, exp(a * x) / a),
    BenchmarkCase("trigonometric product", sin(x)^2, x, x / 2 - sin(2x) / 4),
    BenchmarkCase("trigonometric reciprocal", 1 / (1 + cos(x)), x, tan(x / 2)),
    BenchmarkCase("gaussian", exp(-x^2), x, sqrt(Num(π)) * erf(x) / 2),
    BenchmarkCase("positive gaussian", exp(x^2), x, sqrt(Num(π)) * erfi(x) / 2),
    BenchmarkCase("sine integral", sin(x) / x, x, nothing),
    BenchmarkCase("logarithmic integral", 1 / log(x), x, nothing),
    BenchmarkCase("mixed exponential trig", exp(x) * sin(x), x, exp(x) * (sin(x) - cos(x)) / 2),
    BenchmarkCase("symbolic rational", 1 / (a + b * x), x, log(a + b * x) / b),
]

function contains_unresolved_integral(expr)
    hasmethod(SymbolicIntegration.contains_int, Tuple{typeof(expr)}) &&
        return SymbolicIntegration.contains_int(expr)
    return occursin("∫", string(expr))
end

function check_result(computed, expected)
    contains_unresolved_integral(computed) && return RESULT_FAIL
    expected === nothing && return RESULT_OK

    try
        residual = simplify(computed - expected; expand=true)
        isequal(residual, 0) && return RESULT_OK
        return RESULT_MAYBE_FAIL
    catch
        return RESULT_MAYBE_FAIL
    end
end

function run_case(case::BenchmarkCase, method)
    try
        elapsed = @elapsed computed = integrate(case.integrand, case.variable, method)
        return (code=check_result(computed, case.expected), elapsed=elapsed, result=computed)
    catch err
        err isa InterruptException && rethrow()
        return (code=RESULT_EXCEPTION, elapsed=NaN, result=err)
    end
end

status_symbol(code) =
    code == RESULT_OK ? "ok" :
    code == RESULT_MAYBE_FAIL ? "maybe" :
    code == RESULT_FAIL ? "fail" : "except"

function print_summary(rows)
    println()
    println("Summary")
    println("=======")
    for (name, _) in METHODS
        method_rows = filter(row -> row.method == name, rows)
        total_time = sum(row.elapsed for row in method_rows if isfinite(row.elapsed))
        ok = count(row -> row.code == RESULT_OK, method_rows)
        maybe = count(row -> row.code == RESULT_MAYBE_FAIL, method_rows)
        fail = count(row -> row.code == RESULT_FAIL, method_rows)
        except = count(row -> row.code == RESULT_EXCEPTION, method_rows)
        @printf("%-16s ok=%2d maybe=%2d fail=%2d except=%2d total=%.3fs\n",
                name, ok, maybe, fail, except, total_time)
    end
end

function write_csv(rows, output_file)
    open(output_file, "w") do io
        println(io, "case,method,status,time_seconds,result")
        for row in rows
            result_text = replace(string(row.result), '"' => "\"\"")
            println(io, "\"$(row.case)\",$(row.method),$(status_symbol(row.code)),$(row.elapsed),\"$(result_text)\"")
        end
    end
end

function main()
    println("SymbolicIntegrationMaxima difficult-integral comparison")
    println("Date: ", Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))
    println("Package version: ", Pkg.project().version)
    println("Julia version: ", VERSION)
    println("Cases: ", length(CASES))
    println()

    # Warm up each backend before measuring individual cases.
    for (_, method) in METHODS
        try
            integrate(sin(x), x, method)
        catch
        end
    end

    rows = NamedTuple[]
    for case in CASES
        println(case.name, ": ", case.integrand)
        for (name, method) in METHODS
            result = run_case(case, method)
            push!(rows, (case=case.name, method=name, code=result.code,
                         elapsed=result.elapsed, result=result.result))
            @printf("  %-16s %-6s %8.4fs  %s\n",
                    name, status_symbol(result.code), result.elapsed, result.result)
        end
        println()
    end

    print_summary(rows)

    output_dir = joinpath(@__DIR__, "test_results")
    mkpath(output_dir)
    output_file = joinpath(output_dir, "maxima_method_comparison_" *
                                       Dates.format(now(), "yyyy-mm-dd_HH-MM-SS") * ".csv")
    write_csv(rows, output_file)
    println()
    println("Wrote CSV results to: ", output_file)
end

main()
