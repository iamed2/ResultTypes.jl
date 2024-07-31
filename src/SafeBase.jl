"""
This module contains definitions of common `Base` functions, but 
returning a `Result` type. Such functions start with the `safe_` prefix.

It also contains some specific errors that meant to be more informative.
"""
module SafeBase

export ParseError, safe_parse, EvalError, safe_eval

"A stack trace, as would be accessed when catching an exception."
const Backtrace = Vector{Union{Base.InterpreterIP, Ptr{Nothing}}}

"""
An error when parsing an object of one type into another type.

`source` is the object from that was attempted to be parsed and `target`
is the desired destination type.
"""
struct ParseError <: Exception
  target::Type
  source::Any
  msg::String
  bt::Backtrace
  caused_by::Union{Exception, Nothing}
end

ParseError(target::Type, source::Any, msg::String, bt::Backtrace) =
  ParseError(target::Type, source::Any, msg::String, bt::Backtrace, nothing)

function Base.showerror(io::IO, err::ParseError)
  (; target, source, msg, bt, caused_by) = err
  print(io, "$(typeof(err)): Failed to parse object '$source' into type '$target': $msg")
  Base.show_backtrace(io, bt)
  if !isnothing(caused_by)
    print(io, "\nCaused by:\n")
    showerror(io, err.caused_by)
  end
end

"""
    safe_parse(T, ex)::Result{T, ParseError}

This function should behave like `Base.parse` and `Base.tryparse`. 
It takes a type `T` and a value `ex` to parse, but returns a 
`Result{T, ParseError}` from ResultTypes.jl on failure instead.

- `Base.parse` throws on failure, returns value otherwise
- `Base.tryparse` returns `nothing` on failure, returns value otherwise
- `JuliaModule.safe_parse` returns a `Result{T, ParseError}`.

Please define methods for this function and avoid extending `Base.tryparse` and 
`Base.parse`, as Result types in Julia are generally more performant than throwing exceptions 
and provide cleaner control flow and error reporting than the other solutions. 
"""
function safe_parse end

function safe_parse(T::Type{<:Union{<:AbstractFloat, <:Integer}}, slurp...; kwargs)::Result{T, ParseError}
  res = tryparse(T, slurp...; kwargs)
  isnothing(res) && return ParseError(T, slurp, "Could not parse $(slurp...) into type $T", backtrace())
  res
end

# ---------------------------
# Evaluation 


struct EvalError <: Exception
  mod::Module
  expr::Union{Expr, Symbol}
  exc::Exception
  bt::Backtrace
end

format_code(ex::Symbol) = repr(ex)

function Base.showerror(io::IO, err::EvalError)
  expression_str = replace(repr(err.expr), r"^"m => "  ")

  print(io, "EvalError: ")
  print(
    io,
    """
    Error while evaluating expression:

    $expression_str

    in module `$(err.mod)`, caused by:

    """,
  )
  Base.display_error(io, err.exc, err.bt)
end

"""
Evaluate expression `expr` in module `m` (defaulting to `Kamchatka`).

This function can optionally throw if an exception is encountered.
Otherwise, a silent failure is indicated by returning `nothing`.
"""
function safe_eval(m::Module, expr)::Result{Any, EvalError}
  try
    Core.eval(m, expr)
  catch e
    EvalError(m, expr, e, catch_backtrace())
  end
end

function safe_eval(m::Module, expr::AbstractString; parse_kws...)::Result{Any, EvalError}
  expr = safe_parse_julia(expr; parse_kws...)
  iserror(expr) ? EvalError(m, :error, unwrap_error(expr), backtrace()) : tryeval(m, unwrap(expr))
end

end