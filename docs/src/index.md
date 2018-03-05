# ResultTypes

[![Build Status](https://travis-ci.org/iamed2/ResultTypes.jl.svg?branch=master)](https://travis-ci.org/iamed2/ResultTypes.jl)
[![codecov](https://codecov.io/gh/iamed2/ResultTypes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/iamed2/ResultTypes.jl)

ResultTypes provides a `Result` type which can hold either a value or an error.
This allows us to return a value or an error in a type-stable manner without throwing an exception.

```@meta
DocTestSetup = quote
    using ResultTypes
end
```

## Usage

### Basic

We can construct a `Result` that holds a value:

```jldoctest
julia> x = Result(2); typeof(x)
ResultTypes.Result{Int64,Exception}
```

or a `Result` that holds an error:

```jldoctest
julia> x = ErrorResult(Int, "Oh noes!"); typeof(x)
ResultTypes.Result{Int64,ErrorException}
```

or either with a different error type:

```jldoctest
julia> x = Result(2, DivideError); typeof(x)
ResultTypes.Result{Int64,DivideError}

julia> x = ErrorResult(Int, DivideError()); typeof(x)
ResultTypes.Result{Int64,DivideError}
```

### Exploiting Function Return Types

We can take advantage of automatic conversions in function returns (a Julia 0.5 feature):

```jldoctest integer_division
julia> function integer_division(x::Int, y::Int)::Result{Int, DivideError}
           if y == 0
               return DivideError()
           else
               return div(x, y)
           end
       end
integer_division (generic function with 1 method)
```

This allows us to write code in the body of the function that returns either a value or an error without manually constructing `Result` types.

```jldoctest integer_division
julia> integer_division(3, 4)
Result(0)

julia> integer_division(3, 0)
ErrorResult(Int64, DivideError())
```
