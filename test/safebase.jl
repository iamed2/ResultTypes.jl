using Test
using ResultTypes
using ResultTypes: iserror
using ResultTypes.SafeBase

@testset "ParseError" begin
    inner_e = ErrorException("Test Error")
    outer_e = ParseError(Int64, 123, "outer exception", Union{Ptr{Nothing},Base.InterpreterIP}[], inner_e)
    inner_msg = sprint(Base.showerror, inner_e)
    outer_msg = sprint(Base.showerror, outer_e)
    @test Base.contains(outer_msg, inner_msg)

    outermost_e = ParseError(Int64, 123, "outermost exception", Union{Ptr{Nothing},Base.InterpreterIP}[], outer_e)
    outermost_msg = sprint(Base.showerror, outermost_e)
    @test Base.contains(outermost_msg, inner_msg)
    @test Base.contains(outermost_msg, outer_msg)
end

@testset "Safe Base" begin
    @testset "Safe parsing" begin
        res = safe_parse(Int, "42")
        @test unwrap(res) == 42

        res = safe_parse(Int, "42/2")
        @test iserror(res)
        e = unwrap_error(res)
        @test e.msg == "Could not parse 42/2 into type Int64"
        @test e.source == ("42/2",)
    end

    @testset "Safe Julia Parsing" begin
        res = safe_parse_julia("foo(bar) = 42")
        @test unwrap(res) isa Expr
        @test unwrap(res).args[1] == :(foo(bar))

        res = safe_parse_julia("/a")
        @test iserror(res)
        e = unwrap_error(res)
        @test e isa ParseError
        @test e.source == "/a"
        @test e.msg == "Failed to parse String into Julia expression"


        @test parse_julia("a") === :a
        @test_throws ParseError parse_julia("/a")


        @test unwrap(safe_parse_julia("color(::Apple)")) == parse_julia("color(::Apple)") == :(color(::Apple))
        @test iserror(safe_parse_julia("(")) # Here `Meta.parse`` gives :incomplete, not `ParseError`.
        @test iserror(safe_parse_julia(")")) # This is `ParseError` with `Meta.parse`` as well.
        @test_throws ParseError parse_julia(")")

        # # Check that parsed expr return types align with `Meta.parse`.
        @test typeof(parse_julia("color(::Apple)")) == typeof(Meta.parse("color(::Apple)")) == Expr
        @test typeof(parse_julia("1")) == typeof(Meta.parse("1")) == Int
        @test typeof(parse_julia("Int")) == typeof(Meta.parse("Int")) == Symbol
        @test typeof(parse_julia(":Int")) == typeof(Meta.parse(":Int")) == Meta.QuoteNode

        # Check multi-expression parsing behaviour.
        ex = parseall_julia("\na = 1\nb = a + 1\n")
        @test Meta.isexpr(ex, :toplevel, 4) && ex.args[2] == :(a = 1) && ex.args[4] == :(b = a + 1)

        # # Check that parse_julia with multi-expression input produces error similar to `Meta.parse`.
        ex = unwrap_error(safe_parse_julia("\na = 1\nb = a + 1\n"))
        @test ex.caused_by.diagnostics[1].message == "unexpected text after parsing statement"
    end

    @testset "Safe Eval" begin
        res = safe_eval(Main, :(div(1, 1)))
        @test unwrap(res) == 1

        res = safe_eval(Main, :(div(1, 0)))
        @test iserror(res)
        e = unwrap_error(res)
        @test e isa EvalError

        res = safe_eval(Main, "div(1, 1)")
        @test unwrap(res) == 1

        res = safe_eval(Main, "div(1, 0")
        @test iserror(res)
        e = unwrap_error(res)
        @test e isa EvalError
    end
end
