"""
This module contains definitions of common `Base` functions, but
returning a `Result` type. Such functions start with the `safe_` prefix.

It also contains some specific errors that meant to be more informative.
"""
module SafeBase

using JuliaSyntax
using ..ResultTypes
using ..ResultTypes: iserror
export ParseError, safe_parse, safe_parse_julia, safe_parseall_julia, parse_julia, parseall_julia, EvalError, safe_eval

"""
    ParseError(target::Type, source::Any, msg::String, bt::Any)

An error when parsing an object of one type into another type.

`source` is the object from that was attempted to be parsed and `target`
is the desired destination type.
"""
struct ParseError <: Exception
  target::Type
  source::Any
  msg::String
  "A backtrace as returned by `backtraced()`"
  bt::Any
  caused_by::Union{Exception,Nothing}
end

ParseError(target::Type, source::Any, msg::String, bt::Any) =
  ParseError(target::Type, source::Any, msg::String, bt::Any, nothing)

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

function safe_parse(T::Type{<:Union{<:AbstractFloat,<:Integer}}, slurp...; kwargs...)::Result{T,ParseError}
  res = tryparse(T, slurp...; kwargs...)
  isnothing(res) && return ParseError(T, slurp, "Could not parse $(slurp...) into type $T", backtrace())
  res
end


# ---------------------------------------
# # Julia parsing

"""
    safe_parse_julia(str::AbstractString, rule::Symbol=:statement, filename::Union{Nothing,String}=nothing)

Alternative to `Meta.parse` based on `JuliaSyntax.jl` library. Function doesn't throw, but wraps the result of parsing `str` (or error) in a `Result`.
As opposed to `Meta.parse`, `:error` and `:incomplete` expressions both are treated as `ParseError`.

Optional argument `rule` can accept values :statement or :all, indicating parsing single-expression vs multi-expression inputs, respectively.
Optional argument `filename` is passed to set any file name information, if applicable. This will also annotate errors and warnings with the
source file name.

Implementation of this function mimics [JuliaSyntax._parse](https://github.com/JuliaLang/JuliaSyntax.jl/blob/3bf262bba32e833ed6d0d59a455a62faee97b408/src/parser_api.jl#L77)
"""
function safe_parse_julia(
  str::AbstractString,
  rule::Symbol=:statement,
  filename::Union{Nothing,String}=nothing,
)::Result{Any,ParseError}
  stream = JuliaSyntax.ParseStream(str)

  JuliaSyntax.parse!(stream; rule)

  if peek(stream, skip_newlines=false, skip_whitespace=false) != K"EndMarker"
    JuliaSyntax.emit_diagnostic(stream, error="unexpected text after parsing $rule")
  end

  if JuliaSyntax.any_error(stream.diagnostics) || !JuliaSyntax.isempty(stream.diagnostics)
    ex = JuliaSyntax.ParseError(stream; filename)
    return ParseError(Any, str, "Failed to parse String into Julia expression", backtrace(), ex)
  end
  JuliaSyntax.build_tree(Expr, stream; filename)
end

parse_julia(
  str::AbstractString,
  rule::Symbol=:statement,
  filename::Union{Nothing,String}=nothing,
) = unwrap(safe_parse_julia(str, rule, filename))

"""
    safe_parseall_julia(str::AbstractString, filename::Union{Nothing,String}=nothing)

Alternative to `Meta.parseall` that does not return incomplete expressions and doesn't throw, but wraps the result
of parsing `str` (or error) in a `Result`.
Optionally, a `filename` argument can be passed to attach it to the parsed `LineNumberNode`s.
"""
safe_parseall_julia(str::AbstractString, filename::Union{Nothing,String}=nothing) =
  safe_parse_julia(str, :all, filename)

"""
    parseall_julia(str::AbstractString, filename::Union{Nothing,String}=nothing)

Alternative to `Meta.parseall` that does not return incomplete expressions. Throws on error.
Optionally, a filename argument can be passed to attach it to the parsed `LineNumberNode`s.
"""
parseall_julia(str::AbstractString, filename::Union{Nothing,String}=nothing) = parse_julia(str, :all, filename)


# ---------------------------
# Evaluation


struct EvalError <: Exception
  mod::Module
  expr::Union{Expr,Symbol}
  exc::Exception
  "A backtrace as returned by `backtraced()`"
  bt::Any
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
    safe_eval(m::Module, expr::Any)::Result{Any,EvalError}

Evaluate a Julia expression `expr` in module `m`.

This function can optionally throw if an exception is encountered.
Otherwise, a silent failure is indicated by returning `nothing`.
"""
function safe_eval(m::Module, expr::Any)::Result{Any,EvalError}
  try
    Core.eval(m, expr)
  catch e
    EvalError(m, expr, e, catch_backtrace())
  end
end

function safe_eval(m::Module, expr::AbstractString; parse_kws...)::Result{Any,EvalError}
  expr = safe_parse_julia(expr; parse_kws...)
  iserror(expr) ? EvalError(m, :error, unwrap_error(expr), backtrace()) : safe_eval(m, unwrap(expr))
end

end
