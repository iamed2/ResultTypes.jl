# ResultTypes

[![Build Status](https://travis-ci.org/iamed2/ResultTypes.jl.svg?branch=master)](https://travis-ci.org/iamed2/ResultTypes.jl)
[![codecov](https://codecov.io/gh/iamed2/ResultTypes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/iamed2/ResultTypes.jl)

ResultTypes provides a `Result` type which can hold either a value or an error.
This allows us to return a value or an error in a type-stable manner without throwing an exception.

## Usage

### Basic

We can construct a `Result` that holds a value:

```julia
julia> x = Result(2); typeof(x)
ResultTypes.Result{Int64,ErrorException}
```

or a `Result` that holds an error:

```julia
julia> x = ErrorResult(Int, "Oh noes!"); typeof(x)
ResultTypes.Result{Int64,ErrorException}
```

or either with a different error type:

```julia
julia> x = Result(2, DivideError); typeof(x)
ResultTypes.Result{Int64,DivideError}

julia> x = ErrorResult(Int, DivideError()); typeof(x)
ResultTypes.Result{Int64,DivideError}
```

### Exploiting Function Return Types

We can take advantage of automatic conversions in function returns (a Julia 0.5 feature):

```julia
function integer_division(x::Int, y::Int)::Result{Int, DivideError}
    if y == 0
        return DivideError()
    else
        return div(x, y)
    end
end
```

This allows us to write code in the body of the function that returns either a value or an error without manually constructing `Result` types.

```julia
julia> integer_division(3, 4)
Result(0)

julia> integer_division(3, 0)
ErrorResult(Int64, DivideError())
```

## Evidence of Benefits

### Theoretical

Using the function above, we can use `@code_warntype` to verify that the compiler is doing what we desire:

```julia
julia> @code_warntype integer_division(3,2)
Variables:
  #self#::#integer_division
  x::Int64
  y::Int64

Body:
  begin
      unless (y::Int64 === 0)::Bool goto 4 # line 3:
      return $(Expr(:new, ResultTypes.Result{Int64,DivideError}, :($(Expr(:new, Nullable{Int64}, false))), :($(Expr(:new, Nullable{DivideError}, true, :($(QuoteNode(DivideError()))))))))
      4:  # line 5:
      SSAValue(1) = (Base.checked_sdiv_int)(x::Int64, y::Int64)::Int64
      return $(Expr(:new, ResultTypes.Result{Int64,DivideError}, :($(Expr(:new, Nullable{Int64}, true, SSAValue(1)))), :($(Expr(:new, Nullable{DivideError}, false)))))
  end::ResultTypes.Result{Int64,DivideError}
```

### Experimental

Suppose we have two versions of a function where one returns a value or throws an exception and the other returns a `Result` type.
We want to call the function and return the value if present or a default value if there was an error.
For this example we can use `div` and our `integer_division` function as a microbenchmark (they are too simple to provide a realistic use case).

Here's our wrapping function for `div`:

```julia
function func1(x,y)
   local z
   try
       z = div(x,y)
   catch e
       z = 0
   end

   return z
end
```

and for `integer_division`:

```julia
function func2(x, y)
   r = integer_division(x,y)
   if iserror(r)
       return 0
   else
       return unwrap(r)
   end
end
```

Here are some benchmark results in the average case (on one machine), using [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl):

```julia
julia> using BenchmarkTools

julia> t1 = @benchmark for i = 1:10 func1(3, i % 2) end
BenchmarkTools.Trial:
  memory estimate:  0 bytes
  allocs estimate:  0
  --------------
  minimum time:     299.175 μs (0.00% GC)
  median time:      340.283 μs (0.00% GC)
  mean time:        368.364 μs (0.00% GC)
  maximum time:     1.681 ms (0.00% GC)
  --------------
  samples:          10000
  evals/sample:     1

julia> t2 = @benchmark for i = 1:10 func2(3, i % 2) end
BenchmarkTools.Trial:
  memory estimate:  0 bytes
  allocs estimate:  0
  --------------
  minimum time:     98.093 ns (0.00% GC)
  median time:      111.542 ns (0.00% GC)
  mean time:        120.148 ns (0.00% GC)
  maximum time:     537.122 ns (0.00% GC)
  --------------
  samples:          10000
  evals/sample:     946

julia> judge(mean(t2), mean(t1))
BenchmarkTools.TrialJudgement:
  time:   -99.97% => improvement (5.00% tolerance)
  memory: +0.00% => invariant (1.00% tolerance)
```

As we can see, we get a huge speed improvement without allocating any extra heap memory.

It's also interesting to look at the cost when no error occurs:

```julia
julia> t1 = @benchmark for i = 1:10 func1(3, 1) end
BenchmarkTools.Trial:
  memory estimate:  0 bytes
  allocs estimate:  0
  --------------
  minimum time:     219.074 ns (0.00% GC)
  median time:      236.420 ns (0.00% GC)
  mean time:        252.231 ns (0.00% GC)
  maximum time:     1.049 μs (0.00% GC)
  --------------
  samples:          10000
  evals/sample:     501

julia> t2 = @benchmark for i = 1:10 func2(3, 1) end
BenchmarkTools.Trial:
  memory estimate:  0 bytes
  allocs estimate:  0
  --------------
  minimum time:     150.658 ns (0.00% GC)
  median time:      170.757 ns (0.00% GC)
  mean time:        181.448 ns (0.00% GC)
  maximum time:     1.096 μs (0.00% GC)
  --------------
  samples:          10000
  evals/sample:     555

julia> judge(mean(t2), mean(t1))
BenchmarkTools.TrialJudgement:
  time:   -28.06% => improvement (5.00% tolerance)
  memory: +0.00% => invariant (1.00% tolerance)
```

It's _still faster_ to avoid `try` and use `Result`, even when the error condition is never triggered.
