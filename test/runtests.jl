using Test
using Symbolics
using SymbolicIntegration
using SymbolicIntegrationMaxima
using SpecialFunctions

@variables x a

@testset "Maxima availability" begin
    @test maxima_available()
end

@testset "Symbolics to Maxima serialization" begin
    @test to_maxima(sin(x) + x^2) == "(sin(x)+(x^(2)))"
    @test to_maxima(1 // 2) == "1/2"
    @test to_maxima(x > 0) == "(0<x)"
end

@testset "Maxima parser errors" begin
    @test_throws MaximaError from_maxima("unknown_maxima_function(x)", [x])
    @test_throws MaximaError from_maxima("if x > 0 then x else -x", [x])
    @test_throws MaximaError from_maxima("integrate(foo(x),x)", [x])
end

@testset "Indefinite integrals" begin
    method = MaximaMethod(timeout=10)
    @test isequal(Symbolics.simplify(integrate(sin(x), x, method) + cos(x)), 0)
    @test isequal(Symbolics.simplify(integrate(x^2, x, method) - (x^3) / 3), 0)
    @test isequal(Symbolics.simplify(integrate(exp(a * x), x, method) - exp(a * x) / a), 0)
    @test isequal(Symbolics.simplify(integrate(exp(-(x^2)), x, method) - sqrt(Num(π)) * erf(x) / 2), 0)
    @test occursin("sqrt", string(integrate(exp(-(x^2)), x, method)))
    @test occursin("gamma_incomplete", string(integrate(sin(x) / x, x, method; validate=false)))
    @test occursin("gamma_incomplete", string(integrate(cos(x) / x, x, method; validate=false)))
    @test occursin("gamma_incomplete", string(integrate(1 / log(x), x, method; validate=false)))
    @test occursin("erf", string(integrate(exp(x^2), x, method; validate=false)))
end

@testset "Definite integrals" begin
    method = MaximaMethod(timeout=10, validate=false)
    @test isequal(Symbolics.simplify(integrate(sin(x), x, 0, π, method) - 2), 0)
    @test isequal(Symbolics.simplify(integrate(x, x, 0, a, method) - (a^2) / 2), 0)
    @test isequal(Symbolics.simplify(integrate(exp(-x), x, 0, Inf, method) - 1), 0)
    @test isequal(Symbolics.simplify(integrate(exp(-(x^2)), x, 0, Inf, method) - sqrt(Num(π)) / 2), 0)
    @test isequal(Symbolics.simplify(integrate(sin(x) / x, x, 0, Inf, method) - π / 2), 0)
    @test isequal(Symbolics.simplify(integrate(exp(-a * x), x, 0, Inf, method; assumptions=(a > 0,)) - 1 / a), 0)
end
