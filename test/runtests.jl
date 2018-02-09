using ResultTypes
using Compat.Test
using Nullables

@testset "ResultTypes" begin

@testset "Result" begin
    @testset "Basic result" begin
        x = Result(2)
        @test unwrap(x) === 2
        @test_throws ErrorException unwrap_error(x)
        @test iserror(x) === false
    end

    @testset "Result with error type" begin
        x = Result(2, DivideError)
        @test unwrap(x) === 2
        @test_throws ErrorException unwrap_error(x)
        @test iserror(x) === false
    end

    @testset "Malformed result" begin
        x = Result(Nullable{Int}(), Nullable{DivideError}())
        @test_throws ErrorException unwrap(x)
        @test_throws ErrorException unwrap_error(x)
    end
end

@testset "ErrorResult" begin
    @testset "Basic error" begin
        x = ErrorResult(Int, "Basic Error")
        @test_throws ErrorException unwrap(x)
        e = unwrap_error(x)
        @test isa(e, ErrorException)
        @test e.msg == "Basic Error"
        @test iserror(x) === true
    end

    @testset "Empty error" begin
        x = ErrorResult(Int)
        @test_throws ErrorException unwrap(x)
        e = unwrap_error(x)
        @test isa(e, ErrorException)
        @test iserror(x) === true
    end

    @testset "Typed Error" begin
        x = ErrorResult(Int, DivideError())
        @test_throws DivideError unwrap(x)
        @test isa(unwrap_error(x), DivideError)
        @test iserror(x) === true
    end
end

@testset "Convert" begin
    @testset "From Result" begin
        x = Result(2)
        @test convert(Int, x) === 2
        @test convert(Float64, x) === 2.0
        @test_throws MethodError convert(String, x)
    end

    @testset "From ErrorResult" begin
        x = ErrorResult(Int, "Foo")
        @test_throws ErrorException convert(Int, x)
    end

    @testset "To Result" begin
        x = convert(Result{Int, ErrorException}, 2.0)
        @test unwrap(x) === 2
        @test isa(x, Result{Int, ErrorException})
    end

    @testset "To ErrorResult" begin
        x = convert(Result{Int, DivideError}, DivideError())
        @test unwrap_error(x) == DivideError()
        @test isa(x, Result{Int, DivideError})
    end
end

@testset "Return" begin
    let
        function foo(x::Int, y::Int)::Result{Int, DivideError}
            try
                return div(x, y)
            catch e
                return e
            end
        end

        x = foo(3, 2)
        @test isa(x, Result{Int, DivideError})
        @test unwrap(x) === 1

        y = foo(1, 0)
        @test isa(y, Result{Int, DivideError})
        @test unwrap_error(y) == DivideError()
    end
end

@testset "Show" begin
    @testset "Result" begin
        x = Result(2)

        @test isa(string(x), String)
    end

    @testset "ErrorResult" begin
        x = ErrorResult(Int, "Basic Error")
        @test isa(string(x), String)
    end
end

end
