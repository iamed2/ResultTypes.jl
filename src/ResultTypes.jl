module ResultTypes

export Result, ErrorResult, unwrap, unwrap_error, iserror

immutable Result{T, E<:Exception}
    result::Nullable{T}
    error::Nullable{E}
end

Result{T}(x::T) = Result{T, ErrorException}(Nullable{T}(x), Nullable{ErrorException}())
Result{T, E}(x::T, ::Type{E}) = Result{T, E}(Nullable{T}(x), Nullable{E}())

function ErrorResult{T, E<:Exception}(::Type{T}, e::E)
    Result{T, E}(Nullable{T}(), Nullable{E}(e))
end

function ErrorResult{T}(::Type{T}, e::AbstractString="")
    Result{T, ErrorException}(Nullable{T}(), Nullable{ErrorException}(ErrorException(e)))
end

function unwrap{T, E}(r::Result{T, E})::T
    if !isnull(r.result)
        return get(r.result)
    elseif !isnull(r.error)
        throw(get(r.error))
    else
        error("Empty Result{$T, $E} type")
    end
end

function unwrap_error{T, E}(r::Result{T, E})::E
    if !isnull(r.error)
        return get(r.error)
    else
        error("$r is not an ErrorResult")
    end
end

Base.convert{T, S, E}(::Type{T}, r::Result{S, E})::T = unwrap(r)

function Base.convert{T, S, E}(::Type{Result{S, E}}, x::T)
    Result{S, E}(Nullable{S}(convert(S, x)), Nullable{E}())
end

function Base.convert{T, E}(::Type{Result{T, E}}, e::E)
    Result{T, E}(Nullable{T}(), Nullable{E}(e))
end

function Base.show{T, E}(io::IO, r::Result{T, E})
    if iserror(r)
        print(io, "ErrorResult(", T, ", ", unwrap_error(r), ")")
    else
        print(io, "Result(", unwrap(r), ")")
    end
end

iserror(r::Result) = !isnull(r.error)

end # module
