module ResultTypes

export Result, ErrorResult, unwrap, unwrap_error

struct Result{T, E <: Exception}
    result::Union{Some{T}, Nothing}
    error::Union{E, Nothing}
end

"""
    Result(val::T, exception_type::Type{E}=Exception) -> Result{T, E}

Create a `Result` that could hold a value of type `T` or an exception of type `E`, and
store `val` in it.
If the exception type is not provided, the supertype `Exception` is used as `E`.
"""
Result(x::T) where {T} = Result{T, Exception}(Some(x), nothing)

function Result(x::T, ::Type{E}) where {T, E <: Exception}
    return Result{T, E}(Some(x), nothing)
end

# As of Julia 0.7, constructors no longer fall back to convert methods, so we can
# set that up manually to happen. Constructor methods that don't make sense will
# helpfully produce convert MethodErrors.
Result{T, E}(x) where {T, E <: Exception} = convert(Result{T, E}, x)

"""
    ErrorResult(::Type{T}, exception::E) -> Result{T, E}
    ErrorResult(::Type{T}, exception::AbstractString="") -> Result{T, ErrorException}

Create a `Result` that could hold a value of type `T` or an exception of type `E`, and
store `exception` in it.
If the `exception` is provided as text, it is wrapped in the generic `ErrorException`.
If no exception is provided, an `ErrorException` with an empty string is used.
If the type argument is not provided, `Any` is used.

`ErrorResult` is a convenience function for creating a `Result` and is not its own type.
"""
function ErrorResult(::Type{T}, e::E) where {T, E <: Exception}
    return Result{T, E}(nothing, e)
end

function ErrorResult(::Type{T}, e::AbstractString="") where T
    return Result{T, ErrorException}(nothing, ErrorException(e))
end

ErrorResult(e::Union{Exception, AbstractString}="") = ErrorResult(Any, e)

"""
    unwrap(result::Result{T, E}) -> T
    unwrap(val::T) -> T
    unwrap(::Type{T}, result_or_val) -> T

Assumes `result` holds a value of type `T` and returns it.
If `result` holds an exception instead, that exception is thrown.

If `unwrap`'s argument is not a `Result`, it is returned.

The two-argument form of `unwrap` calls `unwrap` on its second argument, then converts it to
type `T`.
"""
function unwrap(r::Result{T, E})::T where {T, E <: Exception}
    if r.result !== nothing
        return something(r.result)
    elseif r.error !== nothing
        throw(r.error)
    else
        error("Empty Result{$T, $E} type")
    end
end

unwrap(x) = x

# auto-converts to T
function unwrap(::Type{T}, x)::T where {T}
    return unwrap(x)
end

"""
    unwrap_error(result::Result{T, E}) -> E
    unwrap_error(exception::E) -> E

Assumes `result` holds an exception of type `E` and returns it.
If `result` holds a value instead, throw an exception.

If `unwrap_error`'s argument is an `Exception`, that exception is returned.
"""
function unwrap_error(r::Result{T, E})::E where {T, E <: Exception}
    if r.error !== nothing
        return r.error
    else
        error("$r is not an ErrorResult")
    end
end

unwrap_error(e::Exception) = e

function Base.promote_rule(
    ::Type{Result{S1, E1}},
    ::Type{Result{S2, E2}},
) where {S1, E1 <: Exception, S2, E2 <: Exception}
    return Result{promote_type(S1, S2), promote_type(E1, E2)}
end

# To avoid ambiguity errors. For example, when returning `Result` types from a map function
# we end up doing a `convert(::Type{ResultTypes.Result{S,E}}, ::ResultTypes.Result{S,E})`.
function Base.convert(::Type{Result{S, E}}, r::Result{S, E}) where {S, E <: Exception}
    return r
end

function Base.convert(::Type{Result{S, E}}, r::Result) where {S, E <: Exception}
    return promote_type(Result{S, E}, typeof(r))(r.result, r.error)
end

function Base.convert(::Type{Result{S, E}}, x::T) where {T, S, E <: Exception}
    return Result{S, E}(Some(convert(S, x)), nothing)
end

function Base.convert(::Type{Result{T, E}}, e::E) where {T, E <: Exception}
    return Result{T, E}(nothing, e)
end

function Base.show(io::IO, r::Result{T, E}) where {T, E <: Exception}
    if iserror(r)
        print(io, "ErrorResult(", T, ", ", unwrap_error(r), ")")
    else
        print(io, "Result(", unwrap(r), ")")
    end
end

"""
    ResultTypes.iserror(x) -> Bool

If `x` is an `Exception`, return `true`.
If `x` is an `ErrorResult` (a `Result` containing an `Exception`), return `true`.
Return `false` in all other cases.
"""
iserror(e::Exception) = true
iserror(r::Result) = r.error !== nothing
iserror(x) = false

end # module
