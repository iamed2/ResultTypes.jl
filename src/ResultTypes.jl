__precompile__()

module ResultTypes

using Nullables

export Result, ErrorResult, unwrap, unwrap_error, iserror

struct Result{T, E<:Exception}
    result::Nullable{T}
    error::Nullable{E}
end

Result(x::T) where {T} = Result{T, ErrorException}(Nullable{T}(x), Nullable{ErrorException}())
Result(x::T, ::Type{E}) where {T, E} = Result{T, E}(Nullable{T}(x), Nullable{E}())

function ErrorResult(::Type{T}, e::E) where {T, E<:Exception}
    Result{T, E}(Nullable{T}(), Nullable{E}(e))
end

function ErrorResult(::Type{T}, e::AbstractString="") where T
    Result{T, ErrorException}(Nullable{T}(), Nullable{ErrorException}(ErrorException(e)))
end

function unwrap(r::Result{T, E})::T where {T, E}
    if !isnull(r.result)
        return get(r.result)
    elseif !isnull(r.error)
        throw(get(r.error))
    else
        error("Empty Result{$T, $E} type")
    end
end

function unwrap_error(r::Result{T, E})::E where {T, E}
    if !isnull(r.error)
        return get(r.error)
    else
        error("$r is not an ErrorResult")
    end
end

# To avoid ambiguity errors. For example, when returning `Result` types from a map function
# we end up doing a `convert(::Type{ResultTypes.Result{S,E}}, ::ResultTypes.Result{S,E})`.
function Base.convert(::Type{Result{S, E}}, r::Result{S, E}) where {S, E}
    return r
end

function Base.convert(::Type{T}, r::Result{S, E})::T where {T, S, E}
    unwrap(r)
end

function Base.convert(::Type{Result{S, E}}, x::T) where {T, S, E}
    Result{S, E}(Nullable{S}(convert(S, x)), Nullable{E}())
end

function Base.convert(::Type{Result{T, E}}, e::E) where {T, E}
    Result{T, E}(Nullable{T}(), Nullable{E}(e))
end

function Base.show(io::IO, r::Result{T, E}) where {T, E}
    if iserror(r)
        print(io, "ErrorResult(", T, ", ", unwrap_error(r), ")")
    else
        print(io, "Result(", unwrap(r), ")")
    end
end

iserror(r::Result) = !isnull(r.error)

end # module
